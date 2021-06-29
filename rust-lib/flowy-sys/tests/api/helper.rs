use flowy_sys::prelude::{CommandData, CommandSender, CommandSenderRunner, EventResponse, FlowySystem, Module};
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
    static CMD_SENDER: RefCell<Option<CommandSender<i64>>> = RefCell::new(None);
);

pub fn sync_send(data: CommandData<i64>) -> EventResponse {
    CMD_SENDER.with(|cell| match &*cell.borrow() {
        Some(stream) => stream.sync_send(data),
        None => panic!(""),
    })
}

pub fn async_send(data: CommandData<i64>) {
    CMD_SENDER.with(|cell| match &*cell.borrow() {
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
        |module_map| {
            let mut stream = CommandSender::<i64>::new(module_map.clone());
            let runner = CommandSenderRunner::new(module_map, stream.take_data_rx());

            CMD_SENDER.with(|cell| {
                *cell.borrow_mut() = Some(stream);
            });

            runner
        },
    )
    .spawn(async { f() })
    .run()
    .unwrap();
}

pub fn stop_system() { FlowySystem::current().stop(); }
