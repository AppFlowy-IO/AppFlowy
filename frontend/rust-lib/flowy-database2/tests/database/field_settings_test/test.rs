use collab_database::views::DatabaseLayout;
use flowy_database2::entities::FieldType;
use flowy_database2::entities::FieldVisibility;
use flowy_database2::services::field_settings::default_visibility;

use crate::database::field_settings_test::script::FieldSettingsScript::*;
use crate::database::field_settings_test::script::FieldSettingsTest;

/// Check default field settings for grid, kanban and calendar
#[tokio::test]
async fn get_default_field_settings() {
  let mut test = FieldSettingsTest::new_grid().await;
  let visibility = default_visibility(DatabaseLayout::Grid);
  let scripts = vec![AssertAllFieldSettings { visibility }];
  test.run_scripts(scripts).await;

  let mut test = FieldSettingsTest::new_board().await;
  let visibility = default_visibility(DatabaseLayout::Board);
  let scripts = vec![AssertAllFieldSettings { visibility }];
  test.run_scripts(scripts).await;

  let mut test = FieldSettingsTest::new_calendar().await;
  let visibility = default_visibility(DatabaseLayout::Calendar);
  let scripts = vec![AssertAllFieldSettings { visibility }];
  test.run_scripts(scripts).await;
}

/// Update field settings for a field
#[tokio::test]
async fn update_field_settings_test() {
  let mut test = FieldSettingsTest::new_grid().await;
  let checkbox_field = test.get_first_field(FieldType::Checkbox);
  let text_field = test.get_first_field(FieldType::RichText);
  let visibility = default_visibility(DatabaseLayout::Grid);
  let new_visibility = FieldVisibility::AlwaysHidden;

  let scripts = vec![
    AssertAllFieldSettings {
      visibility: visibility.clone(),
    },
    UpdateFieldSettings {
      field_id: checkbox_field.id.clone(),
      visibility: Some(new_visibility.clone()),
    },
    AssertFieldSettings {
      field_id: checkbox_field.id,
      visibility: new_visibility,
    },
    AssertFieldSettings {
      field_id: text_field.id,
      visibility,
    },
  ];
  test.run_scripts(scripts).await;
}
