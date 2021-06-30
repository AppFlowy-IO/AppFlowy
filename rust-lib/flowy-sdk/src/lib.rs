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
        |module_map, runtime| {
            let mut sender = Sender::<i64>::new(module_map.clone());
            runtime.spawn(SenderRunner::new(module_map, sender.take_rx()));

            SENDER.with(|cell| {
                *cell.borrow_mut() = Some(sender);
            });
        },
    )
    .run()
    .unwrap();
}

thread_local!(
    static SENDER: RefCell<Option<Sender<i64>>> = RefCell::new(None);
);

pub fn sync_send(data: SenderData<i64>) -> EventResponse {
    SENDER.with(|cell| match &*cell.borrow() {
        Some(stream) => stream.sync_send(data),
        None => panic!(""),
    })
}

pub fn async_send(data: SenderData<i64>) {
    SENDER.with(|cell| match &*cell.borrow() {
        Some(stream) => {
            stream.async_send(data);
        },
        None => panic!(""),
    });
}
