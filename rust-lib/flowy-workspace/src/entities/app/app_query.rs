use crate::{entities::app::parser::AppId, errors::*};
use flowy_derive::ProtoBuf;
use std::convert::TryInto;

#[derive(Default, ProtoBuf)]
pub struct QueryAppRequest {
    #[pb(index = 1)]
    pub app_id: String,

    #[pb(index = 2)]
    pub read_views: bool,
}

pub struct QueryAppParams {
    pub app_id: String,
    pub read_views: bool,
}

impl TryInto<QueryAppParams> for QueryAppRequest {
    type Error = WorkspaceError;

    fn try_into(self) -> Result<QueryAppParams, Self::Error> {
        let app_id = AppId::parse(self.app_id)
            .map_err(|e| ErrorBuilder::new(WsErrCode::AppIdInvalid).msg(e).build())?
            .0;

        Ok(QueryAppParams {
            app_id,
            read_views: self.read_views,
        })
    }
}
