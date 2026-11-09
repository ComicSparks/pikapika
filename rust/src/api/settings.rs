use super::call::{self, call};

pub async fn load_download_and_export_path() -> Result<String, String> {
    call("loadDownloadAndExportPath", "").await
}

pub async fn save_download_and_export_path(folder: String) -> Result<(), String> {
    call::done(call("saveDownloadAndExportPath", &folder).await)
}

pub async fn load_download_cache_path() -> Result<String, String> {
    call("loadDownloadCachePath", "").await
}

pub async fn save_download_cache_path(folder: String) -> Result<(), String> {
    call::done(call("saveDownloadCachePath", &folder).await)
}

pub async fn load_download_thread_count() -> Result<i64, String> {
    call::parse_i64(&call("loadDownloadThreadCount", "").await?)
}

pub async fn save_download_thread_count(value: i64) -> Result<(), String> {
    call::done(call("saveDownloadThreadCount", &value.to_string()).await)
}

pub async fn reload_switch_address() -> Result<(), String> {
    call::done(call("reloadSwitchAddress", "").await)
}

pub async fn reset_switch_address() -> Result<(), String> {
    call::done(call("resetSwitchAddress", "").await)
}
