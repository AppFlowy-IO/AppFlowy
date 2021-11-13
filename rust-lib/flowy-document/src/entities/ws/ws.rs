use crate::errors::DocError;
use bytes::Bytes;
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_document_infra::entities::doc::{NewDocUser, Revision};
use flowy_ws::{WsMessage, WsModule};
use std::convert::{TryFrom, TryInto};

#[derive(Debug, Clone, ProtoBuf_Enum, Eq, PartialEq, Hash)]
pub enum WsDataType {
    Acked      = 0,
    PushRev    = 1,
    PullRev    = 2, // data should be Revision
    Conflict   = 3,
    NewDocUser = 4,
}

impl WsDataType {
    pub fn data<T>(&self, bytes: Bytes) -> Result<T, DocError>
    where
        T: TryFrom<Bytes, Error = DocError>,
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

    // Opti: parse the data with  type constraints
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

impl std::convert::Into<WsMessage> for WsDocumentData {
    fn into(self) -> WsMessage {
        let bytes: Bytes = self.try_into().unwrap();
        let msg = WsMessage {
            module: WsModule::Doc,
            data: bytes.to_vec(),
        };
        msg
    }
}
