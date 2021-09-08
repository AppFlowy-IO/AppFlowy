use bytes::Bytes;

pub mod dart;
pub mod entities;
mod protobuf;

use crate::{dart::RustStreamSender, entities::ObservableSubject};
use flowy_dispatch::prelude::ToBytes;

pub struct ObservableBuilder {
    id: String,
    payload: Option<Bytes>,
    error: Option<Bytes>,
    source: String,
    ty: i32,
}

impl ObservableBuilder {
    pub fn new<T: Into<i32>>(id: &str, ty: T, source: &str) -> Self {
        Self {
            id: id.to_owned(),
            ty: ty.into(),
            payload: None,
            error: None,
            source: source.to_owned(),
        }
    }

    pub fn payload<T>(mut self, payload: T) -> Self
    where
        T: ToBytes,
    {
        match payload.into_bytes() {
            Ok(bytes) => self.payload = Some(bytes),
            Err(e) => {
                log::error!("Set observable payload failed: {:?}", e);
            },
        }

        self
    }

    pub fn error<T>(mut self, error: T) -> Self
    where
        T: ToBytes,
    {
        match error.into_bytes() {
            Ok(bytes) => self.error = Some(bytes),
            Err(e) => {
                log::error!("Set observable error failed: {:?}", e);
            },
        }
        self
    }

    pub fn build(self) {
        let payload = match self.payload {
            None => None,
            Some(bytes) => Some(bytes.to_vec()),
        };

        let error = match self.error {
            None => None,
            Some(bytes) => Some(bytes.to_vec()),
        };

        let subject = ObservableSubject {
            source: self.source,
            ty: self.ty,
            id: self.id,
            payload,
            error,
        };

        log::debug!("Post {}", subject);
        match RustStreamSender::post(subject) {
            Ok(_) => {},
            Err(error) => log::error!("Send observable subject failed: {}", error),
        }
    }
}
