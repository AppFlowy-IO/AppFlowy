use crate::{
    entities::revision::{RepeatedRevision, Revision, RevisionRange},
    errors::CollaborateError,
};
use bytes::Bytes;
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use std::convert::{TryFrom, TryInto};

#[derive(Debug, Clone, ProtoBuf_Enum, Eq, PartialEq, Hash)]
pub enum DocumentClientWSDataType {
    ClientPushRev = 0,
}

impl DocumentClientWSDataType {
    pub fn data<T>(&self, bytes: Bytes) -> Result<T, CollaborateError>
    where
        T: TryFrom<Bytes, Error = CollaborateError>,
    {
        T::try_from(bytes)
    }
}

impl std::default::Default for DocumentClientWSDataType {
    fn default() -> Self { DocumentClientWSDataType::ClientPushRev }
}

#[derive(ProtoBuf, Default, Debug, Clone)]
pub struct DocumentClientWSData {
    #[pb(index = 1)]
    pub doc_id: String,

    #[pb(index = 2)]
    pub ty: DocumentClientWSDataType,

    #[pb(index = 3)]
    pub data: Vec<u8>,

    #[pb(index = 4)]
    pub id: String,
}

impl std::convert::From<Revision> for DocumentClientWSData {
    fn from(revision: Revision) -> Self {
        let doc_id = revision.doc_id.clone();
        let rev_id = revision.rev_id;
        let bytes: Bytes = revision.try_into().unwrap();
        Self {
            doc_id,
            ty: DocumentClientWSDataType::ClientPushRev,
            data: bytes.to_vec(),
            id: rev_id.to_string(),
        }
    }
}

#[derive(Debug, Clone, ProtoBuf_Enum, Eq, PartialEq, Hash)]
pub enum DocumentServerWSDataType {
    ServerAck     = 0,
    ServerPushRev = 1,
    ServerPullRev = 2,
    UserConnect   = 3,
}

impl std::default::Default for DocumentServerWSDataType {
    fn default() -> Self { DocumentServerWSDataType::ServerPushRev }
}

#[derive(ProtoBuf, Default, Debug, Clone)]
pub struct DocumentServerWSData {
    #[pb(index = 1)]
    pub doc_id: String,

    #[pb(index = 2)]
    pub ty: DocumentServerWSDataType,

    #[pb(index = 3)]
    pub data: Vec<u8>,

    #[pb(index = 4)]
    pub id: String,
}

pub struct DocumentServerWSDataBuilder();
impl DocumentServerWSDataBuilder {
    // DocumentWSDataType::PushRev -> Revision
    pub fn build_push_message(doc_id: &str, revisions: Vec<Revision>, id: &str) -> DocumentServerWSData {
        let repeated_revision = RepeatedRevision { items: revisions };
        let bytes: Bytes = repeated_revision.try_into().unwrap();
        DocumentServerWSData {
            doc_id: doc_id.to_string(),
            ty: DocumentServerWSDataType::ServerPushRev,
            data: bytes.to_vec(),
            id: id.to_string(),
        }
    }

    // DocumentWSDataType::PullRev -> RevisionRange
    pub fn build_pull_message(doc_id: &str, range: RevisionRange, rev_id: i64) -> DocumentServerWSData {
        let bytes: Bytes = range.try_into().unwrap();
        DocumentServerWSData {
            doc_id: doc_id.to_string(),
            ty: DocumentServerWSDataType::ServerPullRev,
            data: bytes.to_vec(),
            id: rev_id.to_string(),
        }
    }

    // DocumentWSDataType::Ack -> RevId
    pub fn build_ack_message(doc_id: &str, id: &str) -> DocumentServerWSData {
        DocumentServerWSData {
            doc_id: doc_id.to_string(),
            ty: DocumentServerWSDataType::ServerAck,
            data: vec![],
            id: id.to_string(),
        }
    }

    // DocumentWSDataType::UserConnect -> DocumentConnected
    // pub fn build_new_document_user_message(doc_id: &str, new_document_user:
    // NewDocumentUser) -> DocumentServerWSData {     let id =
    // new_document_user.user_id.clone();     let bytes: Bytes =
    // new_document_user.try_into().unwrap();     DocumentServerWSData {
    //         doc_id: doc_id.to_string(),
    //         ty: DocumentServerWSDataType::UserConnect,
    //         data: bytes.to_vec(),
    //         id,
    //     }
    // }
}

#[derive(ProtoBuf, Default, Debug, Clone)]
pub struct NewDocumentUser {
    #[pb(index = 1)]
    pub user_id: String,

    #[pb(index = 2)]
    pub doc_id: String,

    // revision_data: the latest rev_id of the document.
    #[pb(index = 3)]
    pub revision_data: Vec<u8>,
}
