use crate::{errors::ErrorCode, parser::view::ViewIdentify};
use flowy_collaboration::entities::doc::DocumentId;
use flowy_derive::ProtoBuf;
use std::convert::TryInto;

#[derive(Default, ProtoBuf)]
pub struct QueryViewRequest {
    #[pb(index = 1)]
    pub view_ids: Vec<String>,
}

#[derive(Default, ProtoBuf, Clone, Debug)]
pub struct ViewId {
    #[pb(index = 1)]
    pub view_id: String,
}

impl std::convert::From<String> for ViewId {
    fn from(view_id: String) -> Self { ViewId { view_id } }
}

impl std::convert::From<ViewId> for DocumentId {
    fn from(identifier: ViewId) -> Self {
        DocumentId {
            doc_id: identifier.view_id,
        }
    }
}

impl TryInto<ViewId> for QueryViewRequest {
    type Error = ErrorCode;
    fn try_into(self) -> Result<ViewId, Self::Error> {
        debug_assert!(self.view_ids.len() == 1);
        if self.view_ids.len() != 1 {
            log::error!("The len of view_ids should be equal to 1");
            return Err(ErrorCode::ViewIdInvalid);
        }

        let view_id = self.view_ids.first().unwrap().clone();
        let view_id = ViewIdentify::parse(view_id)?.0;

        Ok(ViewId { view_id })
    }
}

#[derive(Default, ProtoBuf)]
pub struct RepeatedViewId {
    #[pb(index = 1)]
    pub items: Vec<String>,
}

impl TryInto<RepeatedViewId> for QueryViewRequest {
    type Error = ErrorCode;

    fn try_into(self) -> Result<RepeatedViewId, Self::Error> {
        let mut view_ids = vec![];
        for view_id in self.view_ids {
            let view_id = ViewIdentify::parse(view_id)?.0;

            view_ids.push(view_id);
        }

        Ok(RepeatedViewId { items: view_ids })
    }
}
