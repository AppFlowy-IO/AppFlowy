use flowy_database2::entities::FieldVisibility;
use flowy_database2::services::field_settings::FieldSettingsChangesetParams;

use crate::database::database_editor::DatabaseEditorTest;

#[allow(clippy::enum_variant_names)]
pub enum FieldSettingsScript {
  AssertFieldSettings {
    field_ids: Vec<String>,
    visibility: FieldVisibility,
    width: i32,
  },
  AssertAllFieldSettings {
    visibility: FieldVisibility,
    width: i32,
  },
  UpdateFieldSettings {
    field_id: String,
    visibility: Option<FieldVisibility>,
    width: Option<i32>,
  },
}

pub struct FieldSettingsTest {
  inner: DatabaseEditorTest,
}

impl FieldSettingsTest {
  pub async fn new_grid() -> Self {
    let inner = DatabaseEditorTest::new_grid().await;
    Self { inner }
  }

  pub async fn new_board() -> Self {
    let inner = DatabaseEditorTest::new_board().await;
    Self { inner }
  }

  pub async fn new_calendar() -> Self {
    let inner = DatabaseEditorTest::new_calendar().await;
    Self { inner }
  }

  pub async fn run_scripts(&mut self, scripts: Vec<FieldSettingsScript>) {
    for script in scripts {
      self.run_script(script).await;
    }
  }

  pub async fn run_script(&mut self, script: FieldSettingsScript) {
    match script {
      FieldSettingsScript::AssertFieldSettings {
        field_ids,
        visibility,
        width,
      } => {
        let field_settings = self
          .editor
          .get_field_settings(&self.view_id, field_ids)
          .await
          .unwrap();

        for field_settings in field_settings.into_iter() {
          assert_eq!(field_settings.width, width);
          assert_eq!(field_settings.visibility, visibility);
        }
      },
      FieldSettingsScript::AssertAllFieldSettings { visibility, width } => {
        let field_settings = self
          .editor
          .get_all_field_settings(&self.view_id)
          .await
          .unwrap();

        for field_settings in field_settings.into_iter() {
          assert_eq!(field_settings.width, width);
          assert_eq!(field_settings.visibility, visibility);
        }
      },
      FieldSettingsScript::UpdateFieldSettings {
        field_id,
        visibility,
        width,
      } => {
        let params = FieldSettingsChangesetParams {
          view_id: self.view_id.clone(),
          field_id,
          visibility,
          width,
        };
        let _ = self
          .editor
          .update_field_settings_with_changeset(params)
          .await;
      },
    }
  }
}

impl std::ops::Deref for FieldSettingsTest {
  type Target = DatabaseEditorTest;

  fn deref(&self) -> &Self::Target {
    &self.inner
  }
}

impl std::ops::DerefMut for FieldSettingsTest {
  fn deref_mut(&mut self) -> &mut Self::Target {
    &mut self.inner
  }
}
