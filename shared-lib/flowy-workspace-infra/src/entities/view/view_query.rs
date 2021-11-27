use crate::{errors::ErrorCode, parser::view::ViewId};
use flowy_derive::ProtoBuf;
use flowy_document_infra::entities::doc::DocIdentifier;
use std::convert::TryInto;

#[derive(Default, ProtoBuf)]
pub struct QueryViewRequest {
    #[pb(index = 1)]
    pub view_ids: Vec<String>,
}

#[derive(Default, ProtoBuf, Clone, Debug)]
pub struct ViewIdentifier {
    #[pb(index = 1)]
    pub view_id: String,
}

impl std::convert::From<String> for ViewIdentifier {
    fn from(view_id: String) -> Self { ViewIdentifier { view_id } }
}

impl std::convert::From<ViewIdentifier> for DocIdentifier {
    fn from(identifier: ViewIdentifier) -> Self {
        DocIdentifier {
            doc_id: identifier.view_id,
        }
    }
}

impl TryInto<ViewIdentifier> for QueryViewRequest {
    type Error = ErrorCode;
    fn try_into(self) -> Result<ViewIdentifier, Self::Error> {
        debug_assert!(self.view_ids.len() == 1);
        if self.view_ids.len() != 1 {
            log::error!("The len of view_ids should be equal to 1");
            return Err(ErrorCode::ViewIdInvalid);
        }

        let view_id = self.view_ids.first().unwrap().clone();
        let view_id = ViewId::parse(view_id)?.0;

        Ok(ViewIdentifier { view_id })
    }
}

#[derive(Default, ProtoBuf)]
pub struct ViewIdentifiers {
    #[pb(index = 1)]
    pub view_ids: Vec<String>,
}

impl TryInto<ViewIdentifiers> for QueryViewRequest {
    type Error = ErrorCode;

    fn try_into(self) -> Result<ViewIdentifiers, Self::Error> {
        let mut view_ids = vec![];
        for view_id in self.view_ids {
            let view_id = ViewId::parse(view_id)?.0;

            view_ids.push(view_id);
        }

        Ok(ViewIdentifiers { view_ids })
    }
}
