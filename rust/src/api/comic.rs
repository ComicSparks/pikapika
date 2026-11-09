use serde_json::json;

use crate::pica::dto::{
    Category, Collection, ComicInfo, ComicsPage, EpPage, PicturePage, RemoteImageData,
};

use super::call::{self, call};

pub async fn categories() -> Result<Vec<Category>, String> {
    call::parse_vec(&call("categories", "").await?)
}

pub async fn comics(
    sort: String,
    page: i64,
    category: String,
    tag: String,
    author: String,
    creator_id: String,
    chinese_team: String,
) -> Result<ComicsPage, String> {
    call::parse(
        &call(
            "comics",
            &json!({
                "category": category,
                "tag": tag,
                "author": author,
                "creatorId": creator_id,
                "chineseTeam": chinese_team,
                "sort": sort,
                "page": page,
            })
            .to_string(),
        )
        .await?,
    )
}

pub async fn search_comics(keyword: String, sort: String, page: i64, categories: Vec<String>) -> Result<ComicsPage, String> {
    call::parse(
        &call(
            "searchComics",
            &json!({
                "keyword": keyword,
                "sort": sort,
                "page": page,
                "categories": categories,
            })
            .to_string(),
        )
        .await?,
    )
}

pub async fn random_comics() -> Result<Vec<crate::pica::dto::ComicSimple>, String> {
    call::parse_vec(&call("randomComics", "").await?)
}

pub async fn leaderboard(board_type: String) -> Result<Vec<crate::pica::dto::ComicSimple>, String> {
    call::parse_vec(&call("leaderboard", &board_type).await?)
}

pub async fn comic_info(comic_id: String, ignore_history: bool) -> Result<ComicInfo, String> {
    let method = if ignore_history { "comicInfoA" } else { "comicInfo" };
    call::parse(&call(method, &comic_id).await?)
}

pub async fn comic_ep_page(comic_id: String, page: i64) -> Result<EpPage, String> {
    call::parse(&call("comicEpPage", &json!({"comicId": comic_id, "page": page}).to_string()).await?)
}

pub async fn comic_picture_page_with_quality(
    comic_id: String,
    ep_order: i64,
    page: i64,
    quality: String,
) -> Result<PicturePage, String> {
    call::parse(
        &call(
            "comicPicturePageWithQuality",
            &json!({
                "comicId": comic_id,
                "epOrder": ep_order,
                "page": page,
                "quality": quality,
            })
            .to_string(),
        )
        .await?,
    )
}

pub async fn switch_like(comic_id: String) -> Result<String, String> {
    call("switchLike", &comic_id).await
}

pub async fn switch_favourite(comic_id: String) -> Result<String, String> {
    call("switchFavourite", &comic_id).await
}

pub async fn favourite_comics(sort: String, page: i64) -> Result<ComicsPage, String> {
    call::parse(&call("favouriteComics", &json!({"sort": sort, "page": page}).to_string()).await?)
}

pub async fn recommendation(comic_id: String) -> Result<Vec<crate::pica::dto::ComicSimple>, String> {
    call::parse_vec(&call("recommendation", &comic_id).await?)
}

pub async fn collections() -> Result<Vec<Collection>, String> {
    call::parse_vec(&call("collections", "").await?)
}

pub async fn remote_image_data(file_server: String, path: String) -> Result<RemoteImageData, String> {
    call::parse(&call("remoteImageData", &json!({"fileServer": file_server, "path": path}).to_string()).await?)
}

pub async fn remote_image_preload(file_server: String, path: String) -> Result<(), String> {
    call::done(call("remoteImagePreload", &json!({"fileServer": file_server, "path": path}).to_string()).await)
}

pub async fn download_image_path(path: String) -> Result<String, String> {
    call("downloadImagePath", &path).await
}
