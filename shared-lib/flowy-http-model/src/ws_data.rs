use crate::revision::{Revision, RevisionRange};
use bytes::Bytes;
use serde::{Deserialize, Serialize};
use serde_repr::*;

#[derive(Debug, Clone, Serialize_repr, Deserialize_repr, Eq, PartialEq, Hash)]
#[repr(u8)]
pub enum ClientRevisionWSDataType {
    ClientPushRev = 0,
    ClientPing = 1,
}

impl Default for ClientRevisionWSDataType {
    fn default() -> Self {
        ClientRevisionWSDataType::ClientPushRev
    }
}

#[derive(Serialize, Deserialize, Default, Debug, Clone)]
pub struct ClientRevisionWSData {
    pub object_id: String,
    pub ty: ClientRevisionWSDataType,
    pub revisions: Vec<Revision>,
    pub rev_id: i64,
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
            revisions,
            rev_id,
        }
    }

    pub fn ping(object_id: &str, rev_id: i64) -> Self {
        Self {
            object_id: object_id.to_owned(),
            ty: ClientRevisionWSDataType::ClientPing,
            revisions: vec![],
            rev_id,
        }
    }
}

impl std::convert::TryFrom<bytes::Bytes> for ClientRevisionWSData {
    type Error = serde_json::Error;

    fn try_from(bytes: Bytes) -> Result<Self, Self::Error> {
        serde_json::from_slice(&bytes)
    }
}

impl std::convert::TryFrom<ClientRevisionWSData> for Bytes {
    type Error = serde_json::Error;

    fn try_from(bytes: ClientRevisionWSData) -> Result<Self, Self::Error> {
        serde_json::to_vec(&bytes).map(Bytes::from)
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum WSRevisionPayload {
    ServerAck { rev_id: i64 },
    ServerPushRev { revisions: Vec<Revision> },
    ServerPullRev { range: RevisionRange },
    UserConnect { user: NewDocumentUser },
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct ServerRevisionWSData {
    pub object_id: String,
    pub payload: WSRevisionPayload,
}

impl std::convert::TryFrom<Bytes> for ServerRevisionWSData {
    type Error = serde_json::Error;

    fn try_from(bytes: Bytes) -> Result<Self, Self::Error> {
        serde_json::from_slice(&bytes)
    }
}

impl std::convert::TryFrom<ServerRevisionWSData> for Bytes {
    type Error = serde_json::Error;

    fn try_from(bytes: ServerRevisionWSData) -> Result<Self, Self::Error> {
        serde_json::to_vec(&bytes).map(Bytes::from)
    }
}

pub struct ServerRevisionWSDataBuilder();
impl ServerRevisionWSDataBuilder {
    pub fn build_push_message(object_id: &str, revisions: Vec<Revision>) -> ServerRevisionWSData {
        ServerRevisionWSData {
            object_id: object_id.to_string(),
            payload: WSRevisionPayload::ServerPushRev { revisions },
        }
    }

    pub fn build_pull_message(object_id: &str, range: RevisionRange) -> ServerRevisionWSData {
        ServerRevisionWSData {
            object_id: object_id.to_string(),
            payload: WSRevisionPayload::ServerPullRev { range },
        }
    }

    pub fn build_ack_message(object_id: &str, rev_id: i64) -> ServerRevisionWSData {
        ServerRevisionWSData {
            object_id: object_id.to_string(),
            payload: WSRevisionPayload::ServerAck { rev_id },
        }
    }
}

#[derive(Serialize, Deserialize, Default, Debug, Clone)]
pub struct NewDocumentUser {
    pub user_id: String,
    pub doc_id: String,
    pub latest_rev_id: i64,
}
