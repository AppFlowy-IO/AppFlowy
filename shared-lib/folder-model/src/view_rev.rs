use crate::{TrashRevision, TrashTypeRevision};
use nanoid::nanoid;
use serde::{Deserialize, Serialize};
use serde_repr::*;
pub fn gen_view_id() -> String {
  format!("v:{}", nanoid!(10))
}

#[derive(Default, Clone, Debug, Eq, PartialEq, Serialize, Deserialize)]
pub struct ViewRevision {
  pub id: String,

  #[serde(rename = "belong_to_id")]
  pub app_id: String,

  pub name: String,

  pub desc: String,

  #[serde(default)]
  #[serde(rename = "data_type")]
  pub data_format: ViewDataFormatRevision,

  // #[deprecated]
  version: i64,

  pub belongings: Vec<ViewRevision>,

  #[serde(default)]
  pub modified_time: i64,

  #[serde(default)]
  pub create_time: i64,

  #[serde(default)]
  pub ext_data: String,

  #[serde(default)]
  pub thumbnail: String,

  #[serde(default = "DEFAULT_PLUGIN_TYPE")]
  #[serde(rename = "plugin_type")]
  pub layout: ViewLayoutTypeRevision,
}

impl ViewRevision {
  #[allow(clippy::too_many_arguments)]
  pub fn new(
    id: String,
    app_id: String,
    name: String,
    desc: String,
    data_format: ViewDataFormatRevision,
    layout: ViewLayoutTypeRevision,
    create_time: i64,
    modified_time: i64,
  ) -> Self {
    Self {
      id,
      app_id,
      name,
      desc,
      data_format,
      version: 0,
      belongings: vec![],
      modified_time,
      create_time,
      ext_data: "".to_string(),
      thumbnail: "".to_string(),
      layout,
    }
  }
}

const DEFAULT_PLUGIN_TYPE: fn() -> ViewLayoutTypeRevision = || ViewLayoutTypeRevision::Document;

impl std::convert::From<ViewRevision> for TrashRevision {
  fn from(view_rev: ViewRevision) -> Self {
    TrashRevision {
      id: view_rev.id,
      name: view_rev.name,
      modified_time: view_rev.modified_time,
      create_time: view_rev.create_time,
      ty: TrashTypeRevision::TrashView,
    }
  }
}

#[derive(Eq, PartialEq, Debug, Clone, Serialize_repr, Deserialize_repr)]
#[repr(u8)]
pub enum ViewDataFormatRevision {
  DeltaFormat = 0,
  DatabaseFormat = 1,
  NodeFormat = 2,
}

impl std::default::Default for ViewDataFormatRevision {
  fn default() -> Self {
    ViewDataFormatRevision::DeltaFormat
  }
}

#[derive(Eq, PartialEq, Debug, Clone, Serialize_repr, Deserialize_repr)]
#[repr(u8)]
pub enum ViewLayoutTypeRevision {
  Document = 0,
  // The for historical reasons, the value of Grid is not 1.
  Grid = 3,
  Board = 4,
  Calendar = 5,
}

impl std::default::Default for ViewLayoutTypeRevision {
  fn default() -> Self {
    ViewLayoutTypeRevision::Document
  }
}
