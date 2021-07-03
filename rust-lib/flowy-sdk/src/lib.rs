pub mod module;
pub use module::*;

use flowy_sys::prelude::*;
use module::build_modules;
pub struct FlowySDK {}

impl FlowySDK {
    pub fn init_log(directory: &str) { flowy_log::init_log("flowy", directory, "Debug").unwrap(); }

    pub fn init(path: &str) {
        log::info!("🔥 Start running");
        tracing::info!("🔥 Root path: {}", path);
        EventDispatch::construct(|| build_modules());
    }
}

pub async fn async_send(request: DispatchRequest) -> EventResponse {
    EventDispatch::async_send(request).await
}

pub fn sync_send(request: DispatchRequest) -> EventResponse { EventDispatch::sync_send(request) }
