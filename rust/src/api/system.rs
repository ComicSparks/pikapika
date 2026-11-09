use crate::pica::dto::AppConfig;

use super::call::{self, call};

pub async fn clean_network_cache() -> Result<(), String> {
    call::done(call("cleanNetworkCache", "").await)
}

pub async fn clean_image_cache() -> Result<(), String> {
    call::done(call("cleanImageCache", "").await)
}

pub async fn clean() -> Result<(), String> {
    call::done(call("clean", "").await)
}

pub async fn auto_clean(expire_sec: String) -> Result<(), String> {
    call::done(call("autoClean", &expire_sec).await)
}

pub async fn default_http_client_get(url: String) -> Result<String, String> {
    call("defaultHttpClientGet", &url).await
}

pub async fn config_links() -> Result<std::collections::HashMap<String, String>, String> {
    Ok(call::string_map(&call("configLinks", "").await?))
}

pub async fn app_config() -> Result<AppConfig, String> {
    call::parse(&call("appConfig", "").await?)
}

pub async fn ping(index: String) -> Result<i64, String> {
    call::parse_i64(&call("ping", &index).await?)
}

pub async fn ping_img(index: String) -> Result<i64, String> {
    call::parse_i64(&call("pingImg", &index).await?)
}

pub async fn start_web_server() -> Result<(), String> {
    call::done(call("startWebServer", "").await)
}

pub async fn stop_web_server() -> Result<(), String> {
    call::done(call("stopWebServer", "").await)
}

pub async fn get_home_dir() -> Result<String, String> {
    call("getHomeDir", "").await
}

pub async fn mkdirs(path: String) -> Result<(), String> {
    call::done(call("mkdirs", &path).await)
}
