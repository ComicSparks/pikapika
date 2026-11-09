use std::sync::OnceLock;

use tokio::sync::broadcast;

use crate::db::dto::DownloadComic;

#[derive(Clone, Debug)]
pub enum AppEvent {
    Download { comic: DownloadComic },
    Export { message: String },
}

fn bus() -> &'static broadcast::Sender<AppEvent> {
    static BUS: OnceLock<broadcast::Sender<AppEvent>> = OnceLock::new();
    BUS.get_or_init(|| broadcast::channel(256).0)
}

pub fn subscribe() -> broadcast::Receiver<AppEvent> {
    bus().subscribe()
}

pub fn emit_export(content: &str) {
    let _ = bus().send(AppEvent::Export {
        message: content.to_string(),
    });
}

pub fn emit_download(content: &str) {
    if let Ok(comic) = crate::flex::parse_raw::<DownloadComic>(content) {
        let _ = bus().send(AppEvent::Download { comic });
    }
}
