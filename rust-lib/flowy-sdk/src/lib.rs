use flowy_sys::prelude::*;
use std::cell::RefCell;

pub struct FlowySDK {}

impl FlowySDK {
    pub fn init(path: &str) {
        let modules = init_modules();
        init_system(modules);
    }
}

pub fn init_modules() -> Vec<Module> {
    let modules = vec![];
    modules
}

pub fn init_system<F>(modules: Vec<Module>) {
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
    .run()
    .unwrap();
}

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
