use flowy_database2::entities::FieldVisibility;
use flowy_database2::services::field_settings::FieldSettingsChangesetParams;

use crate::database::database_editor::DatabaseEditorTest;

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

  pub async fn assert_field_settings(
    &mut self,
    field_ids: Vec<String>,
    visibility: FieldVisibility,
    width: i32,
  ) {
    let field_settings = self
      .editor
      .get_field_settings(&self.view_id, field_ids)
      .await
      .unwrap();

    for field_setting in field_settings {
      assert_eq!(field_setting.width, width);
      assert_eq!(field_setting.visibility, visibility);
    }
  }

  pub async fn assert_all_field_settings(&mut self, visibility: FieldVisibility, width: i32) {
    let field_settings = self
      .editor
      .get_all_field_settings(&self.view_id)
      .await
      .unwrap();

    for field_setting in field_settings {
      assert_eq!(field_setting.width, width);
      assert_eq!(field_setting.visibility, visibility);
    }
  }

  pub async fn update_field_settings(
    &mut self,
    field_id: String,
    visibility: Option<FieldVisibility>,
    width: Option<i32>,
  ) {
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
