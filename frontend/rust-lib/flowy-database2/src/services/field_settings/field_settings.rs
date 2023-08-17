use std::collections::HashMap;

use strum::IntoEnumIterator;

use collab_database::views::{DatabaseLayout, FieldSettingsMap, FieldSettingsMapBuilder};

use crate::services::field_settings::IS_VISIBLE;

/// Creates a map of the database layout and the default field settings for fields
/// in a view of that database layout
pub fn default_field_settings_by_layout_map() -> HashMap<DatabaseLayout, FieldSettingsMap> {
  let mut template = HashMap::new();
  for layout_ty in DatabaseLayout::iter() {
    template.insert(layout_ty, default_field_settings_by_layout(layout_ty));
  }

  template
}

/// Returns the default FieldSettingsMap for the given database layout
pub fn default_field_settings_by_layout(layout_ty: DatabaseLayout) -> FieldSettingsMap {
  let is_visible = default_is_visible(layout_ty);
  FieldSettingsMapBuilder::new()
    .insert_bool_value(IS_VISIBLE, is_visible)
    .build()
}

/// Returns the default visibility of a field for the given database layout
pub fn default_is_visible(layout_ty: DatabaseLayout) -> bool {
  match layout_ty {
    DatabaseLayout::Grid => true,
    DatabaseLayout::Board => false,
    DatabaseLayout::Calendar => false,
  }
}
