use bytes::Bytes;
use flowy_derive::ProtoBuf_Enum;
use flowy_dispatch::prelude::{DispatchError, ToBytes};
use flowy_observable::{dart::RustStreamSender, entities::ObservableSubject};

const OBSERVABLE_CATEGORY: &'static str = "Workspace";

#[derive(ProtoBuf_Enum, Debug)]
pub(crate) enum WorkspaceObservable {
    Unknown             = 0,

    UserCreateWorkspace = 10,
    UserDeleteWorkspace = 11,

    WorkspaceUpdated    = 12,
    WorkspaceCreateApp  = 13,
    WorkspaceDeleteApp  = 14,

    AppUpdated          = 21,
    AppCreateView       = 23,
    AppDeleteView       = 24,

    ViewUpdated         = 31,
}

impl std::default::Default for WorkspaceObservable {
    fn default() -> Self { WorkspaceObservable::Unknown }
}

pub(crate) struct ObservableSender {
    ty: WorkspaceObservable,
    subject_id: String,
    payload: Option<Bytes>,
}

impl ObservableSender {
    pub(crate) fn new(subject_id: &str, ty: WorkspaceObservable) -> Self {
        Self {
            subject_id: subject_id.to_owned(),
            ty,
            payload: None,
        }
    }

    #[allow(dead_code)]
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

    pub(crate) fn send(self) {
        log::trace!(
            "Workspace observable id: {}, ty: {:?}",
            self.subject_id,
            self.ty
        );

        let subject_payload = match self.payload {
            None => None,
            Some(bytes) => Some(bytes.to_vec()),
        };

        let subject = ObservableSubject {
            category: OBSERVABLE_CATEGORY.to_string(),
            ty: self.ty as i32,
            subject_id: self.subject_id,
            subject_payload,
        };
        match RustStreamSender::post(subject) {
            Ok(_) => {},
            Err(error) => log::error!("Send observable subject failed: {}", error),
        }
    }
}

pub(crate) fn send_observable(id: &str, ty: WorkspaceObservable) {
    ObservableSender::new(id, ty).send();
}

#[allow(dead_code)]
pub(crate) fn send_observable_with_payload<T>(id: &str, ty: WorkspaceObservable, payload: T)
where
    T: ToBytes,
{
    ObservableSender::new(id, ty).payload(payload).send();
}
