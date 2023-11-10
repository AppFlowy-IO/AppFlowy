use flowy_database2::entities::FieldType;
use flowy_database2::entities::FieldVisibility;
use flowy_database2::services::field_settings::DEFAULT_WIDTH;

use crate::database::field_settings_test::script::FieldSettingsScript::*;
use crate::database::field_settings_test::script::FieldSettingsTest;

/// Check default field settings for grid, kanban and calendar
#[tokio::test]
async fn get_default_field_settings() {
  let mut test = FieldSettingsTest::new_grid().await;
  let scripts = vec![AssertAllFieldSettings {
    visibility: FieldVisibility::AlwaysShown,
    width: DEFAULT_WIDTH,
  }];
  test.run_scripts(scripts).await;

  let mut test = FieldSettingsTest::new_board().await;
  let non_primary_field_ids: Vec<String> = test
    .get_fields()
    .into_iter()
    .filter(|field| !field.is_primary)
    .map(|field| field.id)
    .collect();
  let primary_field_id = test.get_first_field(FieldType::RichText).id;
  let scripts = vec![
    AssertFieldSettings {
      field_ids: non_primary_field_ids.clone(),
      visibility: FieldVisibility::HideWhenEmpty,
      width: DEFAULT_WIDTH,
    },
    AssertFieldSettings {
      field_ids: vec![primary_field_id.clone()],
      visibility: FieldVisibility::AlwaysShown,
      width: DEFAULT_WIDTH,
    },
  ];
  test.run_scripts(scripts).await;

  let mut test = FieldSettingsTest::new_calendar().await;
  let non_primary_field_ids: Vec<String> = test
    .get_fields()
    .into_iter()
    .filter(|field| !field.is_primary)
    .map(|field| field.id)
    .collect();
  let primary_field_id = test.get_first_field(FieldType::RichText).id;
  let scripts = vec![
    AssertFieldSettings {
      field_ids: non_primary_field_ids.clone(),
      visibility: FieldVisibility::HideWhenEmpty,
      width: DEFAULT_WIDTH,
    },
    AssertFieldSettings {
      field_ids: vec![primary_field_id.clone()],
      visibility: FieldVisibility::AlwaysShown,
      width: DEFAULT_WIDTH,
    },
  ];
  test.run_scripts(scripts).await;
}

/// Update field settings for a field
#[tokio::test]
async fn update_field_settings_test() {
  let mut test = FieldSettingsTest::new_board().await;
  let non_primary_field_ids: Vec<String> = test
    .get_fields()
    .into_iter()
    .filter(|field| !field.is_primary)
    .map(|field| field.id)
    .collect();
  let primary_field_id = test.get_first_field(FieldType::RichText).id;

  let scripts = vec![
    AssertFieldSettings {
      field_ids: non_primary_field_ids,
      visibility: FieldVisibility::HideWhenEmpty,
      width: DEFAULT_WIDTH,
    },
    AssertFieldSettings {
      field_ids: vec![primary_field_id.clone()],
      visibility: FieldVisibility::AlwaysShown,
      width: DEFAULT_WIDTH,
    },
    UpdateFieldSettings {
      field_id: primary_field_id,
      visibility: Some(FieldVisibility::HideWhenEmpty),
      width: None,
    },
    AssertAllFieldSettings {
      visibility: FieldVisibility::HideWhenEmpty,
      width: DEFAULT_WIDTH,
    },
  ];
  test.run_scripts(scripts).await;
}
