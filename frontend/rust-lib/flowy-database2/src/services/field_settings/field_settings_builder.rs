use collab_database::views::DatabaseLayout;

use crate::entities::FieldVisibility;

use crate::services::field_settings::{default_visibility, FieldSettings};

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

  pub fn from_layout_type(field_id: &str, layout_ty: DatabaseLayout) -> Self {
    let field_settings = FieldSettings {
      field_id: field_id.to_string(),
      visibility: default_visibility(layout_ty),
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
