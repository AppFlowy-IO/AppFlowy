use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_error::ErrorCode;
use lib_infra::validator_fn::required_not_empty_str;
use std::ops::Deref;
use validator::Validate;

use crate::entities::parser::NotEmptyStr;
use crate::entities::RepeatedFieldIdPB;
use crate::impl_into_field_visibility;
use crate::services::field_settings::FieldSettings;

/// Defines the field settings for a field in a view.
#[derive(Debug, Default, Clone, ProtoBuf, Eq, PartialEq)]
pub struct FieldSettingsPB {
  #[pb(index = 1)]
  pub field_id: String,

  #[pb(index = 2)]
  pub visibility: FieldVisibility,

  #[pb(index = 3)]
  pub width: i32,

  #[pb(index = 4)]
  pub wrap_cell_content: bool,
}

impl From<FieldSettings> for FieldSettingsPB {
  fn from(value: FieldSettings) -> Self {
    Self {
      field_id: value.field_id,
      visibility: value.visibility,
      width: value.width,
      wrap_cell_content: value.wrap_cell_content,
    }
  }
}

#[repr(u8)]
#[derive(Debug, Default, Clone, ProtoBuf_Enum, Eq, PartialEq)]
pub enum FieldVisibility {
  #[default]
  AlwaysShown = 0,
  HideWhenEmpty = 1,
  AlwaysHidden = 2,
}

impl_into_field_visibility!(i64);
impl_into_field_visibility!(u8);

impl From<FieldVisibility> for i64 {
  fn from(value: FieldVisibility) -> Self {
    (value as u8) as i64
  }
}

#[derive(Debug, Default, Clone, ProtoBuf)]
pub struct FieldIdsPB {
  #[pb(index = 1)]
  pub view_id: String,

  #[pb(index = 2)]
  pub field_ids: RepeatedFieldIdPB,
}

/// Defines a set of fields in a database view, identified by their `field_ids`
pub struct FieldIdsParams {
  pub view_id: String,
  pub field_ids: Vec<String>,
}

impl TryInto<(String, Vec<String>)> for FieldIdsPB {
  type Error = ErrorCode;

  fn try_into(self) -> Result<(String, Vec<String>), Self::Error> {
    let view_id = NotEmptyStr::parse(self.view_id)
      .map_err(|_| ErrorCode::ViewIdIsInvalid)?
      .0;
    let field_ids = self
      .field_ids
      .deref()
      .iter()
      .map(|field_id| field_id.field_id.clone())
      .collect();

    Ok((view_id, field_ids))
  }
}

#[derive(Debug, Default, Clone, ProtoBuf, Eq, PartialEq)]
pub struct RepeatedFieldSettingsPB {
  #[pb(index = 1)]
  pub items: Vec<FieldSettingsPB>,
}

impl std::convert::From<Vec<FieldSettingsPB>> for RepeatedFieldSettingsPB {
  fn from(items: Vec<FieldSettingsPB>) -> Self {
    Self { items }
  }
}

#[derive(Debug, Default, Clone, ProtoBuf, Validate)]
pub struct FieldSettingsChangesetPB {
  #[validate(custom(function = "required_not_empty_str"))]
  #[pb(index = 1)]
  pub view_id: String,

  #[validate(custom(function = "required_not_empty_str"))]
  #[pb(index = 2)]
  pub field_id: String,

  #[pb(index = 3, one_of)]
  pub visibility: Option<FieldVisibility>,

  #[pb(index = 4, one_of)]
  pub width: Option<i32>,

  #[pb(index = 5, one_of)]
  pub wrap_cell_content: Option<bool>,
}
