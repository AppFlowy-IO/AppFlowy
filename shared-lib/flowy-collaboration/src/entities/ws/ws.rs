use crate::errors::CollaborateError;
use bytes::Bytes;
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use lib_ot::revision::{RevId, Revision, RevisionRange};
use std::convert::{TryFrom, TryInto};

#[derive(Debug, Clone, ProtoBuf_Enum, Eq, PartialEq, Hash)]
pub enum DocumentWSDataType {
    // The frontend receives the Acked means the backend has accepted the revision
    Acked       = 0,
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
    fn default() -> Self { DocumentWSDataType::Acked }
}

#[derive(ProtoBuf, Default, Debug, Clone)]
pub struct DocumentWSData {
    #[pb(index = 1)]
    pub doc_id: String,

    #[pb(index = 2)]
    pub ty: DocumentWSDataType,

    #[pb(index = 3)]
    pub data: Vec<u8>,

    #[pb(index = 4, one_of)]
    pub id: Option<i64>,
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
            id: Some(rev_id),
        }
    }
}

pub struct WsDocumentDataBuilder();
impl WsDocumentDataBuilder {
    // DocumentWSDataType::PushRev -> Revision
    pub fn build_push_rev_message(doc_id: &str, revision: Revision) -> DocumentWSData {
        let rev_id = revision.rev_id;
        let bytes: Bytes = revision.try_into().unwrap();
        DocumentWSData {
            doc_id: doc_id.to_string(),
            ty: DocumentWSDataType::PushRev,
            data: bytes.to_vec(),
            id: Some(rev_id),
        }
    }

    // DocumentWSDataType::PullRev -> RevisionRange
    pub fn build_push_pull_message(doc_id: &str, range: RevisionRange) -> DocumentWSData {
        let bytes: Bytes = range.try_into().unwrap();
        DocumentWSData {
            doc_id: doc_id.to_string(),
            ty: DocumentWSDataType::PullRev,
            data: bytes.to_vec(),
            id: None,
        }
    }

    // DocumentWSDataType::Acked -> RevId
    pub fn build_acked_message(doc_id: &str, rev_id: i64) -> DocumentWSData {
        let cloned_rev_id = rev_id;
        let rev_id: RevId = rev_id.into();
        let bytes: Bytes = rev_id.try_into().unwrap();

        DocumentWSData {
            doc_id: doc_id.to_string(),
            ty: DocumentWSDataType::Acked,
            data: bytes.to_vec(),
            id: Some(cloned_rev_id),
        }
    }
}

#[derive(ProtoBuf, Default, Debug, Clone)]
pub struct DocumentConnected {
    #[pb(index = 1)]
    pub user_id: String,

    #[pb(index = 2)]
    pub doc_id: String,

    #[pb(index = 3)]
    pub rev_id: i64,
}
