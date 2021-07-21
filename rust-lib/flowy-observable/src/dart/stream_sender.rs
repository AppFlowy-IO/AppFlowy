use crate::entities::ObservableSubject;
use lazy_static::lazy_static;
use std::{convert::TryInto, sync::RwLock};

lazy_static! {
    static ref R2F_STREAM_SENDER: RwLock<RustStreamSender> = RwLock::new(RustStreamSender::new());
}

pub struct RustStreamSender {
    isolate: Option<allo_isolate::Isolate>,
}

impl RustStreamSender {
    fn new() -> Self { Self { isolate: None } }

    fn inner_set_port(&mut self, port: i64) {
        log::debug!("Setup rust to flutter stream with port {}", port);
        self.isolate = Some(allo_isolate::Isolate::new(port));
    }

    fn inner_post(&self, observable_subject: ObservableSubject) -> Result<(), String> {
        match self.isolate {
            Some(ref isolate) => {
                let bytes: Vec<u8> = observable_subject.try_into().unwrap();
                isolate.post(bytes);
                Ok(())
            },
            None => Err("Isolate is not set".to_owned()),
        }
    }

    pub fn set_port(port: i64) {
        match R2F_STREAM_SENDER.write() {
            Ok(mut stream) => stream.inner_set_port(port),
            Err(e) => {
                let msg = format!("Get rust to flutter stream lock fail. {:?}", e);
                log::error!("{:?}", msg);
            },
        }
    }

    pub fn post(observable_subject: ObservableSubject) -> Result<(), String> {
        #[cfg(feature = "dart")]
        match R2F_STREAM_SENDER.read() {
            Ok(stream) => stream.inner_post(observable_subject),
            Err(e) => Err(format!("Get rust to flutter stream lock fail. {:?}", e)),
        }

        #[cfg(not(feature = "dart"))]
        Ok(())
    }
}
