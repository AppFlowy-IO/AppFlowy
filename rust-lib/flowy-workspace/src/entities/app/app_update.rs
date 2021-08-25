use crate::{
    entities::{
        app::{
            parser::{AppColorStyle, AppId, AppName},
            ColorStyle,
        },
        workspace::parser::WorkspaceId,
    },
    errors::{ErrorBuilder, WorkspaceError, WsErrCode},
};
use flowy_derive::ProtoBuf;
use std::convert::TryInto;

#[derive(ProtoBuf, Default)]
pub struct UpdateAppRequest {
    #[pb(index = 1)]
    pub app_id: String,

    #[pb(index = 2, one_of)]
    pub workspace_id: Option<String>,

    #[pb(index = 3, one_of)]
    pub name: Option<String>,

    #[pb(index = 4, one_of)]
    pub desc: Option<String>,

    #[pb(index = 5, one_of)]
    pub color_style: Option<ColorStyle>,

    #[pb(index = 6, one_of)]
    pub is_trash: Option<bool>,
}

#[derive(ProtoBuf, Default)]
pub struct UpdateAppParams {
    #[pb(index = 1)]
    pub app_id: String,

    #[pb(index = 2, one_of)]
    pub workspace_id: Option<String>,

    #[pb(index = 3, one_of)]
    pub name: Option<String>,

    #[pb(index = 4, one_of)]
    pub desc: Option<String>,

    #[pb(index = 5, one_of)]
    pub color_style: Option<ColorStyle>,

    #[pb(index = 6, one_of)]
    pub is_trash: Option<bool>,
}

impl TryInto<UpdateAppParams> for UpdateAppRequest {
    type Error = WorkspaceError;

    fn try_into(self) -> Result<UpdateAppParams, Self::Error> {
        let app_id = AppId::parse(self.app_id)
            .map_err(|e| ErrorBuilder::new(WsErrCode::AppIdInvalid).msg(e).build())?
            .0;

        let name = match self.name {
            None => None,
            Some(name) => Some(
                AppName::parse(name)
                    .map_err(|e| {
                        ErrorBuilder::new(WsErrCode::WorkspaceNameInvalid)
                            .msg(e)
                            .build()
                    })?
                    .0,
            ),
        };

        let workspace_id = match self.workspace_id {
            None => None,
            Some(wid) => Some(
                WorkspaceId::parse(wid)
                    .map_err(|e| {
                        ErrorBuilder::new(WsErrCode::WorkspaceIdInvalid)
                            .msg(e)
                            .build()
                    })?
                    .0,
            ),
        };

        let color_style = match self.color_style {
            None => None,
            Some(color_style) => Some(
                AppColorStyle::parse(color_style)
                    .map_err(|e| {
                        ErrorBuilder::new(WsErrCode::AppColorStyleInvalid)
                            .msg(e)
                            .build()
                    })?
                    .0,
            ),
        };

        Ok(UpdateAppParams {
            app_id,
            workspace_id,
            name,
            desc: self.desc,
            color_style,
            is_trash: self.is_trash,
        })
    }
}
