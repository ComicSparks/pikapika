use flutter_rust_bridge::frb;
use serde::{Deserialize, Serialize};
use serde_json::Value;

use crate::flex::{self, value_string};

#[derive(Clone, Debug)]
#[frb(ignore)]
pub struct Page<T> {
    pub total: i64,
    pub limit: i64,
    pub page: i64,
    pub pages: i64,
    pub docs: Vec<T>,
}

macro_rules! frb_page {
    ($($Name:ident : $Item:ty),+ $(,)?) => {$(
        #[derive(Clone, Debug, Default, Serialize, Deserialize)]
        #[serde(default)]
        pub struct $Name {
            #[serde(default, deserialize_with = "crate::flex::i64")]
            pub total: i64,
            #[serde(default, deserialize_with = "crate::flex::i64")]
            pub limit: i64,
            #[serde(default, deserialize_with = "crate::flex::i64")]
            pub page: i64,
            #[serde(default, deserialize_with = "crate::flex::i64")]
            pub pages: i64,
            #[serde(default)]
            pub docs: Vec<$Item>,
        }

        impl From<Page<$Item>> for $Name {
            fn from(page: Page<$Item>) -> Self {
                Self {
                    total: page.total,
                    limit: page.limit,
                    page: page.page,
                    pages: page.pages,
                    docs: page.docs,
                }
            }
        }
    )+};
}

#[derive(Clone, Debug, Default, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct RemoteImageInfo {
    pub original_name: String,
    pub path: String,
    pub file_server: String,
}

impl<'de> Deserialize<'de> for RemoteImageInfo {
    fn deserialize<D: serde::Deserializer<'de>>(deserializer: D) -> Result<Self, D::Error> {
        let value = Value::deserialize(deserializer)?;
        Ok(match value {
            Value::Object(map) => Self {
                original_name: value_string(map.get("originalName").unwrap_or(&Value::Null)),
                path: value_string(map.get("path").unwrap_or(&Value::Null)),
                file_server: value_string(map.get("fileServer").unwrap_or(&Value::Null)),
            },
            _ => Self::default(),
        })
    }
}

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
#[serde(rename_all = "camelCase", default)]
pub struct Category {
    #[serde(rename = "_id", alias = "id", default, deserialize_with = "crate::flex::string")]
    pub id: String,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub title: String,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub description: String,
    #[serde(default)]
    pub thumb: RemoteImageInfo,
    #[serde(default, deserialize_with = "crate::flex::boolean")]
    pub is_web: bool,
    #[serde(default, deserialize_with = "crate::flex::boolean")]
    pub active: bool,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub link: String,
}

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
#[serde(rename_all = "camelCase", default)]
pub struct ComicSimple {
    #[serde(rename = "_id", alias = "id", default, deserialize_with = "crate::flex::string")]
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
    #[serde(default, deserialize_with = "crate::flex::string_vec")]
    pub categories: Vec<String>,
    #[serde(default)]
    pub thumb: RemoteImageInfo,
    #[serde(default, deserialize_with = "crate::flex::i64")]
    pub likes_count: i64,
}

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
#[serde(rename_all = "camelCase", default)]
pub struct Creator {
    #[serde(rename = "_id", alias = "id", default, deserialize_with = "crate::flex::string")]
    pub id: String,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub gender: String,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub name: String,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub title: String,
    #[serde(default, deserialize_with = "crate::flex::boolean")]
    pub verified: bool,
    #[serde(default, deserialize_with = "crate::flex::i64")]
    pub exp: i64,
    #[serde(default, deserialize_with = "crate::flex::i64")]
    pub level: i64,
    #[serde(default, deserialize_with = "crate::flex::string_vec")]
    pub characters: Vec<String>,
    #[serde(default)]
    pub avatar: RemoteImageInfo,
    #[serde(default, deserialize_with = "flex::opt_string")]
    pub slogan: Option<String>,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub role: String,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub character: String,
}

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
#[serde(rename_all = "camelCase", default)]
pub struct ComicInfo {
    #[serde(rename = "_id", alias = "id", default, deserialize_with = "crate::flex::string")]
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
    #[serde(default, deserialize_with = "crate::flex::string_vec")]
    pub categories: Vec<String>,
    #[serde(default)]
    pub thumb: RemoteImageInfo,
    #[serde(default, deserialize_with = "crate::flex::i64")]
    pub likes_count: i64,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub description: String,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub chinese_team: String,
    #[serde(default, deserialize_with = "crate::flex::string_vec")]
    pub tags: Vec<String>,
    #[serde(rename = "updated_at", alias = "updatedAt", default, deserialize_with = "crate::flex::string")]
    pub updated_at: String,
    #[serde(rename = "created_at", alias = "createdAt", default, deserialize_with = "crate::flex::string")]
    pub created_at: String,
    #[serde(default, deserialize_with = "crate::flex::boolean")]
    pub allow_download: bool,
    #[serde(default, deserialize_with = "crate::flex::i64")]
    pub views_count: i64,
    #[serde(default, deserialize_with = "crate::flex::boolean")]
    pub is_favourite: bool,
    #[serde(default, deserialize_with = "crate::flex::boolean")]
    pub is_liked: bool,
    #[serde(default, deserialize_with = "crate::flex::i64")]
    pub comments_count: i64,
    #[serde(rename = "_creator", default)]
    pub creator: Creator,
}

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
#[serde(rename_all = "camelCase", default)]
pub struct Ep {
    #[serde(rename = "_id", alias = "id", default, deserialize_with = "crate::flex::string")]
    pub id: String,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub title: String,
    #[serde(default, deserialize_with = "crate::flex::i64")]
    pub order: i64,
    #[serde(rename = "updated_at", alias = "updatedAt", default, deserialize_with = "crate::flex::string")]
    pub updated_at: String,
}

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
#[serde(rename_all = "camelCase", default)]
pub struct Picture {
    #[serde(rename = "_id", alias = "id", default, deserialize_with = "crate::flex::string")]
    pub id: String,
    #[serde(default)]
    pub media: RemoteImageInfo,
}

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
#[serde(rename_all = "camelCase", default)]
pub struct CommentUser {
    #[serde(rename = "_id", alias = "id", default, deserialize_with = "crate::flex::string")]
    pub id: String,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub gender: String,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub name: String,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub title: String,
    #[serde(default, deserialize_with = "crate::flex::boolean")]
    pub verified: bool,
    #[serde(default, deserialize_with = "crate::flex::i64")]
    pub exp: i64,
    #[serde(default, deserialize_with = "crate::flex::i64")]
    pub level: i64,
    #[serde(default, deserialize_with = "crate::flex::string_vec")]
    pub characters: Vec<String>,
    #[serde(default)]
    pub avatar: RemoteImageInfo,
    #[serde(default, deserialize_with = "flex::opt_string")]
    pub slogan: Option<String>,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub role: String,
}

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
#[serde(rename_all = "camelCase", default)]
pub struct CommentBase {
    #[serde(rename = "_id", alias = "id", default, deserialize_with = "crate::flex::string")]
    pub id: String,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub content: String,
    #[serde(rename = "_user", default)]
    pub user: CommentUser,
    #[serde(default, deserialize_with = "crate::flex::boolean")]
    pub is_top: bool,
    #[serde(default, deserialize_with = "crate::flex::boolean")]
    pub hide: bool,
    #[serde(rename = "created_at", alias = "createdAt", default, deserialize_with = "crate::flex::string")]
    pub created_at: String,
    #[serde(default, deserialize_with = "crate::flex::i64")]
    pub likes_count: i64,
    #[serde(default, deserialize_with = "crate::flex::i64")]
    pub comments_count: i64,
    #[serde(default, deserialize_with = "crate::flex::boolean")]
    pub is_liked: bool,
}

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
#[serde(rename_all = "camelCase", default)]
pub struct MyCommentComic {
    #[serde(rename = "_id", alias = "id", default, deserialize_with = "crate::flex::string")]
    pub id: String,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub title: String,
}

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
#[serde(rename_all = "camelCase", default)]
pub struct MyComment {
    #[serde(rename = "_id", alias = "id", default, deserialize_with = "crate::flex::string")]
    pub id: String,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub content: String,
    #[serde(default, deserialize_with = "crate::flex::boolean")]
    pub hide: bool,
    #[serde(rename = "created_at", alias = "createdAt", default, deserialize_with = "crate::flex::string")]
    pub created_at: String,
    #[serde(default, deserialize_with = "crate::flex::i64")]
    pub likes_count: i64,
    #[serde(default, deserialize_with = "crate::flex::i64")]
    pub comments_count: i64,
    #[serde(default, deserialize_with = "crate::flex::boolean")]
    pub is_liked: bool,
    #[serde(rename = "_comic", default)]
    pub comic: MyCommentComic,
}

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
#[serde(rename_all = "camelCase", default)]
pub struct GameSimple {
    #[serde(rename = "_id", alias = "id", default, deserialize_with = "crate::flex::string")]
    pub id: String,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub title: String,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub version: String,
    #[serde(default)]
    pub icon: RemoteImageInfo,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub publisher: String,
    #[serde(default, deserialize_with = "crate::flex::boolean")]
    pub adult: bool,
    #[serde(default, deserialize_with = "crate::flex::boolean")]
    pub suggest: bool,
    #[serde(default, deserialize_with = "crate::flex::i64")]
    pub likes_count: i64,
    #[serde(default, deserialize_with = "crate::flex::boolean")]
    pub android: bool,
    #[serde(default, deserialize_with = "crate::flex::boolean")]
    pub ios: bool,
}

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
#[serde(rename_all = "camelCase", default)]
pub struct GameInfo {
    #[serde(rename = "_id", alias = "id", default, deserialize_with = "crate::flex::string")]
    pub id: String,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub title: String,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub version: String,
    #[serde(default)]
    pub icon: RemoteImageInfo,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub publisher: String,
    #[serde(default, deserialize_with = "crate::flex::boolean")]
    pub adult: bool,
    #[serde(default, deserialize_with = "crate::flex::boolean")]
    pub suggest: bool,
    #[serde(default, deserialize_with = "crate::flex::i64")]
    pub likes_count: i64,
    #[serde(default, deserialize_with = "crate::flex::boolean")]
    pub android: bool,
    #[serde(default, deserialize_with = "crate::flex::boolean")]
    pub ios: bool,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub description: String,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub update_content: String,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub video_link: String,
    #[serde(default)]
    pub screenshots: Vec<RemoteImageInfo>,
    #[serde(default, deserialize_with = "crate::flex::i64")]
    pub comments_count: i64,
    #[serde(default, deserialize_with = "crate::flex::i64")]
    pub downloads_count: i64,
    #[serde(default, deserialize_with = "crate::flex::boolean")]
    pub is_liked: bool,
    #[serde(default, deserialize_with = "crate::flex::string_vec")]
    pub android_links: Vec<String>,
    #[serde(default, deserialize_with = "crate::flex::f64")]
    pub android_size: f64,
    #[serde(default, deserialize_with = "crate::flex::string_vec")]
    pub ios_links: Vec<String>,
    #[serde(default, deserialize_with = "crate::flex::f64")]
    pub ios_size: f64,
    #[serde(rename = "updated_at", alias = "updatedAt", default, deserialize_with = "crate::flex::string")]
    pub updated_at: String,
    #[serde(rename = "created_at", alias = "createdAt", default, deserialize_with = "crate::flex::string")]
    pub created_at: String,
}

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
#[serde(rename_all = "camelCase", default)]
pub struct Collection {
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub title: String,
    #[serde(default)]
    pub comics: Vec<ComicSimple>,
}

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
#[serde(rename_all = "camelCase", default)]
pub struct UserProfile {
    #[serde(rename = "_id", alias = "id", default, deserialize_with = "crate::flex::string")]
    pub id: String,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub gender: String,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub name: String,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub title: String,
    #[serde(default, deserialize_with = "crate::flex::boolean")]
    pub verified: bool,
    #[serde(default, deserialize_with = "crate::flex::i64")]
    pub exp: i64,
    #[serde(default, deserialize_with = "crate::flex::i64")]
    pub level: i64,
    #[serde(default, deserialize_with = "crate::flex::string_vec")]
    pub characters: Vec<String>,
    #[serde(default)]
    pub avatar: RemoteImageInfo,
    #[serde(default, deserialize_with = "flex::opt_string")]
    pub slogan: Option<String>,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub birthday: String,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub email: String,
    #[serde(rename = "created_at", alias = "createdAt", default, deserialize_with = "crate::flex::string")]
    pub created_at: String,
    #[serde(default, deserialize_with = "crate::flex::boolean")]
    pub is_punched: bool,
}

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
#[serde(rename_all = "camelCase", default)]
pub struct Knight {
    #[serde(rename = "_id", alias = "id", default, deserialize_with = "crate::flex::string")]
    pub id: String,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub gender: String,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub name: String,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub title: String,
    #[serde(default, deserialize_with = "crate::flex::boolean")]
    pub verified: bool,
    #[serde(default, deserialize_with = "crate::flex::i64")]
    pub exp: i64,
    #[serde(default, deserialize_with = "crate::flex::i64")]
    pub level: i64,
    #[serde(default, deserialize_with = "crate::flex::string_vec")]
    pub characters: Vec<String>,
    #[serde(default)]
    pub avatar: RemoteImageInfo,
    #[serde(default, deserialize_with = "flex::opt_string")]
    pub slogan: Option<String>,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub role: String,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub character: String,
    #[serde(default, deserialize_with = "crate::flex::i64")]
    pub comics_uploaded: i64,
}

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
#[serde(rename_all = "camelCase", default)]
pub struct RemoteImageData {
    #[serde(default, deserialize_with = "crate::flex::i64")]
    pub file_size: i64,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub format: String,
    #[serde(default, deserialize_with = "crate::flex::i64")]
    pub width: i64,
    #[serde(default, deserialize_with = "crate::flex::i64")]
    pub height: i64,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub final_path: String,
}

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
#[serde(default)]
pub struct ForgotPasswordResult {
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub question1: String,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub question2: String,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub question3: String,
}

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
#[serde(default)]
pub struct ResetPasswordResult {
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub password: String,
}

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
#[serde(rename_all = "camelCase", default)]
pub struct AppConfig {
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub latest_version: String,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub download_url: String,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub change_log: String,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub repo: String,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn comic_keeps_id_when_response_has_both_keys() {
        let raw = r#"{
            "total": 1, "limit": 20, "page": 1, "pages": 1,
            "docs": [{
                "_id": "665707029c4bc10d876d9c63",
                "id": "665707029c4bc10d876d9c63",
                "title": "t",
                "author": "a",
                "pagesCount": 1,
                "epsCount": 1,
                "finished": false,
                "categories": [],
                "likesCount": 0,
                "totalLikes": 1,
                "totalViews": 2
            }]
        }"#;
        let page: ComicsPage = crate::flex::parse_raw(raw).expect("both keys");
        assert_eq!(page.docs[0].id, "665707029c4bc10d876d9c63");
    }

    #[test]
    fn comic_accepts_only_id() {
        let raw = r#"{"_id":"","id":"only-id","title":"t"}"#;
        let comic: ComicSimple = crate::flex::parse_raw(raw).expect("alias only");
        assert_eq!(comic.id, "only-id");
    }

    #[test]
    fn picture_page_reads_media() {
        let raw = r#"{
            "total": 1, "limit": 40, "page": 1, "pages": 1,
            "docs": [{
                "_id": "p1",
                "id": "p1",
                "media": {"fileServer": "https://storage.example", "path": "to/a.jpg", "originalName": "a.jpg"}
            }]
        }"#;
        let page: PicturePage = crate::flex::parse_raw(raw).expect("pages");
        assert_eq!(page.docs.len(), 1);
        assert_eq!(page.docs[0].id, "p1");
        assert_eq!(page.docs[0].media.file_server, "https://storage.example");
        assert_eq!(page.docs[0].media.path, "to/a.jpg");
    }

    #[test]
    fn comic_accepts_id_key_without_underscore() {
        let raw = r#"{"id":"only-id","title":"t"}"#;
        let comic: ComicSimple = crate::flex::parse_raw(raw).expect("id key");
        assert_eq!(comic.id, "only-id");
    }
}

frb_page! {
    ComicsPage: ComicSimple,
    EpPage: Ep,
    PicturePage: Picture,
    CommentPage: CommentBase,
    CommentChildrenPage: CommentBase,
    MyCommentsPage: MyComment,
    GamePage: GameSimple,
    GameCommentPage: CommentBase,
    GameCommentChildrenPage: CommentBase,
}
