use crate::{
    entities::app::ColorStyle,
    errors::ErrorCode,
    parser::app::{AppColorStyle, AppId, AppName},
};
use flowy_derive::ProtoBuf;
use std::convert::TryInto;

#[derive(ProtoBuf, Default)]
pub struct UpdateAppRequest {
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

impl TryInto<UpdateAppParams> for UpdateAppRequest {
    type Error = ErrorCode;

    fn try_into(self) -> Result<UpdateAppParams, Self::Error> {
        let app_id = AppId::parse(self.app_id)?.0;

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
