use flowy_sys::prelude::*;
use std::{cell::RefCell, ffi::CStr, os::raw::c_char};

#[no_mangle]
pub extern "C" fn init_sdk(path: *mut c_char) -> i64 {
    let c_str: &CStr = unsafe { CStr::from_ptr(path) };
    let path: &str = c_str.to_str().unwrap();
    println!("{}", path);
    return 1;
}

#[no_mangle]
pub extern "C" fn async_command(port: i64, input: *const u8, len: usize) {
    let bytes = unsafe { std::slice::from_raw_parts(input, len) }.to_vec();
    let request = EventRequest::from_data(bytes);

    let stream_data = StreamData::new(port, Some(request)).with_callback(Box::new(|_config, response| {
        log::info!("async resp: {:?}", response);
    }));

    async_send(stream_data);
}

#[inline(never)]
#[no_mangle]
pub extern "C" fn link_me_please() {}

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
