use crate::{
    entities::parser::{
        app::AppIdentify,
        view::{ViewDesc, ViewIdentify, ViewName, ViewThumbnail},
    },
    errors::ErrorCode,
    impl_def_and_def_mut,
};
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_folder_data_model::revision::{gen_view_id, ViewDataTypeRevision, ViewRevision};
use std::convert::TryInto;

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct View {
    #[pb(index = 1)]
    pub id: String,

    #[pb(index = 2)]
    pub belong_to_id: String,

    #[pb(index = 3)]
    pub name: String,

    #[pb(index = 4)]
    pub data_type: ViewDataType,

    #[pb(index = 5)]
    pub modified_time: i64,

    #[pb(index = 6)]
    pub create_time: i64,

    #[pb(index = 7)]
    pub plugin_type: i32,
}

impl std::convert::From<ViewRevision> for View {
    fn from(rev: ViewRevision) -> Self {
        View {
            id: rev.id,
            belong_to_id: rev.belong_to_id,
            name: rev.name,
            data_type: rev.data_type.into(),
            modified_time: rev.modified_time,
            create_time: rev.create_time,
            plugin_type: rev.plugin_type,
        }
    }
}

#[derive(Eq, PartialEq, Hash, Debug, ProtoBuf_Enum, Clone)]
pub enum ViewDataType {
    TextBlock = 0,
    Grid = 1,
}

impl std::default::Default for ViewDataType {
    fn default() -> Self {
        ViewDataTypeRevision::default().into()
    }
}

impl std::convert::From<ViewDataTypeRevision> for ViewDataType {
    fn from(rev: ViewDataTypeRevision) -> Self {
        match rev {
            ViewDataTypeRevision::TextBlock => ViewDataType::TextBlock,
            ViewDataTypeRevision::Grid => ViewDataType::Grid,
        }
    }
}

impl std::convert::From<ViewDataType> for ViewDataTypeRevision {
    fn from(ty: ViewDataType) -> Self {
        match ty {
            ViewDataType::TextBlock => ViewDataTypeRevision::TextBlock,
            ViewDataType::Grid => ViewDataTypeRevision::Grid,
        }
    }
}

#[derive(Eq, PartialEq, Debug, Default, ProtoBuf, Clone)]
pub struct RepeatedView {
    #[pb(index = 1)]
    pub items: Vec<View>,
}

impl_def_and_def_mut!(RepeatedView, View);

impl std::convert::From<Vec<ViewRevision>> for RepeatedView {
    fn from(values: Vec<ViewRevision>) -> Self {
        let items = values.into_iter().map(|value| value.into()).collect::<Vec<View>>();
        RepeatedView { items }
    }
}
#[derive(Default, ProtoBuf)]
pub struct RepeatedViewId {
    #[pb(index = 1)]
    pub items: Vec<String>,
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
    pub plugin_type: i32,

    #[pb(index = 7)]
    pub data: Vec<u8>,
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
    pub view_id: String,

    #[pb(index = 7)]
    pub data: Vec<u8>,

    #[pb(index = 8)]
    pub plugin_type: i32,
}

impl TryInto<CreateViewParams> for CreateViewPayload {
    type Error = ErrorCode;

    fn try_into(self) -> Result<CreateViewParams, Self::Error> {
        let name = ViewName::parse(self.name)?.0;
        let belong_to_id = AppIdentify::parse(self.belong_to_id)?.0;
        let view_id = gen_view_id();
        let thumbnail = match self.thumbnail {
            None => "".to_string(),
            Some(thumbnail) => ViewThumbnail::parse(thumbnail)?.0,
        };

        Ok(CreateViewParams {
            belong_to_id,
            name,
            desc: self.desc,
            data_type: self.data_type,
            thumbnail,
            view_id,
            data: self.data,
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

impl std::ops::Deref for ViewId {
    type Target = str;

    fn deref(&self) -> &Self::Target {
        &self.value
    }
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

#[derive(ProtoBuf_Enum)]
pub enum MoveFolderItemType {
    MoveApp = 0,
    MoveView = 1,
}

impl std::default::Default for MoveFolderItemType {
    fn default() -> Self {
        MoveFolderItemType::MoveApp
    }
}

#[derive(Default, ProtoBuf)]
pub struct MoveFolderItemPayload {
    #[pb(index = 1)]
    pub item_id: String,

    #[pb(index = 2)]
    pub from: i32,

    #[pb(index = 3)]
    pub to: i32,

    #[pb(index = 4)]
    pub ty: MoveFolderItemType,
}

pub struct MoveFolderItemParams {
    pub item_id: String,
    pub from: usize,
    pub to: usize,
    pub ty: MoveFolderItemType,
}

impl TryInto<MoveFolderItemParams> for MoveFolderItemPayload {
    type Error = ErrorCode;

    fn try_into(self) -> Result<MoveFolderItemParams, Self::Error> {
        let view_id = ViewIdentify::parse(self.item_id)?.0;
        Ok(MoveFolderItemParams {
            item_id: view_id,
            from: self.from as usize,
            to: self.to as usize,
            ty: self.ty,
        })
    }
}

// impl<'de> Deserialize<'de> for ViewDataType {
//     fn deserialize<D>(deserializer: D) -> Result<Self, <D as Deserializer<'de>>::Error>
//     where
//         D: Deserializer<'de>,
//     {
//         struct ViewTypeVisitor();
//
//         impl<'de> Visitor<'de> for ViewTypeVisitor {
//             type Value = ViewDataType;
//             fn expecting(&self, formatter: &mut std::fmt::Formatter) -> std::fmt::Result {
//                 formatter.write_str("RichText, PlainText")
//             }
//
//             fn visit_u8<E>(self, v: u8) -> Result<Self::Value, E>
//             where
//                 E: de::Error,
//             {
//                 let data_type;
//                 match v {
//                     0 => {
//                         data_type = ViewDataType::RichText;
//                     }
//                     1 => {
//                         data_type = ViewDataType::PlainText;
//                     }
//                     _ => {
//                         return Err(de::Error::invalid_value(Unexpected::Unsigned(v as u64), &self));
//                     }
//                 }
//                 Ok(data_type)
//             }
//
//             fn visit_str<E>(self, s: &str) -> Result<Self::Value, E>
//             where
//                 E: de::Error,
//             {
//                 let data_type;
//                 match s {
//                     "Doc" | "RichText" => {
//                         // Rename ViewDataType::Doc to ViewDataType::RichText, So we need to migrate the ViewType manually.
//                         data_type = ViewDataType::RichText;
//                     }
//                     "PlainText" => {
//                         data_type = ViewDataType::PlainText;
//                     }
//                     unknown => {
//                         return Err(de::Error::invalid_value(Unexpected::Str(unknown), &self));
//                     }
//                 }
//                 Ok(data_type)
//             }
//         }
//         deserializer.deserialize_any(ViewTypeVisitor())
//     }
// }
