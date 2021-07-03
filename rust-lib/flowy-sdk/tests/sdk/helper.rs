use flowy_sdk::module::build_modules;
pub use flowy_sdk::*;
use flowy_sys::prelude::*;
use std::{
    fmt::{Debug, Display},
    fs,
    hash::Hash,
    sync::Once,
};

static INIT: Once = Once::new();
pub fn init_sdk() {
    let root_dir = root_dir();

    INIT.call_once(|| {
        FlowySDK::init_log(&root_dir);
    });
    FlowySDK::init(&root_dir);
}

fn root_dir() -> String {
    let mut path = fs::canonicalize(".").unwrap();
    path.push("tests/temp/flowy/");
    let path_str = path.to_str().unwrap().to_string();
    if !std::path::Path::new(&path).exists() {
        std::fs::create_dir_all(path).unwrap();
    }
    path_str
}

pub struct EventTester {
    request: DispatchRequest,
}

impl EventTester {
    pub fn new<E>(event: E, payload: Payload) -> Self
    where
        E: Eq + Hash + Debug + Clone + Display,
    {
        init_sdk();
        Self {
            request: DispatchRequest::new(event, payload),
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

    #[allow(dead_code)]
    pub async fn async_send(self) -> EventResponse {
        let resp = async_send(self.request).await;
        dbg!(&resp);
        resp
    }

    #[allow(dead_code)]
    pub fn sync_send(self) -> EventResponse {
        let resp = sync_send(self.request);
        dbg!(&resp);
        resp
    }
}
