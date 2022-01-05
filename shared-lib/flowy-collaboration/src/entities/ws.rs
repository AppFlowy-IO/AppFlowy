use crate::{
    entities::revision::{RepeatedRevision, RevId, Revision, RevisionRange},
    errors::CollaborateError,
};
use bytes::Bytes;
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use std::convert::{TryFrom, TryInto};

#[derive(Debug, Clone, ProtoBuf_Enum, Eq, PartialEq, Hash)]
pub enum DocumentClientWSDataType {
    ClientPushRev = 0,
    ClientPing    = 1,
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
    pub revisions: RepeatedRevision,

    #[pb(index = 4)]
    id: String,
}

impl DocumentClientWSData {
    pub fn from_revisions(doc_id: &str, revisions: Vec<Revision>) -> Self {
        let rev_id = match revisions.first() {
            None => 0,
            Some(revision) => revision.rev_id,
        };

        Self {
            doc_id: doc_id.to_owned(),
            ty: DocumentClientWSDataType::ClientPushRev,
            revisions: RepeatedRevision::new(revisions),
            id: rev_id.to_string(),
        }
    }

    pub fn ping(doc_id: &str, rev_id: i64) -> Self {
        Self {
            doc_id: doc_id.to_owned(),
            ty: DocumentClientWSDataType::ClientPing,
            revisions: RepeatedRevision::empty(),
            id: rev_id.to_string(),
        }
    }

    pub fn id(&self) -> String { self.id.clone() }
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
}

pub struct DocumentServerWSDataBuilder();
impl DocumentServerWSDataBuilder {
<<<<<<< HEAD
<<<<<<< HEAD
    pub fn build_push_message(doc_id: &str, revisions: Vec<Revision>) -> DocumentServerWSData {
        let repeated_revision = RepeatedRevision::new(revisions);
=======
    pub fn build_push_message(doc_id: &str, repeated_revision: RepeatedRevision) -> DocumentServerWSData {
>>>>>>> upstream/main
=======
    pub fn build_push_message(doc_id: &str, repeated_revision: RepeatedRevision) -> DocumentServerWSData {
>>>>>>> upstream/main
        let bytes: Bytes = repeated_revision.try_into().unwrap();
        DocumentServerWSData {
            doc_id: doc_id.to_string(),
            ty: DocumentServerWSDataType::ServerPushRev,
            data: bytes.to_vec(),
        }
    }

    pub fn build_pull_message(doc_id: &str, range: RevisionRange) -> DocumentServerWSData {
        let bytes: Bytes = range.try_into().unwrap();
        DocumentServerWSData {
            doc_id: doc_id.to_string(),
            ty: DocumentServerWSDataType::ServerPullRev,
            data: bytes.to_vec(),
        }
    }

    pub fn build_ack_message(doc_id: &str, rev_id: i64) -> DocumentServerWSData {
        let rev_id: RevId = rev_id.into();
        let bytes: Bytes = rev_id.try_into().unwrap();
        DocumentServerWSData {
            doc_id: doc_id.to_string(),
            ty: DocumentServerWSDataType::ServerAck,
            data: bytes.to_vec(),
        }
    }
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
