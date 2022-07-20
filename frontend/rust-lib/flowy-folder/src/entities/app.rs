use crate::{
    entities::parser::{
        app::{AppColorStyle, AppIdentify, AppName},
        workspace::WorkspaceIdentify,
    },
    entities::view::RepeatedViewPB,
    errors::ErrorCode,
    impl_def_and_def_mut,
};
use flowy_derive::ProtoBuf;
use flowy_folder_data_model::revision::AppRevision;
use std::convert::TryInto;

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct AppPB {
    #[pb(index = 1)]
    pub id: String,

    #[pb(index = 2)]
    pub workspace_id: String,

    #[pb(index = 3)]
    pub name: String,

    #[pb(index = 4)]
    pub desc: String,

    #[pb(index = 5)]
    pub belongings: RepeatedViewPB,

    #[pb(index = 6)]
    pub version: i64,

    #[pb(index = 7)]
    pub modified_time: i64,

    #[pb(index = 8)]
    pub create_time: i64,
}

impl std::convert::From<AppRevision> for AppPB {
    fn from(app_serde: AppRevision) -> Self {
        AppPB {
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
pub struct RepeatedAppPB {
    #[pb(index = 1)]
    pub items: Vec<AppPB>,
}

impl_def_and_def_mut!(RepeatedAppPB, AppPB);

impl std::convert::From<Vec<AppRevision>> for RepeatedAppPB {
    fn from(values: Vec<AppRevision>) -> Self {
        let items = values.into_iter().map(|value| value.into()).collect::<Vec<AppPB>>();
        RepeatedAppPB { items }
    }
}
#[derive(ProtoBuf, Default)]
pub struct CreateAppPayloadPB {
    #[pb(index = 1)]
    pub workspace_id: String,

    #[pb(index = 2)]
    pub name: String,

    #[pb(index = 3)]
    pub desc: String,

    #[pb(index = 4)]
    pub color_style: ColorStylePB,
}

#[derive(ProtoBuf, Default, Debug, Clone)]
pub struct ColorStylePB {
    #[pb(index = 1)]
    pub theme_color: String,
}

#[derive(Debug)]
pub struct CreateAppParams {
    pub workspace_id: String,
    pub name: String,
    pub desc: String,
    pub color_style: ColorStylePB,
}

impl TryInto<CreateAppParams> for CreateAppPayloadPB {
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

impl std::convert::From<AppColorStyle> for ColorStylePB {
    fn from(data: AppColorStyle) -> Self {
        ColorStylePB {
            theme_color: data.theme_color,
        }
    }
}

#[derive(ProtoBuf, Default, Clone, Debug)]
pub struct AppIdPB {
    #[pb(index = 1)]
    pub value: String,
}

impl AppIdPB {
    pub fn new(app_id: &str) -> Self {
        Self {
            value: app_id.to_string(),
        }
    }
}

#[derive(ProtoBuf, Default)]
pub struct UpdateAppPayloadPB {
    #[pb(index = 1)]
    pub app_id: String,

    #[pb(index = 2, one_of)]
    pub name: Option<String>,

    #[pb(index = 3, one_of)]
    pub desc: Option<String>,

    #[pb(index = 4, one_of)]
    pub color_style: Option<ColorStylePB>,

    #[pb(index = 5, one_of)]
    pub is_trash: Option<bool>,
}

#[derive(Debug, Clone)]
pub struct UpdateAppParams {
    pub app_id: String,

    pub name: Option<String>,

    pub desc: Option<String>,

    pub color_style: Option<ColorStylePB>,

    pub is_trash: Option<bool>,
}

impl UpdateAppParams {
    pub fn new(app_id: &str) -> Self {
        Self {
            app_id: app_id.to_string(),
            name: None,
            desc: None,
            color_style: None,
            is_trash: None,
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

impl TryInto<UpdateAppParams> for UpdateAppPayloadPB {
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
