use std::sync::Once;

#[allow(dead_code)]
pub fn setup_env() {
    static INIT: Once = Once::new();
    INIT.call_once(|| {
        std::env::set_var("RUST_LOG", "flowy_sys=trace,trace");
        env_logger::init();
    });
}

pub struct ExecutorAction {
    command: String,
}

pub struct FlowySystemExecutor {}
