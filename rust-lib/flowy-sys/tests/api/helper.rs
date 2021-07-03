use flowy_sys::prelude::*;
use std::{cell::RefCell, sync::Once};

#[allow(dead_code)]
pub fn setup_env() {
    static INIT: Once = Once::new();
    INIT.call_once(|| {
        std::env::set_var("RUST_LOG", "flowy_sys=debug,debug");
        env_logger::init();
    });
}

pub async fn async_send(request: DispatchRequest) -> EventResponse {
    EventDispatch::async_send(request).await
}

pub fn init_dispatch<F>(module_factory: F)
where
    F: FnOnce() -> Vec<Module>,
{
    EventDispatch::construct(module_factory);
}
