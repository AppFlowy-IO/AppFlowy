use crate::{
    entities::view::RepeatedView,
    errors::*,
    impl_def_and_def_mut,
    parser::{
        app::{AppColorStyle, AppName},
        workspace::WorkspaceId,
    },
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

#[derive(ProtoBuf, Default, Debug, Clone)]
pub struct ColorStyle {
    #[pb(index = 1)]
    pub theme_color: String,
}

#[derive(ProtoBuf, Default, Debug)]
pub struct CreateAppParams {
    #[pb(index = 1)]
    pub workspace_id: String,

    #[pb(index = 2)]
    pub name: String,

    #[pb(index = 3)]
    pub desc: String,

    #[pb(index = 4)]
    pub color_style: ColorStyle,
}

impl TryInto<CreateAppParams> for CreateAppRequest {
    type Error = ErrorCode;

    fn try_into(self) -> Result<CreateAppParams, Self::Error> {
        let name = AppName::parse(self.name)?;
        let id = WorkspaceId::parse(self.workspace_id)?;
        let color_style = AppColorStyle::parse(self.color_style.theme_color.clone())?;

        Ok(CreateAppParams {
            workspace_id: id.0,
            name: name.0,
            desc: self.desc,
            color_style: color_style.into(),
        })
    }
}

impl std::convert::From<AppColorStyle> for ColorStyle {
    fn from(data: AppColorStyle) -> Self {
        ColorStyle {
            theme_color: data.theme_color,
        }
    }
}

#[derive(PartialEq, ProtoBuf, Default, Debug, Clone)]
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

    #[pb(index = 7)]
    pub modified_time: i64,

    #[pb(index = 8)]
    pub create_time: i64,
}

impl App {
    pub fn take_belongings(&mut self) -> RepeatedView { std::mem::take(&mut self.belongings) }
}

#[derive(PartialEq, Debug, Default, ProtoBuf, Clone)]
pub struct RepeatedApp {
    #[pb(index = 1)]
    pub items: Vec<App>,
}

impl_def_and_def_mut!(RepeatedApp, App);
