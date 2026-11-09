use chrono::{DateTime, NaiveDateTime, Utc};
use rusqlite::Row;

pub fn gs(row: &Row, name: &str) -> String {
    row.get::<_, Option<String>>(name)
        .ok()
        .flatten()
        .unwrap_or_default()
}

pub fn gi(row: &Row, name: &str) -> i64 {
    if let Ok(Some(v)) = row.get::<_, Option<i64>>(name) {
        return v;
    }
    if let Ok(Some(v)) = row.get::<_, Option<f64>>(name) {
        return v as i64;
    }
    if let Ok(Some(v)) = row.get::<_, Option<String>>(name) {
        return v.parse().unwrap_or(0);
    }
    0
}

pub fn gb(row: &Row, name: &str) -> bool {
    if let Ok(Some(v)) = row.get::<_, Option<i64>>(name) {
        return v != 0;
    }
    matches!(gs(row, name).to_ascii_lowercase().as_str(), "1" | "true" | "t")
}

pub fn now_sqlite() -> String {
    Utc::now().format("%Y-%m-%d %H:%M:%S%.f").to_string()
}

pub fn now_rfc3339() -> String {
    Utc::now().to_rfc3339_opts(chrono::SecondsFormat::Millis, true)
}

pub fn now_millis() -> i64 {
    Utc::now().timestamp_millis()
}

pub fn now_secs() -> i64 {
    Utc::now().timestamp()
}

pub fn to_rfc3339(raw: &str) -> String {
    let raw = raw.trim();
    if raw.is_empty() {
        return "0001-01-01T00:00:00Z".to_string();
    }
    if let Ok(dt) = DateTime::parse_from_rfc3339(raw) {
        return dt.to_rfc3339_opts(chrono::SecondsFormat::Millis, true);
    }
    let formats = [
        "%Y-%m-%d %H:%M:%S%.f",
        "%Y-%m-%d %H:%M:%S",
        "%Y-%m-%dT%H:%M:%S%.f",
        "%Y-%m-%dT%H:%M:%S",
    ];
    for fmt in formats {
        if let Ok(dt) = NaiveDateTime::parse_from_str(raw, fmt) {
            return DateTime::<Utc>::from_naive_utc_and_offset(dt, Utc)
                .to_rfc3339_opts(chrono::SecondsFormat::Millis, true);
        }
    }
    raw.to_string()
}

pub fn bool_i(v: bool) -> i64 {
    if v { 1 } else { 0 }
}
