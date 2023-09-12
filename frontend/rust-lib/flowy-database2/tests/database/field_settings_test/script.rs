use collab_database::views::DatabaseLayout;
use flowy_database2::entities::FieldVisibility;
use flowy_database2::services::field_settings::FieldSettingsChangesetParams;

use crate::database::database_editor::DatabaseEditorTest;

#[allow(clippy::enum_variant_names)]
pub enum FieldSettingsScript {
  AssertFieldSettings {
    field_ids: Vec<String>,
    layout_ty: DatabaseLayout,
    visibility: FieldVisibility,
  },
  AssertAllFieldSettings {
    layout_ty: DatabaseLayout,
    visibility: FieldVisibility,
  },
  UpdateFieldSettings {
    field_id: String,
    visibility: Option<FieldVisibility>,
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
        layout_ty,
        visibility,
      } => {
        let field_settings = self
          .editor
          .get_field_settings(&self.view_id, layout_ty, field_ids)
          .await
          .unwrap();

        for field_settings in field_settings.into_iter() {
          assert_eq!(field_settings.visibility, visibility)
        }
      },
      FieldSettingsScript::AssertAllFieldSettings {
        layout_ty,
        visibility,
      } => {
        let field_settings = self
          .editor
          .get_all_field_settings(&self.view_id, layout_ty)
          .await
          .unwrap();

        for field_settings in field_settings.into_iter() {
          assert_eq!(field_settings.visibility, visibility)
        }
      },
      FieldSettingsScript::UpdateFieldSettings {
        field_id,
        visibility,
      } => {
        let params = FieldSettingsChangesetParams {
          view_id: self.view_id.clone(),
          field_id,
          visibility,
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
