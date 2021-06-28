use flowy_sys::prelude::{CommandStream, CommandStreamFuture, EventResponse, FlowySystem, Module, StreamData};
use std::{
    cell::RefCell,
    sync::{Once, RwLock},
    task::Context,
};

#[allow(dead_code)]
pub fn setup_env() {
    static INIT: Once = Once::new();
    INIT.call_once(|| {
        std::env::set_var("RUST_LOG", "flowy_sys=debug,debug");
        env_logger::init();
    });
}

pub struct ExecutorAction {
    command: String,
}

pub struct FlowySystemExecutor {}

thread_local!(
    static STREAM_SENDER: RefCell<Option<CommandStream<i64>>> = RefCell::new(None);
);

pub fn sync_send(data: StreamData<i64>) -> EventResponse {
    STREAM_SENDER.with(|cell| match &*cell.borrow() {
        Some(stream) => stream.sync_send(data),
        None => panic!(""),
    })
}

pub fn async_send(data: StreamData<i64>) {
    STREAM_SENDER.with(|cell| match &*cell.borrow() {
        Some(stream) => {
            stream.async_send(data);
        },
        None => panic!(""),
    });
}

pub fn stop_system() { FlowySystem::current().stop(); }

pub fn init_system<F>(modules: Vec<Module>, f: F)
where
    F: FnOnce() + 'static,
{
    FlowySystem::construct(
        || modules,
        |module_map| {
            let mut stream = CommandStream::<i64>::new(module_map.clone());
            let stream_fut = CommandStreamFuture::new(module_map, stream.take_data_rx());

            STREAM_SENDER.with(|cell| {
                *cell.borrow_mut() = Some(stream);
            });

            stream_fut
        },
    )
    .spawn(async { f() })
    .run()
    .unwrap();
}
