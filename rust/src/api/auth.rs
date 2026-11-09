use serde_json::json;

use crate::pica::dto::{ForgotPasswordResult, ResetPasswordResult, UserProfile};

use super::call::{self, call};

pub async fn load_property(name: String, default_value: String) -> Result<String, String> {
    call("loadProperty", &json!({"name": name, "defaultValue": default_value}).to_string()).await
}

pub async fn save_property(name: String, value: String) -> Result<(), String> {
    call::done(call("saveProperty", &json!({"name": name, "value": value}).to_string()).await)
}

pub async fn get_switch_address() -> Result<String, String> {
    call("getSwitchAddress", "").await
}

pub async fn set_switch_address(switch_address: String) -> Result<(), String> {
    call::done(call("setSwitchAddress", switch_address.trim()).await)
}

pub async fn get_image_switch_address() -> Result<String, String> {
    call("getImageSwitchAddress", "").await
}

pub async fn set_image_switch_address(switch_address: String) -> Result<(), String> {
    call::done(call("setImageSwitchAddress", switch_address.trim()).await)
}

pub async fn get_use_api_client_load_image() -> Result<String, String> {
    call("getUseApiClientLoadImage", "").await
}

pub async fn set_use_api_client_load_image(value: String) -> Result<(), String> {
    call::done(call("setUseApiClientLoadImage", value.trim()).await)
}

pub async fn get_proxy() -> Result<String, String> {
    call("getProxy", "").await
}

pub async fn set_proxy(proxy: String) -> Result<(), String> {
    call::done(call("setProxy", proxy.trim()).await)
}

pub async fn get_username() -> Result<String, String> {
    call("getUsername", "").await
}

pub async fn set_username(username: String) -> Result<(), String> {
    call::done(call("setUsername", &username).await)
}

pub async fn get_password() -> Result<String, String> {
    call("getPassword", "").await
}

pub async fn set_password(password: String) -> Result<(), String> {
    call::done(call("setPassword", &password).await)
}

pub async fn pre_login() -> Result<bool, String> {
    Ok(call::parse_bool(&call("preLogin", "").await?))
}

pub async fn login() -> Result<(), String> {
    call::done(call("login", "").await)
}

pub async fn register(
    email: String,
    name: String,
    password: String,
    gender: String,
    birthday: String,
    question1: String,
    answer1: String,
    question2: String,
    answer2: String,
    question3: String,
    answer3: String,
) -> Result<(), String> {
    call::done(
        call(
            "register",
            &json!({
                "email": email,
                "name": name,
                "password": password,
                "gender": gender,
                "birthday": birthday,
                "question1": question1,
                "answer1": answer1,
                "question2": question2,
                "answer2": answer2,
                "question3": question3,
                "answer3": answer3,
            })
            .to_string(),
        )
        .await,
    )
}

pub async fn clear_token() -> Result<(), String> {
    call::done(call("clearToken", "").await)
}

pub async fn user_profile() -> Result<UserProfile, String> {
    call::parse(&call("userProfile", "").await?)
}

pub async fn punch_in() -> Result<(), String> {
    call::done(call("punchIn", "").await)
}

pub async fn update_slogan(slogan: String) -> Result<(), String> {
    call::done(call("updateSlogan", &slogan).await)
}

pub async fn update_avatar(path: String) -> Result<(), String> {
    call::done(call("updateAvatar", &path).await)
}

pub async fn update_password(old_password: String, new_password: String) -> Result<(), String> {
    call::done(
        call(
            "updatePassword",
            &json!({"oldPassword": old_password, "newPassword": new_password}).to_string(),
        )
        .await,
    )
}

pub async fn forgot_password(email: String) -> Result<ForgotPasswordResult, String> {
    call::parse(&call("forgotPassword", &email).await?)
}

pub async fn reset_password(email: String, question_no: i64, answer: String) -> Result<ResetPasswordResult, String> {
    call::parse(
        &call(
            "resetPassword",
            &json!({"email": email, "questionNo": question_no, "answer": answer}).to_string(),
        )
        .await?,
    )
}
