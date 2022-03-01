use crate::{
    entities::trash::{Trash, TrashType},
    errors::ErrorCode,
    impl_def_and_def_mut,
    parser::{
        app::AppIdentify,
        view::{ViewDesc, ViewExtensionData, ViewIdentify, ViewName, ViewThumbnail},
    },
};
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use serde::de::Unexpected;
use serde::{de, de::Visitor, Deserializer};
use serde::{Deserialize, Serialize};
use std::convert::TryInto;

#[derive(Eq, PartialEq, ProtoBuf, Default, Debug, Clone, Serialize, Deserialize)]
pub struct View {
    #[pb(index = 1)]
    pub id: String,

    #[pb(index = 2)]
    pub belong_to_id: String,

    #[pb(index = 3)]
    pub name: String,

    #[pb(index = 4)]
    pub desc: String,

    #[pb(index = 5)]
    #[serde(default)]
    pub data_type: ViewDataType,

    #[pb(index = 6)]
    pub version: i64,

    #[pb(index = 7)]
    pub belongings: RepeatedView,

    #[pb(index = 8)]
    pub modified_time: i64,

    #[pb(index = 9)]
    pub create_time: i64,

    #[pb(index = 10)]
    pub ext_data: String,

    #[pb(index = 11)]
    pub thumbnail: String,

    #[pb(index = 12)]
    #[serde(default = "default_plugin_type")]
    pub plugin_type: i32,
}

fn default_plugin_type() -> i32 {
    0
}

#[derive(Eq, PartialEq, Debug, Default, ProtoBuf, Clone, Serialize, Deserialize)]
#[serde(transparent)]
pub struct RepeatedView {
    #[pb(index = 1)]
    pub items: Vec<View>,
}

impl_def_and_def_mut!(RepeatedView, View);

impl std::convert::From<View> for Trash {
    fn from(view: View) -> Self {
        Trash {
            id: view.id,
            name: view.name,
            modified_time: view.modified_time,
            create_time: view.create_time,
            ty: TrashType::TrashView,
        }
    }
}

#[derive(Eq, PartialEq, Debug, ProtoBuf_Enum, Clone, Serialize)]
pub enum ViewDataType {
    RichText = 0,
    PlainText = 1,
}

impl std::default::Default for ViewDataType {
    fn default() -> Self {
        ViewDataType::PlainText
    }
}

impl std::convert::From<i32> for ViewDataType {
    fn from(val: i32) -> Self {
        match val {
            0 => ViewDataType::RichText,
            1 => ViewDataType::PlainText,
            _ => {
                log::error!("Invalid view type: {}", val);
                ViewDataType::PlainText
            }
        }
    }
}

#[derive(Default, ProtoBuf)]
pub struct CreateViewPayload {
    #[pb(index = 1)]
    pub belong_to_id: String,

    #[pb(index = 2)]
    pub name: String,

    #[pb(index = 3)]
    pub desc: String,

    #[pb(index = 4, one_of)]
    pub thumbnail: Option<String>,

    #[pb(index = 5)]
    pub data_type: ViewDataType,

    #[pb(index = 6)]
    pub ext_data: String,

    #[pb(index = 7)]
    pub plugin_type: i32,
}

#[derive(Default, ProtoBuf, Debug, Clone)]
pub struct CreateViewParams {
    #[pb(index = 1)]
    pub belong_to_id: String,

    #[pb(index = 2)]
    pub name: String,

    #[pb(index = 3)]
    pub desc: String,

    #[pb(index = 4)]
    pub thumbnail: String,

    #[pb(index = 5)]
    pub data_type: ViewDataType,

    #[pb(index = 6)]
    pub ext_data: String,

    #[pb(index = 7)]
    pub view_id: String,

    #[pb(index = 8)]
    pub data: String,

    #[pb(index = 9)]
    pub plugin_type: i32,
}

impl TryInto<CreateViewParams> for CreateViewPayload {
    type Error = ErrorCode;

    fn try_into(self) -> Result<CreateViewParams, Self::Error> {
        let name = ViewName::parse(self.name)?.0;
        let belong_to_id = AppIdentify::parse(self.belong_to_id)?.0;
        let view_id = uuid::Uuid::new_v4().to_string();
        let ext_data = ViewExtensionData::parse(self.ext_data)?.0;
        let thumbnail = match self.thumbnail {
            None => "".to_string(),
            Some(thumbnail) => ViewThumbnail::parse(thumbnail)?.0,
        };
        let data = "".to_string();

        Ok(CreateViewParams {
            belong_to_id,
            name,
            desc: self.desc,
            data_type: self.data_type,
            thumbnail,
            ext_data,
            view_id,
            data,
            plugin_type: self.plugin_type,
        })
    }
}

#[derive(Default, ProtoBuf, Clone, Debug)]
pub struct ViewId {
    #[pb(index = 1)]
    pub value: String,
}

impl std::convert::From<&str> for ViewId {
    fn from(value: &str) -> Self {
        ViewId {
            value: value.to_string(),
        }
    }
}

#[derive(Default, ProtoBuf)]
pub struct RepeatedViewId {
    #[pb(index = 1)]
    pub items: Vec<String>,
}

#[derive(Default, ProtoBuf)]
pub struct UpdateViewPayload {
    #[pb(index = 1)]
    pub view_id: String,

    #[pb(index = 2, one_of)]
    pub name: Option<String>,

    #[pb(index = 3, one_of)]
    pub desc: Option<String>,

    #[pb(index = 4, one_of)]
    pub thumbnail: Option<String>,
}

#[derive(Default, ProtoBuf, Clone, Debug)]
pub struct UpdateViewParams {
    #[pb(index = 1)]
    pub view_id: String,

    #[pb(index = 2, one_of)]
    pub name: Option<String>,

    #[pb(index = 3, one_of)]
    pub desc: Option<String>,

    #[pb(index = 4, one_of)]
    pub thumbnail: Option<String>,
}

impl UpdateViewParams {
    pub fn new(view_id: &str) -> Self {
        Self {
            view_id: view_id.to_owned(),
            ..Default::default()
        }
    }

    pub fn name(mut self, name: &str) -> Self {
        self.name = Some(name.to_owned());
        self
    }

    pub fn desc(mut self, desc: &str) -> Self {
        self.desc = Some(desc.to_owned());
        self
    }
}

impl TryInto<UpdateViewParams> for UpdateViewPayload {
    type Error = ErrorCode;

    fn try_into(self) -> Result<UpdateViewParams, Self::Error> {
        let view_id = ViewIdentify::parse(self.view_id)?.0;

        let name = match self.name {
            None => None,
            Some(name) => Some(ViewName::parse(name)?.0),
        };

        let desc = match self.desc {
            None => None,
            Some(desc) => Some(ViewDesc::parse(desc)?.0),
        };

        let thumbnail = match self.thumbnail {
            None => None,
            Some(thumbnail) => Some(ViewThumbnail::parse(thumbnail)?.0),
        };

        Ok(UpdateViewParams {
            view_id,
            name,
            desc,
            thumbnail,
        })
    }
}

impl<'de> Deserialize<'de> for ViewDataType {
    fn deserialize<D>(deserializer: D) -> Result<Self, <D as Deserializer<'de>>::Error>
    where
        D: Deserializer<'de>,
    {
        struct ViewTypeVisitor();

        impl<'de> Visitor<'de> for ViewTypeVisitor {
            type Value = ViewDataType;
            fn expecting(&self, formatter: &mut std::fmt::Formatter) -> std::fmt::Result {
                formatter.write_str("Plugin, RichText")
            }

            fn visit_str<E>(self, s: &str) -> Result<Self::Value, E>
            where
                E: de::Error,
            {
                let view_type;
                match s {
                    "Doc" | "RichText" => {
                        // Rename ViewType::Doc to ViewType::RichText, So we need to migrate the ViewType manually.
                        view_type = ViewDataType::RichText;
                    }
                    "Plugin" => {
                        view_type = ViewDataType::PlainText;
                    }
                    unknown => {
                        return Err(de::Error::invalid_value(Unexpected::Str(unknown), &self));
                    }
                }
                Ok(view_type)
            }
        }
        deserializer.deserialize_any(ViewTypeVisitor())
    }
}
