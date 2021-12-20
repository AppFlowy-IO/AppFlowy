use crate::errors::CollaborateError;
use bytes::Bytes;
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use lib_infra::uuid;
use lib_ot::revision::{Revision, RevisionRange};
use std::convert::{TryFrom, TryInto};

#[derive(Debug, Clone, ProtoBuf_Enum, Eq, PartialEq, Hash)]
pub enum DocumentWSDataType {
    // The frontend receives the Acked means the backend has accepted the revision
    Ack         = 0,
    // The frontend receives the PushRev event means the backend is pushing the new revision to frontend
    PushRev     = 1,
    // The fronted receives the PullRev event means the backend try to pull the revision from frontend
    PullRev     = 2,
    UserConnect = 3,
}

impl DocumentWSDataType {
    pub fn data<T>(&self, bytes: Bytes) -> Result<T, CollaborateError>
    where
        T: TryFrom<Bytes, Error = CollaborateError>,
    {
        T::try_from(bytes)
    }
}

impl std::default::Default for DocumentWSDataType {
    fn default() -> Self { DocumentWSDataType::Ack }
}

#[derive(ProtoBuf, Default, Debug, Clone)]
pub struct DocumentWSData {
    #[pb(index = 1)]
    pub doc_id: String,

    #[pb(index = 2)]
    pub ty: DocumentWSDataType,

    #[pb(index = 3)]
    pub data: Vec<u8>,

    #[pb(index = 4)]
    pub id: String,
}

impl std::convert::From<Revision> for DocumentWSData {
    fn from(revision: Revision) -> Self {
        let doc_id = revision.doc_id.clone();
        let rev_id = revision.rev_id;
        let bytes: Bytes = revision.try_into().unwrap();
        Self {
            doc_id,
            ty: DocumentWSDataType::PushRev,
            data: bytes.to_vec(),
            id: rev_id.to_string(),
        }
    }
}

pub struct DocumentWSDataBuilder();
impl DocumentWSDataBuilder {
    // DocumentWSDataType::PushRev -> Revision
    pub fn build_push_rev_message(doc_id: &str, revision: Revision) -> DocumentWSData {
        let rev_id = revision.rev_id;
        let bytes: Bytes = revision.try_into().unwrap();
        DocumentWSData {
            doc_id: doc_id.to_string(),
            ty: DocumentWSDataType::PushRev,
            data: bytes.to_vec(),
            id: rev_id.to_string(),
        }
    }

    // DocumentWSDataType::PullRev -> RevisionRange
    pub fn build_push_pull_message(doc_id: &str, range: RevisionRange) -> DocumentWSData {
        let bytes: Bytes = range.try_into().unwrap();
        DocumentWSData {
            doc_id: doc_id.to_string(),
            ty: DocumentWSDataType::PullRev,
            data: bytes.to_vec(),
            id: uuid(),
        }
    }

    // DocumentWSDataType::Ack -> RevId
    pub fn build_ack_message(doc_id: &str, id: &str) -> DocumentWSData {
        DocumentWSData {
            doc_id: doc_id.to_string(),
            ty: DocumentWSDataType::Ack,
            data: vec![],
            id: id.to_string(),
        }
    }

    // DocumentWSDataType::UserConnect -> DocumentConnected
    pub fn build_new_document_user_message(doc_id: &str, new_document_user: NewDocumentUser) -> DocumentWSData {
        let id = new_document_user.user_id.clone();
        let bytes: Bytes = new_document_user.try_into().unwrap();
        DocumentWSData {
            doc_id: doc_id.to_string(),
            ty: DocumentWSDataType::UserConnect,
            data: bytes.to_vec(),
            id,
        }
    }
}

#[derive(ProtoBuf, Default, Debug, Clone)]
pub struct NewDocumentUser {
    #[pb(index = 1)]
    pub user_id: String,

    #[pb(index = 2)]
    pub doc_id: String,

    #[pb(index = 3)]
    pub rev_id: i64,
}
