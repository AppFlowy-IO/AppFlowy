use crate::entities::SubscribeObject;
use bytes::Bytes;
use lazy_static::lazy_static;
use std::{convert::TryInto, sync::RwLock};

lazy_static! {
    static ref DART_STREAM_SENDER: RwLock<DartStreamSender> = RwLock::new(DartStreamSender::new());
}

pub struct DartStreamSender {
    #[allow(dead_code)]
    isolate: Option<allo_isolate::Isolate>,
}

impl DartStreamSender {
    fn new() -> Self {
        Self { isolate: None }
    }

    fn inner_set_port(&mut self, port: i64) {
        log::info!("Setup rust to flutter stream with port {}", port);
        self.isolate = Some(allo_isolate::Isolate::new(port));
    }

    #[allow(dead_code)]
    fn inner_post(&self, observable_subject: SubscribeObject) -> Result<(), String> {
        match self.isolate {
            Some(ref isolate) => {
                let bytes: Bytes = observable_subject.try_into().unwrap();
                isolate.post(bytes.to_vec());
                Ok(())
            }
            None => Err("Isolate is not set".to_owned()),
        }
    }

    pub fn set_port(port: i64) {
        match DART_STREAM_SENDER.write() {
            Ok(mut stream) => stream.inner_set_port(port),
            Err(e) => {
                let msg = format!("Get rust to flutter stream lock fail. {:?}", e);
                log::error!("{:?}", msg);
            }
        }
    }

    pub fn post(_observable_subject: SubscribeObject) -> Result<(), String> {
        #[cfg(feature = "dart")]
        match DART_STREAM_SENDER.read() {
            Ok(stream) => stream.inner_post(_observable_subject),
            Err(e) => Err(format!("Get rust to flutter stream lock fail. {:?}", e)),
        }

        #[cfg(not(feature = "dart"))]
        Ok(())
    }
}
