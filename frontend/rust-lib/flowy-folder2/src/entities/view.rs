use std::collections::HashMap;
use std::convert::TryInto;
use std::ops::{Deref, DerefMut};

use collab_folder::core::{View, ViewLayout};

use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_error::ErrorCode;

use crate::entities::parser::view::{ViewDesc, ViewIdentify, ViewName, ViewThumbnail};
use crate::view_operation::gen_view_id;

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct ViewPB {
  #[pb(index = 1)]
  pub id: String,

  #[pb(index = 2)]
  pub parent_view_id: String,

  #[pb(index = 3)]
  pub name: String,

  #[pb(index = 4)]
  pub create_time: i64,

  #[pb(index = 5)]
  pub child_views: Vec<ViewPB>,

  #[pb(index = 6)]
  pub layout: ViewLayoutPB,
}

pub fn view_pb_without_child_views(view: View) -> ViewPB {
  ViewPB {
    id: view.id,
    parent_view_id: view.parent_view_id,
    name: view.name,
    create_time: view.created_at,
    child_views: Default::default(),
    layout: view.layout.into(),
  }
}

/// Returns a ViewPB with child views. Only the first level of child views are included.
pub fn view_pb_with_child_views(view: View, child_views: Vec<View>) -> ViewPB {
  ViewPB {
    id: view.id,
    parent_view_id: view.parent_view_id,
    name: view.name,
    create_time: view.created_at,
    child_views: child_views
      .into_iter()
      .map(view_pb_without_child_views)
      .collect(),
    layout: view.layout.into(),
  }
}

#[derive(Eq, PartialEq, Hash, Debug, ProtoBuf_Enum, Clone)]
pub enum ViewLayoutPB {
  Document = 0,
  Grid = 1,
  Board = 2,
  Calendar = 3,
}

impl std::default::Default for ViewLayoutPB {
  fn default() -> Self {
    ViewLayoutPB::Document
  }
}

impl ViewLayoutPB {
  pub fn is_database(&self) -> bool {
    matches!(
      self,
      ViewLayoutPB::Grid | ViewLayoutPB::Board | ViewLayoutPB::Calendar
    )
  }
}

impl std::convert::From<ViewLayout> for ViewLayoutPB {
  fn from(rev: ViewLayout) -> Self {
    match rev {
      ViewLayout::Grid => ViewLayoutPB::Grid,
      ViewLayout::Board => ViewLayoutPB::Board,
      ViewLayout::Document => ViewLayoutPB::Document,
      ViewLayout::Calendar => ViewLayoutPB::Calendar,
    }
  }
}

#[derive(Eq, PartialEq, Debug, Default, ProtoBuf, Clone)]
pub struct RepeatedViewPB {
  #[pb(index = 1)]
  pub items: Vec<ViewPB>,
}

impl std::convert::From<Vec<ViewPB>> for RepeatedViewPB {
  fn from(items: Vec<ViewPB>) -> Self {
    RepeatedViewPB { items }
  }
}

impl Deref for RepeatedViewPB {
  type Target = Vec<ViewPB>;

  fn deref(&self) -> &Self::Target {
    &self.items
  }
}

impl DerefMut for RepeatedViewPB {
  fn deref_mut(&mut self) -> &mut Self::Target {
    &mut self.items
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
  pub parent_view_id: String,

  #[pb(index = 2)]
  pub name: String,

  #[pb(index = 3)]
  pub desc: String,

  #[pb(index = 4, one_of)]
  pub thumbnail: Option<String>,

  #[pb(index = 5)]
  pub layout: ViewLayoutPB,

  #[pb(index = 6)]
  pub initial_data: Vec<u8>,

  #[pb(index = 7)]
  pub meta: HashMap<String, String>,

  /// Mark the view as current view after creation.
  #[pb(index = 8)]
  pub set_as_current: bool,
}

#[derive(Debug, Clone)]
pub struct CreateViewParams {
  pub parent_view_id: String,
  pub name: String,
  pub desc: String,
  pub layout: ViewLayoutPB,
  pub view_id: String,
  pub initial_data: Vec<u8>,
  pub meta: HashMap<String, String>,
  /// Mark the view as current view after creation.
  pub set_as_current: bool,
}

impl TryInto<CreateViewParams> for CreateViewPayloadPB {
  type Error = ErrorCode;

  fn try_into(self) -> Result<CreateViewParams, Self::Error> {
    let name = ViewName::parse(self.name)?.0;
    let belong_to_id = ViewIdentify::parse(self.parent_view_id)?.0;
    let view_id = gen_view_id();

    Ok(CreateViewParams {
      parent_view_id: belong_to_id,
      name,
      desc: self.desc,
      layout: self.layout,
      view_id,
      initial_data: self.initial_data,
      meta: self.meta,
      set_as_current: self.set_as_current,
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

#[derive(Default, ProtoBuf, Clone, Debug)]
pub struct DeletedViewPB {
  #[pb(index = 1)]
  pub view_id: String,

  #[pb(index = 2, one_of)]
  pub index: Option<i32>,
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

  #[pb(index = 5, one_of)]
  pub layout: Option<ViewLayoutPB>,
}

#[derive(Clone, Debug)]
pub struct UpdateViewParams {
  pub view_id: String,
  pub name: Option<String>,
  pub desc: Option<String>,
  pub thumbnail: Option<String>,
  pub layout: Option<ViewLayout>,
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
      layout: self.layout.map(|ty| ty.into()),
    })
  }
}

#[derive(Default, ProtoBuf)]
pub struct MoveViewPayloadPB {
  #[pb(index = 1)]
  pub view_id: String,

  #[pb(index = 2)]
  pub from: i32,

  #[pb(index = 3)]
  pub to: i32,
}

pub struct MoveViewParams {
  pub view_id: String,
  pub from: usize,
  pub to: usize,
}

impl TryInto<MoveViewParams> for MoveViewPayloadPB {
  type Error = ErrorCode;

  fn try_into(self) -> Result<MoveViewParams, Self::Error> {
    let view_id = ViewIdentify::parse(self.view_id)?.0;
    Ok(MoveViewParams {
      view_id,
      from: self.from as usize,
      to: self.to as usize,
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
