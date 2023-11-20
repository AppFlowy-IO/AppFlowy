use collab::core::any_map::AnyMapExtension;
use collab_database::views::{DatabaseLayout, FieldSettingsMap, FieldSettingsMapBuilder};

use crate::entities::FieldVisibility;
use crate::services::field_settings::default_field_visibility;

/// Stores the field settings for a single field
#[derive(Debug, Clone)]
pub struct FieldSettings {
  pub field_id: String,
  pub visibility: FieldVisibility,
  pub width: i32,
}

pub const VISIBILITY: &str = "visibility";
pub const WIDTH: &str = "width";

pub const DEFAULT_WIDTH: i32 = 150;

impl FieldSettings {
  pub fn from_anymap(
    field_id: &str,
    layout_type: DatabaseLayout,
    field_settings: &FieldSettingsMap,
  ) -> Self {
    let visibility = field_settings
      .get_i64_value(VISIBILITY)
      .map(Into::into)
      .unwrap_or_else(|| default_field_visibility(layout_type));
    let width = field_settings
      .get_i64_value(WIDTH)
      .map(|value| value as i32)
      .unwrap_or(DEFAULT_WIDTH);

    Self {
      field_id: field_id.to_string(),
      visibility,
      width,
    }
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
