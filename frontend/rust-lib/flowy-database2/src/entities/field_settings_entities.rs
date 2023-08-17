use flowy_derive::ProtoBuf;
use flowy_error::ErrorCode;
use std::ops::Deref;

use crate::entities::parser::NotEmptyStr;
use crate::entities::RepeatedFieldIdPB;
use crate::services::field_settings::{FieldSettings, FieldSettingsChangesetParams};

/// Defines the field settings for a field in a view.
#[derive(Debug, Default, Clone, ProtoBuf)]
pub struct FieldSettingsPB {
  #[pb(index = 1)]
  pub field_id: String,

  #[pb(index = 2)]
  pub is_visible: bool,
}

impl From<FieldSettings> for FieldSettingsPB {
  fn from(value: FieldSettings) -> Self {
    Self {
      field_id: value.field_id,
      is_visible: value.is_visible,
    }
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
      .into_iter()
      .map(|field_id| field_id.field_id.clone())
      .collect();

    Ok((view_id, field_ids))
  }
}

#[derive(Debug, Default, Clone, ProtoBuf)]
pub struct RepeatedFieldSettingsPB {
  #[pb(index = 1)]
  pub items: Vec<FieldSettingsPB>,
}

#[derive(Debug, Default, Clone, ProtoBuf)]
pub struct FieldSettingsChangesetPB {
  #[pb(index = 1)]
  pub view_id: String,

  #[pb(index = 2)]
  pub field_id: String,

  #[pb(index = 3, one_of)]
  pub is_visible: Option<bool>,
}

impl From<FieldSettingsChangesetParams> for FieldSettingsChangesetPB {
  fn from(value: FieldSettingsChangesetParams) -> Self {
    Self {
      view_id: value.view_id,
      field_id: value.field_id,
      is_visible: value.is_visible,
    }
  }
}

impl TryFrom<FieldSettingsChangesetPB> for FieldSettingsChangesetParams {
  type Error = ErrorCode;

  fn try_from(value: FieldSettingsChangesetPB) -> Result<Self, Self::Error> {
    Ok(FieldSettingsChangesetParams {
      view_id: value.view_id,
      field_id: value.field_id,
      is_visible: value.is_visible,
    })
  }
}
