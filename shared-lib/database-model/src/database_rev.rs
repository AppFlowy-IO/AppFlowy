use crate::{DatabaseBlockRevision, LayoutSetting};
use bytes::Bytes;
use indexmap::IndexMap;
use nanoid::nanoid;
use serde::{Deserialize, Serialize};
use serde_repr::{Deserialize_repr, Serialize_repr};
use std::sync::Arc;

pub fn gen_database_id() -> String {
  // nanoid calculator https://zelark.github.io/nano-id-cc/
  format!("d:{}", nanoid!(10))
}

pub fn gen_block_id() -> String {
  format!("b:{}", nanoid!(10))
}

pub fn gen_field_id() -> String {
  nanoid!(6)
}

#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct DatabaseRevision {
  #[serde(rename = "grid_id")]
  pub database_id: String,
  pub fields: Vec<Arc<FieldRevision>>,
  pub blocks: Vec<Arc<DatabaseBlockMetaRevision>>,
}

impl DatabaseRevision {
  pub fn new(database_id: &str) -> Self {
    Self {
      database_id: database_id.to_owned(),
      fields: vec![],
      blocks: vec![],
    }
  }

  pub fn from_build_context(
    database_id: &str,
    field_revs: Vec<Arc<FieldRevision>>,
    block_metas: Vec<DatabaseBlockMetaRevision>,
  ) -> Self {
    Self {
      database_id: database_id.to_owned(),
      fields: field_revs,
      blocks: block_metas.into_iter().map(Arc::new).collect(),
    }
  }
}

#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize, Deserialize)]
pub struct DatabaseBlockMetaRevision {
  pub block_id: String,
  pub start_row_index: i32,
  pub row_count: i32,
}

impl DatabaseBlockMetaRevision {
  pub fn len(&self) -> i32 {
    self.row_count
  }

  pub fn is_empty(&self) -> bool {
    self.row_count == 0
  }
}

impl DatabaseBlockMetaRevision {
  pub fn new() -> Self {
    DatabaseBlockMetaRevision {
      block_id: gen_block_id(),
      ..Default::default()
    }
  }
}

pub struct DatabaseBlockMetaRevisionChangeset {
  pub block_id: String,
  pub start_row_index: Option<i32>,
  pub row_count: Option<i32>,
}

impl DatabaseBlockMetaRevisionChangeset {
  pub fn from_row_count(block_id: String, row_count: i32) -> Self {
    Self {
      block_id,
      start_row_index: None,
      row_count: Some(row_count),
    }
  }
}

#[derive(Debug, Clone, Default, Serialize, Deserialize, Eq, PartialEq)]
pub struct FieldRevision {
  pub id: String,

  pub name: String,

  pub desc: String,

  #[serde(rename = "field_type")]
  pub ty: FieldTypeRevision,

  pub frozen: bool,

  pub visibility: bool,

  pub width: i32,

  /// type_options contains key/value pairs
  /// key: id of the FieldType
  /// value: type-option data that can be parsed into specified TypeOptionStruct.
  ///
  /// For example, CheckboxTypeOption, MultiSelectTypeOption etc.
  #[serde(with = "indexmap::serde_seq")]
  pub type_options: IndexMap<String, String>,

  #[serde(default = "DEFAULT_IS_PRIMARY_VALUE")]
  pub is_primary: bool,
}

impl AsRef<FieldRevision> for FieldRevision {
  fn as_ref(&self) -> &FieldRevision {
    self
  }
}

const DEFAULT_IS_PRIMARY_VALUE: fn() -> bool = || false;

impl FieldRevision {
  pub fn new<T: Into<FieldTypeRevision>>(
    name: &str,
    desc: &str,
    field_type: T,
    width: i32,
    is_primary: bool,
  ) -> Self {
    Self {
      id: gen_field_id(),
      name: name.to_string(),
      desc: desc.to_string(),
      ty: field_type.into(),
      frozen: false,
      visibility: true,
      width,
      type_options: Default::default(),
      is_primary,
    }
  }

  pub fn insert_type_option<T>(&mut self, type_option: &T)
  where
    T: TypeOptionDataSerializer + ?Sized,
  {
    let id = self.ty.to_string();
    self.type_options.insert(id, type_option.json_str());
  }

  pub fn get_type_option<T: TypeOptionDataDeserializer>(
    &self,
    field_type_rev: FieldTypeRevision,
  ) -> Option<T> {
    let id = field_type_rev.to_string();
    self.type_options.get(&id).map(|s| T::from_json_str(s))
  }

  pub fn insert_type_option_str(&mut self, field_type: &FieldTypeRevision, json_str: String) {
    let id = field_type.to_string();
    self.type_options.insert(id, json_str);
  }

  pub fn get_type_option_str<T: Into<FieldTypeRevision>>(&self, field_type: T) -> Option<&str> {
    let field_type_rev = field_type.into();
    let id = field_type_rev.to_string();
    self.type_options.get(&id).map(|s| s.as_str())
  }
}

/// The macro [impl_type_option] will implement the [TypeOptionDataSerializer] for the type that
/// supports the serde trait and the TryInto<Bytes> trait.
pub trait TypeOptionDataSerializer {
  fn json_str(&self) -> String;
  fn protobuf_bytes(&self) -> Bytes;
}

/// The macro [impl_type_option] will implement the [TypeOptionDataDeserializer] for the type that
/// supports the serde trait and the TryFrom<Bytes> trait.
pub trait TypeOptionDataDeserializer {
  fn from_json_str(s: &str) -> Self;
  fn from_protobuf_bytes(bytes: Bytes) -> Self;
}

#[derive(Clone, Default, Deserialize, Serialize)]
pub struct BuildDatabaseContext {
  pub field_revs: Vec<Arc<FieldRevision>>,
  pub block_metas: Vec<DatabaseBlockMetaRevision>,
  pub blocks: Vec<DatabaseBlockRevision>,
  pub layout_setting: LayoutSetting,

  // String in JSON format. It can be deserialized into [GridViewRevision]
  pub database_view_data: String,
}

impl BuildDatabaseContext {
  pub fn new() -> Self {
    Self::default()
  }
}

impl std::convert::From<BuildDatabaseContext> for Bytes {
  fn from(ctx: BuildDatabaseContext) -> Self {
    let bytes = serde_json::to_vec(&ctx).unwrap_or_else(|_| vec![]);
    Bytes::from(bytes)
  }
}

impl std::convert::TryFrom<Bytes> for BuildDatabaseContext {
  type Error = serde_json::Error;

  fn try_from(bytes: Bytes) -> Result<Self, Self::Error> {
    let ctx: BuildDatabaseContext = serde_json::from_slice(&bytes)?;
    Ok(ctx)
  }
}

pub type FieldTypeRevision = u8;
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CalendarLayoutSetting {
  pub layout_ty: CalendarLayout,
  pub first_day_of_week: i32,
  pub show_weekends: bool,
  pub show_week_numbers: bool,
  pub layout_field_id: String,
}

impl CalendarLayoutSetting {
  pub fn new(layout_field_id: String) -> Self {
    CalendarLayoutSetting {
      layout_ty: CalendarLayout::default(),
      first_day_of_week: DEFAULT_FIRST_DAY_OF_WEEK,
      show_weekends: DEFAULT_SHOW_WEEKENDS,
      show_week_numbers: DEFAULT_SHOW_WEEK_NUMBERS,
      layout_field_id,
    }
  }
}

#[derive(Debug, Clone, Eq, PartialEq, Default, Serialize_repr, Deserialize_repr)]
#[repr(u8)]
pub enum CalendarLayout {
  #[default]
  MonthLayout = 0,
  WeekLayout = 1,
  DayLayout = 2,
}

pub const DEFAULT_FIRST_DAY_OF_WEEK: i32 = 0;
pub const DEFAULT_SHOW_WEEKENDS: bool = true;
pub const DEFAULT_SHOW_WEEK_NUMBERS: bool = true;
