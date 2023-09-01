use std::collections::HashMap;

use strum::IntoEnumIterator;

use collab_database::views::{DatabaseLayout, FieldSettingsMap, FieldSettingsMapBuilder};

use crate::{entities::FieldVisibility, services::field_settings::VISIBILITY};

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
  let visibility = default_visibility(layout_ty);
  FieldSettingsMapBuilder::new()
    .insert_i64_value(VISIBILITY, visibility.into())
    .build()
}

/// Returns the default visibility of a field for the given database layout
pub fn default_visibility(layout_ty: DatabaseLayout) -> FieldVisibility {
  match layout_ty {
    DatabaseLayout::Grid => FieldVisibility::AlwaysShown,
    DatabaseLayout::Board => FieldVisibility::HideWhenEmpty,
    DatabaseLayout::Calendar => FieldVisibility::HideWhenEmpty,
  }
}
