pub mod dto;
pub(crate) mod rows;
pub mod store;

use std::path::Path;
use std::sync::Mutex;
use std::time::Duration;

use rusqlite::Connection;

#[allow(unused_imports)]
pub use rows::*;

pub struct Databases {
    pub properties: Mutex<Connection>,
    pub network: Mutex<Connection>,
    pub comic: Mutex<Connection>,
    pub pkz: Mutex<Connection>,
    pub favorite: Mutex<Connection>,
}

impl Databases {
    pub fn open(dir: &Path) -> Result<Self, String> {
        Ok(Self {
            properties: Mutex::new(open_db(&dir.join("properties.db"), schema_properties)?),
            network: Mutex::new(open_db(&dir.join("network_cache.db"), schema_network)?),
            comic: Mutex::new(open_db(&dir.join("comic_center.db"), schema_comic)?),
            pkz: Mutex::new(open_db(&dir.join("pkz_center.db"), schema_pkz)?),
            favorite: Mutex::new(open_db(&dir.join("local_favorite.db"), schema_favorite)?),
        })
    }
}

fn open_db(path: &Path, schema: fn(&Connection) -> Result<(), String>) -> Result<Connection, String> {
    let conn = Connection::open(path).map_err(|e| format!("打开 {} 失败: {e}", path.display()))?;
    conn.busy_timeout(Duration::from_secs(8))
        .map_err(|e| e.to_string())?;
    let _ = conn.execute_batch("PRAGMA foreign_keys = ON;");
    schema(&conn)?;
    Ok(conn)
}

fn exec_ignore(conn: &Connection, sql: &str) {
    let _ = conn.execute(sql, []);
}

fn schema_properties(conn: &Connection) -> Result<(), String> {
    conn.execute_batch(
        "CREATE TABLE IF NOT EXISTS properties (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            created_at TEXT,
            updated_at TEXT,
            deleted_at TEXT,
            k TEXT,
            v TEXT
        );",
    )
    .map_err(|e| e.to_string())?;
    exec_ignore(conn, "CREATE UNIQUE INDEX IF NOT EXISTS uk_k ON properties(k)");
    for col in ["created_at", "updated_at", "deleted_at", "k", "v"] {
        exec_ignore(conn, &format!("ALTER TABLE properties ADD COLUMN {col} TEXT"));
    }
    Ok(())
}

fn schema_network(conn: &Connection) -> Result<(), String> {
    conn.execute_batch(
        "CREATE TABLE IF NOT EXISTS network_caches (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            created_at TEXT,
            updated_at TEXT,
            deleted_at TEXT,
            k TEXT,
            v TEXT
        );",
    )
    .map_err(|e| e.to_string())?;
    exec_ignore(conn, "CREATE UNIQUE INDEX IF NOT EXISTS uk_k ON network_caches(k)");
    for col in ["created_at", "updated_at", "deleted_at", "k", "v"] {
        exec_ignore(conn, &format!("ALTER TABLE network_caches ADD COLUMN {col} TEXT"));
    }
    Ok(())
}

fn schema_comic(conn: &Connection) -> Result<(), String> {
    conn.execute_batch(
        "CREATE TABLE IF NOT EXISTS comic_views (
            id TEXT PRIMARY KEY,
            created_at TEXT, updated_at TEXT, title TEXT, author TEXT,
            pages_count INTEGER, eps_count INTEGER, finished INTEGER,
            categories TEXT, thumb_original_name TEXT, thumb_file_server TEXT, thumb_path TEXT,
            likes_count INTEGER, description TEXT, chinese_team TEXT, tags TEXT,
            allow_download INTEGER, views_count INTEGER, is_favourite INTEGER, is_liked INTEGER,
            comments_count INTEGER, last_view_time TEXT, last_view_ep_order INTEGER,
            last_view_ep_title TEXT, last_view_picture_rank INTEGER, pinned_at INTEGER
        );
        CREATE TABLE IF NOT EXISTS remote_images (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            created_at TEXT, updated_at TEXT, deleted_at TEXT,
            file_server TEXT, path TEXT, file_size INTEGER, format TEXT,
            width INTEGER, height INTEGER, local_path TEXT
        );
        CREATE TABLE IF NOT EXISTS comic_downloads (
            id TEXT PRIMARY KEY,
            created_at TEXT, updated_at TEXT, title TEXT, author TEXT,
            pages_count INTEGER, eps_count INTEGER, finished INTEGER,
            categories TEXT, thumb_original_name TEXT, thumb_file_server TEXT, thumb_path TEXT,
            description TEXT, chinese_team TEXT, tags TEXT,
            selected_ep_count INTEGER, selected_picture_count INTEGER,
            download_ep_count INTEGER, download_picture_count INTEGER,
            download_finished INTEGER, download_finished_time TEXT,
            download_failed INTEGER, deleting INTEGER,
            thumb_file_size INTEGER, thumb_format TEXT, thumb_width INTEGER, thumb_height INTEGER,
            thumb_local_path TEXT, pause INTEGER, from_degenerator TEXT, custom_folder TEXT
        );
        CREATE TABLE IF NOT EXISTS comic_download_eps (
            id TEXT PRIMARY KEY,
            comic_id TEXT, updated_at TEXT, ep_order INTEGER, title TEXT,
            fetched_pictures INTEGER, selected_picture_count INTEGER, download_picture_count INTEGER,
            download_finished INTEGER, download_finished_time TEXT, download_failed INTEGER
        );
        CREATE TABLE IF NOT EXISTS comic_download_pictures (
            id TEXT PRIMARY KEY,
            comic_id TEXT, ep_id TEXT, ep_order INTEGER, rank_in_ep INTEGER,
            download_finished INTEGER, download_finished_time TEXT, download_failed INTEGER,
            original_name TEXT, file_server TEXT, path TEXT, file_size INTEGER,
            format TEXT, width INTEGER, height INTEGER, local_path TEXT
        );
        CREATE TABLE IF NOT EXISTS comic_subscribes (
            id TEXT PRIMARY KEY,
            created_at TEXT, updated_at TEXT, title TEXT, author TEXT,
            pages_count INTEGER, eps_count INTEGER, finished INTEGER,
            categories TEXT, thumb_original_name TEXT, thumb_file_server TEXT, thumb_path TEXT,
            likes_count INTEGER, description TEXT, chinese_team TEXT, tags TEXT,
            allow_download INTEGER, views_count INTEGER, is_favourite INTEGER, is_liked INTEGER,
            comments_count INTEGER, subscribe_time TEXT, update_subscribe_time TEXT, new_ep_count INTEGER
        );",
    )
    .map_err(|e| e.to_string())?;
    for sql in [
        "ALTER TABLE comic_views ADD COLUMN pinned_at INTEGER",
        "ALTER TABLE comic_downloads ADD COLUMN custom_folder TEXT",
        "ALTER TABLE comic_downloads ADD COLUMN pause INTEGER",
        "ALTER TABLE comic_downloads ADD COLUMN from_degenerator TEXT",
        "ALTER TABLE comic_subscribes ADD COLUMN new_ep_count INTEGER",
        "CREATE UNIQUE INDEX IF NOT EXISTS uk_fp ON remote_images(file_server, path)",
        "CREATE INDEX IF NOT EXISTS idx_comic_id ON comic_download_eps(comic_id)",
        "CREATE INDEX IF NOT EXISTS idx_ep_id ON comic_download_pictures(ep_id)",
        "CREATE INDEX IF NOT EXISTS download_cf ON comic_downloads(custom_folder)",
    ] {
        exec_ignore(conn, sql);
    }
    Ok(())
}

fn schema_pkz(conn: &Connection) -> Result<(), String> {
    conn.execute_batch(
        "CREATE TABLE IF NOT EXISTS pkz_view_logs (
            file_name TEXT PRIMARY KEY,
            file_path TEXT,
            last_view_comic_id TEXT,
            last_view_comic_title TEXT,
            last_view_time TEXT
        );
        CREATE TABLE IF NOT EXISTS pkz_comic_view_logs (
            file_name TEXT,
            last_view_comic_id TEXT,
            file_path TEXT,
            last_view_comic_title TEXT,
            last_view_ep_id TEXT,
            last_view_ep_name TEXT,
            last_view_picture_rank INTEGER,
            last_view_time TEXT,
            PRIMARY KEY (file_name, last_view_comic_id)
        );",
    )
    .map_err(|e| e.to_string())?;
    Ok(())
}

fn schema_favorite(conn: &Connection) -> Result<(), String> {
    conn.execute_batch(
        "CREATE TABLE IF NOT EXISTS local_favorite_folders (
            id TEXT PRIMARY KEY,
            name TEXT,
            created_at INTEGER,
            updated_at INTEGER,
            deleted_at INTEGER
        );
        CREATE TABLE IF NOT EXISTS local_favorite_comics (
            comic_id TEXT PRIMARY KEY,
            folder_id TEXT,
            info TEXT,
            created_at INTEGER,
            updated_at INTEGER,
            deleted_at INTEGER
        );",
    )
    .map_err(|e| e.to_string())?;
    Ok(())
}
