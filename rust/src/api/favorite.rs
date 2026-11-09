use serde_json::json;

use crate::db::dto::{ComicSubscribe, LocalFavoriteComic, LocalFavoriteFolder, ViewLog};

use super::call::{self, call};

pub async fn view_log_page(offset: i64, limit: i64) -> Result<Vec<ViewLog>, String> {
    call::parse_vec(&call("viewLogPage", &json!({"offset": offset, "limit": limit}).to_string()).await?)
}

pub async fn clear_all_view_log() -> Result<(), String> {
    call::done(call("clearAllViewLog", "").await)
}

pub async fn delete_view_log(id: String) -> Result<(), String> {
    call::done(call("deleteViewLog", &id).await)
}

pub async fn set_view_log_pinned(comic_id: String, pinned: bool) -> Result<(), String> {
    call::done(call("setViewLogPinned", &json!({"comicId": comic_id, "pinned": pinned}).to_string()).await)
}

pub async fn view_comic(id: String) -> Result<(), String> {
    call::done(call("viewComic", &id).await)
}

pub async fn store_view_ep(comic_id: String, ep_order: i64, ep_title: String, picture_rank: i64) -> Result<(), String> {
    call::done(
        call(
            "storeViewEp",
            &json!({
                "comicId": comic_id,
                "epOrder": ep_order,
                "epTitle": ep_title,
                "pictureRank": picture_rank,
            })
            .to_string(),
        )
        .await,
    )
}

pub async fn load_view(comic_id: String) -> Result<Option<ViewLog>, String> {
    call::parse_opt(&call("loadView", &comic_id).await?)
}

pub async fn load_viewed_list(ids: Vec<String>) -> Result<Vec<String>, String> {
    let params = serde_json::to_string(&ids).map_err(|e| e.to_string())?;
    call::parse_vec(&call("loadViewedList", &params).await?)
}

pub async fn load_subscribed(comic_id: String) -> Result<Option<ComicSubscribe>, String> {
    call::parse_opt(&call("loadSubscribed", &comic_id).await?)
}

pub async fn add_subscribed(comic_id: String) -> Result<(), String> {
    call::done(call("addSubscribed", &comic_id).await)
}

pub async fn remove_subscribed(comic_id: String) -> Result<(), String> {
    call::done(call("removeSubscribed", &comic_id).await)
}

pub async fn remove_all_subscribed() -> Result<(), String> {
    call::done(call("removeAllSubscribed", "").await)
}

pub async fn all_subscribed() -> Result<Vec<ComicSubscribe>, String> {
    call::parse_vec(&call("allSubscribed", "").await?)
}

pub async fn update_subscribed() -> Result<(), String> {
    call::done(call("updateSubscribed", "").await)
}

pub async fn update_subscribed_force() -> Result<(), String> {
    call::done(call("updateSubscribedForce", "").await)
}

pub async fn create_local_favorite_folder(name: String) -> Result<LocalFavoriteFolder, String> {
    call::parse(&call("createLocalFavoriteFolder", &json!({"name": name}).to_string()).await?)
}

pub async fn update_local_favorite_folder(folder: LocalFavoriteFolder) -> Result<(), String> {
    let params = serde_json::to_string(&folder).map_err(|e| e.to_string())?;
    call::done(call("updateLocalFavoriteFolder", &params).await)
}

pub async fn delete_local_favorite_folder(folder_id: String) -> Result<(), String> {
    call::done(call("deleteLocalFavoriteFolder", &folder_id).await)
}

pub async fn get_local_favorite_folder(folder_id: String) -> Result<LocalFavoriteFolder, String> {
    call::parse(&call("getLocalFavoriteFolder", &folder_id).await?)
}

pub async fn list_local_favorite_folders() -> Result<Vec<LocalFavoriteFolder>, String> {
    call::parse_vec(&call("listLocalFavoriteFolders", "").await?)
}

pub async fn count_local_favorite_folders() -> Result<i64, String> {
    call::parse_i64(&call("countLocalFavoriteFolders", "").await?)
}

pub async fn add_local_favorite_comic(comic_id: String, folder_id: String, info: String) -> Result<(), String> {
    call::done(
        call(
            "addLocalFavoriteComic",
            &json!({"comicId": comic_id, "folderId": folder_id, "info": info}).to_string(),
        )
        .await,
    )
}

pub async fn remove_local_favorite_comic(comic_id: String) -> Result<(), String> {
    call::done(call("removeLocalFavoriteComic", &comic_id).await)
}

pub async fn move_local_favorite_comics(comic_ids: Vec<String>, folder_id: String) -> Result<(), String> {
    call::done(call("moveLocalFavoriteComics", &json!({"comicIds": comic_ids, "folderId": folder_id}).to_string()).await)
}

pub async fn get_local_favorite_comic(comic_id: String) -> Result<Option<LocalFavoriteComic>, String> {
    call::parse_opt(&call("getLocalFavoriteComic", &comic_id).await?)
}

pub async fn list_local_favorite_comics(folder_id: String) -> Result<Vec<LocalFavoriteComic>, String> {
    call::parse_vec(&call("listLocalFavoriteComics", &json!({"folderId": folder_id}).to_string()).await?)
}

pub async fn list_all_local_favorite_comics() -> Result<Vec<LocalFavoriteComic>, String> {
    call::parse_vec(&call("listAllLocalFavoriteComics", "").await?)
}

pub async fn merge_local_favorites_from_web_dav(
    webdav_root: String,
    webdav_username: String,
    webdav_password: String,
) -> Result<(), String> {
    call::done(
        call(
            "mergeLocalFavoritesFromWebDav",
            &json!({
                "webdavRoot": webdav_root,
                "webdavUsername": webdav_username,
                "webdavPassword": webdav_password,
            })
            .to_string(),
        )
        .await,
    )
}
