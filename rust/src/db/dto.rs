use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
#[serde(rename_all = "camelCase", default)]
pub struct ViewLog {
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub id: String,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub title: String,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub author: String,
    #[serde(default, deserialize_with = "crate::flex::i64")]
    pub pages_count: i64,
    #[serde(default, deserialize_with = "crate::flex::i64")]
    pub eps_count: i64,
    #[serde(default, deserialize_with = "crate::flex::boolean")]
    pub finished: bool,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub categories: String,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub thumb_original_name: String,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub thumb_file_server: String,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub thumb_path: String,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub description: String,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub chinese_team: String,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub tags: String,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub last_view_time: String,
    #[serde(default, deserialize_with = "crate::flex::i64")]
    pub last_view_ep_order: i64,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub last_view_ep_title: String,
    #[serde(default, deserialize_with = "crate::flex::i64")]
    pub last_view_picture_rank: i64,
    #[serde(default, deserialize_with = "crate::flex::i64")]
    pub pinned_at: i64,
}

#[cfg(test)]
mod tests {
    use super::DownloadComic;

    #[test]
    fn stored_download_keeps_plain_id() {
        let raw = r#"{"id":"comic-1","title":"t","createdAt":"2020-01-01T00:00:00Z","updatedAt":"2020-01-02T00:00:00Z"}"#;
        let comic: DownloadComic = crate::flex::parse_raw(raw).expect("plain id");
        assert_eq!(comic.id, "comic-1");
        assert_eq!(comic.title, "t");
        assert_eq!(comic.created_at, "2020-01-01T00:00:00Z");
        assert_eq!(comic.updated_at, "2020-01-02T00:00:00Z");
    }
}

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
#[serde(rename_all = "camelCase", default)]
pub struct DownloadComic {
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub id: String,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub created_at: String,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub updated_at: String,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub title: String,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub author: String,
    #[serde(default, deserialize_with = "crate::flex::i64")]
    pub pages_count: i64,
    #[serde(default, deserialize_with = "crate::flex::i64")]
    pub eps_count: i64,
    #[serde(default, deserialize_with = "crate::flex::boolean")]
    pub finished: bool,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub categories: String,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub thumb_original_name: String,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub thumb_file_server: String,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub thumb_path: String,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub thumb_local_path: String,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub description: String,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub chinese_team: String,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub tags: String,
    #[serde(default, deserialize_with = "crate::flex::i64")]
    pub selected_ep_count: i64,
    #[serde(default, deserialize_with = "crate::flex::i64")]
    pub selected_picture_count: i64,
    #[serde(default, deserialize_with = "crate::flex::i64")]
    pub download_ep_count: i64,
    #[serde(default, deserialize_with = "crate::flex::i64")]
    pub download_picture_count: i64,
    #[serde(default, deserialize_with = "crate::flex::boolean")]
    pub download_finished: bool,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub download_finished_time: String,
    #[serde(default, deserialize_with = "crate::flex::boolean")]
    pub download_failed: bool,
    #[serde(default, deserialize_with = "crate::flex::boolean")]
    pub deleting: bool,
}

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
#[serde(rename_all = "camelCase", default)]
pub struct DownloadEp {
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub comic_id: String,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub id: String,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub updated_at: String,
    #[serde(default, deserialize_with = "crate::flex::i64")]
    pub ep_order: i64,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub title: String,
    #[serde(default, deserialize_with = "crate::flex::boolean")]
    pub fetched_pictures: bool,
    #[serde(default, deserialize_with = "crate::flex::i64")]
    pub selected_picture_count: i64,
    #[serde(default, deserialize_with = "crate::flex::i64")]
    pub download_picture_count: i64,
    #[serde(default, deserialize_with = "crate::flex::boolean")]
    pub download_finish: bool,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub download_finish_time: String,
    #[serde(default, deserialize_with = "crate::flex::boolean")]
    pub download_failed: bool,
}

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
#[serde(rename_all = "camelCase", default)]
pub struct DownloadPicture {
    #[serde(default, deserialize_with = "crate::flex::i64")]
    pub rank_in_ep: i64,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub file_server: String,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub path: String,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub local_path: String,
    #[serde(default, deserialize_with = "crate::flex::i64")]
    pub width: i64,
    #[serde(default, deserialize_with = "crate::flex::i64")]
    pub height: i64,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub format: String,
    #[serde(default, deserialize_with = "crate::flex::i64")]
    pub file_size: i64,
}

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
#[serde(rename_all = "camelCase", default)]
pub struct ComicSubscribe {
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub id: String,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub title: String,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub author: String,
    #[serde(default, deserialize_with = "crate::flex::i64")]
    pub pages_count: i64,
    #[serde(default, deserialize_with = "crate::flex::i64")]
    pub eps_count: i64,
    #[serde(default, deserialize_with = "crate::flex::boolean")]
    pub finished: bool,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub categories: String,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub thumb_original_name: String,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub thumb_file_server: String,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub thumb_path: String,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub description: String,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub chinese_team: String,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub tags: String,
    #[serde(default, deserialize_with = "crate::flex::i64")]
    pub likes_count: i64,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub subscribe_time: String,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub update_subscribe_time: String,
    #[serde(default, deserialize_with = "crate::flex::i64")]
    pub new_ep_count: i64,
}

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
#[serde(rename_all = "camelCase", default)]
pub struct LocalFavoriteFolder {
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub id: String,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub name: String,
    #[serde(default, deserialize_with = "crate::flex::i64")]
    pub created_at: i64,
    #[serde(default, deserialize_with = "crate::flex::i64")]
    pub updated_at: i64,
    #[serde(default, deserialize_with = "crate::flex::i64")]
    pub deleted_at: i64,
}

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
#[serde(rename_all = "camelCase", default)]
pub struct LocalFavoriteComic {
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub comic_id: String,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub folder_id: String,
    #[serde(default, deserialize_with = "crate::flex::opt_string")]
    pub info: Option<String>,
    #[serde(default, deserialize_with = "crate::flex::i64")]
    pub created_at: i64,
    #[serde(default, deserialize_with = "crate::flex::i64")]
    pub updated_at: i64,
    #[serde(default, deserialize_with = "crate::flex::i64")]
    pub deleted_at: i64,
}

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
#[serde(rename_all = "camelCase", default)]
pub struct PkzComicViewLog {
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub file_name: String,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub last_view_comic_id: String,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub file_path: String,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub last_view_comic_title: String,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub last_view_ep_id: String,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub last_view_ep_name: String,
    #[serde(default, deserialize_with = "crate::flex::i64")]
    pub last_view_picture_rank: i64,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub last_view_time: String,
}
