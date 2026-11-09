use std::sync::{Mutex, OnceLock};

use serde_json::{json, Value};

use crate::app::App;
use crate::db::store;

const CONFIG_URL: &str = "https://cdn.comicsparks.work/cfg/pikapika";

fn cache() -> &'static Mutex<Option<Value>> {
    static CACHE: OnceLock<Mutex<Option<Value>>> = OnceLock::new();
    CACHE.get_or_init(|| Mutex::new(None))
}

pub async fn warm(app: std::sync::Arc<App>) {
    let _ = remote(&app).await;
}

pub async fn remote(app: &App) -> Result<Value, String> {
    if let Some(value) = cache().lock().ok().and_then(|g| g.clone()) {
        return Ok(value);
    }
    let (status, bytes) = app.http.direct("GET", CONFIG_URL, &[], None).await?;
    if status >= 400 {
        return Ok(json!({}));
    }
    let value: Value = serde_json::from_slice(&bytes).unwrap_or(json!({}));
    if let Ok(mut guard) = cache().lock() {
        *guard = Some(value.clone());
    }
    Ok(value)
}

pub fn links(value: &Value) -> Value {
    value.get("links").cloned().unwrap_or(json!({}))
}

pub fn app_config(value: &Value) -> Value {
    json!({
        "latestVersion": value.get("latestVersion").cloned().unwrap_or(Value::String(String::new())),
        "downloadUrl": value.get("downloadUrl").cloned().unwrap_or(Value::String(String::new())),
        "changeLog": value.get("changeLog").cloned().unwrap_or(Value::String(String::new())),
        "repo": value.get("repo").cloned().unwrap_or(Value::String(String::new())),
    })
}

pub fn ensure_install_id(app: &App) -> Result<String, String> {
    let conn = app.db.properties.lock().map_err(|e| e.to_string())?;
    let current = store::load_property(&conn, "install_id", "")?;
    if !current.is_empty() {
        return Ok(current);
    }
    let id = uuid::Uuid::new_v4().simple().to_string();
    store::save_property(&conn, "install_id", &id)?;
    Ok(id)
}
