use crate::{entities::app::parser::BelongToId, errors::*};
use flowy_derive::ProtoBuf;
use std::convert::TryInto;

#[derive(Default, ProtoBuf)]
pub struct QueryAppRequest {
    #[pb(index = 1)]
    pub app_id: String,

    #[pb(index = 2)]
    pub read_belongings: bool,

    #[pb(index = 3)]
    pub is_trash: bool,
}

impl QueryAppRequest {
    pub fn new(app_id: &str) -> Self {
        QueryAppRequest {
            app_id: app_id.to_string(),
            read_belongings: false,
            is_trash: false,
        }
    }

    pub fn set_read_views(mut self, read_views: bool) -> Self {
        self.read_belongings = read_views;
        self
    }

    pub fn set_is_trash(mut self, is_trash: bool) -> Self {
        self.is_trash = is_trash;
        self
    }
}

pub struct QueryAppParams {
    pub app_id: String,
    pub read_belongings: bool,
    pub is_trash: bool,
}

impl TryInto<QueryAppParams> for QueryAppRequest {
    type Error = WorkspaceError;

    fn try_into(self) -> Result<QueryAppParams, Self::Error> {
        let app_id = BelongToId::parse(self.app_id)
            .map_err(|e| ErrorBuilder::new(WsErrCode::AppIdInvalid).msg(e).build())?
            .0;

        Ok(QueryAppParams {
            app_id,
            read_belongings: self.read_belongings,
            is_trash: self.is_trash,
        })
    }
}
