use anyhow::bail;
use collab::core::any_map::AnyMapExtension;
use collab_database::views::{FieldSettingsMap, FieldSettingsMapBuilder};

/// Stores the field settings for a single field
#[derive(Debug, Clone)]
pub struct FieldSettings {
  pub field_id: String,
  pub is_visible: bool,
}

pub const IS_VISIBLE: &str = "is_visible";

impl FieldSettings {
  pub fn try_from_anymap(
    field_id: String,
    field_settings: FieldSettingsMap,
  ) -> Result<Self, anyhow::Error> {
    let is_visible = match field_settings.get_bool_value(IS_VISIBLE) {
      Some(is_visible) => is_visible,
      _ => bail!("Invalid field settings data"),
    };

    Ok(Self {
      field_id,
      is_visible,
    })
  }
}

impl From<FieldSettings> for FieldSettingsMap {
  fn from(field_settings: FieldSettings) -> Self {
    FieldSettingsMapBuilder::new()
      .insert_bool_value(IS_VISIBLE, field_settings.is_visible)
      .build()
  }
}

/// Contains the changeset to a field's settings.
/// A `Some` value for constitutes a change in that particular setting
pub struct FieldSettingsChangesetParams {
  pub view_id: String,
  pub field_id: String,
  pub is_visible: Option<bool>,
}
