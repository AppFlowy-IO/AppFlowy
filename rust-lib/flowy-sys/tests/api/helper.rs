use flowy_sys::prelude::{EventResponse, FlowySystem, Module, Sender, SenderRequest, SenderRunner};
use std::{cell::RefCell, sync::Once};

#[allow(dead_code)]
pub fn setup_env() {
    static INIT: Once = Once::new();
    INIT.call_once(|| {
        std::env::set_var("RUST_LOG", "flowy_sys=debug,debug");
        env_logger::init();
    });
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

pub fn init_system<F>(modules: Vec<Module>, f: F)
where
    F: FnOnce() + 'static,
{
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
    .spawn(async { f() })
    .run()
    .unwrap();
}

pub fn stop_system() { FlowySystem::current().stop(); }
