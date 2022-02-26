use crate::{
    entities::revision::{RepeatedRevision, RevId, Revision, RevisionRange},
    errors::CollaborateError,
};
use bytes::Bytes;
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use std::convert::{TryFrom, TryInto};

#[derive(Debug, Clone, ProtoBuf_Enum, Eq, PartialEq, Hash)]
pub enum ClientRevisionWSDataType {
    ClientPushRev = 0,
    ClientPing = 1,
}

impl ClientRevisionWSDataType {
    pub fn data<T>(&self, bytes: Bytes) -> Result<T, CollaborateError>
    where
        T: TryFrom<Bytes, Error = CollaborateError>,
    {
        T::try_from(bytes)
    }
}

impl std::default::Default for ClientRevisionWSDataType {
    fn default() -> Self {
        ClientRevisionWSDataType::ClientPushRev
    }
}

#[derive(ProtoBuf, Default, Debug, Clone)]
pub struct ClientRevisionWSData {
    #[pb(index = 1)]
    pub object_id: String,

    #[pb(index = 2)]
    pub ty: ClientRevisionWSDataType,

    #[pb(index = 3)]
    pub revisions: RepeatedRevision,

    #[pb(index = 4)]
    data_id: String,
}

impl ClientRevisionWSData {
    pub fn from_revisions(object_id: &str, revisions: Vec<Revision>) -> Self {
        let rev_id = match revisions.first() {
            None => 0,
            Some(revision) => revision.rev_id,
        };

        Self {
            object_id: object_id.to_owned(),
            ty: ClientRevisionWSDataType::ClientPushRev,
            revisions: RepeatedRevision::new(revisions),
            data_id: rev_id.to_string(),
        }
    }

    pub fn ping(object_id: &str, rev_id: i64) -> Self {
        Self {
            object_id: object_id.to_owned(),
            ty: ClientRevisionWSDataType::ClientPing,
            revisions: RepeatedRevision::empty(),
            data_id: rev_id.to_string(),
        }
    }

    pub fn id(&self) -> String {
        self.data_id.clone()
    }
}

#[derive(Debug, Clone, ProtoBuf_Enum, Eq, PartialEq, Hash)]
pub enum ServerRevisionWSDataType {
    ServerAck = 0,
    ServerPushRev = 1,
    ServerPullRev = 2,
    UserConnect = 3,
}

impl std::default::Default for ServerRevisionWSDataType {
    fn default() -> Self {
        ServerRevisionWSDataType::ServerPushRev
    }
}

#[derive(ProtoBuf, Default, Debug, Clone)]
pub struct ServerRevisionWSData {
    #[pb(index = 1)]
    pub object_id: String,

    #[pb(index = 2)]
    pub ty: ServerRevisionWSDataType,

    #[pb(index = 3)]
    pub data: Vec<u8>,
}

pub struct ServerRevisionWSDataBuilder();
impl ServerRevisionWSDataBuilder {
    pub fn build_push_message(object_id: &str, repeated_revision: RepeatedRevision) -> ServerRevisionWSData {
        let bytes: Bytes = repeated_revision.try_into().unwrap();
        ServerRevisionWSData {
            object_id: object_id.to_string(),
            ty: ServerRevisionWSDataType::ServerPushRev,
            data: bytes.to_vec(),
        }
    }

    pub fn build_pull_message(object_id: &str, range: RevisionRange) -> ServerRevisionWSData {
        let bytes: Bytes = range.try_into().unwrap();
        ServerRevisionWSData {
            object_id: object_id.to_string(),
            ty: ServerRevisionWSDataType::ServerPullRev,
            data: bytes.to_vec(),
        }
    }

    pub fn build_ack_message(object_id: &str, rev_id: i64) -> ServerRevisionWSData {
        let rev_id: RevId = rev_id.into();
        let bytes: Bytes = rev_id.try_into().unwrap();
        ServerRevisionWSData {
            object_id: object_id.to_string(),
            ty: ServerRevisionWSDataType::ServerAck,
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
