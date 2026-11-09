use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
#[serde(default)]
pub struct ProInfoAf {
    #[serde(default, deserialize_with = "crate::flex::boolean")]
    pub is_pro: bool,
    #[serde(default, deserialize_with = "crate::flex::i64")]
    pub expire: i64,
}

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
#[serde(default)]
pub struct ProInfoPat {
    #[serde(default, deserialize_with = "crate::flex::boolean")]
    pub is_pro: bool,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub pat_id: String,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub bind_uid: String,
    #[serde(default, deserialize_with = "crate::flex::i64")]
    pub request_delete: i64,
    #[serde(default, deserialize_with = "crate::flex::i64")]
    pub re_bind: i64,
    #[serde(default, deserialize_with = "crate::flex::i64")]
    pub error_type: i64,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub error_msg: String,
    #[serde(default, deserialize_with = "crate::flex::string")]
    pub access_key: String,
}

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
#[serde(default)]
pub struct ProInfoAll {
    #[serde(default)]
    pub pro_info_af: ProInfoAf,
    #[serde(default)]
    pub pro_info_pat: ProInfoPat,
}
