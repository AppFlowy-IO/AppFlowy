use crate::{
    module::Module,
    request::EventRequest,
    response::EventResponse,
    rt::SystemCommand,
    stream::*,
    system::FlowySystem,
};
use futures_core::ready;
use lazy_static::lazy_static;
use protobuf::Message;
use std::{
    cell::RefCell,
    future::Future,
    sync::{Arc, RwLock},
    task::Context,
};
use tokio::{
    macros::support::{Pin, Poll},
    sync::{mpsc::UnboundedSender, oneshot},
};

#[no_mangle]
pub extern "C" fn async_command(port: i64, input: *const u8, len: usize) {
    let bytes = unsafe { std::slice::from_raw_parts(input, len) }.to_vec();
    let request = EventRequest::from_data(bytes);

    let stream_data = StreamData::new(port, Some(request), Box::new(|port, response| {}));
    send(stream_data);
}

#[no_mangle]
pub extern "C" fn free_rust(ptr: *mut u8, length: u32) { reclaim_rust(ptr, length) }

#[no_mangle]
pub extern "C" fn init_stream(port: i64) -> i32 { return 0; }

#[allow(unused_attributes)]
pub fn reclaim_rust(ptr: *mut u8, length: u32) {
    unsafe {
        let len: usize = length as usize;
        Vec::from_raw_parts(ptr, len, len);
    }
}

thread_local!(
    static STREAM_SENDER: RefCell<Option<UnboundedSender<StreamData<i64>>>> = RefCell::new(None);
);

pub fn send(data: StreamData<i64>) {
    STREAM_SENDER.with(|cell| match &*cell.borrow() {
        Some(tx) => {
            tx.send(data);
        },
        None => panic!(""),
    });
}

pub fn init_dart<F>(modules: Vec<Module>, f: F)
where
    F: FnOnce() + 'static,
{
    let mut stream = CommandStream::<i64>::new();
    let stream = CommandStream::<i64>::new();
    let tx = stream.tx();

    STREAM_SENDER.with(|cell| {
        *cell.borrow_mut() = Some(tx);
    });

    FlowySystem::construct(|| modules, stream)
        .spawn(async { f() })
        .run()
        .unwrap();

    // FlowySystem::construct(|| modules, stream)
    //     .spawn(async move {
    //         let request = EventRequest::new("1".to_string());
    //         let stream_data = StreamData::new(
    //             1,
    //             Some(request),
    //             Box::new(|config, response| {
    //                 log::info!("😁{:?}", response);
    //             }),
    //         );
    //
    //         send(stream_data);
    //
    //         FlowySystem::current().stop();
    //     })
    //     .run()
    //     .unwrap();
}
