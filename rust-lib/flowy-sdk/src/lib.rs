pub mod module;
pub use module::*;

use flowy_sys::prelude::*;
use module::build_modules;
pub struct FlowySDK {}

impl FlowySDK {
    pub fn init_log() { flowy_log::init_log("flowy", "Debug").unwrap(); }

    pub fn init(path: &str) {
        log::info!("🔥 System start running");
        log::debug!("🔥 Root path: {}", path);
        EventDispatch::construct(|| build_modules());
    }
}

pub async fn async_send(data: DispatchRequest<i64>) -> Result<EventResponse, SystemError> {
    EventDispatch::async_send(data).await
}

pub fn sync_send(data: DispatchRequest<i64>) -> Result<EventResponse, SystemError> {
    EventDispatch::sync_send(data)
}
