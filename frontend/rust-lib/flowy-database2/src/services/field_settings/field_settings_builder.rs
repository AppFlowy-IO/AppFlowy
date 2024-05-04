use std::collections::HashMap;

use collab_database::fields::Field;
use collab_database::views::{
  DatabaseLayout, FieldSettingsByFieldIdMap, FieldSettingsMap, FieldSettingsMapBuilder,
};
use strum::IntoEnumIterator;

use crate::entities::FieldVisibility;
use crate::services::field_settings::{FieldSettings, DEFAULT_WIDTH, VISIBILITY, WIDTH};

/// Helper struct to create a new field setting
pub struct FieldSettingsBuilder {
  inner: FieldSettings,
}

impl FieldSettingsBuilder {
  pub fn new(field_id: &str) -> Self {
    let field_settings = FieldSettings {
      field_id: field_id.to_string(),
      visibility: FieldVisibility::AlwaysShown,
      width: DEFAULT_WIDTH,
      wrap_cell_content: false,
    };

    Self {
      inner: field_settings,
    }
  }

  pub fn visibility(mut self, visibility: FieldVisibility) -> Self {
    self.inner.visibility = visibility;
    self
  }

  pub fn width(mut self, width: i32) -> Self {
    self.inner.width = width;
    self
  }

  pub fn build(self) -> FieldSettings {
    self.inner
  }
}

#[inline]
pub fn default_field_visibility(layout_type: DatabaseLayout) -> FieldVisibility {
  match layout_type {
    DatabaseLayout::Grid => FieldVisibility::AlwaysShown,
    DatabaseLayout::Board => FieldVisibility::HideWhenEmpty,
    DatabaseLayout::Calendar => FieldVisibility::HideWhenEmpty,
  }
}

pub fn default_field_settings_for_fields(
  fields: &[Field],
  layout_type: DatabaseLayout,
) -> FieldSettingsByFieldIdMap {
  fields
    .iter()
    .map(|field| {
      let field_settings = field_settings_for_field(layout_type, field);
      (field.id.clone(), field_settings)
    })
    .collect::<HashMap<_, _>>()
    .into()
}

pub fn field_settings_for_field(
  database_layout: DatabaseLayout,
  field: &Field,
) -> FieldSettingsMap {
  let visibility = if field.is_primary {
    FieldVisibility::AlwaysShown
  } else {
    default_field_visibility(database_layout)
  };

  FieldSettingsBuilder::new(&field.id)
    .visibility(visibility)
    .build()
    .into()
}

pub fn default_field_settings_by_layout_map() -> HashMap<DatabaseLayout, FieldSettingsMap> {
  let mut map = HashMap::new();
  for layout_ty in DatabaseLayout::iter() {
    let visibility = default_field_visibility(layout_ty);
    let field_settings = FieldSettingsMapBuilder::new()
      .insert_i64_value(VISIBILITY, visibility.into())
      .build();
    map.insert(layout_ty, field_settings);
  }

  map
}
