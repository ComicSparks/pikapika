use std::fs::{self, File};
use std::io::{Read, Write};
use std::net::TcpListener;
use std::path::{Path, PathBuf};
use std::sync::Mutex;

use flate2::write::DeflateEncoder;
use flate2::Compression;
use serde_json::{json, Value};
use zip::write::SimpleFileOptions;
use zip::{CompressionMethod, ZipArchive, ZipWriter};

use crate::app::App;
use crate::db::store;
use crate::events;

pub struct SocketExport {
    pub listener: Option<TcpListener>,
}

impl SocketExport {
    pub fn new() -> Self {
        Self { listener: None }
    }
}

pub fn require_pro(app: &App) -> Result<(), String> {
    if app.is_pro()? {
        Ok(())
    } else {
        Err("\n发电之后才能使用鸭\n".into())
    }
}

pub fn export_zip(app: &App, comic_id: &str, dir: &str, name: &str) -> Result<String, String> {
    require_pro(app)?;
    let file = target_file(app, comic_id, dir, name, "zip")?;
    let mut zip = ZipWriter::new(File::create(&file).map_err(|e| e.to_string())?);
    write_bundle(app, comic_id, &mut zip)?;
    zip.finish().map_err(|e| e.to_string())?;
    Ok(file.to_string_lossy().to_string())
}

pub fn export_pki(app: &App, comic_id: &str, dir: &str, name: &str) -> Result<String, String> {
    require_pro(app)?;
    let file = target_file(app, comic_id, dir, name, "pki")?;
    let bundle = bundle_files(app, comic_id)?;
    write_pki(&file, &bundle)?;
    Ok(file.to_string_lossy().to_string())
}

pub fn export_jpg(app: &App, comic_id: &str, dir: &str, name: &str) -> Result<(), String> {
    let folder = target_dir(app, comic_id, dir, name)?;
    fs::create_dir_all(&folder).map_err(|e| e.to_string())?;
    for (rel, bytes) in bundle_files(app, comic_id)? {
        if rel == "data.js" {
            continue;
        }
        let path = folder.join(&rel);
        if let Some(parent) = path.parent() {
            fs::create_dir_all(parent).map_err(|e| e.to_string())?;
        }
        fs::write(path, bytes).map_err(|e| e.to_string())?;
        events::emit_export(&format!("导出 {rel}"));
    }
    Ok(())
}

pub fn export_jpeg_zip(app: &App, comic_id: &str, dir: &str, name: &str) -> Result<String, String> {
    require_pro(app)?;
    let file = target_file(app, comic_id, dir, name, "zip")?;
    let mut zip = ZipWriter::new(File::create(&file).map_err(|e| e.to_string())?);
    let opts = SimpleFileOptions::default().compression_method(CompressionMethod::Deflated);
    for (rel, bytes) in bundle_files(app, comic_id)? {
        if rel == "data.js" || rel == "logo" {
            continue;
        }
        let jpeg = to_jpeg(&bytes)?;
        zip.start_file(format!("{rel}.jpg"), opts).map_err(|e| e.to_string())?;
        zip.write_all(&jpeg).map_err(|e| e.to_string())?;
    }
    zip.finish().map_err(|e| e.to_string())?;
    Ok(file.to_string_lossy().to_string())
}

pub fn export_pdf(app: &App, comic_id: &str, dir: &str, name: &str, per_folder: bool) -> Result<(), String> {
    require_pro(app)?;
    let files = bundle_files(app, comic_id)?;
    if per_folder {
        let folder = target_dir(app, comic_id, dir, name)?;
        fs::create_dir_all(&folder).map_err(|e| e.to_string())?;
        let mut chapter = Vec::new();
        let mut current = String::new();
        for (rel, bytes) in files {
            if !rel.starts_with("pictures/") {
                continue;
            }
            let group = rel.split('_').next().unwrap_or("ep").to_string();
            if !current.is_empty() && group != current {
                fs::write(folder.join(format!("{current}.pdf")), images_pdf(&chapter)?).map_err(|e| e.to_string())?;
                chapter.clear();
            }
            current = group;
            chapter.push(to_jpeg(&bytes)?);
        }
        if !chapter.is_empty() {
            fs::write(folder.join(format!("{current}.pdf")), images_pdf(&chapter)?).map_err(|e| e.to_string())?;
        }
    } else {
        let file = target_file(app, comic_id, dir, name, "pdf")?;
        let jpegs = files
            .into_iter()
            .filter(|(rel, _)| rel.starts_with("pictures/"))
            .map(|(_, bytes)| to_jpeg(&bytes))
            .collect::<Result<Vec<_>, _>>()?;
        fs::write(file, images_pdf(&jpegs)?).map_err(|e| e.to_string())?;
    }
    Ok(())
}

pub fn export_epub(app: &App, comic_id: &str, dir: &str, name: &str) -> Result<(), String> {
    require_pro(app)?;
    let file = target_file(app, comic_id, dir, name, "epub")?;
    let mut zip = ZipWriter::new(File::create(&file).map_err(|e| e.to_string())?);
    let stored = SimpleFileOptions::default().compression_method(CompressionMethod::Stored);
    let deflated = SimpleFileOptions::default().compression_method(CompressionMethod::Deflated);
    zip.start_file("mimetype", stored).map_err(|e| e.to_string())?;
    zip.write_all(b"application/epub+zip").map_err(|e| e.to_string())?;
    zip.start_file("META-INF/container.xml", deflated).map_err(|e| e.to_string())?;
    zip.write_all(br#"<?xml version="1.0"?><container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container"><rootfiles><rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/></rootfiles></container>"#)
        .map_err(|e| e.to_string())?;
    let files = bundle_files(app, comic_id)?;
    let mut manifest = String::new();
    let mut spine = String::new();
    let mut index = 0;
    for (rel, bytes) in &files {
        if !rel.starts_with("pictures/") {
            continue;
        }
        index += 1;
        let image = format!("images/{index}.jpg");
        let page = format!("page{index}.xhtml");
        zip.start_file(format!("OEBPS/{image}"), deflated).map_err(|e| e.to_string())?;
        zip.write_all(&to_jpeg(bytes)?).map_err(|e| e.to_string())?;
        let xhtml = format!(r#"<?xml version="1.0"?><html xmlns="http://www.w3.org/1999/xhtml"><body><img src="{image}" alt=""/></body></html>"#);
        zip.start_file(format!("OEBPS/{page}"), deflated).map_err(|e| e.to_string())?;
        zip.write_all(xhtml.as_bytes()).map_err(|e| e.to_string())?;
        manifest.push_str(&format!(r#"<item id="i{index}" href="{image}" media-type="image/jpeg"/><item id="p{index}" href="{page}" media-type="application/xhtml+xml"/>"#));
        spine.push_str(&format!(r#"<itemref idref="p{index}"/>"#));
    }
    let opf = format!(r#"<?xml version="1.0"?><package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="id"><metadata xmlns:dc="http://purl.org/dc/elements/1.1/"><dc:title>{comic_id}</dc:title><dc:language>zh</dc:language><dc:identifier id="id">{comic_id}</dc:identifier></metadata><manifest>{manifest}</manifest><spine>{spine}</spine></package>"#);
    zip.start_file("OEBPS/content.opf", deflated).map_err(|e| e.to_string())?;
    zip.write_all(opf.as_bytes()).map_err(|e| e.to_string())?;
    zip.finish().map_err(|e| e.to_string())?;
    Ok(())
}

pub fn export_cbz(app: &App, comic_id: &str, dir: &str, name: &str) -> Result<String, String> {
    require_pro(app)?;
    let file = target_file(app, comic_id, dir, name, "zip")?;
    let mut zip = ZipWriter::new(File::create(&file).map_err(|e| e.to_string())?);
    let opts = SimpleFileOptions::default().compression_method(CompressionMethod::Deflated);
    let comic = {
        let conn = app.db.comic.lock().map_err(|e| e.to_string())?;
        store::find_download(&conn, comic_id)?.ok_or("not found")?
    };
    let eps = {
        let conn = app.db.comic.lock().map_err(|e| e.to_string())?;
        store::list_eps(&conn, comic_id)?
    };
    let mut meta_eps = Vec::new();
    for ep in eps {
        let ep_id = ep["id"].as_str().unwrap_or("");
        let pictures = {
            let conn = app.db.comic.lock().map_err(|e| e.to_string())?;
            store::list_pictures(&conn, ep_id)?
        };
        let cbz_name = format!("{:04}.cbz", ep["epOrder"].as_i64().unwrap_or(0));
        let mut inner = ZipWriter::new(std::io::Cursor::new(Vec::new()));
        for picture in &pictures {
            let local = picture["localPath"].as_str().unwrap_or("");
            if local.is_empty() {
                continue;
            }
            let bytes = fs::read(app.paths.download_file(local)).unwrap_or_default();
            let name = format!("{:04}.jpg", picture["rankInEp"].as_i64().unwrap_or(0));
            inner.start_file(&name, opts).map_err(|e| e.to_string())?;
            inner.write_all(&bytes).map_err(|e| e.to_string())?;
        }
        let cbz = inner.finish().map_err(|e| e.to_string())?.into_inner();
        zip.start_file(&cbz_name, opts).map_err(|e| e.to_string())?;
        zip.write_all(&cbz).map_err(|e| e.to_string())?;
        meta_eps.push(json!({"ep": ep, "cbzName": cbz_name}));
    }
    let meta = json!({"comic": comic, "epList": meta_eps});
    zip.start_file("data.js", opts).map_err(|e| e.to_string())?;
    zip.write_all(format!("data = {meta}").as_bytes()).map_err(|e| e.to_string())?;
    zip.finish().map_err(|e| e.to_string())?;
    Ok(file.to_string_lossy().to_string())
}

pub fn import_zip(app: &App, path: &str, pki: bool) -> Result<(), String> {
    let file = File::open(path).map_err(|e| e.to_string())?;
    let mut archive = ZipArchive::new(file).map_err(|e| e.to_string())?;
    let mut data = String::new();
    let mut files = Vec::new();
    for i in 0..archive.len() {
        let mut entry = archive.by_index(i).map_err(|e| e.to_string())?;
        let name = entry.name().to_string();
        let mut bytes = Vec::new();
        entry.read_to_end(&mut bytes).map_err(|e| e.to_string())?;
        if pki {
            for byte in &mut bytes {
                *byte ^= 170;
            }
        }
        if name == "data.js" {
            data = String::from_utf8_lossy(&bytes).trim_start_matches("data = ").to_string();
        } else {
            files.push((name, bytes));
        }
    }
    let value: Value = serde_json::from_str(&data).map_err(|e| e.to_string())?;
    let comic = value.clone();
    let id = comic["id"].as_str().unwrap_or("").to_string();
    if id.is_empty() {
        return Err("压缩包里没有漫画数据".into());
    }
    let eps = comic["epList"].as_array().cloned().unwrap_or_default();
    {
        let conn = app.db.comic.lock().map_err(|e| e.to_string())?;
        if store::find_download(&conn, &id)?.is_none() {
            let ep_rows: Vec<Value> = eps.iter().map(|ep| ep.clone()).collect();
            store::create_download(&conn, &comic, &ep_rows)?;
        }
    }
    for ep in &eps {
        let pictures = ep["pictureList"].as_array().cloned().unwrap_or_default();
        for picture in pictures {
            let src = picture["srcPath"].as_str().unwrap_or("");
            let local = picture["localPath"].as_str().unwrap_or("");
            if let Some((_, bytes)) = files.iter().find(|(name, _)| name == src) {
                if !local.is_empty() {
                    let real = app.paths.download_file(local);
                    if let Some(parent) = real.parent() {
                        fs::create_dir_all(parent).map_err(|e| e.to_string())?;
                    }
                    fs::write(real, bytes).map_err(|e| e.to_string())?;
                }
            }
        }
    }
    events::emit_export("导入完成");
    Ok(())
}

pub fn listen_socket(slot: &Mutex<SocketExport>, comic_id: String, app: std::sync::Arc<App>) -> Result<u16, String> {
    let listener = TcpListener::bind("0.0.0.0:0").map_err(|e| e.to_string())?;
    listener.set_nonblocking(false).ok();
    let port = listener.local_addr().map_err(|e| e.to_string())?.port();
    {
        let mut guard = slot.lock().map_err(|e| e.to_string())?;
        guard.listener = Some(listener.try_clone().map_err(|e| e.to_string())?);
    }
    std::thread::spawn(move || {
        if let Ok(listener) = slot_listener(&app) {
            if let Ok((mut stream, _)) = listener.accept() {
                if let Ok(path) = export_zip(&app, &comic_id, &std::env::temp_dir().to_string_lossy(), "") {
                    if let Ok(bytes) = fs::read(path) {
                        let _ = stream.write_all(&bytes);
                    }
                }
            }
        }
    });
    Ok(port)
}

fn slot_listener(app: &App) -> Result<TcpListener, String> {
    let guard = app.socket.lock().map_err(|e| e.to_string())?;
    guard.listener.as_ref().and_then(|l| l.try_clone().ok()).ok_or("没有监听".into())
}

pub fn close_socket(slot: &Mutex<SocketExport>) {
    if let Ok(mut guard) = slot.lock() {
        guard.listener = None;
    }
}

pub fn import_socket(app: &App, addr: &str) -> Result<(), String> {
    use std::net::TcpStream;
    let mut stream = TcpStream::connect(addr).map_err(|e| e.to_string())?;
    let mut bytes = Vec::new();
    stream.read_to_end(&mut bytes).map_err(|e| e.to_string())?;
    let path = app.paths.tmp.join("socket-import.zip");
    fs::write(&path, bytes).map_err(|e| e.to_string())?;
    import_zip(app, &path.to_string_lossy(), false)
}

fn write_bundle<W: Write + std::io::Seek>(app: &App, comic_id: &str, zip: &mut ZipWriter<W>) -> Result<(), String> {
    let opts = SimpleFileOptions::default().compression_method(CompressionMethod::Deflated);
    for (rel, bytes) in bundle_files(app, comic_id)? {
        events::emit_export(&format!("正在导出 {rel}"));
        zip.start_file(rel, opts).map_err(|e| e.to_string())?;
        zip.write_all(&bytes).map_err(|e| e.to_string())?;
    }
    Ok(())
}

fn bundle_files(app: &App, comic_id: &str) -> Result<Vec<(String, Vec<u8>)>, String> {
    let comic = {
        let conn = app.db.comic.lock().map_err(|e| e.to_string())?;
        store::find_download(&conn, comic_id)?.ok_or("not found")?
    };
    if !comic["downloadFinished"].as_bool().unwrap_or(false) {
        return Err("not download finish".into());
    }
    let eps = {
        let conn = app.db.comic.lock().map_err(|e| e.to_string())?;
        store::list_eps(&conn, comic_id)?
    };
    let mut files = Vec::new();
    let mut json_eps = Vec::new();
    for ep in eps {
        let ep_id = ep["id"].as_str().unwrap_or("");
        let pictures = {
            let conn = app.db.comic.lock().map_err(|e| e.to_string())?;
            store::list_pictures(&conn, ep_id)?
        };
        let mut json_pictures = Vec::new();
        for picture in pictures {
            let src = format!(
                "pictures/{:04}_{:04}",
                ep["epOrder"].as_i64().unwrap_or(0),
                picture["rankInEp"].as_i64().unwrap_or(0)
            );
            let local = picture["localPath"].as_str().unwrap_or("");
            let bytes = fs::read(app.paths.download_file(local)).unwrap_or_default();
            files.push((src.clone(), bytes));
            let mut picture = picture;
            if let Value::Object(map) = &mut picture {
                map.insert("srcPath".into(), Value::String(src));
            }
            json_pictures.push(picture);
        }
        let mut ep = ep;
        if let Value::Object(map) = &mut ep {
            map.insert("pictureList".into(), Value::Array(json_pictures));
        }
        json_eps.push(ep);
    }
    if let Some(logo) = comic["thumbLocalPath"].as_str() {
        if !logo.is_empty() {
            if let Ok(bytes) = fs::read(app.paths.download_file(logo)) {
                files.push(("logo".into(), bytes));
            }
        }
    }
    let mut payload = comic;
    if let Value::Object(map) = &mut payload {
        map.insert("epList".into(), Value::Array(json_eps));
    }
    files.push(("data.js".into(), format!("data = {payload}").into_bytes()));
    Ok(files)
}

fn write_pki(path: &Path, files: &[(String, Vec<u8>)]) -> Result<(), String> {
    let mut out = File::create(path).map_err(|e| e.to_string())?;
    let mut locals = Vec::new();
    let mut offset = 0u32;
    for (name, bytes) in files {
        let mut xored = bytes.clone();
        for byte in &mut xored {
            *byte ^= 170;
        }
        let mut encoder = DeflateEncoder::new(Vec::new(), Compression::default());
        encoder.write_all(&xored).map_err(|e| e.to_string())?;
        let data = encoder.finish().map_err(|e| e.to_string())?;
        let name_bytes = name.as_bytes();
        let crc = crc32(&xored);
        let local = local_header(name_bytes, &data, crc, xored.len() as u32);
        out.write_all(&local).map_err(|e| e.to_string())?;
        locals.push((name_bytes.to_vec(), crc, data.len() as u32, xored.len() as u32, offset));
        offset += local.len() as u32;
    }
    let central_start = offset;
    for (name, crc, comp, raw, local_off) in &locals {
        let central = central_header(name, *crc, *comp, *raw, *local_off);
        out.write_all(&central).map_err(|e| e.to_string())?;
        offset += central.len() as u32;
    }
    let central_size = offset - central_start;
    out.write_all(&end_of_central(locals.len() as u16, central_size, central_start))
        .map_err(|e| e.to_string())?;
    Ok(())
}

fn local_header(name: &[u8], data: &[u8], crc: u32, raw: u32) -> Vec<u8> {
    let mut buf = Vec::new();
    buf.extend_from_slice(&0x04034b50u32.to_le_bytes());
    buf.extend_from_slice(&20u16.to_le_bytes());
    buf.extend_from_slice(&0u16.to_le_bytes());
    buf.extend_from_slice(&0x7575u16.to_le_bytes());
    buf.extend_from_slice(&0u16.to_le_bytes());
    buf.extend_from_slice(&0u16.to_le_bytes());
    buf.extend_from_slice(&crc.to_le_bytes());
    buf.extend_from_slice(&(data.len() as u32).to_le_bytes());
    buf.extend_from_slice(&raw.to_le_bytes());
    buf.extend_from_slice(&(name.len() as u16).to_le_bytes());
    buf.extend_from_slice(&0u16.to_le_bytes());
    buf.extend_from_slice(name);
    buf.extend_from_slice(data);
    buf
}

fn central_header(name: &[u8], crc: u32, comp: u32, raw: u32, offset: u32) -> Vec<u8> {
    let mut buf = Vec::new();
    buf.extend_from_slice(&0x02014b50u32.to_le_bytes());
    buf.extend_from_slice(&20u16.to_le_bytes());
    buf.extend_from_slice(&20u16.to_le_bytes());
    buf.extend_from_slice(&0u16.to_le_bytes());
    buf.extend_from_slice(&0x7575u16.to_le_bytes());
    buf.extend_from_slice(&0u16.to_le_bytes());
    buf.extend_from_slice(&0u16.to_le_bytes());
    buf.extend_from_slice(&crc.to_le_bytes());
    buf.extend_from_slice(&comp.to_le_bytes());
    buf.extend_from_slice(&raw.to_le_bytes());
    buf.extend_from_slice(&(name.len() as u16).to_le_bytes());
    buf.extend_from_slice(&0u16.to_le_bytes());
    buf.extend_from_slice(&0u16.to_le_bytes());
    buf.extend_from_slice(&0u16.to_le_bytes());
    buf.extend_from_slice(&0u16.to_le_bytes());
    buf.extend_from_slice(&0u32.to_le_bytes());
    buf.extend_from_slice(&offset.to_le_bytes());
    buf.extend_from_slice(name);
    buf
}

fn end_of_central(count: u16, size: u32, offset: u32) -> Vec<u8> {
    let mut buf = Vec::new();
    buf.extend_from_slice(&0x06054b50u32.to_le_bytes());
    buf.extend_from_slice(&0u16.to_le_bytes());
    buf.extend_from_slice(&0u16.to_le_bytes());
    buf.extend_from_slice(&count.to_le_bytes());
    buf.extend_from_slice(&count.to_le_bytes());
    buf.extend_from_slice(&size.to_le_bytes());
    buf.extend_from_slice(&offset.to_le_bytes());
    buf.extend_from_slice(&0u16.to_le_bytes());
    buf
}

fn crc32(data: &[u8]) -> u32 {
    let mut crc = 0xffffffffu32;
    for byte in data {
        crc ^= *byte as u32;
        for _ in 0..8 {
            let mask = (crc & 1).wrapping_neg();
            crc = (crc >> 1) ^ (0xedb88320 & mask);
        }
    }
    !crc
}

fn to_jpeg(bytes: &[u8]) -> Result<Vec<u8>, String> {
    if image::guess_format(bytes).ok() == Some(image::ImageFormat::Jpeg) {
        return Ok(bytes.to_vec());
    }
    let img = image::load_from_memory(bytes).map_err(|e| e.to_string())?;
    let mut out = Vec::new();
    let mut cursor = std::io::Cursor::new(&mut out);
    img.write_to(&mut cursor, image::ImageFormat::Jpeg).map_err(|e| e.to_string())?;
    Ok(out)
}

fn images_pdf(jpegs: &[Vec<u8>]) -> Result<Vec<u8>, String> {
    if jpegs.is_empty() {
        return Err("没有图片".into());
    }
    let mut objects: Vec<Vec<u8>> = Vec::new();
    objects.push(b"<< /Type /Catalog /Pages 2 0 R >>".to_vec());
    let mut kids = String::new();
    for index in 0..jpegs.len() {
        kids.push_str(&format!("{} 0 R ", index * 2 + 3));
    }
    objects.push(format!("<< /Type /Pages /Count {} /Kids [{}] >>", jpegs.len(), kids).into_bytes());
    for (index, jpeg) in jpegs.iter().enumerate() {
        let img_id = index * 2 + 4;
        objects.push(format!("<< /Type /Page /Parent 2 0 R /MediaBox [0 0 600 800] /Resources << /XObject << /Im {img_id} 0 R >> >> /Contents {} 0 R >>", index * 2 + 5).into_bytes());
        let mut image = format!("<< /Type /XObject /Subtype /Image /Width 600 /Height 800 /ColorSpace /DeviceRGB /BitsPerComponent 8 /Filter /DCTDecode /Length {} >>\nstream\n", jpeg.len()).into_bytes();
        image.extend_from_slice(jpeg);
        image.extend_from_slice(b"\nendstream");
        objects.push(image);
        objects.push(b"<< /Length 45 >>\nstream\nq 600 0 0 800 0 0 cm /Im Do Q\nendstream".to_vec());
    }
    let mut out = b"%PDF-1.4\n".to_vec();
    let mut offsets = vec![0];
    for (index, object) in objects.iter().enumerate() {
        offsets.push(out.len());
        out.extend_from_slice(format!("{} 0 obj\n", index + 1).as_bytes());
        out.extend_from_slice(object);
        out.extend_from_slice(b"\nendobj\n");
    }
    let xref = out.len();
    out.extend_from_slice(format!("xref\n0 {}\n", objects.len() + 1).as_bytes());
    out.extend_from_slice(b"0000000000 65535 f \n");
    for offset in offsets.iter().skip(1) {
        out.extend_from_slice(format!("{offset:010} 00000 n \n").as_bytes());
    }
    out.extend_from_slice(format!("trailer << /Size {} /Root 1 0 R >>\nstartxref\n{xref}\n%%EOF", objects.len() + 1).as_bytes());
    Ok(out)
}

fn target_file(app: &App, comic_id: &str, dir: &str, name: &str, ext: &str) -> Result<PathBuf, String> {
    let comic = {
        let conn = app.db.comic.lock().map_err(|e| e.to_string())?;
        store::find_download(&conn, comic_id)?.ok_or("not found")?
    };
    let title = safe_name(comic["title"].as_str().unwrap_or(comic_id));
    let file_name = if name.trim().is_empty() {
        format!("{title}-{}.{ext}", chrono::Utc::now().format("%Y_%m_%d_%H_%M_%S"))
    } else if name.ends_with(&format!(".{ext}")) {
        safe_name(name)
    } else {
        format!("{}.{ext}", safe_name(name))
    };
    let dir = if dir.is_empty() { app.paths.download.clone() } else { PathBuf::from(dir) };
    fs::create_dir_all(&dir).map_err(|e| e.to_string())?;
    let path = dir.join(file_name);
    if path.exists() {
        return Err("exists".into());
    }
    Ok(path)
}

fn target_dir(app: &App, comic_id: &str, dir: &str, name: &str) -> Result<PathBuf, String> {
    let comic = {
        let conn = app.db.comic.lock().map_err(|e| e.to_string())?;
        store::find_download(&conn, comic_id)?.ok_or("not found")?
    };
    let title = if name.trim().is_empty() {
        safe_name(comic["title"].as_str().unwrap_or(comic_id))
    } else {
        safe_name(name)
    };
    let dir = if dir.is_empty() { app.paths.download.clone() } else { PathBuf::from(dir) };
    Ok(dir.join(title))
}

fn safe_name(name: &str) -> String {
    name.chars()
        .map(|c| if "\\/:*?\"<>|".contains(c) { '_' } else { c })
        .collect::<String>()
        .trim()
        .to_string()
}
