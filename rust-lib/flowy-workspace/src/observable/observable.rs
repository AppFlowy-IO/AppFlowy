use bytes::Bytes;
use flowy_derive::ProtoBuf_Enum;
use flowy_dispatch::prelude::ToBytes;
use flowy_observable::{dart::RustStreamSender, entities::ObservableSubject};

const OBSERVABLE_CATEGORY: &'static str = "Workspace";

#[derive(ProtoBuf_Enum, Debug)]
pub(crate) enum WorkspaceObservable {
    Unknown              = 0,

    UserCreateWorkspace  = 10,
    UserDeleteWorkspace  = 11,

    WorkspaceUpdated     = 12,
    WorkspaceCreateApp   = 13,
    WorkspaceDeleteApp   = 14,
    WorkspaceListUpdated = 15,

    AppUpdated           = 21,
    AppCreateView        = 23,
    AppDeleteView        = 24,

    ViewUpdated          = 31,
}

impl std::default::Default for WorkspaceObservable {
    fn default() -> Self { WorkspaceObservable::Unknown }
}

pub(crate) struct ObservableBuilder {
    id: String,
    payload: Option<Bytes>,
    error: Option<Bytes>,
    ty: WorkspaceObservable,
}

impl ObservableBuilder {
    pub(crate) fn new(id: &str, ty: WorkspaceObservable) -> Self {
        Self {
            id: id.to_owned(),
            ty,
            payload: None,
            error: None,
        }
    }

    pub(crate) fn payload<T>(mut self, payload: T) -> Self
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

    pub(crate) fn error<T>(mut self, error: T) -> Self
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

    pub(crate) fn build(self) {
        log::trace!("Workspace observable id: {}, ty: {:?}", self.id, self.ty);

        let payload = match self.payload {
            None => None,
            Some(bytes) => Some(bytes.to_vec()),
        };

        let error = match self.error {
            None => None,
            Some(bytes) => Some(bytes.to_vec()),
        };

        let subject = ObservableSubject {
            category: OBSERVABLE_CATEGORY.to_string(),
            ty: self.ty as i32,
            id: self.id,
            payload,
            error,
        };
        match RustStreamSender::post(subject) {
            Ok(_) => {},
            Err(error) => log::error!("Send observable subject failed: {}", error),
        }
    }
}
