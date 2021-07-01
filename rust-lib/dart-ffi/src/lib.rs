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

pub struct FFICommand {
    event: String,
    payload: Vec<u8>,
}

impl FFICommand {
    pub fn from_bytes(bytes: Vec<u8>) -> Self { unimplemented!() }

    pub fn from_u8_pointer(pointer: *const u8, len: usize) -> Self {
        let bytes = unsafe { std::slice::from_raw_parts(pointer, len) }.to_vec();
        unimplemented!()
    }
}

#[no_mangle]
pub extern "C" fn async_command(port: i64, input: *const u8, len: usize) {
    let FFICommand { event, payload } = FFICommand::from_u8_pointer(input, len);

    let mut request = SenderRequest::new(port, event).callback(|_, resp| {
        log::info!("async resp: {:?}", resp);
    });

    if !payload.is_empty() {
        request = request.payload(Payload::Bytes(payload));
    }

    async_send(request);
}

#[no_mangle]
pub extern "C" fn sync_command(input: *const u8, len: usize) -> *const u8 { unimplemented!() }

#[inline(never)]
#[no_mangle]
pub extern "C" fn link_me_please() {}
