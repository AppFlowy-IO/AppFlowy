use crate::{
    entities::view::parser::ViewId,
    errors::{ErrorBuilder, ErrorCode, WorkspaceError},
};
use flowy_derive::ProtoBuf;
use flowy_document::entities::doc::QueryDocParams;
use std::convert::TryInto;

#[derive(Default, ProtoBuf)]
pub struct QueryViewRequest {
    #[pb(index = 1)]
    pub view_id: String,

    #[pb(index = 2)]
    pub is_trash: bool,

    #[pb(index = 3)]
    pub read_belongings: bool,
}

impl QueryViewRequest {
    pub fn new(view_id: &str) -> Self {
        Self {
            view_id: view_id.to_owned(),
            is_trash: false,
            read_belongings: false,
        }
    }

    pub fn trash(mut self) -> Self {
        self.is_trash = true;
        self
    }
}

#[derive(Default, ProtoBuf, Clone, Debug)]
pub struct QueryViewParams {
    #[pb(index = 1)]
    pub view_id: String,

    #[pb(index = 2)]
    pub is_trash: bool,

    #[pb(index = 3)]
    pub read_belongings: bool,
}

impl QueryViewParams {
    pub fn new(view_id: &str) -> Self {
        Self {
            view_id: view_id.to_owned(),
            ..Default::default()
        }
    }

    pub fn trash(mut self) -> Self {
        self.is_trash = true;
        self
    }

    pub fn read_belongings(mut self) -> Self {
        self.read_belongings = true;
        self
    }
}

impl std::convert::Into<QueryDocParams> for QueryViewParams {
    fn into(self) -> QueryDocParams { QueryDocParams { doc_id: self.view_id } }
}

impl TryInto<QueryViewParams> for QueryViewRequest {
    type Error = WorkspaceError;
    fn try_into(self) -> Result<QueryViewParams, Self::Error> {
        let view_id = ViewId::parse(self.view_id)
            .map_err(|e| ErrorBuilder::new(ErrorCode::ViewIdInvalid).msg(e).build())?
            .0;

        Ok(QueryViewParams {
            view_id,
            is_trash: self.is_trash,
            read_belongings: self.read_belongings,
        })
    }
}

#[derive(Default, ProtoBuf)]
pub struct OpenViewRequest {
    #[pb(index = 1)]
    pub view_id: String,
}

impl std::convert::TryInto<QueryDocParams> for OpenViewRequest {
    type Error = WorkspaceError;

    fn try_into(self) -> Result<QueryDocParams, Self::Error> {
        let view_id = ViewId::parse(self.view_id)
            .map_err(|e| ErrorBuilder::new(ErrorCode::ViewIdInvalid).msg(e).build())?
            .0;
        Ok(QueryDocParams { doc_id: view_id })
    }
}
