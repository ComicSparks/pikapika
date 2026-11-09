use crate::pro::dto::ProInfoAll;

use super::call::{self, call};

pub async fn pro_info_all() -> Result<ProInfoAll, String> {
    call::parse(&call("proInfoAll", "").await?)
}

pub async fn reload_pro() -> Result<(), String> {
    call::done(call("reloadPro", "").await)
}

pub async fn get_pro_server_name() -> Result<String, String> {
    call("getProServerName", "").await
}

pub async fn set_pro_server_name(server_name: String) -> Result<(), String> {
    call::done(call("setProServerName", &server_name).await)
}

pub async fn input_cd_key(cd_key: String) -> Result<(), String> {
    call::done(call("inputCdKey", &cd_key).await)
}

pub async fn set_pat_access_key(access_key: String) -> Result<(), String> {
    call::done(call("setPatAccessKey", &access_key).await)
}

pub async fn reload_pat_account() -> Result<(), String> {
    call::done(call("reloadPatAccount", "").await)
}

pub async fn bind_this_account() -> Result<(), String> {
    call::done(call("bindThisAccount", "").await)
}

pub async fn clear_pat() -> Result<(), String> {
    call::done(call("clearPat", "").await)
}
