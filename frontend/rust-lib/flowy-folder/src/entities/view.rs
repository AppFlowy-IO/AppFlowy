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
pub struct ViewPB {
    #[pb(index = 1)]
    pub id: String,

    #[pb(index = 2)]
    pub app_id: String,

    #[pb(index = 3)]
    pub name: String,

    #[pb(index = 4)]
    pub data_type: ViewDataTypePB,

    #[pb(index = 5)]
    pub modified_time: i64,

    #[pb(index = 6)]
    pub create_time: i64,

    #[pb(index = 7)]
    pub plugin_type: i32,
}

impl std::convert::From<ViewRevision> for ViewPB {
    fn from(rev: ViewRevision) -> Self {
        ViewPB {
            id: rev.id,
            app_id: rev.app_id,
            name: rev.name,
            data_type: rev.data_type.into(),
            modified_time: rev.modified_time,
            create_time: rev.create_time,
            plugin_type: rev.plugin_type,
        }
    }
}

#[derive(Eq, PartialEq, Hash, Debug, ProtoBuf_Enum, Clone)]
pub enum ViewDataTypePB {
    Document = 0,
    Database = 1,
}

impl std::default::Default for ViewDataTypePB {
    fn default() -> Self {
        ViewDataTypeRevision::default().into()
    }
}

impl std::convert::From<ViewDataTypeRevision> for ViewDataTypePB {
    fn from(rev: ViewDataTypeRevision) -> Self {
        match rev {
            ViewDataTypeRevision::Document => ViewDataTypePB::Document,
            ViewDataTypeRevision::Database => ViewDataTypePB::Database,
        }
    }
}

impl std::convert::From<ViewDataTypePB> for ViewDataTypeRevision {
    fn from(ty: ViewDataTypePB) -> Self {
        match ty {
            ViewDataTypePB::Document => ViewDataTypeRevision::Document,
            ViewDataTypePB::Database => ViewDataTypeRevision::Database,
        }
    }
}

#[derive(Eq, PartialEq, Hash, Debug, ProtoBuf_Enum, Clone)]
pub enum ViewLayoutTypePB {
    Grid = 0,
    Board = 1,
}

impl std::default::Default for ViewLayoutTypePB {
    fn default() -> Self {
        ViewLayoutTypePB::Grid
    }
}

#[derive(Eq, PartialEq, Debug, Default, ProtoBuf, Clone)]
pub struct RepeatedViewPB {
    #[pb(index = 1)]
    pub items: Vec<ViewPB>,
}

impl_def_and_def_mut!(RepeatedViewPB, ViewPB);

impl std::convert::From<Vec<ViewRevision>> for RepeatedViewPB {
    fn from(values: Vec<ViewRevision>) -> Self {
        let items = values.into_iter().map(|value| value.into()).collect::<Vec<ViewPB>>();
        RepeatedViewPB { items }
    }
}
#[derive(Default, ProtoBuf)]
pub struct RepeatedViewIdPB {
    #[pb(index = 1)]
    pub items: Vec<String>,
}

#[derive(Default, ProtoBuf)]
pub struct CreateViewPayloadPB {
    #[pb(index = 1)]
    pub belong_to_id: String,

    #[pb(index = 2)]
    pub name: String,

    #[pb(index = 3)]
    pub desc: String,

    #[pb(index = 4, one_of)]
    pub thumbnail: Option<String>,

    #[pb(index = 5)]
    pub data_type: ViewDataTypePB,

    #[pb(index = 6)]
    pub layout: ViewLayoutTypePB,

    #[pb(index = 7)]
    pub plugin_type: i32,

    #[pb(index = 8)]
    pub view_content_data: Vec<u8>,
}

#[derive(Debug, Clone)]
pub struct CreateViewParams {
    pub belong_to_id: String,
    pub name: String,
    pub desc: String,
    pub thumbnail: String,
    pub data_type: ViewDataTypePB,
    pub layout: ViewLayoutTypePB,
    pub view_id: String,
    pub view_content_data: Vec<u8>,
    pub plugin_type: i32,
}

impl TryInto<CreateViewParams> for CreateViewPayloadPB {
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
            layout: self.layout,
            thumbnail,
            view_id,
            view_content_data: self.view_content_data,
            plugin_type: self.plugin_type,
        })
    }
}

#[derive(Default, ProtoBuf, Clone, Debug)]
pub struct ViewIdPB {
    #[pb(index = 1)]
    pub value: String,
}

impl std::convert::From<&str> for ViewIdPB {
    fn from(value: &str) -> Self {
        ViewIdPB {
            value: value.to_string(),
        }
    }
}

impl std::ops::Deref for ViewIdPB {
    type Target = str;

    fn deref(&self) -> &Self::Target {
        &self.value
    }
}

#[derive(Default, ProtoBuf)]
pub struct UpdateViewPayloadPB {
    #[pb(index = 1)]
    pub view_id: String,

    #[pb(index = 2, one_of)]
    pub name: Option<String>,

    #[pb(index = 3, one_of)]
    pub desc: Option<String>,

    #[pb(index = 4, one_of)]
    pub thumbnail: Option<String>,
}

#[derive(Clone, Debug)]
pub struct UpdateViewParams {
    pub view_id: String,
    pub name: Option<String>,
    pub desc: Option<String>,
    pub thumbnail: Option<String>,
}

impl TryInto<UpdateViewParams> for UpdateViewPayloadPB {
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
pub struct MoveFolderItemPayloadPB {
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

impl TryInto<MoveFolderItemParams> for MoveFolderItemPayloadPB {
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
