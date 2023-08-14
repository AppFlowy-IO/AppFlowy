use std::collections::HashMap;

use strum::IntoEnumIterator;

use collab_database::views::{DatabaseLayout, FieldSettingsMap, FieldSettingsMapBuilder};

use crate::services::field_settings::IS_VISIBLE;

pub fn default_field_settings_by_layout_map() -> HashMap<DatabaseLayout, FieldSettingsMap> {
  let mut template = HashMap::new();
  for layout_ty in DatabaseLayout::iter() {
    template.insert(layout_ty, default_field_settings_by_layout(layout_ty));
  }

  template
}

pub fn default_field_settings_by_layout(layout_ty: DatabaseLayout) -> FieldSettingsMap {
  let is_visible = default_is_visible(layout_ty);
  FieldSettingsMapBuilder::new()
    .insert_bool_value(IS_VISIBLE, is_visible)
    .build()
}

pub fn default_is_visible(layout_ty: DatabaseLayout) -> bool {
  match layout_ty {
    DatabaseLayout::Grid => true,
    DatabaseLayout::Board => false,
    DatabaseLayout::Calendar => false,
  }
}
