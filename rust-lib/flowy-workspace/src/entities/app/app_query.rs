use crate::{entities::app::parser::AppId, errors::*};
use flowy_derive::ProtoBuf;
use std::convert::TryInto;

#[derive(Default, ProtoBuf, Clone)]
pub struct QueryAppRequest {
    #[pb(index = 1)]
    pub app_ids: Vec<String>,
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
        }
    }
}

impl TryInto<AppIdentifier> for QueryAppRequest {
    type Error = WorkspaceError;

    fn try_into(self) -> Result<AppIdentifier, Self::Error> {
        debug_assert!(self.app_ids.len() == 1);
        if self.app_ids.len() != 1 {
            return Err(WorkspaceError::invalid_view_id().context("The len of app_ids should be equal to 1"));
        }

        let app_id = self.app_ids.first().unwrap().clone();
        let app_id = AppId::parse(app_id)
            .map_err(|e| WorkspaceError::invalid_app_id().context(e))?
            .0;
        Ok(AppIdentifier { app_id })
    }
}
