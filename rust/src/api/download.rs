use serde_json::json;

use crate::db::dto::{DownloadComic, DownloadEp, DownloadPicture};
use crate::pica::dto::{ComicInfo, Ep};

use super::call::{self, call};

pub async fn download_running() -> Result<bool, String> {
    Ok(call::parse_bool(&call("downloadRunning", "").await?))
}

pub async fn set_download_running(running: bool) -> Result<(), String> {
    call::done(call("setDownloadRunning", if running { "true" } else { "false" }).await)
}

pub async fn create_download(comic: ComicInfo, episodes: Vec<Ep>) -> Result<(), String> {
    call::done(call("createDownload", &download_body(&comic, &episodes)).await)
}

pub async fn add_download(comic: ComicInfo, episodes: Vec<Ep>) -> Result<(), String> {
    call::done(call("addDownload", &download_body(&comic, &episodes)).await)
}

pub async fn load_download_comic(comic_id: String) -> Result<Option<DownloadComic>, String> {
    call::parse_opt(&call("loadDownloadComic", &comic_id).await?)
}

pub async fn all_downloads(search: String, custom_folder: String) -> Result<Vec<DownloadComic>, String> {
    call::parse_vec(
        &call(
            "allDownloads",
            &json!({"search": search, "customFolder": custom_folder}).to_string(),
        )
        .await?,
    )
}

pub async fn all_custom_folders() -> Result<Vec<String>, String> {
    call::parse_vec(&call("allCustomFolders", "").await?)
}

pub async fn delete_download_comic(comic_id: String) -> Result<(), String> {
    call::done(call("deleteDownloadComic", &comic_id).await)
}

pub async fn move_download_comic(comic_id_list: Vec<String>, custom_folder: String) -> Result<(), String> {
    call::done(
        call(
            "moveDownloadComic",
            &json!({"comicIdList": comic_id_list, "customFolder": custom_folder}).to_string(),
        )
        .await,
    )
}

pub async fn download_ep_list(comic_id: String) -> Result<Vec<DownloadEp>, String> {
    call::parse_vec(&call("downloadEpList", &comic_id).await?)
}

pub async fn download_pictures_by_ep_id(ep_id: String) -> Result<Vec<DownloadPicture>, String> {
    call::parse_vec(&call("downloadPicturesByEpId", &ep_id).await?)
}

pub async fn reset_all_downloads() -> Result<(), String> {
    call::done(call("resetAllDownloads", "").await)
}

pub async fn download_all(comic_ids: Vec<String>) -> Result<(), String> {
    let params = serde_json::to_string(&comic_ids).map_err(|e| e.to_string())?;
    call::done(call("downloadAll", &params).await)
}

pub async fn convert_image_to_jpeg100(path: String, dir: String) -> Result<(), String> {
    call::done(call("convertImageToJPEG100", &json!({"path": path, "dir": dir}).to_string()).await)
}

fn download_body(comic: &ComicInfo, episodes: &[Ep]) -> String {
    let categories = serde_json::to_string(&comic.categories).unwrap_or_else(|_| "[]".into());
    let tags = serde_json::to_string(&comic.tags).unwrap_or_else(|_| "[]".into());
    json!({
        "comic": {
            "id": comic.id,
            "createdAt": comic.created_at,
            "updatedAt": comic.updated_at,
            "title": comic.title,
            "author": comic.author,
            "pagesCount": comic.pages_count,
            "epsCount": comic.eps_count,
            "finished": comic.finished,
            "categories": categories,
            "thumbOriginalName": comic.thumb.original_name,
            "thumbFileServer": comic.thumb.file_server,
            "thumbPath": comic.thumb.path,
            "description": comic.description,
            "chineseTeam": comic.chinese_team,
            "tags": tags,
        },
        "epList": episodes.iter().map(|ep| json!({
            "comicId": comic.id,
            "id": ep.id,
            "updatedAt": ep.updated_at,
            "epOrder": ep.order,
            "title": ep.title,
        })).collect::<Vec<_>>(),
    })
    .to_string()
}
