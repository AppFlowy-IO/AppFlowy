use flowy_sdk::module::build_modules;
pub use flowy_sdk::*;
use flowy_sys::prelude::*;
use std::{
    fmt::{Debug, Display},
    hash::Hash,
    sync::Once,
};

static INIT: Once = Once::new();
#[allow(dead_code)]

pub fn init_system() {
    INIT.call_once(|| {
        FlowySDK::init_log();
    });

    FlowySDK::init("123");
}

pub struct FlowySDKTester {
    request: DispatchRequest<i64>,
}

impl FlowySDKTester {
    pub fn new<E>(event: E) -> Self
    where
        E: Eq + Hash + Debug + Clone + Display,
    {
        Self {
            request: DispatchRequest::new(1, event),
        }
    }

    #[allow(dead_code)]
    pub fn bytes_payload<T>(mut self, payload: T) -> Self
    where
        T: serde::Serialize,
    {
        let bytes: Vec<u8> = bincode::serialize(&payload).unwrap();
        self.request = self.request.payload(Payload::Bytes(bytes));
        self
    }

    #[allow(dead_code)]
    pub fn protobuf_payload<T>(mut self, payload: T) -> Self
    where
        T: ::protobuf::Message,
    {
        let bytes: Vec<u8> = payload.write_to_bytes().unwrap();
        self.request = self.request.payload(Payload::Bytes(bytes));
        self
    }

    pub async fn async_send(self) -> EventResponse {
        init_system();
        let resp = async_send(self.request).await.unwrap();
        dbg!(&resp);
        resp
    }

    pub fn sync_send(self) -> EventResponse {
        init_system();
        let resp = sync_send(self.request).unwrap();
        dbg!(&resp);
        resp
    }
}
