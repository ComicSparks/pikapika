pub mod dto;

use base64::Engine;
use rand::rngs::OsRng;
use rsa::pkcs1::DecodeRsaPrivateKey;
use rsa::pkcs8::DecodePublicKey;
use rsa::traits::PublicKeyParts;
use rsa::{Pkcs1v15Encrypt, RsaPrivateKey, RsaPublicKey};
use serde_json::{json, Value};

use crate::net::Http;

const SERVER_PUK: &str = "MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQC2KcD4z4/mjU2V8gQ9Cvpe3U4N\nmcLFOCo1fMoxiDcDWpAzSWBMV46MHZT8Y3fm3pRztjDaWQMYhhbPHhg9ySgIesIm\nXq/BLp7khcACK6nXhsKFNpove8UjHXuy71ZWY3WItf8uUTEkpW2mZUEXLlN+nPj5\nDxfXzjJK7wrYa1Za4wIDAQAB";
const CLIENT_PRK: &str = "MIICXAIBAAKBgQC4C1gberr4/5ksHtbXPczvUEPelW6pQhOIXsFC0xNuF30HgGLT\n2rxH3F6MuId8pNj1TgfQfqfVoQVhp6ShhfU4KwnI9JH/n3EWygoRGiY6VlxDOOB9\nvUwRAXs/JSa5715HJahnxxYXxASUJUkrgTnha8iS9y82V3odE76RwVe+mwIDAQAB\nAoGBAJHaI6P7Wmt0HA5UDkybpGpPQMoHwKAQRmx/M0djAXXw1Vv5idh881M7uA5r\nOqwz8+BLS3QWu6lYJ2yhr512DMNxu9z+zvbzgRr7JkikW8m9dbCua2hNl13h6cCD\n3lAvPTU8PG9PUYmOu5kwP0Kd4YJtblw6QikgwnpQyqILwptxAkEAxAVOQJPKZM0N\npJSeXgCo39nS7PPcvPHBu2bUDnKvqAIpwLDZMGlS8YYt1dcBvuqWyfeMehKdDOp9\n414ShZjFswJBAPBb5vnoJY1ouNsVQ4V3eUZdigLJYzh/CySfiJ7YLf8xEnCbK0yN\ndw4ou7EsB0KJzsPw/KrAtukJbFWrndN3/3kCQBPvWjL1FMtFk1KejrCOrp39YBcb\nAeLxTzuIzJ4fib+zYJ2pHp1uyLGpbLXnpNTOtMEbfNzZUcGDg4QBCC8wB0MCQCl6\n0ruiEoj635v/aW2pFqbMEbs1Yggn9JZXac5v5FA7+cCxJqHJcBhjczC6Nm6HNcWe\n2xvksiw5UhbezRfnh5ECQHgO5Z8aPLvHrPpINryKwvgP6Bfc2Rn9w+TTKsn1WgKJ\nQj/uwTGM9xITj2X7C6RBaHKZchiLa+G1PprEDK9BIdc=";

pub fn server_url(name: &str) -> String {
    match name {
        "" | "ORI" | "ori" => "https://ele.comicsparks.work/".into(),
        "jdtvmstd22deytdzenvydyil3e0jkxfu" => "https://jdtvmstd22deytdzenvydyil3e0jkxfu.lambda-url.ap-east-1.on.aws/".into(),
        "mek5hrs65poai2eqjjofqr7ynu0nxkqx" => "https://mek5hrs65poai2eqjjofqr7ynu0nxkqx.lambda-url.ap-east-1.on.aws/".into(),
        "6h2odtaft7fuvssx6v5b73pwie0dfgvm" => "https://6h2odtaft7fuvssx6v5b73pwie0dfgvm.lambda-url.us-west-2.on.aws/".into(),
        "ilsfsfkt75kp2nnfievnqcjmza0ooksc" => "https://ilsfsfkt75kp2nnfievnqcjmza0ooksc.lambda-url.us-west-2.on.aws/".into(),
        "wuwjgjgautzqf6ybwmma6e2pw40iilcy" => "https://wuwjgjgautzqf6ybwmma6e2pw40iilcy.lambda-url.us-west-2.on.aws/".into(),
        "phuto27lxoqo4skduakcs4siwu0ffwoh" => "https://phuto27lxoqo4skduakcs4siwu0ffwoh.lambda-url.ap-northeast-1.on.aws/".into(),
        "4sfkal33ch44fle6u6smhwufri0cmgnv" => "https://4sfkal33ch44fle6u6smhwufri0cmgnv.lambda-url.ap-northeast-1.on.aws/".into(),
        other => {
            if let Some((id, region)) = other.split_once('|') {
                if id.chars().all(|c| c.is_ascii_lowercase() || c.is_ascii_digit())
                    && region.chars().all(|c| c.is_ascii_lowercase() || c.is_ascii_digit() || c == '-')
                {
                    return format!("https://{id}.lambda-url.{region}.on.aws/");
                }
            }
            "https://ele.comicsparks.work/".into()
        }
    }
}

pub async fn register_cdkey(http: &Http, url: &str, username: &str, cd_key: &str) -> Result<i64, String> {
    let body = json!({"user": username, "cd_key": cd_key}).to_string();
    let encrypted = encrypt(body.as_bytes())?;
    let (status, bytes) = http
        .direct(
            "POST",
            url,
            &[("Content-Type", "text/plan".into())],
            Some(encrypted.into_bytes()),
        )
        .await?;
    if status != 200 {
        return Err("not success".into());
    }
    let plain = decrypt(&bytes)?;
    let result: Value = serde_json::from_slice(&plain).map_err(|e| e.to_string())?;
    if result["username"].as_str().unwrap_or("") != username {
        return Err("username not match".into());
    }
    let timestamp = result["timestamp"].as_i64().unwrap_or(0);
    if chrono::Utc::now().timestamp() + 3600 * 24 * 2 < timestamp {
        return Err("timestamp not match".into());
    }
    Ok(result["expire"].as_i64().unwrap_or(0))
}

pub async fn pat_check(http: &Http, key: &str) -> Result<Value, String> {
    let body = json!({"access_key": key}).to_string();
    let encrypted = encrypt(body.as_bytes())?;
    let (status, bytes) = http
        .direct(
            "POST",
            "https://pat.comicsparks.work/bind_state",
            &[("Content-Type", "text/plan".into())],
            Some(encrypted.into_bytes()),
        )
        .await?;
    if status != 200 {
        return Err(String::from_utf8_lossy(&bytes).to_string());
    }
    let plain = decrypt(&bytes)?;
    serde_json::from_slice(&plain).map_err(|e| e.to_string())
}

pub async fn pat_bind(http: &Http, key: &str, user: &str) -> Result<(), String> {
    let body = json!({"access_key": key, "user": user}).to_string();
    let encrypted = encrypt(body.as_bytes())?;
    let (status, bytes) = http
        .direct(
            "POST",
            "https://pat.comicsparks.work/bind_user",
            &[("Content-Type", "text/plan".into())],
            Some(encrypted.into_bytes()),
        )
        .await?;
    if status != 200 {
        return Err(String::from_utf8_lossy(&bytes).to_string());
    }
    Ok(())
}

fn keys() -> Result<(RsaPublicKey, RsaPrivateKey), String> {
    let public_der = base64::engine::general_purpose::STANDARD
        .decode(SERVER_PUK.replace('\n', ""))
        .map_err(|e| e.to_string())?;
    let private_der = base64::engine::general_purpose::STANDARD
        .decode(CLIENT_PRK.replace('\n', ""))
        .map_err(|e| e.to_string())?;
    let public = RsaPublicKey::from_public_key_der(&public_der).map_err(|e| e.to_string())?;
    let private = RsaPrivateKey::from_pkcs1_der(&private_der).map_err(|e| e.to_string())?;
    Ok((public, private))
}

fn encrypt(data: &[u8]) -> Result<String, String> {
    let (public, _) = keys()?;
    let limit = public.size() - 11;
    let mut out = Vec::new();
    let mut rng = OsRng;
    for chunk in data.chunks(limit) {
        let part = public
            .encrypt(&mut rng, Pkcs1v15Encrypt, chunk)
            .map_err(|e| e.to_string())?;
        out.extend(part);
    }
    Ok(base64::engine::general_purpose::STANDARD.encode(out))
}

fn decrypt(data: &[u8]) -> Result<Vec<u8>, String> {
    let text = String::from_utf8_lossy(data);
    let raw = base64::engine::general_purpose::STANDARD
        .decode(text.trim())
        .map_err(|e| e.to_string())?;
    let (_, private) = keys()?;
    let limit = private.size();
    let mut out = Vec::new();
    for chunk in raw.chunks(limit) {
        let part = private.decrypt(Pkcs1v15Encrypt, chunk).map_err(|e| e.to_string())?;
        out.extend(part);
    }
    Ok(out)
}
