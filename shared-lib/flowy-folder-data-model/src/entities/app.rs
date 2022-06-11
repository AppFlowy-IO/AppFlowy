use crate::entities::view::ViewSerde;
use crate::{
    entities::view::RepeatedView,
    errors::ErrorCode,
    impl_def_and_def_mut,
    parser::{
        app::{AppColorStyle, AppIdentify, AppName},
        workspace::WorkspaceIdentify,
    },
};
use flowy_derive::ProtoBuf;
use nanoid::nanoid;
use serde::{Deserialize, Serialize};
use std::convert::TryInto;

pub fn gen_app_id() -> String {
    nanoid!(10)
}
#[derive(Eq, PartialEq, ProtoBuf, Default, Debug, Clone)]
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

#[derive(Serialize, Deserialize)]
pub struct AppSerde {
    pub id: String,

    pub workspace_id: String,

    pub name: String,

    pub desc: String,

    pub belongings: Vec<ViewSerde>,

    pub version: i64,

    pub modified_time: i64,

    pub create_time: i64,
}

impl std::convert::From<AppSerde> for App {
    fn from(app_serde: AppSerde) -> Self {
        App {
            id: app_serde.id,
            workspace_id: app_serde.workspace_id,
            name: app_serde.name,
            desc: app_serde.desc,
            belongings: app_serde.belongings.into(),
            version: app_serde.version,
            modified_time: app_serde.modified_time,
            create_time: app_serde.create_time,
        }
    }
}

#[derive(Eq, PartialEq, Debug, Default, ProtoBuf, Clone)]
pub struct RepeatedApp {
    #[pb(index = 1)]
    pub items: Vec<App>,
}

impl_def_and_def_mut!(RepeatedApp, App);

impl std::convert::From<Vec<AppSerde>> for RepeatedApp {
    fn from(values: Vec<AppSerde>) -> Self {
        let items = values.into_iter().map(|value| value.into()).collect::<Vec<App>>();
        RepeatedApp { items }
    }
}

#[derive(ProtoBuf, Default)]
pub struct CreateAppPayload {
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

impl TryInto<CreateAppParams> for CreateAppPayload {
    type Error = ErrorCode;

    fn try_into(self) -> Result<CreateAppParams, Self::Error> {
        let name = AppName::parse(self.name)?;
        let id = WorkspaceIdentify::parse(self.workspace_id)?;
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

#[derive(ProtoBuf, Default, Clone, Debug)]
pub struct AppId {
    #[pb(index = 1)]
    pub value: String,
}

impl AppId {
    pub fn new(app_id: &str) -> Self {
        Self {
            value: app_id.to_string(),
        }
    }
}

#[derive(ProtoBuf, Default)]
pub struct UpdateAppPayload {
    #[pb(index = 1)]
    pub app_id: String,

    #[pb(index = 2, one_of)]
    pub name: Option<String>,

    #[pb(index = 3, one_of)]
    pub desc: Option<String>,

    #[pb(index = 4, one_of)]
    pub color_style: Option<ColorStyle>,

    #[pb(index = 5, one_of)]
    pub is_trash: Option<bool>,
}

#[derive(ProtoBuf, Default, Clone, Debug)]
pub struct UpdateAppParams {
    #[pb(index = 1)]
    pub app_id: String,

    #[pb(index = 2, one_of)]
    pub name: Option<String>,

    #[pb(index = 3, one_of)]
    pub desc: Option<String>,

    #[pb(index = 4, one_of)]
    pub color_style: Option<ColorStyle>,

    #[pb(index = 5, one_of)]
    pub is_trash: Option<bool>,
}

impl UpdateAppParams {
    pub fn new(app_id: &str) -> Self {
        Self {
            app_id: app_id.to_string(),
            ..Default::default()
        }
    }

    pub fn name(mut self, name: &str) -> Self {
        self.name = Some(name.to_string());
        self
    }

    pub fn desc(mut self, desc: &str) -> Self {
        self.desc = Some(desc.to_string());
        self
    }

    pub fn trash(mut self) -> Self {
        self.is_trash = Some(true);
        self
    }
}

impl TryInto<UpdateAppParams> for UpdateAppPayload {
    type Error = ErrorCode;

    fn try_into(self) -> Result<UpdateAppParams, Self::Error> {
        let app_id = AppIdentify::parse(self.app_id)?.0;

        let name = match self.name {
            None => None,
            Some(name) => Some(AppName::parse(name)?.0),
        };

        let color_style = match self.color_style {
            None => None,
            Some(color_style) => Some(AppColorStyle::parse(color_style.theme_color)?.into()),
        };

        Ok(UpdateAppParams {
            app_id,
            name,
            desc: self.desc,
            color_style,
            is_trash: self.is_trash,
        })
    }
}
