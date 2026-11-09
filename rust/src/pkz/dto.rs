use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
#[serde(default)]
pub struct PkzPicture {
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub id: String,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub title: String,
    #[serde(default, deserialize_with = "crate::flex::i64")]
    pub width: i64,
    #[serde(default, deserialize_with = "crate::flex::i64")]
    pub height: i64,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub format: String,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub picture_path: String,
    #[serde(default, deserialize_with = "crate::flex::i64")]
    pub idx: i64,
}

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
#[serde(default)]
pub struct PkzChapter {
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub id: String,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub title: String,
    #[serde(default, deserialize_with = "crate::flex::i64")]
    pub updated_at: i64,
    #[serde(default, deserialize_with = "crate::flex::i64")]
    pub created_at: i64,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub cover_path: String,
    #[serde(default)]
    pub pictures: Vec<PkzPicture>,
    #[serde(default, deserialize_with = "crate::flex::i64")]
    pub picture_count: i64,
    #[serde(default, deserialize_with = "crate::flex::i64")]
    pub idx: i64,
}

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
#[serde(default)]
pub struct PkzVolume {
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub id: String,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub title: String,
    #[serde(default, deserialize_with = "crate::flex::i64")]
    pub updated_at: i64,
    #[serde(default, deserialize_with = "crate::flex::i64")]
    pub created_at: i64,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub cover_path: String,
    #[serde(default)]
    pub chapters: Vec<PkzChapter>,
    #[serde(default, deserialize_with = "crate::flex::i64")]
    pub chapter_count: i64,
    #[serde(default, deserialize_with = "crate::flex::i64")]
    pub picture_count: i64,
    #[serde(default, deserialize_with = "crate::flex::i64")]
    pub idx: i64,
}

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
#[serde(default)]
pub struct PkzComic {
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub id: String,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub title: String,
    #[serde(default, deserialize_with = "crate::flex::string_vec")]
    pub categories: Vec<String>,
    #[serde(default, deserialize_with = "crate::flex::string_vec")]
    pub tags: Vec<String>,
    #[serde(default, deserialize_with = "crate::flex::i64")]
    pub updated_at: i64,
    #[serde(default, deserialize_with = "crate::flex::i64")]
    pub created_at: i64,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub description: String,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub chinese_team: String,
    #[serde(default, deserialize_with = "crate::flex::boolean")]
    pub finished: bool,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub cover_path: String,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub author_avatar_path: String,
    #[serde(default)]
    pub volumes: Vec<PkzVolume>,
    #[serde(default, deserialize_with = "crate::flex::i64")]
    pub volumes_count: i64,
    #[serde(default, deserialize_with = "crate::flex::i64")]
    pub chapter_count: i64,
    #[serde(default, deserialize_with = "crate::flex::i64")]
    pub picture_count: i64,
    #[serde(default, deserialize_with = "crate::flex::i64")]
    pub idx: i64,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub author: String,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub author_id: String,
}

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
#[serde(default)]
pub struct PkzArchive {
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub cover_path: String,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub author_avatar_path: String,
    #[serde(default)]
    pub comics: Vec<PkzComic>,
    #[serde(default, deserialize_with = "crate::flex::i64")]
    pub comic_count: i64,
    #[serde(default, deserialize_with = "crate::flex::i64")]
    pub volumes_count: i64,
    #[serde(default, deserialize_with = "crate::flex::i64")]
    pub chapter_count: i64,
    #[serde(default, deserialize_with = "crate::flex::i64")]
    pub picture_count: i64,
}
