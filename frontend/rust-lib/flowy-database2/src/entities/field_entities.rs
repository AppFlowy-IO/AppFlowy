#![allow(clippy::upper_case_acronyms)]

use std::fmt::{Display, Formatter};
use std::sync::Arc;

use collab_database::fields::Field;
use collab_database::views::FieldOrder;
use serde_repr::*;
use strum_macros::{EnumCount as EnumCountMacro, EnumIter};

use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_error::ErrorCode;

use crate::entities::parser::NotEmptyStr;
use crate::impl_into_field_type;

/// [FieldPB] defines a Field's attributes. Such as the name, field_type, and width. etc.
#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct FieldPB {
  #[pb(index = 1)]
  pub id: String,

  #[pb(index = 2)]
  pub name: String,

  #[pb(index = 3)]
  pub field_type: FieldType,

  #[pb(index = 4)]
  pub visibility: bool,

  #[pb(index = 5)]
  pub width: i32,

  #[pb(index = 6)]
  pub is_primary: bool,
}

impl std::convert::From<Field> for FieldPB {
  fn from(field: Field) -> Self {
    Self {
      id: field.id,
      name: field.name,
      field_type: FieldType::from(field.field_type),
      visibility: field.visibility,
      width: field.width as i32,
      is_primary: field.is_primary,
    }
  }
}

/// [FieldIdPB] id of the [Field]
#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct FieldIdPB {
  #[pb(index = 1)]
  pub field_id: String,
}

impl std::convert::From<&str> for FieldIdPB {
  fn from(s: &str) -> Self {
    FieldIdPB {
      field_id: s.to_owned(),
    }
  }
}

impl std::convert::From<String> for FieldIdPB {
  fn from(s: String) -> Self {
    FieldIdPB { field_id: s }
  }
}

impl From<FieldOrder> for FieldIdPB {
  fn from(field_order: FieldOrder) -> Self {
    Self {
      field_id: field_order.id,
    }
  }
}

impl std::convert::From<&Arc<Field>> for FieldIdPB {
  fn from(field_rev: &Arc<Field>) -> Self {
    Self {
      field_id: field_rev.id.clone(),
    }
  }
}
#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct DatabaseFieldChangesetPB {
  #[pb(index = 1)]
  pub view_id: String,

  #[pb(index = 2)]
  pub inserted_fields: Vec<IndexFieldPB>,

  #[pb(index = 3)]
  pub deleted_fields: Vec<FieldIdPB>,

  #[pb(index = 4)]
  pub updated_fields: Vec<FieldPB>,
}

impl DatabaseFieldChangesetPB {
  pub fn insert(database_id: &str, inserted_fields: Vec<IndexFieldPB>) -> Self {
    Self {
      view_id: database_id.to_owned(),
      inserted_fields,
      deleted_fields: vec![],
      updated_fields: vec![],
    }
  }

  pub fn delete(database_id: &str, deleted_fields: Vec<FieldIdPB>) -> Self {
    Self {
      view_id: database_id.to_string(),
      inserted_fields: vec![],
      deleted_fields,
      updated_fields: vec![],
    }
  }

  pub fn update(database_id: &str, updated_fields: Vec<FieldPB>) -> Self {
    Self {
      view_id: database_id.to_string(),
      inserted_fields: vec![],
      deleted_fields: vec![],
      updated_fields,
    }
  }
}

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct IndexFieldPB {
  #[pb(index = 1)]
  pub field: FieldPB,

  #[pb(index = 2)]
  pub index: i32,
}

impl IndexFieldPB {
  pub fn from_field(field: Field, index: usize) -> Self {
    Self {
      field: FieldPB::from(field),
      index: index as i32,
    }
  }
}

#[derive(Debug, Default, ProtoBuf)]
pub struct CreateFieldPayloadPB {
  #[pb(index = 1)]
  pub view_id: String,

  #[pb(index = 2)]
  pub field_type: FieldType,

  /// If the type_option_data is not empty, it will be used to create the field.
  /// Otherwise, the default value will be used.
  #[pb(index = 3, one_of)]
  pub type_option_data: Option<Vec<u8>>,
}

#[derive(Clone)]
pub struct CreateFieldParams {
  pub view_id: String,
  pub field_type: FieldType,
  /// If the type_option_data is not empty, it will be used to create the field.
  /// Otherwise, the default value will be used.
  pub type_option_data: Option<Vec<u8>>,
}

impl TryInto<CreateFieldParams> for CreateFieldPayloadPB {
  type Error = ErrorCode;

  fn try_into(self) -> Result<CreateFieldParams, Self::Error> {
    let view_id = NotEmptyStr::parse(self.view_id).map_err(|_| ErrorCode::DatabaseIdIsEmpty)?;
    Ok(CreateFieldParams {
      view_id: view_id.0,
      field_type: self.field_type,
      type_option_data: self.type_option_data,
    })
  }
}

#[derive(Debug, Default, ProtoBuf)]
pub struct UpdateFieldTypePayloadPB {
  #[pb(index = 1)]
  pub view_id: String,

  #[pb(index = 2)]
  pub field_id: String,

  #[pb(index = 3)]
  pub field_type: FieldType,
}

pub struct EditFieldParams {
  pub view_id: String,
  pub field_id: String,
  pub field_type: FieldType,
}

impl TryInto<EditFieldParams> for UpdateFieldTypePayloadPB {
  type Error = ErrorCode;

  fn try_into(self) -> Result<EditFieldParams, Self::Error> {
    let view_id = NotEmptyStr::parse(self.view_id).map_err(|_| ErrorCode::DatabaseIdIsEmpty)?;
    let field_id = NotEmptyStr::parse(self.field_id).map_err(|_| ErrorCode::FieldIdIsEmpty)?;
    Ok(EditFieldParams {
      view_id: view_id.0,
      field_id: field_id.0,
      field_type: self.field_type,
    })
  }
}

#[derive(Debug, Default, ProtoBuf)]
pub struct TypeOptionPathPB {
  #[pb(index = 1)]
  pub view_id: String,

  #[pb(index = 2)]
  pub field_id: String,

  #[pb(index = 3)]
  pub field_type: FieldType,
}

pub struct TypeOptionPathParams {
  pub view_id: String,
  pub field_id: String,
  pub field_type: FieldType,
}

impl TryInto<TypeOptionPathParams> for TypeOptionPathPB {
  type Error = ErrorCode;

  fn try_into(self) -> Result<TypeOptionPathParams, Self::Error> {
    let database_id = NotEmptyStr::parse(self.view_id).map_err(|_| ErrorCode::DatabaseIdIsEmpty)?;
    let field_id = NotEmptyStr::parse(self.field_id).map_err(|_| ErrorCode::FieldIdIsEmpty)?;
    Ok(TypeOptionPathParams {
      view_id: database_id.0,
      field_id: field_id.0,
      field_type: self.field_type,
    })
  }
}

#[derive(Debug, Default, ProtoBuf)]
pub struct TypeOptionPB {
  #[pb(index = 1)]
  pub view_id: String,

  #[pb(index = 2)]
  pub field: FieldPB,

  #[pb(index = 3)]
  pub type_option_data: Vec<u8>,
}

/// Collection of the [FieldPB]
#[derive(Debug, Default, ProtoBuf)]
pub struct RepeatedFieldPB {
  #[pb(index = 1)]
  pub items: Vec<FieldPB>,
}
impl std::ops::Deref for RepeatedFieldPB {
  type Target = Vec<FieldPB>;
  fn deref(&self) -> &Self::Target {
    &self.items
  }
}

impl std::ops::DerefMut for RepeatedFieldPB {
  fn deref_mut(&mut self) -> &mut Self::Target {
    &mut self.items
  }
}

impl std::convert::From<Vec<FieldPB>> for RepeatedFieldPB {
  fn from(items: Vec<FieldPB>) -> Self {
    Self { items }
  }
}

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct RepeatedFieldIdPB {
  #[pb(index = 1)]
  pub items: Vec<FieldIdPB>,
}

impl std::ops::Deref for RepeatedFieldIdPB {
  type Target = Vec<FieldIdPB>;
  fn deref(&self) -> &Self::Target {
    &self.items
  }
}

impl std::convert::From<Vec<FieldIdPB>> for RepeatedFieldIdPB {
  fn from(items: Vec<FieldIdPB>) -> Self {
    RepeatedFieldIdPB { items }
  }
}

impl std::convert::From<String> for RepeatedFieldIdPB {
  fn from(s: String) -> Self {
    RepeatedFieldIdPB {
      items: vec![FieldIdPB::from(s)],
    }
  }
}

/// [TypeOptionChangesetPB] is used to update the type-option data.
#[derive(ProtoBuf, Default)]
pub struct TypeOptionChangesetPB {
  #[pb(index = 1)]
  pub view_id: String,

  #[pb(index = 2)]
  pub field_id: String,

  /// Check out [TypeOptionPB] for more details.
  #[pb(index = 3)]
  pub type_option_data: Vec<u8>,
}

#[derive(Clone)]
pub struct TypeOptionChangesetParams {
  pub view_id: String,
  pub field_id: String,
  pub type_option_data: Vec<u8>,
}

impl TryInto<TypeOptionChangesetParams> for TypeOptionChangesetPB {
  type Error = ErrorCode;

  fn try_into(self) -> Result<TypeOptionChangesetParams, Self::Error> {
    let view_id = NotEmptyStr::parse(self.view_id).map_err(|_| ErrorCode::DatabaseIdIsEmpty)?;
    let _ = NotEmptyStr::parse(self.field_id.clone()).map_err(|_| ErrorCode::FieldIdIsEmpty)?;

    Ok(TypeOptionChangesetParams {
      view_id: view_id.0,
      field_id: self.field_id,
      type_option_data: self.type_option_data,
    })
  }
}

#[derive(ProtoBuf, Default)]
pub struct GetFieldPayloadPB {
  #[pb(index = 1)]
  pub view_id: String,

  #[pb(index = 2, one_of)]
  pub field_ids: Option<RepeatedFieldIdPB>,
}

pub struct GetFieldParams {
  pub view_id: String,
  pub field_ids: Option<Vec<String>>,
}

impl TryInto<GetFieldParams> for GetFieldPayloadPB {
  type Error = ErrorCode;

  fn try_into(self) -> Result<GetFieldParams, Self::Error> {
    let view_id = NotEmptyStr::parse(self.view_id).map_err(|_| ErrorCode::DatabaseIdIsEmpty)?;
    let field_ids = self.field_ids.map(|repeated| {
      repeated
        .items
        .into_iter()
        .map(|item| item.field_id)
        .collect::<Vec<String>>()
    });

    Ok(GetFieldParams {
      view_id: view_id.0,
      field_ids,
    })
  }
}

/// [FieldChangesetPB] is used to modify the corresponding field. It defines which properties of
/// the field can be modified.
///
/// Pass in None if you don't want to modify a property
/// Pass in Some(Value) if you want to modify a property
///
#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct FieldChangesetPB {
  #[pb(index = 1)]
  pub field_id: String,

  #[pb(index = 2)]
  pub view_id: String,

  #[pb(index = 3, one_of)]
  pub name: Option<String>,

  #[pb(index = 4, one_of)]
  pub desc: Option<String>,

  #[pb(index = 5, one_of)]
  pub frozen: Option<bool>,

  #[pb(index = 6, one_of)]
  pub visibility: Option<bool>,

  #[pb(index = 7, one_of)]
  pub width: Option<i32>,
}

impl TryInto<FieldChangesetParams> for FieldChangesetPB {
  type Error = ErrorCode;

  fn try_into(self) -> Result<FieldChangesetParams, Self::Error> {
    let view_id = NotEmptyStr::parse(self.view_id).map_err(|_| ErrorCode::DatabaseIdIsEmpty)?;
    let field_id = NotEmptyStr::parse(self.field_id).map_err(|_| ErrorCode::FieldIdIsEmpty)?;
    // if let Some(type_option_data) = self.type_option_data.as_ref() {
    //     if type_option_data.is_empty() {
    //         return Err(ErrorCode::TypeOptionDataIsEmpty);
    //     }
    // }

    Ok(FieldChangesetParams {
      field_id: field_id.0,
      view_id: view_id.0,
      name: self.name,
      desc: self.desc,
      frozen: self.frozen,
      visibility: self.visibility,
      width: self.width,
      // type_option_data: self.type_option_data,
    })
  }
}

#[derive(Debug, Clone, Default)]
pub struct FieldChangesetParams {
  pub field_id: String,

  pub view_id: String,

  pub name: Option<String>,

  pub desc: Option<String>,

  pub frozen: Option<bool>,

  pub visibility: Option<bool>,

  pub width: Option<i32>,
  // pub type_option_data: Option<Vec<u8>>,
}
/// Certain field types have user-defined options such as color, date format, number format,
/// or a list of values for a multi-select list. These options are defined within a specialization
/// of the FieldTypeOption class.
///
/// You could check [this](https://appflowy.gitbook.io/docs/essential-documentation/contribute-to-appflowy/architecture/frontend/grid#fieldtype)
/// for more information.
///
/// The order of the enum can't be changed. If you want to add a new type,
/// it would be better to append it to the end of the list.
#[derive(
  Debug,
  Clone,
  PartialEq,
  Hash,
  Eq,
  ProtoBuf_Enum,
  EnumCountMacro,
  EnumIter,
  Serialize_repr,
  Deserialize_repr,
)]
#[repr(u8)]
#[derive(Default)]
pub enum FieldType {
  #[default]
  RichText = 0,
  Number = 1,
  DateTime = 2,
  SingleSelect = 3,
  MultiSelect = 4,
  Checkbox = 5,
  URL = 6,
  Checklist = 7,
  LastEditedTime = 8,
  CreatedTime = 9,
}

impl Display for FieldType {
  fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
    let value: i64 = self.clone().into();
    f.write_fmt(format_args!("{}", value))
  }
}

impl AsRef<FieldType> for FieldType {
  fn as_ref(&self) -> &FieldType {
    self
  }
}

impl From<&FieldType> for FieldType {
  fn from(field_type: &FieldType) -> Self {
    field_type.clone()
  }
}

impl FieldType {
  pub fn value(&self) -> i64 {
    self.clone().into()
  }

  pub fn default_cell_width(&self) -> i32 {
    match self {
      FieldType::DateTime | FieldType::LastEditedTime | FieldType::CreatedTime => 180,
      _ => 150,
    }
  }

  pub fn default_name(&self) -> String {
    let s = match self {
      FieldType::RichText => "Text",
      FieldType::Number => "Number",
      FieldType::DateTime => "Date",
      FieldType::SingleSelect => "Single Select",
      FieldType::MultiSelect => "Multi Select",
      FieldType::Checkbox => "Checkbox",
      FieldType::URL => "URL",
      FieldType::Checklist => "Checklist",
      FieldType::LastEditedTime => "Last edited time",
      FieldType::CreatedTime => "Created time",
    };
    s.to_string()
  }

  pub fn is_number(&self) -> bool {
    matches!(self, FieldType::Number)
  }

  pub fn is_text(&self) -> bool {
    matches!(self, FieldType::RichText)
  }

  pub fn is_checkbox(&self) -> bool {
    matches!(self, FieldType::Checkbox)
  }

  pub fn is_date(&self) -> bool {
    matches!(self, FieldType::DateTime)
      || matches!(self, FieldType::LastEditedTime)
      || matches!(self, FieldType::CreatedTime)
  }

  pub fn is_single_select(&self) -> bool {
    matches!(self, FieldType::SingleSelect)
  }

  pub fn is_multi_select(&self) -> bool {
    matches!(self, FieldType::MultiSelect)
  }

  pub fn is_last_edited_time(&self) -> bool {
    matches!(self, FieldType::LastEditedTime)
  }

  pub fn is_created_time(&self) -> bool {
    matches!(self, FieldType::CreatedTime)
  }

  pub fn is_url(&self) -> bool {
    matches!(self, FieldType::URL)
  }

  pub fn is_select_option(&self) -> bool {
    self.is_single_select() || self.is_multi_select()
  }

  pub fn is_checklist(&self) -> bool {
    matches!(self, FieldType::Checklist)
  }

  pub fn can_be_group(&self) -> bool {
    self.is_select_option() || self.is_checkbox() || self.is_url()
  }

  pub fn is_auto_update(&self) -> bool {
    self.is_last_edited_time()
  }
}

impl_into_field_type!(i64);
impl_into_field_type!(u8);

impl From<FieldType> for i64 {
  fn from(ty: FieldType) -> Self {
    (ty as u8) as i64
  }
}

impl From<&FieldType> for i64 {
  fn from(ty: &FieldType) -> Self {
    i64::from(ty.clone())
  }
}

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct DuplicateFieldPayloadPB {
  #[pb(index = 1)]
  pub field_id: String,

  #[pb(index = 2)]
  pub view_id: String,
}

// #[derive(Debug, Clone, Default, ProtoBuf)]
// pub struct GridFieldIdentifierPayloadPB {
//   #[pb(index = 1)]
//   pub field_id: String,
//
//   #[pb(index = 2)]
//   pub view_id: String,
// }

impl TryInto<FieldIdParams> for DuplicateFieldPayloadPB {
  type Error = ErrorCode;

  fn try_into(self) -> Result<FieldIdParams, Self::Error> {
    let view_id = NotEmptyStr::parse(self.view_id).map_err(|_| ErrorCode::DatabaseIdIsEmpty)?;
    let field_id = NotEmptyStr::parse(self.field_id).map_err(|_| ErrorCode::FieldIdIsEmpty)?;
    Ok(FieldIdParams {
      view_id: view_id.0,
      field_id: field_id.0,
    })
  }
}

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct DeleteFieldPayloadPB {
  #[pb(index = 1)]
  pub field_id: String,

  #[pb(index = 2)]
  pub view_id: String,
}

impl TryInto<FieldIdParams> for DeleteFieldPayloadPB {
  type Error = ErrorCode;

  fn try_into(self) -> Result<FieldIdParams, Self::Error> {
    let view_id = NotEmptyStr::parse(self.view_id).map_err(|_| ErrorCode::DatabaseIdIsEmpty)?;
    let field_id = NotEmptyStr::parse(self.field_id).map_err(|_| ErrorCode::FieldIdIsEmpty)?;
    Ok(FieldIdParams {
      view_id: view_id.0,
      field_id: field_id.0,
    })
  }
}

pub struct FieldIdParams {
  pub field_id: String,
  pub view_id: String,
}
