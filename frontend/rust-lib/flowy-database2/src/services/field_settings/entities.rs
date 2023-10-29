use anyhow::bail;
use collab::core::any_map::AnyMapExtension;
use collab_database::views::{FieldSettingsMap, FieldSettingsMapBuilder};

use crate::entities::FieldVisibility;

/// Stores the field settings for a single field
#[derive(Debug, Clone)]
pub struct FieldSettings {
  pub field_id: String,
  pub visibility: FieldVisibility,
  pub width: i32,
}

pub const VISIBILITY: &str = "visibility";
pub const WIDTH: &str = "width";

impl FieldSettings {
  pub fn try_from_anymap(
    field_id: String,
    field_settings: FieldSettingsMap,
  ) -> Result<Self, anyhow::Error> {
    let (visibility, width) = match (
      field_settings.get_i64_value(VISIBILITY),
      field_settings.get_i64_value(WIDTH),
    ) {
      (Some(visbility), Some(width)) => (visbility.into(), width as i32),
      _ => bail!("Invalid field settings data"),
    };

    Ok(Self {
      field_id,
      visibility,
      width,
    })
  }
}

impl From<FieldSettings> for FieldSettingsMap {
  fn from(field_settings: FieldSettings) -> Self {
    FieldSettingsMapBuilder::new()
      .insert_i64_value(VISIBILITY, field_settings.visibility.into())
      .insert_i64_value(WIDTH, field_settings.width as i64)
      .build()
  }
}

/// Contains the changeset to a field's settings.
/// A `Some` value constitutes a change in that particular setting
pub struct FieldSettingsChangesetParams {
  pub view_id: String,
  pub field_id: String,
  pub visibility: Option<FieldVisibility>,
  pub width: Option<i32>,
}
