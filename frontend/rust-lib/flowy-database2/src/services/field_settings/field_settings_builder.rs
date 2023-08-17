use collab_database::views::DatabaseLayout;

use crate::services::field_settings::FieldSettings;

use crate::services::field_settings::default_is_visible;

/// Helper struct to create a new field setting
pub struct FieldSettingsBuilder {
  field_settings: FieldSettings,
}

impl FieldSettingsBuilder {
  pub fn new(field_id: &str) -> Self {
    let field_settings = FieldSettings {
      field_id: field_id.to_string(),
      is_visible: true,
    };
    Self { field_settings }
  }

  pub fn from_layout_type(field_id: &str, layout_ty: DatabaseLayout) -> Self {
    let field_settings = FieldSettings {
      field_id: field_id.to_string(),
      is_visible: default_is_visible(layout_ty),
    };
    Self { field_settings }
  }

  pub fn field_id(mut self, field_id: &str) -> Self {
    self.field_settings.field_id = field_id.to_string();
    self
  }

  pub fn is_visible(mut self, is_visible: bool) -> Self {
    self.field_settings.is_visible = is_visible;
    self
  }

  pub fn build(self) -> FieldSettings {
    self.field_settings
  }
}
