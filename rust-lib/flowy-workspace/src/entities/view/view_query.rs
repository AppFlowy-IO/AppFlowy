use crate::{entities::view::parser::ViewId, errors::WorkspaceError};
use flowy_derive::ProtoBuf;
use flowy_document::entities::doc::DocIdentifier;
use std::convert::TryInto;

#[derive(Default, ProtoBuf)]
pub struct QueryViewRequest {
    #[pb(index = 1)]
    pub view_id: String,

    #[pb(index = 2)]
    pub read_belongings: bool,
}

impl QueryViewRequest {
    pub fn new(view_id: &str) -> Self {
        Self {
            view_id: view_id.to_owned(),
            read_belongings: false,
        }
    }
}

#[derive(Default, ProtoBuf, Clone, Debug)]
pub struct QueryViewParams {
    #[pb(index = 1)]
    pub view_id: String,

    #[pb(index = 2)]
    pub read_belongings: bool,
}

impl QueryViewParams {
    pub fn new(view_id: &str) -> Self {
        Self {
            view_id: view_id.to_owned(),
            ..Default::default()
        }
    }

    pub fn read_belongings(mut self) -> Self {
        self.read_belongings = true;
        self
    }
}

impl std::convert::Into<DocIdentifier> for QueryViewParams {
    fn into(self) -> DocIdentifier { DocIdentifier { doc_id: self.view_id } }
}

impl TryInto<QueryViewParams> for QueryViewRequest {
    type Error = WorkspaceError;
    fn try_into(self) -> Result<QueryViewParams, Self::Error> {
        let view_id = ViewId::parse(self.view_id)
            .map_err(|e| WorkspaceError::view_id().context(e))?
            .0;

        Ok(QueryViewParams {
            view_id,
            read_belongings: self.read_belongings,
        })
    }
}

#[derive(Default, ProtoBuf)]
pub struct OpenViewRequest {
    #[pb(index = 1)]
    pub view_id: String,
}

impl std::convert::TryInto<DocIdentifier> for OpenViewRequest {
    type Error = WorkspaceError;

    fn try_into(self) -> Result<DocIdentifier, Self::Error> {
        let view_id = ViewId::parse(self.view_id)
            .map_err(|e| WorkspaceError::view_id().context(e))?
            .0;
        Ok(DocIdentifier { doc_id: view_id })
    }
}
