pub mod dto;

use std::time::{SystemTime, UNIX_EPOCH};

use hmac::{Hmac, Mac};
use percent_encoding::{utf8_percent_encode, AsciiSet, NON_ALPHANUMERIC};
use serde_json::{json, Value};
use sha2::Sha256;

use crate::net::Http;

const SERVER: &str = "https://picaapi.picacomic.com/";
const API_KEY: &str = "C69BAF41DA5ABD1FFEDC6D2FEA56B";
const NONCE: &str = "b1ab87b4800d4d4590a11701b8551afa";
const SECRET: &str = r#"~d}$Q7$eIni=V)9\RK/P.RM4;9[7|@/CA}b~OW!3?EV`:<>M7pddUBL5n|0/*Cn"#;
const QUERY: &AsciiSet = &NON_ALPHANUMERIC.remove(b'-').remove(b'_').remove(b'.');

type HmacSha256 = Hmac<Sha256>;

#[derive(Clone, Default)]
pub struct Pica {
    pub token: String,
}

impl Pica {
    pub async fn get(&self, http: &Http, path: &str) -> Result<Value, String> {
        self.request(http, "GET", path, None, None).await
    }

    pub async fn get_quality(&self, http: &Http, path: &str, quality: &str) -> Result<Value, String> {
        self.request(http, "GET", path, None, Some(quality)).await
    }

    pub async fn post(&self, http: &Http, path: &str, body: Option<Value>) -> Result<Value, String> {
        self.request(http, "POST", path, body, None).await
    }

    pub async fn put(&self, http: &Http, path: &str, body: Option<Value>) -> Result<Value, String> {
        self.request(http, "PUT", path, body, None).await
    }

    async fn request(
        &self,
        http: &Http,
        method: &str,
        path: &str,
        body: Option<Value>,
        quality: Option<&str>,
    ) -> Result<Value, String> {
        let url = format!("{SERVER}{path}");
        let time = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .map_err(|e| e.to_string())?
            .as_secs()
            .to_string();
        let sign_path = path.trim_start_matches('/');
        let raw = format!("{sign_path}{time}{NONCE}{method}{API_KEY}").to_ascii_lowercase();
        let mut mac = HmacSha256::new_from_slice(SECRET.as_bytes()).map_err(|e| e.to_string())?;
        mac.update(raw.as_bytes());
        let signature = hex::encode(mac.finalize().into_bytes());
        let payload = body.map(|v| v.to_string().into_bytes());
        let mut headers = vec![
            ("api-key", API_KEY.to_string()),
            ("accept", "application/vnd.picacomic.com.v1+json".into()),
            ("app-channel", "2".into()),
            ("time", time),
            ("nonce", NONCE.into()),
            ("signature", signature),
            ("app-version", "2.2.1.2.3.3".into()),
            ("app-uuid", "defaultUuid".into()),
            ("app-platform", "android".into()),
            ("app-build-version", "44".into()),
            ("Content-Type", "application/json; charset=UTF-8".into()),
            ("User-Agent", "okhttp/3.8.1".into()),
            ("authorization", self.token.clone()),
            ("image-quality", quality.unwrap_or("original").to_string()),
        ];
        let _ = &mut headers;
        let (status, bytes) = http.api(method, &url, &headers, payload).await?;
        if status == 0 {
            return Err("空响应".into());
        }
        let value: Value = serde_json::from_slice(&bytes).map_err(|e| {
            format!("{e}: {}", String::from_utf8_lossy(&bytes).chars().take(180).collect::<String>())
        })?;
        let code = value.get("code").cloned().unwrap_or(json!(200));
        let ok = code.as_i64() == Some(200) || code.as_str() == Some("200");
        if !ok {
            let message = value
                .get("message")
                .and_then(|v| v.as_str())
                .unwrap_or("接口错误");
            return Err(message.to_string());
        }
        Ok(value)
    }

    pub async fn login(&mut self, http: &Http, username: &str, password: &str) -> Result<(), String> {
        let value = self
            .post(http, "auth/sign-in", Some(json!({"email": username, "password": password})))
            .await?;
        self.token = value["data"]["token"].as_str().unwrap_or("").to_string();
        if self.token.is_empty() {
            return Err("登录没有返回 token".into());
        }
        Ok(())
    }

    pub async fn register(&self, http: &Http, body: Value) -> Result<(), String> {
        self.post(http, "auth/register", Some(body)).await?;
        Ok(())
    }
}

pub fn q(value: &str) -> String {
    utf8_percent_encode(value, QUERY).to_string()
}

pub fn at(value: &Value, path: &[&str]) -> Value {
    let mut cur = value;
    for key in path {
        cur = match cur.get(*key) {
            Some(next) => next,
            None => return Value::Null,
        };
    }
    cur.clone()
}

pub fn string_of(value: &Value) -> String {
    match value {
        Value::String(s) => s.clone(),
        Value::Null => String::new(),
        other => other.to_string(),
    }
}
