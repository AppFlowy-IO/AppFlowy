use crate::{errors::ErrorCode, parser::app::AppIdentify};
use flowy_derive::ProtoBuf;
use std::convert::TryInto;

#[derive(Default, ProtoBuf, Clone)]
pub struct QueryAppRequest {
    #[pb(index = 1)]
    pub app_ids: Vec<String>,
}

#[derive(ProtoBuf, Default, Clone, Debug)]
pub struct AppId {
    #[pb(index = 1)]
    pub app_id: String,
}

impl AppId {
    pub fn new(app_id: &str) -> Self {
        Self {
            app_id: app_id.to_string(),
        }
    }
}

impl TryInto<AppId> for QueryAppRequest {
    type Error = ErrorCode;

    fn try_into(self) -> Result<AppId, Self::Error> {
        debug_assert!(self.app_ids.len() == 1);
        if self.app_ids.len() != 1 {
            log::error!("The len of app_ids should be equal to 1");
            return Err(ErrorCode::AppIdInvalid);
        }

        let app_id = self.app_ids.first().unwrap().clone();
        let app_id = AppIdentify::parse(app_id)?.0;
        Ok(AppId { app_id })
    }
}
