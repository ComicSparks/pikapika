use crate::app;
use crate::events::AppEvent;
use crate::frb_generated::StreamSink;

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    flutter_rust_bridge::setup_default_user_utils();
}

pub async fn init_application(data_dir: String) -> Result<(), String> {
    app::init(&data_dir).await.map(|_| ())
}

pub fn application_dir() -> Result<String, String> {
    app::data_dir()
}

pub async fn events(sink: StreamSink<AppEvent>) {
    let mut receiver = crate::events::subscribe();
    loop {
        match receiver.recv().await {
            Ok(message) => {
                if sink.add(message).is_err() {
                    break;
                }
            }
            Err(tokio::sync::broadcast::error::RecvError::Lagged(_)) => continue,
            Err(tokio::sync::broadcast::error::RecvError::Closed) => break,
        }
    }
}
