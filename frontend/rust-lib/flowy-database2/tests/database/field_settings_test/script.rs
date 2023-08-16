use flowy_database2::services::field_settings::FieldSettingsChangesetParams;

use crate::database::database_editor::DatabaseEditorTest;

pub enum FieldSettingsScript {
  AssertFieldSettings {
    visibility: Vec<bool>,
  },
  UpdateFieldSettings {
    index: usize,
    is_visible: Option<bool>,
  },
}

pub struct FieldSettingsTest {
  database_test: DatabaseEditorTest,
}

impl FieldSettingsTest {
  pub async fn new_grid() -> Self {
    let database_test = DatabaseEditorTest::new_grid().await;
    Self { database_test }
  }

  pub async fn new_board() -> Self {
    let database_test = DatabaseEditorTest::new_board().await;
    Self { database_test }
  }

  pub async fn new_calendar() -> Self {
    let database_test = DatabaseEditorTest::new_calendar().await;
    Self { database_test }
  }

  pub async fn run_scripts(&mut self, scripts: Vec<FieldSettingsScript>) {
    for script in scripts {
      self.run_script(script).await;
    }
  }

  pub async fn run_script(&mut self, script: FieldSettingsScript) {
    match script {
      FieldSettingsScript::AssertFieldSettings { visibility } => {
        let field_settings = self
          .database_test
          .editor
          .get_all_field_settings(&self.database_test.view_id)
          .await
          .unwrap();

        for (field_settings, is_visible) in field_settings.into_iter().zip(visibility) {
          assert_eq!(field_settings.is_visible, is_visible)
        }
      },
      FieldSettingsScript::UpdateFieldSettings { index, is_visible } => {
        let field = self.database_test.fields.get(index).unwrap();
        let params = FieldSettingsChangesetParams {
          view_id: self.database_test.view_id.clone(),
          field_id: field.id.clone(),
          is_visible,
        };
        let _ = self
          .database_test
          .editor
          .update_field_settings_with_changeset(params)
          .await;
      },
    }
  }
}
