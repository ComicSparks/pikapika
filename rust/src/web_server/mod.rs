use std::convert::Infallible;
use std::fs;
use std::net::SocketAddr;
use std::sync::atomic::{AtomicBool, Ordering};

use bytes::Bytes;
use http_body_util::Full;
use hyper::body::Incoming;
use hyper::service::service_fn;
use hyper::{Request, Response};
use hyper_util::rt::TokioIo;
use serde_json::Value;
use tokio::net::TcpListener;

use crate::app::App;
use crate::db::store;

static RUNNING: AtomicBool = AtomicBool::new(false);

pub async fn start(app: std::sync::Arc<App>) -> Result<(), String> {
    if RUNNING.swap(true, Ordering::SeqCst) {
        return Err("网页服务已经在运行".into());
    }
    let listener = TcpListener::bind("0.0.0.0:8080").await.map_err(|e| {
        RUNNING.store(false, Ordering::SeqCst);
        e.to_string()
    })?;
    tokio::spawn(async move {
        loop {
            if !RUNNING.load(Ordering::SeqCst) {
                break;
            }
            let Ok((stream, _)) = listener.accept().await else {
                break;
            };
            let app = app.clone();
            tokio::spawn(async move {
                let service = service_fn(move |req| handle(app.clone(), req));
                let _ = hyper::server::conn::http1::Builder::new()
                    .serve_connection(TokioIo::new(stream), service)
                    .await;
            });
        }
    });
    Ok(())
}

pub fn stop() {
    RUNNING.store(false, Ordering::SeqCst);
}

async fn handle(app: std::sync::Arc<App>, req: Request<Incoming>) -> Result<Response<Full<Bytes>>, Infallible> {
    let path = req.uri().path().to_string();
    let body = if path == "/allDownloads.json" {
        let conn = app.db.comic.lock().ok();
        let value = conn
            .and_then(|conn| store::all_downloads(&conn, "", "").ok())
            .unwrap_or(Value::Array(vec![]));
        json_response(value.to_string())
    } else if let Some(rest) = path.strip_prefix("/downloadResource/") {
        let bytes = fs::read(app.paths.download_file(rest)).unwrap_or_default();
        Response::new(Full::new(Bytes::from(bytes)))
    } else if path == "/" || path == "/index.html" {
        text_response(include_str!("../../assets/web/index.html"), "text/html; charset=utf-8")
    } else if path == "/app.js" {
        text_response(include_str!("../../assets/web/app.js"), "application/javascript")
    } else if path == "/bookshelf.js" {
        text_response(include_str!("../../assets/web/bookshelf.js"), "application/javascript")
    } else if path == "/comic.js" {
        text_response(include_str!("../../assets/web/comic.js"), "application/javascript")
    } else if path == "/reader.js" {
        text_response(include_str!("../../assets/web/reader.js"), "application/javascript")
    } else if path == "/axios.min.js" {
        text_response(include_str!("../../assets/web/axios.min.js"), "application/javascript")
    } else {
        let mut missing = Response::new(Full::new(Bytes::from_static(b"not found")));
        *missing.status_mut() = hyper::StatusCode::NOT_FOUND;
        missing
    };
    let _ = SocketAddr::from(([0, 0, 0, 0], 8080));
    Ok(body)
}

fn text_response(body: &str, content_type: &str) -> Response<Full<Bytes>> {
    let mut response = Response::new(Full::new(Bytes::from(body.to_string())));
    response.headers_mut().insert(
        hyper::header::CONTENT_TYPE,
        content_type.parse().unwrap_or(hyper::header::HeaderValue::from_static("text/plain")),
    );
    response
}

fn json_response(body: String) -> Response<Full<Bytes>> {
    text_response(&body, "application/json")
}
