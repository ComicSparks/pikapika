use std::fs;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;
use std::time::Duration;

use serde_json::{json, Value};
use tokio::time::sleep;

use crate::app::App;
use crate::db::store;
use crate::events;
use crate::image_cache::{decode_info, fetch_bytes};
use crate::pica::at;

pub struct DownloadCtl {
    pub running: AtomicBool,
}

impl DownloadCtl {
    pub fn new() -> Self {
        Self {
            running: AtomicBool::new(true),
        }
    }
}

pub async fn run(app: Arc<App>) {
    loop {
        if app.download.running.load(Ordering::SeqCst) {
            if let Err(err) = step(&app).await {
                events::emit_export(&format!("下载出错: {err}"));
            }
        }
        sleep(Duration::from_millis(800)).await;
    }
}

async fn step(app: &App) -> Result<(), String> {
    {
        let conn = app.db.comic.lock().map_err(|e| e.to_string())?;
        if let Some(item) = store::deleting_one(&conn)? {
            let id = item["id"].as_str().unwrap_or("").to_string();
            drop(conn);
            let _ = fs::remove_dir_all(app.paths.download_file(&id));
            let conn = app.db.comic.lock().map_err(|e| e.to_string())?;
            store::delete_download_tree(&conn, &id)?;
            return Ok(());
        }
    }
    let comic = {
        let conn = app.db.comic.lock().map_err(|e| e.to_string())?;
        store::next_download(&conn)?
    };
    let Some(comic) = comic else {
        return Ok(());
    };
    events::emit_download(&comic.to_string());
    let comic_id = comic["id"].as_str().unwrap_or("").to_string();
    let eps = {
        let conn = app.db.comic.lock().map_err(|e| e.to_string())?;
        store::list_eps(&conn, &comic_id)?
    };
    for ep in eps {
        if !app.download.running.load(Ordering::SeqCst) {
            return Ok(());
        }
        if ep["fetchedPictures"].as_bool().unwrap_or(false) || ep["downloadFailed"].as_bool().unwrap_or(false) {
            continue;
        }
        let ep_id = ep["id"].as_str().unwrap_or("").to_string();
        let order = ep["epOrder"].as_i64().unwrap_or(0);
        match fetch_ep_pictures(app, &comic_id, &ep_id, order).await {
            Ok(count) => {
                let conn = app.db.comic.lock().map_err(|e| e.to_string())?;
                store::mark_ep_fetched(&conn, &ep_id, count)?;
                store::bump_selected_pictures(&conn, &comic_id, count)?;
            }
            Err(_) => {
                let conn = app.db.comic.lock().map_err(|e| e.to_string())?;
                store::mark_ep_failed(&conn, &ep_id)?;
            }
        }
    }
    let threads = app
        .prop("downloadThreadCount", "1")
        .ok()
        .and_then(|value| value.parse::<i64>().ok())
        .unwrap_or(1)
        .clamp(1, 16);
    for _ in 0..threads {
        if !app.download.running.load(Ordering::SeqCst) {
            return Ok(());
        }
        let picture = {
            let conn = app.db.comic.lock().map_err(|e| e.to_string())?;
            store::next_picture(&conn, &comic_id)?
        };
        let Some(picture) = picture else {
            break;
        };
        if download_one(app, &picture).await.is_err() {
            let conn = app.db.comic.lock().map_err(|e| e.to_string())?;
            store::picture_failed(&conn, picture["id"].as_str().unwrap_or(""))?;
        }
    }
    if let Some(updated) = {
        let conn = app.db.comic.lock().map_err(|e| e.to_string())?;
        store::find_download(&conn, &comic_id)?
    } {
        events::emit_download(&updated.to_string());
    }
    Ok(())
}

async fn fetch_ep_pictures(app: &App, comic_id: &str, ep_id: &str, order: i64) -> Result<i64, String> {
    let mut page = 1i64;
    let mut pictures = Vec::new();
    loop {
        let token = app.pica.lock().map_err(|e| e.to_string())?.token.clone();
        if token.is_empty() {
            return Err("未登录".into());
        }
        let path = format!("comics/{comic_id}/order/{order}/pages?page={page}");
        let value = {
            let pica = app.pica.lock().map_err(|e| e.to_string())?.clone();
            pica.get(&app.http, &path).await?
        };
        let docs = at(&value, &["data", "pages", "docs"]);
        let pages = at(&value, &["data", "pages", "pages"]).as_i64().unwrap_or(page);
        let Some(list) = docs.as_array() else {
            break;
        };
        if list.is_empty() {
            break;
        }
        for (index, doc) in list.iter().enumerate() {
            let media = &doc["media"];
            pictures.push(json!({
                "id": doc["_id"].as_str().unwrap_or(""),
                "comicId": comic_id,
                "epId": ep_id,
                "epOrder": order,
                "rankInEp": (page - 1) * 40 + index as i64 + 1,
                "originalName": media["originalName"].as_str().unwrap_or(""),
                "fileServer": media["fileServer"].as_str().unwrap_or(""),
                "path": media["path"].as_str().unwrap_or(""),
            }));
        }
        if page >= pages {
            break;
        }
        page += 1;
    }
    let count = pictures.len() as i64;
    let conn = app.db.comic.lock().map_err(|e| e.to_string())?;
    store::insert_pictures(&conn, &pictures)?;
    Ok(count)
}

async fn download_one(app: &App, picture: &Value) -> Result<(), String> {
    let file_server = picture["fileServer"].as_str().unwrap_or("");
    let path = picture["path"].as_str().unwrap_or("");
    let bytes = fetch_bytes(&app.http, file_server, path).await?;
    let (format, width, height) = decode_info(&bytes)?;
    let rel = format!(
        "{}/{}/{}",
        picture["comicId"].as_str().unwrap_or(""),
        picture["epOrder"].as_i64().unwrap_or(0),
        picture["rankInEp"].as_i64().unwrap_or(0)
    );
    let real = app.paths.download_file(&rel);
    if let Some(parent) = real.parent() {
        fs::create_dir_all(parent).map_err(|e| e.to_string())?;
    }
    fs::write(&real, &bytes).map_err(|e| e.to_string())?;
    let conn = app.db.comic.lock().map_err(|e| e.to_string())?;
    store::picture_success(
        &conn,
        picture["id"].as_str().unwrap_or(""),
        picture["epId"].as_str().unwrap_or(""),
        picture["comicId"].as_str().unwrap_or(""),
        bytes.len() as i64,
        &format,
        width,
        height,
        &rel,
    )?;
    Ok(())
}

pub async fn save_logo(app: &App, comic: &Value) -> Result<(), String> {
    let server = comic["thumbFileServer"].as_str().unwrap_or("");
    let path = comic["thumbPath"].as_str().unwrap_or("");
    if server.is_empty() || path.is_empty() {
        return Ok(());
    }
    let bytes = fetch_bytes(&app.http, server, path).await?;
    let (format, width, height) = decode_info(&bytes)?;
    let id = comic["id"].as_str().unwrap_or("");
    let rel = format!("{id}/logo");
    let real = app.paths.download_file(&rel);
    if let Some(parent) = real.parent() {
        fs::create_dir_all(parent).map_err(|e| e.to_string())?;
    }
    fs::write(&real, &bytes).map_err(|e| e.to_string())?;
    let conn = app.db.comic.lock().map_err(|e| e.to_string())?;
    store::update_logo(&conn, id, bytes.len() as i64, &format, width, height, &rel)
}
