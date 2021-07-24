use flowy_derive::ProtoBuf_Enum;
use flowy_dispatch::prelude::ToBytes;
use flowy_observable::{dart::RustStreamSender, entities::ObservableSubject};
const OBSERVABLE_CATEGORY: &'static str = "Workspace";

#[derive(ProtoBuf_Enum, Debug)]
pub(crate) enum WorkspaceObservable {
    Unknown             = 0,

    WorkspaceUpdateDesc = 10,
    WorkspaceAddApp     = 11,

    AppUpdateDesc       = 20,
    AppAddView          = 21,

    ViewUpdateDesc      = 30,
}

impl std::default::Default for WorkspaceObservable {
    fn default() -> Self { WorkspaceObservable::Unknown }
}

pub(crate) struct ObservableSender {
    ty: WorkspaceObservable,
    subject_id: String,
    payload: Option<Vec<u8>>,
}

impl ObservableSender {
    pub(crate) fn new(subject_id: &str, ty: WorkspaceObservable) -> Self {
        Self {
            subject_id: subject_id.to_owned(),
            ty,
            payload: None,
        }
    }

    pub(crate) fn payload<T>(mut self, payload: T) -> Self
    where
        T: ToBytes,
    {
        let bytes = payload.into_bytes().unwrap();
        self.payload = Some(bytes);
        self
    }

    pub(crate) fn send(self) {
        log::debug!(
            "Workspace observable id: {}, ty: {:?}",
            self.subject_id,
            self.ty
        );

        let subject = ObservableSubject {
            category: OBSERVABLE_CATEGORY.to_string(),
            ty: self.ty as i32,
            subject_id: self.subject_id,
            subject_payload: self.payload,
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

pub(crate) fn send_observable_with_payload<T>(id: &str, ty: WorkspaceObservable, payload: T)
where
    T: ToBytes,
{
    ObservableSender::new(id, ty).payload(payload).send();
}
