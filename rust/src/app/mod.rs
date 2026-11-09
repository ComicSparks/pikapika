mod dispatch;

use std::sync::{Arc, Mutex, OnceLock};

use crate::db::store;
use crate::db::Databases;
use crate::download::DownloadCtl;
use crate::export::SocketExport;
use crate::image_cache::ImageCache;
use crate::net::{parse_proxy, NetSettings, Http};
use crate::paths::Paths;
use crate::pica::Pica;

pub struct App {
    pub paths: Paths,
    pub db: Databases,
    pub http: Http,
    pub pica: Mutex<Pica>,
    pub images: ImageCache,
    pub download: DownloadCtl,
    pub socket: Mutex<SocketExport>,
}

fn slot() -> &'static Mutex<Option<Arc<App>>> {
    static SLOT: OnceLock<Mutex<Option<Arc<App>>>> = OnceLock::new();
    SLOT.get_or_init(|| Mutex::new(None))
}

pub fn current() -> Result<Arc<App>, String> {
    slot()
        .lock()
        .map_err(|e| e.to_string())?
        .as_ref()
        .cloned()
        .ok_or_else(|| "应用还没有初始化".to_string())
}

pub async fn init(explicit: &str) -> Result<Arc<App>, String> {
    {
        let guard = slot().lock().map_err(|e| e.to_string())?;
        if let Some(app) = guard.as_ref() {
            return Ok(app.clone());
        }
    }
    let paths = Paths::resolve(explicit)?;
    let db = Databases::open(&paths.databases)?;
    let http = Http::new();
    let app = Arc::new(App {
        paths,
        db,
        http,
        pica: Mutex::new(Pica::default()),
        images: ImageCache::new(),
        download: DownloadCtl::new(),
        socket: Mutex::new(SocketExport::new()),
    });
    app.reload_net()?;
    {
        let conn = app.db.properties.lock().map_err(|e| e.to_string())?;
        let token = store::load_property(&conn, "token", "")?;
        drop(conn);
        app.pica.lock().map_err(|e| e.to_string())?.token = token;
    }
    let _ = crate::telemetry::ensure_install_id(&app);
    let worker = app.clone();
    tokio::spawn(async move {
        crate::download::run(worker).await;
    });
    let warm = app.clone();
    tokio::spawn(async move {
        crate::telemetry::warm(warm).await;
    });
    let mut guard = slot().lock().map_err(|e| e.to_string())?;
    if let Some(existing) = guard.as_ref() {
        return Ok(existing.clone());
    }
    *guard = Some(app.clone());
    Ok(app)
}

impl App {
    pub fn reload_net(&self) -> Result<(), String> {
        let conn = self.db.properties.lock().map_err(|e| e.to_string())?;
        let proxy = store::load_property(&conn, "proxy", "")?;
        let shunt = store::load_property(&conn, "switchAddress", "3")?;
        let image = store::load_property(&conn, "imageSwitchAddress", "1")?;
        let addr2 = store::load_property(&conn, "switchAddress2", "")?;
        let addr3 = store::load_property(&conn, "switchAddress3", "")?;
        drop(conn);
        let mut settings = NetSettings {
            proxy: parse_proxy(&proxy)?,
            shunt_index: shunt.parse().unwrap_or(3),
            image_index: image.parse().unwrap_or(1),
            addresses: crate::net::default_addresses(),
        };
        if !addr2.is_empty() {
            if settings.addresses.len() > 2 {
                settings.addresses[2] = addr2;
            }
        }
        if !addr3.is_empty() {
            if settings.addresses.len() > 3 {
                settings.addresses[3] = addr3;
            }
        }
        self.http.update(settings);
        Ok(())
    }

    pub fn prop(&self, name: &str, default_value: &str) -> Result<String, String> {
        let conn = self.db.properties.lock().map_err(|e| e.to_string())?;
        store::load_property(&conn, name, default_value)
    }

    pub fn set_prop(&self, name: &str, value: &str) -> Result<(), String> {
        let conn = self.db.properties.lock().map_err(|e| e.to_string())?;
        store::save_property(&conn, name, value)
    }

    pub fn is_pro(&self) -> Result<bool, String> {
        let info = dispatch::pro_info(self)?;
        Ok(info["pro_info_af"]["is_pro"].as_bool().unwrap_or(false)
            || info["pro_info_pat"]["is_pro"].as_bool().unwrap_or(false))
    }
}

pub async fn invoke(method: &str, params: &str) -> Result<String, String> {
    let app = current()?;
    dispatch::invoke(app, method, params).await
}

pub fn data_dir() -> Result<String, String> {
    Ok(current()?.paths.root.to_string_lossy().to_string())
}

#[cfg(test)]
mod tests {
    use super::init;

    #[tokio::test]
    async fn init_is_idempotent() {
        let dir = std::env::temp_dir().join(format!("pikapika-init-{}", std::process::id()));
        let _ = std::fs::remove_dir_all(&dir);
        let path = dir.to_string_lossy().to_string();
        init(&path).await.expect("first init");
        init(&path).await.expect("second init");
        let stored = super::data_dir().expect("dir");
        assert!(stored.contains("pikapika-init-"));
    }
}
