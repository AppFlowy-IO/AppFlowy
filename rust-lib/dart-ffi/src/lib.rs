mod c;

use crate::c::forget_rust;
use flowy_sdk::*;
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

    let stream_data = CommandData::new(port, Some(request)).with_callback(Box::new(|_config, response| {
        log::info!("async resp: {:?}", response);
    }));

    async_send(stream_data);
}

#[no_mangle]
pub extern "C" fn sync_command(input: *const u8, len: usize) -> *const u8 {
    let bytes = unsafe { std::slice::from_raw_parts(input, len) }.to_vec();
    forget_rust(bytes)
}

#[inline(never)]
#[no_mangle]
pub extern "C" fn link_me_please() {}
