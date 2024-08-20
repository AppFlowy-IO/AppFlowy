use collab::preclude::Any;
use collab::util::AnyMapExt;
use collab_database::views::{DatabaseLayout, FieldSettingsMap, FieldSettingsMapBuilder};

use crate::entities::FieldVisibility;
use crate::services::field_settings::default_field_visibility;

/// Stores the field settings for a single field
#[derive(Debug, Clone)]
pub struct FieldSettings {
  pub field_id: String,
  pub visibility: FieldVisibility,
  pub width: i32,
  pub wrap_cell_content: bool,
}

pub const VISIBILITY: &str = "visibility";
pub const WIDTH: &str = "width";
pub const DEFAULT_WIDTH: i32 = 150;
pub const WRAP_CELL_CONTENT: &str = "wrap";

impl FieldSettings {
  pub fn from_any_map(
    field_id: &str,
    layout_type: DatabaseLayout,
    field_settings: &FieldSettingsMap,
  ) -> Self {
    let visibility = field_settings
      .get_as::<i64>(VISIBILITY)
      .map(Into::into)
      .unwrap_or_else(|| default_field_visibility(layout_type));
    let width = field_settings.get_as::<i32>(WIDTH).unwrap_or(DEFAULT_WIDTH);
    let wrap_cell_content: bool = field_settings.get_as(WRAP_CELL_CONTENT).unwrap_or(true);

    Self {
      field_id: field_id.to_string(),
      visibility,
      width,
      wrap_cell_content,
    }
  }
}

impl From<FieldSettings> for FieldSettingsMap {
  fn from(field_settings: FieldSettings) -> Self {
    FieldSettingsMapBuilder::from([
      (
        VISIBILITY.into(),
        Any::BigInt(i64::from(field_settings.visibility)),
      ),
      (WIDTH.into(), Any::BigInt(field_settings.width as i64)),
      (
        WRAP_CELL_CONTENT.into(),
        field_settings.wrap_cell_content.into(),
      ),
    ])
  }
}
