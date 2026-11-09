use serde_json::json;

use super::call::{self, call};

fn located(comic_id: &str, dir: &str, name: &str) -> String {
    json!({"comicId": comic_id, "dir": dir, "name": name}).to_string()
}

pub async fn export_comic_download(comic_id: String, dir: String, name: String) -> Result<(), String> {
    call::done(call("exportComicDownload", &located(&comic_id, &dir, &name)).await)
}

pub async fn export_comic_download_to_pki(comic_id: String, dir: String, name: String) -> Result<(), String> {
    call::done(call("exportComicDownloadToPki", &located(&comic_id, &dir, &name)).await)
}

pub async fn export_comic_jpegs_even_not_finish(comic_id: String, dir: String, name: String) -> Result<(), String> {
    call::done(call("exportComicJpegsEvenNotFinish", &located(&comic_id, &dir, &name)).await)
}

pub async fn export_comic_download_to_jpg(comic_id: String, dir: String, name: String) -> Result<(), String> {
    call::done(call("exportComicDownloadToJPG", &located(&comic_id, &dir, &name)).await)
}

pub async fn export_comic_download_to_pdf(comic_id: String, dir: String, name: String) -> Result<(), String> {
    call::done(call("exportComicDownloadToPDF", &located(&comic_id, &dir, &name)).await)
}

pub async fn export_comic_download_to_epub(comic_id: String, dir: String, name: String) -> Result<(), String> {
    call::done(call("exportComicDownloadToEpub", &located(&comic_id, &dir, &name)).await)
}

pub async fn export_comic_download_to_pdf_folder(comic_id: String, dir: String, name: String) -> Result<(), String> {
    call::done(call("exportComicDownloadToPDFFolder", &located(&comic_id, &dir, &name)).await)
}

pub async fn export_comic_download_jpeg_zip(comic_id: String, dir: String, name: String) -> Result<(), String> {
    call::done(call("exportComicDownloadJpegZip", &located(&comic_id, &dir, &name)).await)
}

pub async fn export_comic_download_to_cbzs_zip(comic_id: String, dir: String, name: String) -> Result<(), String> {
    call::done(call("exportComicDownloadToCbzsZip", &located(&comic_id, &dir, &name)).await)
}

pub async fn export_comic_download_to_pkz(comic_ids: Vec<String>, dir: String, name: String) -> Result<(), String> {
    call::done(call("exportComicDownloadToPkz", &json!({"comicIds": comic_ids, "dir": dir, "name": name}).to_string()).await)
}

pub async fn export_any_comic_downloads_to_zip(comic_ids: Vec<String>, dir: String) -> Result<(), String> {
    call::done(call("exportAnyComicDownloadsToZip", &json!({"comicIds": comic_ids, "dir": dir}).to_string()).await)
}

pub async fn export_any_comic_downloads_to_pki(comic_ids: Vec<String>, dir: String) -> Result<(), String> {
    call::done(call("exportAnyComicDownloadsToPki", &json!({"comicIds": comic_ids, "dir": dir}).to_string()).await)
}

pub async fn import_comic_download_dir(dir: String) -> Result<(), String> {
    call::done(call("importComicDownloadDir", &dir).await)
}

pub async fn export_comic_using_socket(comic_id: String) -> Result<i64, String> {
    call::parse_i64(&call("exportComicUsingSocket", &comic_id).await?)
}

pub async fn export_comic_using_socket_exit() -> Result<(), String> {
    call::done(call("exportComicUsingSocketExit", "").await)
}

pub async fn import_comic_download(zip_path: String) -> Result<(), String> {
    call::done(call("importComicDownload", &zip_path).await)
}

pub async fn import_comic_download_pki(zip_path: String) -> Result<(), String> {
    call::done(call("importComicDownloadPki", &zip_path).await)
}

pub async fn import_comic_download_using_socket(addr: String) -> Result<(), String> {
    call::done(call("importComicDownloadUsingSocket", &addr).await)
}

pub async fn client_ip_set() -> Result<String, String> {
    call("clientIpSet", "").await
}

pub async fn merge_histories_from_web_dav(
    root: String,
    username: String,
    password: String,
    file: String,
    direction: String,
) -> Result<(), String> {
    call::done(
        call(
            "mergeHistoriesFromWebDav",
            &json!({
                "root": root,
                "username": username,
                "password": password,
                "file": file,
                "direction": direction,
            })
            .to_string(),
        )
        .await,
    )
}

pub async fn merge_histories_from_local(local_path: String) -> Result<(), String> {
    call::done(call("mergeHistoriesFromLocal", &local_path).await)
}

pub async fn import_comic_view_form_off(db_path: String) -> Result<(), String> {
    call::done(call("importComicViewFormOff", &db_path).await)
}
