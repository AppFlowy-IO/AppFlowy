mod c;

use crate::c::forget_rust;
use flowy_sdk::*;
use flowy_sys::prelude::*;
use std::{cell::RefCell, ffi::CStr, future::Future, os::raw::c_char};

#[no_mangle]
pub extern "C" fn init_sdk(path: *mut c_char) -> i64 {
    let c_str: &CStr = unsafe { CStr::from_ptr(path) };
    let path: &str = c_str.to_str().unwrap();
    FlowySDK::init_log();
    FlowySDK::init(path);
    return 1;
}

#[derive(serde::Deserialize)]
pub struct FFICommand {
    event: String,
    payload: Vec<u8>,
}

impl FFICommand {
    pub fn from_bytes(bytes: Vec<u8>) -> Self {
        let command: FFICommand = serde_json::from_slice(&bytes).unwrap();
        command
    }

    pub fn from_u8_pointer(pointer: *const u8, len: usize) -> Self {
        let bytes = unsafe { std::slice::from_raw_parts(pointer, len) }.to_vec();
        FFICommand::from_bytes(bytes)
    }
}

#[no_mangle]
pub extern "C" fn async_command(port: i64, input: *const u8, len: usize) {
    let FFICommand { event, payload } = FFICommand::from_u8_pointer(input, len);
    log::info!("Event: {:?}", event);

    let mut request = DispatchRequest::new(port, event).callback(|_, resp| {
        log::info!("async resp: {:?}", resp);
    });

    if !payload.is_empty() {
        request = request.payload(Payload::Bytes(payload));
    }

    async_send(request);
    spawn_future(async { vec![] }, 123);
}

#[no_mangle]
pub extern "C" fn sync_command(input: *const u8, len: usize) -> *const u8 { unimplemented!() }

#[inline(never)]
#[no_mangle]
pub extern "C" fn link_me_please() {}

#[inline(always)]
fn spawn_future<F>(future: F, port: i64)
where
    F: Future<Output = Vec<u8>> + Send + 'static,
{
    let isolate = allo_isolate::Isolate::new(port);
    isolate.catch_unwind(future);

    // if let Err(e) = isolate.catch_unwind(future) {
    //     if let Some(msg) = e.downcast_ref::<&str>() {
    //         log::error!("🔥 {:?}", msg);
    //     } else {
    //         log::error!("no info provided for that panic 😡");
    //     }
    // }
}
