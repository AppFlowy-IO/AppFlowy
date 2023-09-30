use std::collections::HashMap;
use std::sync::Arc;

use collab_database::database::MutexDatabase;
use collab_database::fields::Field;
use collab_database::views::{
  DatabaseLayout, FieldSettingsByFieldIdMap, FieldSettingsMap, FieldSettingsMapBuilder,
};
use strum::IntoEnumIterator;

use crate::entities::FieldVisibility;

use crate::services::field_settings::{FieldSettings, VISIBILITY};

/// Helper struct to create a new field setting
pub struct FieldSettingsBuilder {
  field_settings: FieldSettings,
}

impl FieldSettingsBuilder {
  pub fn new(field_id: &str) -> Self {
    let field_settings = FieldSettings {
      field_id: field_id.to_string(),
      visibility: FieldVisibility::AlwaysShown,
    };
    Self { field_settings }
  }

  pub fn field_id(mut self, field_id: &str) -> Self {
    self.field_settings.field_id = field_id.to_string();
    self
  }

  pub fn visibility(mut self, visibility: FieldVisibility) -> Self {
    self.field_settings.visibility = visibility;
    self
  }

  pub fn build(self) -> FieldSettings {
    self.field_settings
  }
}

pub struct DatabaseFieldSettingsMapBuilder {
  pub fields: Vec<Field>,
  pub database_layout: DatabaseLayout,
}

impl DatabaseFieldSettingsMapBuilder {
  pub fn new(fields: Vec<Field>, database_layout: DatabaseLayout) -> Self {
    Self {
      fields,
      database_layout,
    }
  }

  pub fn from_database(database: Arc<MutexDatabase>, database_layout: DatabaseLayout) -> Self {
    let fields = database.lock().get_fields(None);
    Self {
      fields,
      database_layout,
    }
  }

  pub fn build(self) -> FieldSettingsByFieldIdMap {
    self
      .fields
      .into_iter()
      .map(|field| {
        let field_settings = field_settings_for_field(self.database_layout, &field);
        (field.id, field_settings)
      })
      .collect::<HashMap<String, FieldSettingsMap>>()
      .into()
  }
}

pub fn field_settings_for_field(
  database_layout: DatabaseLayout,
  field: &Field,
) -> FieldSettingsMap {
  let visibility = if field.is_primary {
    FieldVisibility::AlwaysShown
  } else {
    match database_layout {
      DatabaseLayout::Grid => FieldVisibility::AlwaysShown,
      DatabaseLayout::Board => FieldVisibility::HideWhenEmpty,
      DatabaseLayout::Calendar => FieldVisibility::HideWhenEmpty,
    }
  };

  FieldSettingsBuilder::new(&field.id)
    .visibility(visibility)
    .build()
    .into()
}

pub fn default_field_settings_by_layout_map() -> HashMap<DatabaseLayout, FieldSettingsMap> {
  let mut map = HashMap::new();
  for layout_ty in DatabaseLayout::iter() {
    let visibility = match layout_ty {
      DatabaseLayout::Grid => FieldVisibility::AlwaysShown,
      DatabaseLayout::Board => FieldVisibility::HideWhenEmpty,
      DatabaseLayout::Calendar => FieldVisibility::HideWhenEmpty,
    };
    let field_settings = FieldSettingsMapBuilder::new()
      .insert_i64_value(VISIBILITY, visibility.into())
      .build();
    map.insert(layout_ty, field_settings);
  }

  map
}
