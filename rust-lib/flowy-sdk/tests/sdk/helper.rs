use flowy_sdk::module::build_modules;
pub use flowy_sdk::*;
use flowy_sys::prelude::*;
use std::{
    fmt::{Debug, Display},
    hash::Hash,
    sync::Once,
};

static INIT: Once = Once::new();
pub fn run_test_system<F>(f: F)
where
    F: FnOnce() + 'static,
{
    INIT.call_once(|| {
        flowy_log::init_log("flowy", "Debug").unwrap();
    });

    let mut runner = init_system(build_modules());
    runner = runner.spawn(async {
        f();
        FlowySystem::current().stop();
    });

    log::info!("🔥🔥🔥 System start running");
    match runner.run() {
        Ok(_) => {},
        Err(e) => log::error!("System run fail with error: {:?}", e),
    }
}

pub struct FlowySDKTester {
    request: SenderRequest<i64>,
    callback: Option<BoxStreamCallback<i64>>,
}

impl FlowySDKTester {
    pub fn new<E>(event: E) -> Self
    where
        E: Eq + Hash + Debug + Clone + Display,
    {
        Self {
            request: SenderRequest::new(1, event),
            callback: None,
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
    pub fn callback<F>(mut self, callback: F) -> Self
    where
        F: FnOnce(i64, EventResponse) + 'static + Send + Sync,
    {
        self.request = self.request.callback(|config, response| {
            dbg!(&response);
            callback(config, response);
        });
        self
    }

    pub fn run(self) {
        run_test_system(move || {
            async_send(self.request);
        });
    }
}
