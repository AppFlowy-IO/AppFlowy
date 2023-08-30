use anyhow::bail;
use collab::core::any_map::AnyMapExtension;
use collab_database::views::{FieldSettingsMap, FieldSettingsMapBuilder};

use crate::entities::FieldVisibility;

/// Stores the field settings for a single field
#[derive(Debug, Clone)]
pub struct FieldSettings {
  pub field_id: String,
  pub visibility: FieldVisibility,
}

pub const VISIBILITY: &str = "visibility";

impl FieldSettings {
  pub fn try_from_anymap(
    field_id: String,
    field_settings: FieldSettingsMap,
  ) -> Result<Self, anyhow::Error> {
    let visibility = match field_settings.get_i64_value(VISIBILITY) {
      Some(visbility) => visbility.into(),
      _ => bail!("Invalid field settings data"),
    };

    Ok(Self {
      field_id,
      visibility,
    })
  }
}

impl From<FieldSettings> for FieldSettingsMap {
  fn from(field_settings: FieldSettings) -> Self {
    FieldSettingsMapBuilder::new()
      .insert_i64_value(VISIBILITY, field_settings.visibility.into())
      .build()
  }
}

/// Contains the changeset to a field's settings.
/// A `Some` value for constitutes a change in that particular setting
pub struct FieldSettingsChangesetParams {
  pub view_id: String,
  pub field_id: String,
  pub visibility: Option<FieldVisibility>,
}
