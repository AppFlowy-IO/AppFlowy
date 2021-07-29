use crate::{
    entities::view::parser::ViewId,
    errors::{ErrorBuilder, WorkspaceError, WsErrCode},
};
use flowy_derive::ProtoBuf;
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

    pub fn set_is_trash(mut self, is_trash: bool) -> Self {
        self.is_trash = is_trash;
        self
    }
}

pub struct QueryViewParams {
    pub view_id: String,
    pub is_trash: bool,
    pub read_belongings: bool,
}

impl TryInto<QueryViewParams> for QueryViewRequest {
    type Error = WorkspaceError;

    fn try_into(self) -> Result<QueryViewParams, Self::Error> {
        let view_id = ViewId::parse(self.view_id)
            .map_err(|e| ErrorBuilder::new(WsErrCode::ViewIdInvalid).msg(e).build())?
            .0;

        Ok(QueryViewParams {
            view_id,
            is_trash: self.is_trash,
            read_belongings: self.read_belongings,
        })
    }
}
