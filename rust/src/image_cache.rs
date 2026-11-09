use std::fs;

use md5::{Digest, Md5};
use serde_json::{json, Value};

use crate::db::store;
use crate::net::{rewrite_image_server, Http};
use crate::paths::Paths;

pub struct ImageCache;

impl ImageCache {
    pub fn new() -> Self {
        Self
    }

    pub async fn load(
        &self,
        http: &Http,
        paths: &Paths,
        db: &crate::db::Databases,
        file_server: &str,
        path: &str,
        preload: bool,
    ) -> Result<Value, String> {
        {
            let conn = db.comic.lock().map_err(|e| e.to_string())?;
            if let Some(found) = store::find_remote(&conn, file_server, path)? {
                let id = found["id"].as_i64().unwrap_or(0);
                let _ = store::touch_remote(&conn, id);
                if preload {
                    return Ok(Value::Null);
                }
                return Ok(display(paths, &found));
            }
        }
        let settings = http.settings();
        let server = rewrite_image_server(file_server, settings.image_index);
        let url = format!("{}/static/{}", server.trim_end_matches('/'), path.trim_start_matches('/'));
        let (status, bytes) = http
            .direct("GET", &url, &[("user-agent", "okhttp/3.8.1".into())], None)
            .await?;
        if status != 200 {
            return Err(format!("图片状态码 {status}"));
        }
        let (format, width, height) = decode_info(&bytes)?;
        let name = format!("{:x}", Md5::digest(format!("{file_server}${path}").as_bytes()));
        let real = paths.remote_file(&name);
        fs::write(&real, &bytes).map_err(|e| e.to_string())?;
        {
            let conn = db.comic.lock().map_err(|e| e.to_string())?;
            store::save_remote(
                &conn,
                file_server,
                path,
                bytes.len() as i64,
                &format,
                width,
                height,
                &name,
            )?;
            if preload {
                return Ok(Value::Null);
            }
            let found = store::find_remote(&conn, file_server, path)?.unwrap_or(json!({
                "fileSize": bytes.len(),
                "format": format,
                "width": width,
                "height": height,
                "localPath": name,
            }));
            Ok(display(paths, &found))
        }
    }
}

fn display(paths: &Paths, found: &Value) -> Value {
    json!({
        "fileSize": found["fileSize"].as_i64().unwrap_or(0),
        "format": found["format"].as_str().unwrap_or(""),
        "width": found["width"].as_i64().unwrap_or(0),
        "height": found["height"].as_i64().unwrap_or(0),
        "finalPath": paths.remote_file(found["localPath"].as_str().unwrap_or("")).to_string_lossy(),
    })
}

pub fn decode_info(bytes: &[u8]) -> Result<(String, i64, i64), String> {
    let format = image::guess_format(bytes).map_err(|e| e.to_string())?;
    let name = match format {
        image::ImageFormat::Jpeg => "jpeg",
        image::ImageFormat::Png => "png",
        image::ImageFormat::Gif => "gif",
        image::ImageFormat::WebP => "webp",
        other => return Err(format!("不支持的图片格式 {other:?}")),
    };
    let img = image::load_from_memory(bytes).map_err(|e| e.to_string())?;
    Ok((name.to_string(), img.width() as i64, img.height() as i64))
}

pub async fn fetch_bytes(http: &Http, file_server: &str, path: &str) -> Result<Vec<u8>, String> {
    let settings = http.settings();
    let server = rewrite_image_server(file_server, settings.image_index);
    let url = format!("{}/static/{}", server.trim_end_matches('/'), path.trim_start_matches('/'));
    let (status, bytes) = http
        .direct("GET", &url, &[("user-agent", "okhttp/3.8.1".into())], None)
        .await?;
    if status != 200 {
        return Err(format!("图片状态码 {status}"));
    }
    Ok(bytes)
}
