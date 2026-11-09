pub mod dto;

use std::fs::File;
use std::io::{Read, Write};

use base64::Engine;
use serde_json::Value;
use zip::write::SimpleFileOptions;
use zip::{CompressionMethod, ZipArchive, ZipWriter};

const KEY: u8 = 170;

pub fn read_archive(path: &str) -> Result<Value, String> {
    let bytes = read_entry(path, "PKZ-INFO")?;
    serde_json::from_slice(&bytes).map_err(|e| e.to_string())
}

pub fn read_file(path: &str, inner: &str) -> Result<String, String> {
    let bytes = read_entry(path, inner)?;
    Ok(base64::engine::general_purpose::STANDARD.encode(bytes))
}

pub fn read_entry(path: &str, inner: &str) -> Result<Vec<u8>, String> {
    let file = File::open(path).map_err(|e| e.to_string())?;
    let mut archive = ZipArchive::new(file).map_err(|e| e.to_string())?;
    let mut entry = archive.by_name(inner).map_err(|e| e.to_string())?;
    let mut bytes = Vec::new();
    entry.read_to_end(&mut bytes).map_err(|e| e.to_string())?;
    for byte in &mut bytes {
        *byte ^= KEY;
    }
    Ok(bytes)
}

pub fn write_download_pkz(path: &str, title: &str, author: &str, pages: &[(String, Vec<u8>)]) -> Result<(), String> {
    let file = File::create(path).map_err(|e| e.to_string())?;
    let mut zip = ZipWriter::new(file);
    let opts = SimpleFileOptions::default().compression_method(CompressionMethod::Deflated);
    let mut pictures = Vec::new();
    for (index, (_, bytes)) in pages.iter().enumerate() {
        let name = uuid::Uuid::new_v4().to_string();
        let mut stored = bytes.clone();
        for byte in &mut stored {
            *byte ^= KEY;
        }
        zip.start_file(&name, opts).map_err(|e| e.to_string())?;
        zip.write_all(&stored).map_err(|e| e.to_string())?;
        pictures.push(serde_json::json!({
            "id": name,
            "title": format!("{index}"),
            "width": 0,
            "height": 0,
            "format": "jpeg",
            "picture_path": name,
            "idx": index,
        }));
    }
    let count = pictures.len();
    let chapter = serde_json::json!({
        "id": "chapter",
        "title": "1",
        "updated_at": 0,
        "created_at": 0,
        "cover_path": "",
        "picture_count": count,
        "idx": 0,
        "pictures": pictures,
    });
    let volume = serde_json::json!({
        "id": "volume",
        "title": "1",
        "updated_at": 0,
        "created_at": 0,
        "cover_path": "",
        "chapter_count": 1,
        "picture_count": count,
        "idx": 0,
        "chapters": [chapter],
    });
    let comic = serde_json::json!({
        "id": "comic",
        "title": title,
        "categories": [],
        "tags": [],
        "author_id": "",
        "author": author,
        "updated_at": 0,
        "created_at": 0,
        "description": "",
        "chinese_team": "",
        "finished": true,
        "cover_path": "",
        "author_avatar_path": "",
        "volumes_count": 1,
        "chapter_count": 1,
        "picture_count": count,
        "idx": 0,
        "volumes": [volume],
    });
    let archive = serde_json::json!({
        "name": title,
        "author": author,
        "description": "",
        "cover_path": "",
        "author_avatar_path": "",
        "comic_count": 1,
        "volumes_count": 1,
        "chapter_count": 1,
        "picture_count": count,
        "comics": [comic],
    });
    let mut info = archive.to_string().into_bytes();
    for byte in &mut info {
        *byte ^= KEY;
    }
    zip.start_file("PKZ-INFO", opts).map_err(|e| e.to_string())?;
    zip.write_all(&info).map_err(|e| e.to_string())?;
    zip.finish().map_err(|e| e.to_string())?;
    Ok(())
}
