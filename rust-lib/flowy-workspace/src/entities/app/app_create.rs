use crate::{
    entities::{
        app::parser::{AppColorStyle, AppName},
        view::RepeatedView,
        workspace::parser::WorkspaceId,
    },
    errors::*,
    impl_def_and_def_mut,
};
use bytes::Bytes;
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

#[derive(ProtoBuf, Default, Debug, Clone)]
pub struct ColorStyle {
    #[pb(index = 1)]
    pub theme_color: String,
}

#[derive(ProtoBuf, Default)]
pub struct CreateAppParams {
    #[pb(index = 1)]
    pub workspace_id: String,

    #[pb(index = 2)]
    pub name: String,

    #[pb(index = 3)]
    pub desc: String,

    #[pb(index = 4)]
    pub color_style: ColorStyle,

    #[pb(index = 5)]
    pub user_id: String,
}

impl TryInto<CreateAppParams> for CreateAppRequest {
    type Error = WorkspaceError;

    fn try_into(self) -> Result<CreateAppParams, Self::Error> {
        let name = AppName::parse(self.name)
            .map_err(|e| ErrorBuilder::new(WsErrCode::AppNameInvalid).msg(e).build())?;

        let id = WorkspaceId::parse(self.workspace_id).map_err(|e| {
            ErrorBuilder::new(WsErrCode::WorkspaceIdInvalid)
                .msg(e)
                .build()
        })?;

        let color_style = AppColorStyle::parse(self.color_style).map_err(|e| {
            ErrorBuilder::new(WsErrCode::AppColorStyleInvalid)
                .msg(e)
                .build()
        })?;

        Ok(CreateAppParams {
            workspace_id: id.0,
            name: name.0,
            desc: self.desc,
            color_style: color_style.0,
            user_id: "".to_string(),
        })
    }
}

#[derive(PartialEq, ProtoBuf, Default, Debug)]
pub struct App {
    #[pb(index = 1)]
    pub id: String,

    #[pb(index = 2)]
    pub workspace_id: String,

    #[pb(index = 3)]
    pub name: String,

    #[pb(index = 4)]
    pub desc: String,

    #[pb(index = 5)]
    pub belongings: RepeatedView,

    #[pb(index = 6)]
    pub version: i64,
}

#[derive(PartialEq, Debug, Default, ProtoBuf)]
pub struct RepeatedApp {
    #[pb(index = 1)]
    pub items: Vec<App>,
}

impl_def_and_def_mut!(RepeatedApp, App);
