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
}

pub struct QueryViewParams {
    pub view_id: String,
}

impl TryInto<QueryViewParams> for QueryViewRequest {
    type Error = WorkspaceError;

    fn try_into(self) -> Result<QueryViewParams, Self::Error> {
        let view_id = ViewId::parse(self.view_id)
            .map_err(|e| ErrorBuilder::new(WsErrCode::ViewIdInvalid).msg(e).build())?
            .0;

        Ok(QueryViewParams { view_id })
    }
}
