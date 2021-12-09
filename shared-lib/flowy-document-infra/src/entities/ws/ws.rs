use crate::{entities::doc::NewDocUser, errors::DocumentError};
use bytes::Bytes;
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use lib_ot::revision::{RevId, Revision, RevisionRange};
use std::convert::{TryFrom, TryInto};

#[derive(Debug, Clone, ProtoBuf_Enum, Eq, PartialEq, Hash)]
pub enum WsDataType {
    // The frontend receives the Acked means the backend has accepted the revision
    Acked      = 0,
    // The frontend receives the PushRev event means the backend is pushing the new revision to frontend
    PushRev    = 1,
    // The fronted receives the PullRev event means the backend try to pull the revision from frontend
    PullRev    = 2,
    Conflict   = 3,
    NewDocUser = 4,
}

impl WsDataType {
    pub fn data<T>(&self, bytes: Bytes) -> Result<T, DocumentError>
    where
        T: TryFrom<Bytes, Error = DocumentError>,
    {
        T::try_from(bytes)
    }
}

impl std::default::Default for WsDataType {
    fn default() -> Self { WsDataType::Acked }
}

#[derive(ProtoBuf, Default, Debug, Clone)]
pub struct WsDocumentData {
    #[pb(index = 1)]
    pub doc_id: String,

    #[pb(index = 2)]
    pub ty: WsDataType,

    #[pb(index = 3)]
    pub data: Vec<u8>,
}

impl std::convert::From<Revision> for WsDocumentData {
    fn from(revision: Revision) -> Self {
        let doc_id = revision.doc_id.clone();
        let bytes: Bytes = revision.try_into().unwrap();
        Self {
            doc_id,
            ty: WsDataType::PushRev,
            data: bytes.to_vec(),
        }
    }
}

impl std::convert::From<NewDocUser> for WsDocumentData {
    fn from(user: NewDocUser) -> Self {
        let doc_id = user.doc_id.clone();
        let bytes: Bytes = user.try_into().unwrap();
        Self {
            doc_id,
            ty: WsDataType::NewDocUser,
            data: bytes.to_vec(),
        }
    }
}

pub struct WsDocumentDataBuilder();
impl WsDocumentDataBuilder {
    // WsDataType::PushRev -> Revision
    pub fn build_push_rev_message(doc_id: &str, revision: Revision) -> WsDocumentData {
        let bytes: Bytes = revision.try_into().unwrap();
        WsDocumentData {
            doc_id: doc_id.to_string(),
            ty: WsDataType::PushRev,
            data: bytes.to_vec(),
        }
    }

    // WsDataType::PullRev -> RevisionRange
    pub fn build_push_pull_message(doc_id: &str, range: RevisionRange) -> WsDocumentData {
        let bytes: Bytes = range.try_into().unwrap();
        WsDocumentData {
            doc_id: doc_id.to_string(),
            ty: WsDataType::PullRev,
            data: bytes.to_vec(),
        }
    }

    // WsDataType::Acked -> RevId
    pub fn build_acked_message(doc_id: &str, rev_id: i64) -> WsDocumentData {
        let rev_id: RevId = rev_id.into();
        let bytes: Bytes = rev_id.try_into().unwrap();
        WsDocumentData {
            doc_id: doc_id.to_string(),
            ty: WsDataType::Acked,
            data: bytes.to_vec(),
        }
    }
}
