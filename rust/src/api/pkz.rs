use base64::Engine;
use serde_json::json;

use crate::db::dto::PkzComicViewLog;
use crate::pkz::dto::PkzArchive;

use super::call::{self, call};

pub async fn pkz_info(pkz_path: String) -> Result<PkzArchive, String> {
    call::parse(&call("pkzInfo", &pkz_path).await?)
}

pub async fn load_pkz_file(pkz_path: String, path: String) -> Result<Vec<u8>, String> {
    let raw = call("loadPkzFile", &json!({"pkzPath": pkz_path, "path": path}).to_string()).await?;
    base64::engine::general_purpose::STANDARD
        .decode(raw.trim())
        .map_err(|e| e.to_string())
}

pub async fn pkz_comic_view_logs(file_name: String) -> Result<Vec<PkzComicViewLog>, String> {
    call::parse_vec(&call("pkzComicViewLogs", &file_name).await?)
}

pub async fn pkz_comic_view_log_by_pkz_name_and_id(file_name: String, comic_id: String) -> Result<Option<PkzComicViewLog>, String> {
    call::parse_opt(
        &call(
            "pkzComicViewLogByPkzNameAndId",
            &json!({"fileName": file_name, "comicId": comic_id}).to_string(),
        )
        .await?,
    )
}

pub async fn view_pkz(file_name: String, file_path: String) -> Result<(), String> {
    call::done(call("viewPkz", &json!({"fileName": file_name, "filePath": file_path}).to_string()).await)
}

pub async fn view_pkz_comic(file_name: String, file_path: String, comic_id: String, comic_title: String) -> Result<(), String> {
    call::done(
        call(
            "viewPkzComic",
            &json!({
                "fileName": file_name,
                "filePath": file_path,
                "comicId": comic_id,
                "comicTitle": comic_title,
            })
            .to_string(),
        )
        .await,
    )
}

pub async fn view_pkz_ep_and_picture(
    file_name: String,
    file_path: String,
    comic_id: String,
    comic_title: String,
    ep_id: String,
    ep_title: String,
    picture_rank: i64,
) -> Result<(), String> {
    call::done(
        call(
            "viewPkzEpAndPicture",
            &json!({
                "fileName": file_name,
                "filePath": file_path,
                "comicId": comic_id,
                "comicTitle": comic_title,
                "epId": ep_id,
                "epTitle": ep_title,
                "pictureRank": picture_rank,
            })
            .to_string(),
        )
        .await,
    )
}
