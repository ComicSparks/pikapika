use serde::de::DeserializeOwned;
use serde_json::Value;

pub(crate) async fn call(method: &str, params: &str) -> Result<String, String> {
    crate::app::invoke(method, params).await
}

pub(crate) fn parse<T: DeserializeOwned>(raw: &str) -> Result<T, String> {
    crate::flex::parse_raw(raw)
}

pub(crate) fn parse_vec<T: DeserializeOwned>(raw: &str) -> Result<Vec<T>, String> {
    let trimmed = raw.trim();
    if trimmed.is_empty() || trimmed == "null" {
        return Ok(Vec::new());
    }
    parse(trimmed)
}

pub(crate) fn parse_opt<T: DeserializeOwned>(raw: &str) -> Result<Option<T>, String> {
    let trimmed = raw.trim();
    if trimmed.is_empty() || trimmed == "null" || trimmed == "nil" {
        return Ok(None);
    }
    parse(trimmed).map(Some)
}

pub(crate) fn parse_i64(raw: &str) -> Result<i64, String> {
    let trimmed = raw.trim().trim_matches('"');
    if trimmed.is_empty() || trimmed == "null" {
        return Ok(0);
    }
    trimmed
        .parse::<i64>()
        .or_else(|_| trimmed.parse::<f64>().map(|value| value as i64))
        .map_err(|e| e.to_string())
}

pub(crate) fn parse_bool(raw: &str) -> bool {
    raw.trim().trim_matches('"') == "true"
}

pub(crate) fn done(raw: Result<String, String>) -> Result<(), String> {
    raw.map(|_| ())
}

pub(crate) fn string_map(raw: &str) -> std::collections::HashMap<String, String> {
    let value: Value = serde_json::from_str(raw).unwrap_or(Value::Null);
    let mut map = std::collections::HashMap::new();
    if let Some(object) = value.as_object() {
        for (key, item) in object {
            map.insert(key.clone(), crate::flex::value_string(item));
        }
    }
    map
}
