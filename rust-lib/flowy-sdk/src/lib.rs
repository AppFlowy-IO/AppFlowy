pub mod module;
pub use module::*;

use flowy_sys::prelude::*;
use module::build_modules;
use std::cell::RefCell;
pub struct FlowySDK {}

impl FlowySDK {
    pub fn init(path: &str) {
        flowy_log::init_log("flowy", "Debug").unwrap();

        log::info!("🔥🔥🔥 System start running");
        match init_system(build_modules()).run() {
            Ok(_) => {},
            Err(e) => log::error!("System run fail with error: {:?}", e),
        }
    }
}

pub fn init_system(modules: Vec<Module>) -> SystemRunner {
    FlowySystem::construct(
        || modules,
        |module_map, runtime| {
            let mut sender = Sender::<i64>::new(module_map.clone());
            runtime.spawn(SenderRunner::new(module_map, sender.take_rx()));

            SENDER.with(|cell| {
                *cell.borrow_mut() = Some(sender);
            });
        },
    )
}

thread_local!(
    static SENDER: RefCell<Option<Sender<i64>>> = RefCell::new(None);
);

pub fn sync_send(data: SenderRequest<i64>) -> EventResponse {
    SENDER.with(|cell| match &*cell.borrow() {
        Some(stream) => stream.sync_send(data),
        None => panic!(""),
    })
}

pub fn async_send(data: SenderRequest<i64>) {
    SENDER.with(|cell| match &*cell.borrow() {
        Some(stream) => {
            stream.async_send(data);
        },
        None => panic!(""),
    });
}
