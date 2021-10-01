use crate::{entities::app::parser::AppId, errors::*};
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

    pub fn read_views(mut self) -> Self {
        self.read_belongings = true;
        self
    }

    pub fn trash(mut self) -> Self {
        self.is_trash = true;
        self
    }
}

#[derive(ProtoBuf, Default, Clone, Debug)]
pub struct QueryAppParams {
    #[pb(index = 1)]
    pub app_id: String,

    #[pb(index = 2)]
    pub read_belongings: bool,

    #[pb(index = 3)]
    pub is_trash: bool,
}

impl QueryAppParams {
    pub fn new(app_id: &str) -> Self {
        Self {
            app_id: app_id.to_string(),
            ..Default::default()
        }
    }

    pub fn read_belongings(mut self) -> Self {
        self.read_belongings = true;
        self
    }

    pub fn trash(mut self) -> Self {
        self.is_trash = true;
        self
    }
}

impl TryInto<QueryAppParams> for QueryAppRequest {
    type Error = WorkspaceError;

    fn try_into(self) -> Result<QueryAppParams, Self::Error> {
        let app_id = AppId::parse(self.app_id)
            .map_err(|e| WorkspaceError::app_id().context(e))?
            .0;

        Ok(QueryAppParams {
            app_id,
            read_belongings: self.read_belongings,
            is_trash: self.is_trash,
        })
    }
}
