use rusqlite::{params, Connection, OptionalExtension};
use serde_json::{json, Value};

use super::rows::{bool_i, gb, gi, gs, now_millis, now_rfc3339, now_sqlite, to_rfc3339};

pub fn load_property(conn: &Connection, name: &str, default_value: &str) -> Result<String, String> {
    let mut stmt = conn
        .prepare("SELECT v FROM properties WHERE k = ?1 AND deleted_at IS NULL")
        .map_err(|e| e.to_string())?;
    let value = stmt
        .query_row(params![name], |row| row.get::<_, Option<String>>(0))
        .optional()
        .map_err(|e| e.to_string())?;
    Ok(value.flatten().unwrap_or_else(|| default_value.to_string()))
}

pub fn save_property(conn: &Connection, name: &str, value: &str) -> Result<(), String> {
    let now = now_sqlite();
    let changed = conn
        .execute(
            "UPDATE properties SET v = ?1, updated_at = ?2 WHERE k = ?3 AND deleted_at IS NULL",
            params![value, now, name],
        )
        .map_err(|e| e.to_string())?;
    if changed == 0 {
        conn.execute(
            "INSERT INTO properties (created_at, updated_at, deleted_at, k, v) VALUES (?1, ?2, NULL, ?3, ?4)",
            params![now, now, name, value],
        )
        .map_err(|e| e.to_string())?;
    }
    Ok(())
}

pub fn load_cache(conn: &Connection, key: &str, expire_ms: i64) -> Result<String, String> {
    let mut stmt = conn
        .prepare("SELECT v, updated_at FROM network_caches WHERE k = ?1 AND deleted_at IS NULL")
        .map_err(|e| e.to_string())?;
    let row = stmt
        .query_row(params![key], |row| {
            Ok((gs(row, "v"), gs(row, "updated_at")))
        })
        .optional()
        .map_err(|e| e.to_string())?;
    if let Some((value, updated)) = row {
        if cache_fresh(&updated, expire_ms) {
            return Ok(value);
        }
    }
    Ok(String::new())
}

fn cache_fresh(updated: &str, expire_ms: i64) -> bool {
    if expire_ms <= 1 {
        return false;
    }
    let rfc = to_rfc3339(updated);
    if let Ok(dt) = chrono::DateTime::parse_from_rfc3339(&rfc) {
        let age = chrono::Utc::now().signed_duration_since(dt.with_timezone(&chrono::Utc));
        return age.num_milliseconds() < expire_ms;
    }
    false
}

pub fn save_cache(conn: &Connection, key: &str, value: &str) -> Result<(), String> {
    let now = now_sqlite();
    let changed = conn
        .execute(
            "UPDATE network_caches SET v = ?1, updated_at = ?2 WHERE k = ?3 AND deleted_at IS NULL",
            params![value, now, key],
        )
        .map_err(|e| e.to_string())?;
    if changed == 0 {
        conn.execute(
            "INSERT INTO network_caches (created_at, updated_at, deleted_at, k, v) VALUES (?1, ?2, NULL, ?3, ?4)",
            params![now, now, key, value],
        )
        .map_err(|e| e.to_string())?;
    }
    Ok(())
}

pub fn clear_cache(conn: &Connection) -> Result<(), String> {
    conn.execute("DELETE FROM network_caches", [])
        .map_err(|e| e.to_string())?;
    Ok(())
}

pub fn remove_cache_like(conn: &Connection, key: &str) -> Result<(), String> {
    conn.execute("DELETE FROM network_caches WHERE k = ?1", params![key])
        .map_err(|e| e.to_string())?;
    Ok(())
}

fn view_json(row: &rusqlite::Row) -> Value {
    json!({
        "id": gs(row, "id"),
        "createdAt": to_rfc3339(&gs(row, "created_at")),
        "updatedAt": to_rfc3339(&gs(row, "updated_at")),
        "title": gs(row, "title"),
        "author": gs(row, "author"),
        "pagesCount": gi(row, "pages_count"),
        "epsCount": gi(row, "eps_count"),
        "finished": gb(row, "finished"),
        "categories": gs(row, "categories"),
        "thumbOriginalName": gs(row, "thumb_original_name"),
        "thumbFileServer": gs(row, "thumb_file_server"),
        "thumbPath": gs(row, "thumb_path"),
        "likesCount": gi(row, "likes_count"),
        "description": gs(row, "description"),
        "chineseTeam": gs(row, "chinese_team"),
        "tags": gs(row, "tags"),
        "allowDownload": gb(row, "allow_download"),
        "viewsCount": gi(row, "views_count"),
        "isFavourite": gb(row, "is_favourite"),
        "isLiked": gb(row, "is_liked"),
        "commentsCount": gi(row, "comments_count"),
        "lastViewTime": to_rfc3339(&gs(row, "last_view_time")),
        "lastViewEpOrder": gi(row, "last_view_ep_order"),
        "lastViewEpTitle": gs(row, "last_view_ep_title"),
        "lastViewPictureRank": gi(row, "last_view_picture_rank"),
        "pinnedAt": gi(row, "pinned_at"),
    })
}

pub fn upsert_view_info(conn: &Connection, comic: &Value) -> Result<(), String> {
    let id = comic.get("id").and_then(|v| v.as_str()).unwrap_or("").to_string();
    if id.is_empty() {
        return Err("缺少漫画 id".into());
    }
    let now = now_sqlite();
    let exists = conn
        .query_row(
            "SELECT 1 FROM comic_views WHERE id = ?1",
            params![id],
            |_| Ok(()),
        )
        .optional()
        .map_err(|e| e.to_string())?
        .is_some();
    let categories = json_text(comic.get("categories"));
    let tags = json_text(comic.get("tags"));
    let thumb = comic.get("thumb").cloned().unwrap_or(Value::Null);
    if exists {
        conn.execute(
            "UPDATE comic_views SET updated_at=?1, title=?2, author=?3, pages_count=?4, eps_count=?5,
             finished=?6, categories=?7, thumb_original_name=?8, thumb_file_server=?9, thumb_path=?10,
             likes_count=?11, description=?12, chinese_team=?13, tags=?14, allow_download=?15,
             views_count=?16, is_favourite=?17, is_liked=?18, comments_count=?19, last_view_time=?20
             WHERE id=?21",
            params![
                text_or(comic, "updated_at", &now),
                text(comic, "title"),
                text(comic, "author"),
                num(comic, "pagesCount"),
                num(comic, "epsCount"),
                bool_i(flag(comic, "finished")),
                categories,
                text(&thumb, "originalName"),
                text(&thumb, "fileServer"),
                text(&thumb, "path"),
                num(comic, "likesCount"),
                text(comic, "description"),
                text(comic, "chineseTeam"),
                tags,
                bool_i(flag(comic, "allowDownload")),
                num(comic, "viewsCount"),
                bool_i(flag(comic, "isFavourite")),
                bool_i(flag(comic, "isLiked")),
                num(comic, "commentsCount"),
                now,
                id,
            ],
        )
        .map_err(|e| e.to_string())?;
    } else {
        conn.execute(
            "INSERT INTO comic_views (
                id, created_at, updated_at, title, author, pages_count, eps_count, finished,
                categories, thumb_original_name, thumb_file_server, thumb_path, likes_count,
                description, chinese_team, tags, allow_download, views_count, is_favourite,
                is_liked, comments_count, last_view_time, last_view_ep_order, last_view_ep_title,
                last_view_picture_rank, pinned_at
            ) VALUES (?1,?2,?3,?4,?5,?6,?7,?8,?9,?10,?11,?12,?13,?14,?15,?16,?17,?18,?19,?20,?21,?22,0,'',0,0)",
            params![
                id,
                text_or(comic, "created_at", &now),
                text_or(comic, "updated_at", &now),
                text(comic, "title"),
                text(comic, "author"),
                num(comic, "pagesCount"),
                num(comic, "epsCount"),
                bool_i(flag(comic, "finished")),
                categories,
                text(&thumb, "originalName"),
                text(&thumb, "fileServer"),
                text(&thumb, "path"),
                num(comic, "likesCount"),
                text(comic, "description"),
                text(comic, "chineseTeam"),
                tags,
                bool_i(flag(comic, "allowDownload")),
                num(comic, "viewsCount"),
                bool_i(flag(comic, "isFavourite")),
                bool_i(flag(comic, "isLiked")),
                num(comic, "commentsCount"),
                now,
            ],
        )
        .map_err(|e| e.to_string())?;
    }
    Ok(())
}

pub fn touch_views(conn: &Connection, ids: &str) -> Result<(), String> {
    let mut now = chrono::Utc::now();
    for id in ids.split(',') {
        let id = id.trim();
        if id.is_empty() {
            continue;
        }
        conn.execute(
            "UPDATE comic_views SET last_view_time = ?1 WHERE id = ?2",
            params![now.format("%Y-%m-%d %H:%M:%S%.f").to_string(), id],
        )
        .map_err(|e| e.to_string())?;
        now -= chrono::Duration::milliseconds(1);
    }
    Ok(())
}

pub fn store_view_ep(conn: &Connection, id: &str, order: i64, title: &str, rank: i64) -> Result<(), String> {
    conn.execute(
        "UPDATE comic_views SET last_view_time=?1, last_view_ep_order=?2, last_view_ep_title=?3, last_view_picture_rank=?4 WHERE id=?5",
        params![now_sqlite(), order, title, rank, id],
    )
    .map_err(|e| e.to_string())?;
    Ok(())
}

pub fn load_view(conn: &Connection, id: &str) -> Result<Option<Value>, String> {
    let mut stmt = conn
        .prepare("SELECT * FROM comic_views WHERE id = ?1")
        .map_err(|e| e.to_string())?;
    let row = stmt
        .query_row(params![id], |row| Ok(view_json(row)))
        .optional()
        .map_err(|e| e.to_string())?;
    Ok(row)
}

pub fn view_log_page(conn: &Connection, offset: i64, limit: i64) -> Result<Value, String> {
    let mut stmt = conn
        .prepare(
            "SELECT * FROM comic_views ORDER BY CASE WHEN pinned_at > 0 THEN 1 ELSE 0 END DESC, last_view_time DESC LIMIT ?1 OFFSET ?2",
        )
        .map_err(|e| e.to_string())?;
    let rows = stmt
        .query_map(params![limit, offset], |row| Ok(view_json(row)))
        .map_err(|e| e.to_string())?;
    let mut list = Vec::new();
    for row in rows {
        list.push(row.map_err(|e| e.to_string())?);
    }
    Ok(Value::Array(list))
}

pub fn viewed_ids(conn: &Connection, ids: &[String]) -> Result<Vec<String>, String> {
    let mut found = Vec::new();
    for id in ids {
        let hit = conn
            .query_row(
                "SELECT id FROM comic_views WHERE id = ?1",
                params![id],
                |row| row.get::<_, String>(0),
            )
            .optional()
            .map_err(|e| e.to_string())?;
        if let Some(id) = hit {
            found.push(id);
        }
    }
    Ok(found)
}

pub fn delete_views(conn: &Connection, ids: &str) -> Result<(), String> {
    for id in ids.split(',') {
        let id = id.trim();
        if id.is_empty() {
            continue;
        }
        conn.execute("DELETE FROM comic_views WHERE id = ?1", params![id])
            .map_err(|e| e.to_string())?;
    }
    Ok(())
}

pub fn clear_views(conn: &Connection) -> Result<(), String> {
    conn.execute("DELETE FROM comic_views", [])
        .map_err(|e| e.to_string())?;
    Ok(())
}

pub fn pin_views(conn: &Connection, ids: &str, pinned: bool) -> Result<(), String> {
    let value = if pinned { now_millis() } else { 0 };
    for id in ids.split(',') {
        let id = id.trim();
        if id.is_empty() {
            continue;
        }
        conn.execute(
            "UPDATE comic_views SET pinned_at = ?1 WHERE id = ?2",
            params![value, id],
        )
        .map_err(|e| e.to_string())?;
    }
    Ok(())
}

pub fn find_remote(conn: &Connection, file_server: &str, path: &str) -> Result<Option<Value>, String> {
    let mut stmt = conn
        .prepare("SELECT * FROM remote_images WHERE file_server = ?1 AND path = ?2 AND deleted_at IS NULL")
        .map_err(|e| e.to_string())?;
    stmt.query_row(params![file_server, path], |row| {
        Ok(json!({
            "id": gi(row, "id"),
            "fileServer": gs(row, "file_server"),
            "path": gs(row, "path"),
            "fileSize": gi(row, "file_size"),
            "format": gs(row, "format"),
            "width": gi(row, "width"),
            "height": gi(row, "height"),
            "localPath": gs(row, "local_path"),
        }))
    })
    .optional()
    .map_err(|e| e.to_string())
}

pub fn save_remote(
    conn: &Connection,
    file_server: &str,
    path: &str,
    file_size: i64,
    format: &str,
    width: i64,
    height: i64,
    local_path: &str,
) -> Result<(), String> {
    let now = now_sqlite();
    let changed = conn
        .execute(
            "UPDATE remote_images SET file_size=?1, format=?2, width=?3, height=?4, local_path=?5, updated_at=?6 WHERE file_server=?7 AND path=?8",
            params![file_size, format, width, height, local_path, now, file_server, path],
        )
        .map_err(|e| e.to_string())?;
    if changed == 0 {
        conn.execute(
            "INSERT INTO remote_images (created_at, updated_at, deleted_at, file_server, path, file_size, format, width, height, local_path)
             VALUES (?1,?2,NULL,?3,?4,?5,?6,?7,?8,?9)",
            params![now, now, file_server, path, file_size, format, width, height, local_path],
        )
        .map_err(|e| e.to_string())?;
    }
    Ok(())
}

pub fn touch_remote(conn: &Connection, id: i64) -> Result<(), String> {
    conn.execute(
        "UPDATE remote_images SET updated_at = ?1 WHERE id = ?2",
        params![now_sqlite(), id],
    )
    .map_err(|e| e.to_string())?;
    Ok(())
}

pub fn clear_remote_rows(conn: &Connection) -> Result<Vec<String>, String> {
    let mut stmt = conn
        .prepare("SELECT local_path FROM remote_images")
        .map_err(|e| e.to_string())?;
    let rows = stmt
        .query_map([], |row| row.get::<_, String>(0))
        .map_err(|e| e.to_string())?;
    let mut paths = Vec::new();
    for row in rows {
        paths.push(row.map_err(|e| e.to_string())?);
    }
    conn.execute("DELETE FROM remote_images", [])
        .map_err(|e| e.to_string())?;
    Ok(paths)
}

fn text(v: &Value, key: &str) -> String {
    v.get(key)
        .and_then(|x| x.as_str())
        .unwrap_or("")
        .to_string()
}

fn text_or(v: &Value, key: &str, default: &str) -> String {
    let value = text(v, key);
    if value.is_empty() {
        default.to_string()
    } else {
        value
    }
}

fn num(v: &Value, key: &str) -> i64 {
    v.get(key).and_then(|x| x.as_i64()).unwrap_or(0)
}

fn flag(v: &Value, key: &str) -> bool {
    v.get(key).and_then(|x| x.as_bool()).unwrap_or(false)
}

fn json_text(v: Option<&Value>) -> String {
    match v {
        Some(Value::String(s)) => s.clone(),
        Some(other) => other.to_string(),
        None => "[]".to_string(),
    }
}

pub fn download_json(row: &rusqlite::Row) -> Value {
    json!({
        "id": gs(row, "id"),
        "createdAt": to_rfc3339(&gs(row, "created_at")),
        "updatedAt": to_rfc3339(&gs(row, "updated_at")),
        "title": gs(row, "title"),
        "author": gs(row, "author"),
        "pagesCount": gi(row, "pages_count"),
        "epsCount": gi(row, "eps_count"),
        "finished": gb(row, "finished"),
        "categories": gs(row, "categories"),
        "thumbOriginalName": gs(row, "thumb_original_name"),
        "thumbFileServer": gs(row, "thumb_file_server"),
        "thumbPath": gs(row, "thumb_path"),
        "thumbLocalPath": gs(row, "thumb_local_path"),
        "description": gs(row, "description"),
        "chineseTeam": gs(row, "chinese_team"),
        "tags": gs(row, "tags"),
        "selectedEpCount": gi(row, "selected_ep_count"),
        "selectedPictureCount": gi(row, "selected_picture_count"),
        "downloadEpCount": gi(row, "download_ep_count"),
        "downloadPictureCount": gi(row, "download_picture_count"),
        "downloadFinished": gb(row, "download_finished"),
        "downloadFinishedTime": to_rfc3339(&gs(row, "download_finished_time")),
        "downloadFailed": gb(row, "download_failed"),
        "deleting": gb(row, "deleting"),
        "pause": gb(row, "pause"),
        "customFolder": gs(row, "custom_folder"),
        "fromDegenerator": gs(row, "from_degenerator"),
    })
}

pub fn ep_json(row: &rusqlite::Row) -> Value {
    json!({
        "comicId": gs(row, "comic_id"),
        "id": gs(row, "id"),
        "updatedAt": to_rfc3339(&gs(row, "updated_at")),
        "epOrder": gi(row, "ep_order"),
        "title": gs(row, "title"),
        "fetchedPictures": gb(row, "fetched_pictures"),
        "selectedPictureCount": gi(row, "selected_picture_count"),
        "downloadPictureCount": gi(row, "download_picture_count"),
        "downloadFinish": gb(row, "download_finished"),
        "downloadFinishTime": to_rfc3339(&gs(row, "download_finished_time")),
        "downloadFailed": gb(row, "download_failed"),
    })
}

pub fn picture_json(row: &rusqlite::Row) -> Value {
    json!({
        "id": gs(row, "id"),
        "comicId": gs(row, "comic_id"),
        "epId": gs(row, "ep_id"),
        "epOrder": gi(row, "ep_order"),
        "rankInEp": gi(row, "rank_in_ep"),
        "downloadFinish": gb(row, "download_finished"),
        "downloadFinishTime": to_rfc3339(&gs(row, "download_finished_time")),
        "downloadFailed": gb(row, "download_failed"),
        "originalName": gs(row, "original_name"),
        "fileServer": gs(row, "file_server"),
        "path": gs(row, "path"),
        "fileSize": gi(row, "file_size"),
        "format": gs(row, "format"),
        "width": gi(row, "width"),
        "height": gi(row, "height"),
        "localPath": gs(row, "local_path"),
    })
}

pub fn download_count(conn: &Connection) -> Result<i64, String> {
    conn.query_row("SELECT COUNT(1) FROM comic_downloads WHERE deleting = 0 OR deleting IS NULL", [], |row| row.get(0))
        .map_err(|e| e.to_string())
}

pub fn find_download(conn: &Connection, id: &str) -> Result<Option<Value>, String> {
    let mut stmt = conn
        .prepare("SELECT * FROM comic_downloads WHERE id = ?1")
        .map_err(|e| e.to_string())?;
    stmt.query_row(params![id], |row| Ok(download_json(row)))
        .optional()
        .map_err(|e| e.to_string())
}

pub fn create_download(conn: &Connection, comic: &Value, eps: &[Value]) -> Result<(), String> {
    let id = text(comic, "id");
    let now = now_sqlite();
    conn.execute(
        "INSERT OR REPLACE INTO comic_downloads (
            id, created_at, updated_at, title, author, pages_count, eps_count, finished,
            categories, thumb_original_name, thumb_file_server, thumb_path, description, chinese_team, tags,
            selected_ep_count, selected_picture_count, download_ep_count, download_picture_count,
            download_finished, download_finished_time, download_failed, deleting,
            thumb_file_size, thumb_format, thumb_width, thumb_height, thumb_local_path,
            pause, from_degenerator, custom_folder
        ) VALUES (?1,?2,?3,?4,?5,?6,?7,?8,?9,?10,?11,?12,?13,?14,?15,?16,0,0,0,0,'',0,0,0,'',0,0,'',0,?17,'')",
        params![
            id,
            text_or(comic, "createdAt", &now),
            text_or(comic, "updatedAt", &now),
            text(comic, "title"),
            text(comic, "author"),
            num(comic, "pagesCount"),
            num(comic, "epsCount"),
            bool_i(flag(comic, "finished")),
            text(comic, "categories"),
            text(comic, "thumbOriginalName"),
            text(comic, "thumbFileServer"),
            text(comic, "thumbPath"),
            text(comic, "description"),
            text(comic, "chineseTeam"),
            text(comic, "tags"),
            eps.len() as i64,
            "PK",
        ],
    )
    .map_err(|e| e.to_string())?;
    for ep in eps {
        insert_ep(conn, ep)?;
    }
    Ok(())
}

pub fn add_download_eps(conn: &Connection, eps: &[Value]) -> Result<(), String> {
    for ep in eps {
        insert_ep(conn, ep)?;
    }
    if let Some(comic_id) = eps.first().map(|ep| text(ep, "comicId")) {
        let count: i64 = conn
            .query_row(
                "SELECT COUNT(1) FROM comic_download_eps WHERE comic_id = ?1",
                params![comic_id],
                |row| row.get(0),
            )
            .unwrap_or(0);
        conn.execute(
            "UPDATE comic_downloads SET selected_ep_count = ?1, download_finished = 0, pause = 0 WHERE id = ?2",
            params![count, comic_id],
        )
        .map_err(|e| e.to_string())?;
    }
    Ok(())
}

fn insert_ep(conn: &Connection, ep: &Value) -> Result<(), String> {
    conn.execute(
        "INSERT OR IGNORE INTO comic_download_eps (
            id, comic_id, updated_at, ep_order, title, fetched_pictures,
            selected_picture_count, download_picture_count, download_finished,
            download_finished_time, download_failed
        ) VALUES (?1,?2,?3,?4,?5,0,0,0,0,'',0)",
        params![
            text(ep, "id"),
            text(ep, "comicId"),
            text_or(ep, "updatedAt", &now_rfc3339()),
            num(ep, "epOrder"),
            text(ep, "title"),
        ],
    )
    .map_err(|e| e.to_string())?;
    Ok(())
}

pub fn list_eps(conn: &Connection, comic_id: &str) -> Result<Vec<Value>, String> {
    let mut stmt = conn
        .prepare("SELECT * FROM comic_download_eps WHERE comic_id = ?1 ORDER BY ep_order")
        .map_err(|e| e.to_string())?;
    let rows = stmt
        .query_map(params![comic_id], |row| Ok(ep_json(row)))
        .map_err(|e| e.to_string())?;
    let mut list = Vec::new();
    for row in rows {
        list.push(row.map_err(|e| e.to_string())?);
    }
    Ok(list)
}

pub fn list_pictures(conn: &Connection, ep_id: &str) -> Result<Vec<Value>, String> {
    let mut stmt = conn
        .prepare("SELECT * FROM comic_download_pictures WHERE ep_id = ?1 ORDER BY rank_in_ep")
        .map_err(|e| e.to_string())?;
    let rows = stmt
        .query_map(params![ep_id], |row| Ok(picture_json(row)))
        .map_err(|e| e.to_string())?;
    let mut list = Vec::new();
    for row in rows {
        list.push(row.map_err(|e| e.to_string())?);
    }
    Ok(list)
}

pub fn all_downloads(conn: &Connection, search: &str, folder: &str) -> Result<Value, String> {
    let mut stmt = conn
        .prepare("SELECT * FROM comic_downloads WHERE (deleting = 0 OR deleting IS NULL) ORDER BY updated_at DESC")
        .map_err(|e| e.to_string())?;
    let rows = stmt
        .query_map([], |row| Ok(download_json(row)))
        .map_err(|e| e.to_string())?;
    let mut list = Vec::new();
    for row in rows {
        let item = row.map_err(|e| e.to_string())?;
        let title = item.get("title").and_then(|v| v.as_str()).unwrap_or("");
        let custom = item.get("customFolder").and_then(|v| v.as_str()).unwrap_or("");
        if !search.is_empty() && !title.to_lowercase().contains(&search.to_lowercase()) {
            continue;
        }
        if !folder.is_empty() && custom != folder {
            continue;
        }
        list.push(item);
    }
    Ok(Value::Array(list))
}

pub fn custom_folders(conn: &Connection) -> Result<Value, String> {
    let mut stmt = conn
        .prepare("SELECT DISTINCT custom_folder FROM comic_downloads WHERE custom_folder IS NOT NULL AND custom_folder != ''")
        .map_err(|e| e.to_string())?;
    let rows = stmt
        .query_map([], |row| row.get::<_, String>(0))
        .map_err(|e| e.to_string())?;
    let mut list = Vec::new();
    for row in rows {
        list.push(Value::String(row.map_err(|e| e.to_string())?));
    }
    Ok(Value::Array(list))
}

pub fn mark_deleting(conn: &Connection, id: &str) -> Result<(), String> {
    conn.execute("UPDATE comic_downloads SET deleting = 1 WHERE id = ?1", params![id])
        .map_err(|e| e.to_string())?;
    Ok(())
}

pub fn move_downloads(conn: &Connection, ids: &[String], folder: &str) -> Result<(), String> {
    for id in ids {
        conn.execute(
            "UPDATE comic_downloads SET custom_folder = ?1 WHERE id = ?2",
            params![folder, id],
        )
        .map_err(|e| e.to_string())?;
    }
    Ok(())
}

pub fn reset_failed(conn: &Connection) -> Result<(), String> {
    conn.execute_batch(
        "UPDATE comic_downloads SET download_failed = 0;
         UPDATE comic_download_eps SET download_failed = 0;
         UPDATE comic_download_pictures SET download_failed = 0;",
    )
    .map_err(|e| e.to_string())
}

pub fn next_download(conn: &Connection) -> Result<Option<Value>, String> {
    let mut stmt = conn
        .prepare("SELECT * FROM comic_downloads WHERE (download_finished = 0 OR download_finished IS NULL) AND (download_failed = 0 OR download_failed IS NULL) AND (pause = 0 OR pause IS NULL) AND (deleting = 0 OR deleting IS NULL) LIMIT 1")
        .map_err(|e| e.to_string())?;
    stmt.query_row([], |row| Ok(download_json(row)))
        .optional()
        .map_err(|e| e.to_string())
}

pub fn deleting_one(conn: &Connection) -> Result<Option<Value>, String> {
    let mut stmt = conn
        .prepare("SELECT * FROM comic_downloads WHERE deleting = 1 LIMIT 1")
        .map_err(|e| e.to_string())?;
    stmt.query_row([], |row| Ok(download_json(row)))
        .optional()
        .map_err(|e| e.to_string())
}

pub fn delete_download_tree(conn: &Connection, id: &str) -> Result<(), String> {
    conn.execute("DELETE FROM comic_download_pictures WHERE comic_id = ?1", params![id])
        .map_err(|e| e.to_string())?;
    conn.execute("DELETE FROM comic_download_eps WHERE comic_id = ?1", params![id])
        .map_err(|e| e.to_string())?;
    conn.execute("DELETE FROM comic_downloads WHERE id = ?1", params![id])
        .map_err(|e| e.to_string())?;
    Ok(())
}

pub fn insert_pictures(conn: &Connection, pictures: &[Value]) -> Result<(), String> {
    for picture in pictures {
        conn.execute(
            "INSERT OR IGNORE INTO comic_download_pictures (
                id, comic_id, ep_id, ep_order, rank_in_ep, download_finished, download_finished_time,
                download_failed, original_name, file_server, path, file_size, format, width, height, local_path
            ) VALUES (?1,?2,?3,?4,?5,0,'',0,?6,?7,?8,0,'',0,0,'')",
            params![
                text(picture, "id"),
                text(picture, "comicId"),
                text(picture, "epId"),
                num(picture, "epOrder"),
                num(picture, "rankInEp"),
                text(picture, "originalName"),
                text(picture, "fileServer"),
                text(picture, "path"),
            ],
        )
        .map_err(|e| e.to_string())?;
    }
    Ok(())
}

pub fn mark_ep_fetched(conn: &Connection, ep_id: &str, count: i64) -> Result<(), String> {
    conn.execute(
        "UPDATE comic_download_eps SET fetched_pictures = 1, selected_picture_count = ?1 WHERE id = ?2",
        params![count, ep_id],
    )
    .map_err(|e| e.to_string())?;
    Ok(())
}

pub fn mark_ep_failed(conn: &Connection, ep_id: &str) -> Result<(), String> {
    conn.execute(
        "UPDATE comic_download_eps SET download_failed = 1 WHERE id = ?1",
        params![ep_id],
    )
    .map_err(|e| e.to_string())?;
    Ok(())
}

pub fn next_picture(conn: &Connection, comic_id: &str) -> Result<Option<Value>, String> {
    let mut stmt = conn
        .prepare("SELECT * FROM comic_download_pictures WHERE comic_id = ?1 AND (download_finished = 0 OR download_finished IS NULL) AND (download_failed = 0 OR download_failed IS NULL) ORDER BY ep_order, rank_in_ep LIMIT 1")
        .map_err(|e| e.to_string())?;
    stmt.query_row(params![comic_id], |row| Ok(picture_json(row)))
        .optional()
        .map_err(|e| e.to_string())
}

pub fn picture_success(
    conn: &Connection,
    id: &str,
    ep_id: &str,
    comic_id: &str,
    size: i64,
    format: &str,
    width: i64,
    height: i64,
    local_path: &str,
) -> Result<(), String> {
    let now = now_sqlite();
    conn.execute(
        "UPDATE comic_download_pictures SET download_finished=1, download_finished_time=?1, file_size=?2, format=?3, width=?4, height=?5, local_path=?6, download_failed=0 WHERE id=?7",
        params![now, size, format, width, height, local_path, id],
    )
    .map_err(|e| e.to_string())?;
    conn.execute(
        "UPDATE comic_download_eps SET download_picture_count = (SELECT COUNT(1) FROM comic_download_pictures WHERE ep_id = ?1 AND download_finished = 1) WHERE id = ?1",
        params![ep_id],
    )
    .map_err(|e| e.to_string())?;
    conn.execute(
        "UPDATE comic_downloads SET download_picture_count = (SELECT COUNT(1) FROM comic_download_pictures WHERE comic_id = ?1 AND download_finished = 1), updated_at = ?2 WHERE id = ?1",
        params![comic_id, now],
    )
    .map_err(|e| e.to_string())?;
    let (selected, done): (i64, i64) = conn
        .query_row(
            "SELECT selected_picture_count, download_picture_count FROM comic_download_eps WHERE id = ?1",
            params![ep_id],
            |row| Ok((row.get(0)?, row.get(1)?)),
        )
        .unwrap_or((1, 0));
    if selected > 0 && done >= selected {
        conn.execute(
            "UPDATE comic_download_eps SET download_finished = 1, download_finished_time = ?1 WHERE id = ?2",
            params![now, ep_id],
        )
        .map_err(|e| e.to_string())?;
    }
    let unfinished: i64 = conn
        .query_row(
            "SELECT COUNT(1) FROM comic_download_eps WHERE comic_id = ?1 AND (download_finished = 0 OR download_finished IS NULL) AND (download_failed = 0 OR download_failed IS NULL)",
            params![comic_id],
            |row| row.get(0),
        )
        .unwrap_or(1);
    if unfinished == 0 {
        conn.execute(
            "UPDATE comic_downloads SET download_finished = 1, download_finished_time = ?1, download_ep_count = selected_ep_count WHERE id = ?2",
            params![now, comic_id],
        )
        .map_err(|e| e.to_string())?;
    }
    Ok(())
}

pub fn picture_failed(conn: &Connection, id: &str) -> Result<(), String> {
    conn.execute(
        "UPDATE comic_download_pictures SET download_failed = 1 WHERE id = ?1",
        params![id],
    )
    .map_err(|e| e.to_string())?;
    Ok(())
}

pub fn update_logo(conn: &Connection, id: &str, size: i64, format: &str, width: i64, height: i64, path: &str) -> Result<(), String> {
    conn.execute(
        "UPDATE comic_downloads SET thumb_file_size=?1, thumb_format=?2, thumb_width=?3, thumb_height=?4, thumb_local_path=?5 WHERE id=?6",
        params![size, format, width, height, path, id],
    )
    .map_err(|e| e.to_string())?;
    Ok(())
}

pub fn bump_selected_pictures(conn: &Connection, comic_id: &str, extra: i64) -> Result<(), String> {
    conn.execute(
        "UPDATE comic_downloads SET selected_picture_count = selected_picture_count + ?1 WHERE id = ?2",
        params![extra, comic_id],
    )
    .map_err(|e| e.to_string())?;
    Ok(())
}

pub fn subscribe_json(row: &rusqlite::Row) -> Value {
    let mut value = view_json(row);
    if let Value::Object(map) = &mut value {
        map.insert("subscribeTime".into(), Value::String(to_rfc3339(&gs(row, "subscribe_time"))));
        map.insert("updateSubscribeTime".into(), Value::String(to_rfc3339(&gs(row, "update_subscribe_time"))));
        map.insert("newEpCount".into(), json!(gi(row, "new_ep_count")));
    }
    value
}

pub fn load_subscribe(conn: &Connection, id: &str) -> Result<Option<Value>, String> {
    let mut stmt = conn
        .prepare("SELECT * FROM comic_subscribes WHERE id = ?1")
        .map_err(|e| e.to_string())?;
    stmt.query_row(params![id], |row| Ok(subscribe_json(row)))
        .optional()
        .map_err(|e| e.to_string())
}

pub fn save_subscribe(conn: &Connection, comic: &Value) -> Result<(), String> {
    let id = comic.get("_id").and_then(|v| v.as_str()).or_else(|| comic.get("id").and_then(|v| v.as_str())).unwrap_or("");
    if id.is_empty() {
        return Err("缺少漫画 id".into());
    }
    let now = now_sqlite();
    let thumb = comic.get("thumb").cloned().unwrap_or(Value::Null);
    conn.execute(
        "INSERT OR REPLACE INTO comic_subscribes (
            id, created_at, updated_at, title, author, pages_count, eps_count, finished,
            categories, thumb_original_name, thumb_file_server, thumb_path, likes_count,
            description, chinese_team, tags, allow_download, views_count, is_favourite, is_liked,
            comments_count, subscribe_time, update_subscribe_time, new_ep_count
        ) VALUES (?1,?2,?3,?4,?5,?6,?7,?8,?9,?10,?11,?12,?13,?14,?15,?16,?17,?18,?19,?20,?21,?22,?22,0)",
        params![
            id,
            text_or(comic, "created_at", &now),
            text_or(comic, "updated_at", &now),
            text(comic, "title"),
            text(comic, "author"),
            num(comic, "pagesCount"),
            num(comic, "epsCount"),
            bool_i(flag(comic, "finished")),
            json_text(comic.get("categories")),
            text(&thumb, "originalName"),
            text(&thumb, "fileServer"),
            text(&thumb, "path"),
            num(comic, "likesCount"),
            text(comic, "description"),
            text(comic, "chineseTeam"),
            json_text(comic.get("tags")),
            bool_i(flag(comic, "allowDownload")),
            num(comic, "viewsCount"),
            bool_i(flag(comic, "isFavourite")),
            bool_i(flag(comic, "isLiked")),
            num(comic, "commentsCount"),
            now,
        ],
    )
    .map_err(|e| e.to_string())?;
    Ok(())
}

pub fn remove_subscribe(conn: &Connection, id: &str) -> Result<(), String> {
    conn.execute("DELETE FROM comic_subscribes WHERE id = ?1", params![id])
        .map_err(|e| e.to_string())?;
    Ok(())
}

pub fn remove_all_subscribe(conn: &Connection) -> Result<(), String> {
    conn.execute("DELETE FROM comic_subscribes", [])
        .map_err(|e| e.to_string())?;
    Ok(())
}

pub fn all_subscribe(conn: &Connection) -> Result<Value, String> {
    let mut stmt = conn
        .prepare("SELECT * FROM comic_subscribes ORDER BY subscribe_time DESC")
        .map_err(|e| e.to_string())?;
    let rows = stmt
        .query_map([], |row| Ok(subscribe_json(row)))
        .map_err(|e| e.to_string())?;
    let mut list = Vec::new();
    for row in rows {
        list.push(row.map_err(|e| e.to_string())?);
    }
    Ok(Value::Array(list))
}

pub fn set_new_ep(conn: &Connection, id: &str, count: i64) -> Result<(), String> {
    conn.execute(
        "UPDATE comic_subscribes SET new_ep_count = ?1, update_subscribe_time = ?2, eps_count = eps_count WHERE id = ?3",
        params![count, now_sqlite(), id],
    )
    .map_err(|e| e.to_string())?;
    Ok(())
}

pub fn pkz_view(conn: &Connection, file_name: &str, file_path: &str) -> Result<Value, String> {
    conn.execute(
        "INSERT INTO pkz_view_logs (file_name, file_path, last_view_comic_id, last_view_comic_title, last_view_time)
         VALUES (?1,?2,'','',?3)
         ON CONFLICT(file_name) DO UPDATE SET file_path=?2, last_view_time=?3",
        params![file_name, file_path, now_sqlite()],
    )
    .map_err(|e| e.to_string())?;
    conn.query_row(
        "SELECT * FROM pkz_view_logs WHERE file_name = ?1",
        params![file_name],
        |row| {
            Ok(json!({
                "fileName": gs(row, "file_name"),
                "filePath": gs(row, "file_path"),
                "lastViewComicId": gs(row, "last_view_comic_id"),
                "lastViewComicTitle": gs(row, "last_view_comic_title"),
                "lastViewTime": to_rfc3339(&gs(row, "last_view_time")),
            }))
        },
    )
    .map_err(|e| e.to_string())
}

pub fn pkz_logs(conn: &Connection, file_name: &str) -> Result<Value, String> {
    let mut stmt = conn
        .prepare("SELECT * FROM pkz_comic_view_logs WHERE file_name = ?1")
        .map_err(|e| e.to_string())?;
    let rows = stmt
        .query_map(params![file_name], |row| Ok(pkz_log_json(row)))
        .map_err(|e| e.to_string())?;
    let mut list = Vec::new();
    for row in rows {
        list.push(row.map_err(|e| e.to_string())?);
    }
    Ok(Value::Array(list))
}

pub fn pkz_log_one(conn: &Connection, file_name: &str, comic_id: &str) -> Result<Option<Value>, String> {
    let mut stmt = conn
        .prepare("SELECT * FROM pkz_comic_view_logs WHERE file_name = ?1 AND last_view_comic_id = ?2")
        .map_err(|e| e.to_string())?;
    stmt.query_row(params![file_name, comic_id], |row| Ok(pkz_log_json(row)))
        .optional()
        .map_err(|e| e.to_string())
}

fn pkz_log_json(row: &rusqlite::Row) -> Value {
    json!({
        "fileName": gs(row, "file_name"),
        "filePath": gs(row, "file_path"),
        "lastViewComicId": gs(row, "last_view_comic_id"),
        "lastViewComicTitle": gs(row, "last_view_comic_title"),
        "lastViewEpId": gs(row, "last_view_ep_id"),
        "lastViewEpName": gs(row, "last_view_ep_name"),
        "lastViewPictureRank": gi(row, "last_view_picture_rank"),
        "lastViewTime": to_rfc3339(&gs(row, "last_view_time")),
    })
}

pub fn pkz_view_comic(conn: &Connection, file_name: &str, file_path: &str, comic_id: &str, title: &str) -> Result<(), String> {
    conn.execute(
        "INSERT INTO pkz_comic_view_logs (file_name, last_view_comic_id, file_path, last_view_comic_title, last_view_ep_id, last_view_ep_name, last_view_picture_rank, last_view_time)
         VALUES (?1,?2,?3,?4,'','',0,?5)
         ON CONFLICT(file_name, last_view_comic_id) DO UPDATE SET file_path=?3, last_view_comic_title=?4, last_view_time=?5",
        params![file_name, comic_id, file_path, title, now_sqlite()],
    )
    .map_err(|e| e.to_string())?;
    conn.execute(
        "UPDATE pkz_view_logs SET last_view_comic_id=?1, last_view_comic_title=?2, last_view_time=?3, file_path=?4 WHERE file_name=?5",
        params![comic_id, title, now_sqlite(), file_path, file_name],
    )
    .map_err(|e| e.to_string())?;
    Ok(())
}

pub fn pkz_view_ep(conn: &Connection, file_name: &str, comic_id: &str, ep_id: &str, ep_name: &str, rank: i64) -> Result<(), String> {
    conn.execute(
        "UPDATE pkz_comic_view_logs SET last_view_ep_id=?1, last_view_ep_name=?2, last_view_picture_rank=?3, last_view_time=?4 WHERE file_name=?5 AND last_view_comic_id=?6",
        params![ep_id, ep_name, rank, now_sqlite(), file_name, comic_id],
    )
    .map_err(|e| e.to_string())?;
    Ok(())
}

pub fn favorite_folder_json(row: &rusqlite::Row) -> Value {
    json!({
        "id": gs(row, "id"),
        "name": gs(row, "name"),
        "createdAt": gi(row, "created_at"),
        "updatedAt": gi(row, "updated_at"),
        "deletedAt": gi(row, "deleted_at"),
    })
}

pub fn favorite_comic_json(row: &rusqlite::Row) -> Value {
    json!({
        "comicId": gs(row, "comic_id"),
        "folderId": gs(row, "folder_id"),
        "info": gs(row, "info"),
        "createdAt": gi(row, "created_at"),
        "updatedAt": gi(row, "updated_at"),
        "deletedAt": gi(row, "deleted_at"),
    })
}

pub fn create_folder(conn: &Connection, name: &str) -> Result<Value, String> {
    let id = uuid::Uuid::new_v4().to_string();
    let now = now_millis();
    conn.execute(
        "INSERT INTO local_favorite_folders (id, name, created_at, updated_at, deleted_at) VALUES (?1,?2,?3,?3,0)",
        params![id, name, now],
    )
    .map_err(|e| e.to_string())?;
    conn.query_row("SELECT * FROM local_favorite_folders WHERE id = ?1", params![id], |row| Ok(favorite_folder_json(row)))
        .map_err(|e| e.to_string())
}

pub fn update_folder(conn: &Connection, folder: &Value) -> Result<(), String> {
    conn.execute(
        "UPDATE local_favorite_folders SET name=?1, updated_at=?2 WHERE id=?3",
        params![text(folder, "name"), now_millis(), text(folder, "id")],
    )
    .map_err(|e| e.to_string())?;
    Ok(())
}

pub fn delete_folder(conn: &Connection, id: &str) -> Result<(), String> {
    let now = now_millis();
    conn.execute(
        "UPDATE local_favorite_folders SET deleted_at=?1, updated_at=?1 WHERE id=?2",
        params![now, id],
    )
    .map_err(|e| e.to_string())?;
    conn.execute(
        "UPDATE local_favorite_comics SET folder_id='', updated_at=?1 WHERE folder_id=?2",
        params![now, id],
    )
    .map_err(|e| e.to_string())?;
    Ok(())
}

pub fn get_folder(conn: &Connection, id: &str) -> Result<Value, String> {
    conn.query_row(
        "SELECT * FROM local_favorite_folders WHERE id=?1 AND (deleted_at = 0 OR deleted_at IS NULL)",
        params![id],
        |row| Ok(favorite_folder_json(row)),
    )
    .map_err(|e| e.to_string())
}

pub fn list_folders(conn: &Connection) -> Result<Value, String> {
    let mut stmt = conn
        .prepare("SELECT * FROM local_favorite_folders WHERE deleted_at = 0 OR deleted_at IS NULL ORDER BY created_at")
        .map_err(|e| e.to_string())?;
    let rows = stmt
        .query_map([], |row| Ok(favorite_folder_json(row)))
        .map_err(|e| e.to_string())?;
    let mut list = Vec::new();
    for row in rows {
        list.push(row.map_err(|e| e.to_string())?);
    }
    Ok(Value::Array(list))
}

pub fn count_folders(conn: &Connection) -> Result<i64, String> {
    conn.query_row(
        "SELECT COUNT(1) FROM local_favorite_folders WHERE deleted_at = 0 OR deleted_at IS NULL",
        [],
        |row| row.get(0),
    )
    .map_err(|e| e.to_string())
}

pub fn add_favorite(conn: &Connection, comic_id: &str, folder_id: &str, info: &str) -> Result<(), String> {
    let now = now_millis();
    conn.execute(
        "INSERT INTO local_favorite_comics (comic_id, folder_id, info, created_at, updated_at, deleted_at)
         VALUES (?1,?2,?3,?4,?4,0)
         ON CONFLICT(comic_id) DO UPDATE SET folder_id=?2, info=?3, updated_at=?4, deleted_at=0",
        params![comic_id, folder_id, info, now],
    )
    .map_err(|e| e.to_string())?;
    Ok(())
}

pub fn remove_favorite(conn: &Connection, comic_id: &str) -> Result<(), String> {
    conn.execute(
        "UPDATE local_favorite_comics SET deleted_at=?1, updated_at=?1 WHERE comic_id=?2",
        params![now_millis(), comic_id],
    )
    .map_err(|e| e.to_string())?;
    Ok(())
}

pub fn move_favorites(conn: &Connection, ids: &[String], folder_id: &str) -> Result<(), String> {
    for id in ids {
        conn.execute(
            "UPDATE local_favorite_comics SET folder_id=?1, updated_at=?2 WHERE comic_id=?3",
            params![folder_id, now_millis(), id],
        )
        .map_err(|e| e.to_string())?;
    }
    Ok(())
}

pub fn get_favorite(conn: &Connection, comic_id: &str) -> Result<Option<Value>, String> {
    let mut stmt = conn
        .prepare("SELECT * FROM local_favorite_comics WHERE comic_id=?1 AND (deleted_at = 0 OR deleted_at IS NULL)")
        .map_err(|e| e.to_string())?;
    stmt.query_row(params![comic_id], |row| Ok(favorite_comic_json(row)))
        .optional()
        .map_err(|e| e.to_string())
}

pub fn list_favorites(conn: &Connection, folder_id: &str) -> Result<Value, String> {
    let mut stmt = conn
        .prepare("SELECT * FROM local_favorite_comics WHERE folder_id=?1 AND (deleted_at = 0 OR deleted_at IS NULL) ORDER BY created_at DESC")
        .map_err(|e| e.to_string())?;
    let rows = stmt
        .query_map(params![folder_id], |row| Ok(favorite_comic_json(row)))
        .map_err(|e| e.to_string())?;
    let mut list = Vec::new();
    for row in rows {
        list.push(row.map_err(|e| e.to_string())?);
    }
    Ok(Value::Array(list))
}

pub fn list_all_favorites(conn: &Connection) -> Result<Value, String> {
    let mut stmt = conn
        .prepare("SELECT * FROM local_favorite_comics WHERE deleted_at = 0 OR deleted_at IS NULL ORDER BY created_at DESC")
        .map_err(|e| e.to_string())?;
    let rows = stmt
        .query_map([], |row| Ok(favorite_comic_json(row)))
        .map_err(|e| e.to_string())?;
    let mut list = Vec::new();
    for row in rows {
        list.push(row.map_err(|e| e.to_string())?);
    }
    Ok(Value::Array(list))
}

pub fn export_favorites(conn: &Connection) -> Result<Value, String> {
    Ok(json!({
        "folders": list_folders(conn)?,
        "comics": list_all_favorites(conn)?,
    }))
}

pub fn merge_favorites(conn: &Connection, data: &Value) -> Result<(), String> {
    if let Some(folders) = data.get("folders").and_then(|v| v.as_array()) {
        for folder in folders {
            let id = text(folder, "id");
            if id.is_empty() {
                continue;
            }
            conn.execute(
                "INSERT OR IGNORE INTO local_favorite_folders (id, name, created_at, updated_at, deleted_at) VALUES (?1,?2,?3,?4,?5)",
                params![id, text(folder, "name"), num(folder, "createdAt"), num(folder, "updatedAt"), num(folder, "deletedAt")],
            )
            .map_err(|e| e.to_string())?;
        }
    }
    if let Some(comics) = data.get("comics").and_then(|v| v.as_array()) {
        for comic in comics {
            add_favorite(conn, &text(comic, "comicId"), &text(comic, "folderId"), &text(comic, "info"))?;
        }
    }
    Ok(())
}

pub fn last_views(conn: &Connection, limit: i64) -> Result<Vec<Value>, String> {
    let page = view_log_page(conn, 0, limit)?;
    Ok(page.as_array().cloned().unwrap_or_default())
}

pub fn merge_views(conn: &Connection, views: &[Value]) -> Result<bool, String> {
    let mut changed = false;
    for view in views {
        let id = text(view, "id");
        if id.is_empty() {
            continue;
        }
        let existing = load_view(conn, &id)?;
        if existing.is_none() {
            let now = now_sqlite();
            conn.execute(
                "INSERT INTO comic_views (id, created_at, updated_at, title, author, pages_count, eps_count, finished, categories, thumb_original_name, thumb_file_server, thumb_path, description, chinese_team, tags, last_view_time, last_view_ep_order, last_view_ep_title, last_view_picture_rank, pinned_at)
                 VALUES (?1,?2,?2,?3,?4,?5,?6,?7,?8,?9,?10,?11,?12,?13,?14,?15,?16,?17,?18,?19)",
                params![
                    id, now, text(view, "title"), text(view, "author"), num(view, "pagesCount"), num(view, "epsCount"),
                    bool_i(flag(view, "finished")), text(view, "categories"), text(view, "thumbOriginalName"),
                    text(view, "thumbFileServer"), text(view, "thumbPath"), text(view, "description"),
                    text(view, "chineseTeam"), text(view, "tags"), text(view, "lastViewTime"),
                    num(view, "lastViewEpOrder"), text(view, "lastViewEpTitle"), num(view, "lastViewPictureRank"),
                    num(view, "pinnedAt"),
                ],
            )
            .map_err(|e| e.to_string())?;
            changed = true;
        }
    }
    Ok(changed)
}
