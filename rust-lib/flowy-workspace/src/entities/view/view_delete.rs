use crate::{entities::view::parser::ViewId, errors::WorkspaceError};
use flowy_derive::ProtoBuf;

use std::convert::TryInto;

#[derive(Default, ProtoBuf)]
pub struct DeleteViewRequest {
    #[pb(index = 1)]
    view_ids: Vec<String>,
}

#[derive(Default, ProtoBuf)]
pub struct DeleteViewParams {
    #[pb(index = 1)]
    pub view_ids: Vec<String>,
}

impl TryInto<DeleteViewParams> for DeleteViewRequest {
    type Error = WorkspaceError;

    fn try_into(self) -> Result<DeleteViewParams, Self::Error> {
        let mut view_ids = vec![];
        for view_id in self.view_ids {
            let view_id = ViewId::parse(view_id)
                .map_err(|e| WorkspaceError::view_id().context(e))?
                .0;

            view_ids.push(view_id);
        }

        Ok(DeleteViewParams { view_ids })
    }
}
