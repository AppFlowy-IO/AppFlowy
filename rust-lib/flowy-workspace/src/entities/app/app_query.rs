use crate::{entities::app::parser::AppId, errors::*};
use flowy_derive::ProtoBuf;
use std::convert::TryInto;

#[derive(Default, ProtoBuf)]
pub struct QueryAppRequest {
    #[pb(index = 1)]
    pub app_id: String,

    #[pb(index = 2)]
    pub is_trash: bool,
}

impl QueryAppRequest {
    pub fn new(app_id: &str) -> Self {
        QueryAppRequest {
            app_id: app_id.to_string(),
            is_trash: false,
        }
    }
}

#[derive(ProtoBuf, Default, Clone, Debug)]
pub struct AppIdentifier {
    #[pb(index = 1)]
    pub app_id: String,
}

impl AppIdentifier {
    pub fn new(app_id: &str) -> Self {
        Self {
            app_id: app_id.to_string(),
            ..Default::default()
        }
    }
}

impl TryInto<AppIdentifier> for QueryAppRequest {
    type Error = WorkspaceError;

    fn try_into(self) -> Result<AppIdentifier, Self::Error> {
        let app_id = AppId::parse(self.app_id)
            .map_err(|e| WorkspaceError::app_id().context(e))?
            .0;

        Ok(AppIdentifier { app_id })
    }
}
