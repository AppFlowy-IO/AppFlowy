use crate::database::field_settings_test::script::FieldSettingsScript::*;
use crate::database::field_settings_test::script::FieldSettingsTest;

/// Check default field settings for grid, kanban and calendar
#[tokio::test]
async fn get_default_field_settings() {
  let mut test = FieldSettingsTest::new_grid().await;
  let scripts = vec![AssertFieldSettings {
    visibility: vec![true, true, true, true, true, true, true, true, true, true],
  }];
  test.run_scripts(scripts).await;

  let mut test = FieldSettingsTest::new_board().await;
  let scripts = vec![AssertFieldSettings {
    visibility: vec![
      false, false, false, false, false, false, false, false, false, false,
    ],
  }];
  test.run_scripts(scripts).await;

  let mut test = FieldSettingsTest::new_calendar().await;
  let scripts = vec![AssertFieldSettings {
    visibility: vec![
      false, false, false, false, false, false, false, false, false, false,
    ],
  }];
  test.run_scripts(scripts).await;
}

/// Update field settings for a field
#[tokio::test]
async fn update_field_settings_test() {
  let mut test = FieldSettingsTest::new_grid().await;
  let scripts = vec![
    AssertFieldSettings {
      visibility: vec![true, true, true, true, true, true, true, true, true, true],
    },
    UpdateFieldSettings {
      index: 1,
      is_visible: Some(false),
    },
  ];
  test.run_scripts(scripts).await;
}
