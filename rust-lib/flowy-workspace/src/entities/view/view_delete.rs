use crate::{entities::view::parser::ViewId, errors::WorkspaceError};
use flowy_derive::ProtoBuf;
use flowy_document::entities::doc::QueryDocParams;
use std::convert::TryInto;

#[derive(Default, ProtoBuf)]
pub struct DeleteViewRequest {
    #[pb(index = 1)]
    view_id: String,
}

#[derive(Default, ProtoBuf)]
pub struct DeleteViewParams {
    #[pb(index = 1)]
    pub view_id: String,
}

impl TryInto<DeleteViewParams> for DeleteViewRequest {
    type Error = WorkspaceError;

    fn try_into(self) -> Result<DeleteViewParams, Self::Error> {
        let view_id = ViewId::parse(self.view_id)
            .map_err(|e| WorkspaceError::view_id().context(e))?
            .0;

        Ok(DeleteViewParams { view_id })
    }
}

impl std::convert::Into<QueryDocParams> for DeleteViewParams {
    fn into(self) -> QueryDocParams { QueryDocParams { doc_id: self.view_id } }
}
