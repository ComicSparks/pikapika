use serde::Deserialize;
use serde::de::{DeserializeOwned, Deserializer};
use serde_json::Value;

pub fn strip_nulls(value: Value) -> Value {
    match value {
        Value::Object(map) => {
            let mut out = serde_json::Map::new();
            for (key, item) in map {
                if !item.is_null() {
                    out.insert(key, strip_nulls(item));
                }
            }
            Value::Object(out)
        }
        Value::Array(items) => Value::Array(
            items
                .into_iter()
                .filter(|item| !item.is_null())
                .map(strip_nulls)
                .collect(),
        ),
        other => other,
    }
}

/// 接口有时同一字段同时给主名和别名，例如 `_id` 和 `id`。
/// serde 的 alias 遇到两个键会报 duplicate field，这里在两个键都存在时只留一个。
/// 只有 `id` 或只有 `createdAt` 的本地数据保持原样。
fn collapse_aliases(value: Value) -> Value {
    match value {
        Value::Object(map) => {
            let mut out = serde_json::Map::new();
            for (key, item) in map {
                out.insert(key, collapse_aliases(item));
            }
            prefer(&mut out, "_id", "id");
            prefer(&mut out, "created_at", "createdAt");
            prefer(&mut out, "updated_at", "updatedAt");
            Value::Object(out)
        }
        Value::Array(items) => Value::Array(items.into_iter().map(collapse_aliases).collect()),
        other => other,
    }
}

fn prefer(map: &mut serde_json::Map<String, Value>, primary: &str, alias: &str) {
    if !map.contains_key(primary) || !map.contains_key(alias) {
        return;
    }
    let primary_empty = match map.get(primary) {
        None | Some(Value::Null) => true,
        Some(Value::String(text)) if text.is_empty() => true,
        _ => false,
    };
    if primary_empty {
        if let Some(alias_value) = map.remove(alias) {
            map.insert(primary.to_string(), alias_value);
        }
    } else {
        map.remove(alias);
    }
}

pub fn parse_raw<T: DeserializeOwned>(raw: &str) -> Result<T, String> {
    let value: Value = serde_json::from_str(raw).map_err(|e| e.to_string())?;
    let value = collapse_aliases(strip_nulls(value));
    serde_json::from_value(value).map_err(|e| {
        let preview: String = raw.chars().take(400).collect();
        let message = format!("{e}; payload={preview}");
        eprintln!("parse failed: {message}");
        message
    })
}

pub fn value_string(value: &Value) -> String {
    match value {
        Value::String(text) => text.clone(),
        Value::Number(number) => number.to_string(),
        Value::Bool(flag) => flag.to_string(),
        _ => String::new(),
    }
}

pub fn string<'de, D: Deserializer<'de>>(deserializer: D) -> Result<String, D::Error> {
    let value = Value::deserialize(deserializer)?;
    Ok(value_string(&value))
}

pub fn i64<'de, D: Deserializer<'de>>(deserializer: D) -> Result<i64, D::Error> {
    let value = Value::deserialize(deserializer)?;
    Ok(match value {
        Value::Number(number) => number
            .as_i64()
            .or_else(|| number.as_u64().map(|n| n as i64))
            .or_else(|| number.as_f64().map(|n| n as i64))
            .unwrap_or(0),
        Value::String(text) => text.parse::<i64>().unwrap_or_else(|_| text.parse::<f64>().map(|n| n as i64).unwrap_or(0)),
        Value::Bool(flag) => i64::from(flag),
        _ => 0,
    })
}

pub fn f64<'de, D: Deserializer<'de>>(deserializer: D) -> Result<f64, D::Error> {
    let value = Value::deserialize(deserializer)?;
    Ok(match value {
        Value::Number(number) => number.as_f64().or_else(|| number.as_i64().map(|n| n as f64)).unwrap_or(0.0),
        Value::String(text) => text.parse::<f64>().unwrap_or(0.0),
        Value::Bool(flag) => {
            if flag {
                1.0
            } else {
                0.0
            }
        }
        _ => 0.0,
    })
}

pub fn boolean<'de, D: Deserializer<'de>>(deserializer: D) -> Result<bool, D::Error> {
    let value = Value::deserialize(deserializer)?;
    Ok(match value {
        Value::Bool(flag) => flag,
        Value::Number(number) => number.as_i64().unwrap_or(0) != 0,
        Value::String(text) => text == "true" || text == "1",
        _ => false,
    })
}

pub fn string_vec<'de, D: Deserializer<'de>>(deserializer: D) -> Result<Vec<String>, D::Error> {
    let value = Value::deserialize(deserializer)?;
    Ok(match value {
        Value::Array(items) => items.iter().map(value_string).collect(),
        Value::String(text) => serde_json::from_str::<Vec<Value>>(&text)
            .map(|items| items.iter().map(value_string).collect())
            .unwrap_or_else(|_| {
                if text.is_empty() {
                    Vec::new()
                } else {
                    vec![text]
                }
            }),
        _ => Vec::new(),
    })
}

pub fn opt_string<'de, D: Deserializer<'de>>(deserializer: D) -> Result<Option<String>, D::Error> {
    let value = Option::<Value>::deserialize(deserializer)?;
    Ok(match value {
        None | Some(Value::Null) => None,
        Some(other) => {
            let text = value_string(&other);
            if text.is_empty() {
                None
            } else {
                Some(text)
            }
        }
    })
}
