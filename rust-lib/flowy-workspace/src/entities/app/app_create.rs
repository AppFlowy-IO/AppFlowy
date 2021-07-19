use crate::{
    entities::{
        app::parser::{AppColorStyle, AppName},
        workspace::parser::WorkspaceId,
    },
    errors::*,
};
use flowy_derive::ProtoBuf;
use std::convert::TryInto;

#[derive(ProtoBuf, Default)]
pub struct CreateAppRequest {
    #[pb(index = 1)]
    pub workspace_id: String,

    #[pb(index = 2)]
    pub name: String,

    #[pb(index = 3)]
    pub desc: String,

    #[pb(index = 4)]
    pub color_style: ColorStyle,
}

#[derive(ProtoBuf, Default, Debug)]
pub struct ColorStyle {
    #[pb(index = 1)]
    pub theme_color: String,
}

pub struct CreateAppParams {
    pub workspace_id: String,
    pub name: String,
    pub desc: String,
    pub color_style: ColorStyle,
}

impl TryInto<CreateAppParams> for CreateAppRequest {
    type Error = WorkspaceError;

    fn try_into(self) -> Result<CreateAppParams, Self::Error> {
        let name = AppName::parse(self.name).map_err(|e| {
            ErrorBuilder::new(WorkspaceErrorCode::AppNameInvalid)
                .msg(e)
                .build()
        })?;

        let id = WorkspaceId::parse(self.workspace_id).map_err(|e| {
            ErrorBuilder::new(WorkspaceErrorCode::WorkspaceIdInvalid)
                .msg(e)
                .build()
        })?;

        let color_style = AppColorStyle::parse(self.color_style).map_err(|e| {
            ErrorBuilder::new(WorkspaceErrorCode::AppColorStyleInvalid)
                .msg(e)
                .build()
        })?;

        Ok(CreateAppParams {
            workspace_id: id.0,
            name: name.0,
            desc: self.desc,
            color_style: color_style.0,
        })
    }
}

#[derive(ProtoBuf, Default, Debug)]
pub struct App {
    #[pb(index = 1)]
    pub id: String,

    #[pb(index = 2)]
    pub workspace_id: String,

    #[pb(index = 3)]
    pub name: String,

    #[pb(index = 4)]
    pub desc: String,
}
