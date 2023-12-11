use flowy_database2::entities::FieldType;
use flowy_database2::entities::FieldVisibility;
use flowy_database2::services::field_settings::DEFAULT_WIDTH;

use crate::database::field_settings_test::script::FieldSettingsTest;

/// Check default field settings for grid, kanban and calendar
#[tokio::test]
async fn get_default_grid_field_settings() {
  // grid
  let mut test = FieldSettingsTest::new_grid().await;
  test
    .assert_all_field_settings(FieldVisibility::AlwaysShown, DEFAULT_WIDTH)
    .await;
}

#[tokio::test]
async fn get_default_board_field_settings() {
  // board
  let mut test = FieldSettingsTest::new_board().await;
  let non_primary_field_ids: Vec<String> = test
    .get_fields()
    .into_iter()
    .filter(|field| !field.is_primary)
    .map(|field| field.id)
    .collect();
  let primary_field_id = test.get_first_field(FieldType::RichText).id;
  test
    .assert_field_settings(
      non_primary_field_ids.clone(),
      FieldVisibility::HideWhenEmpty,
      DEFAULT_WIDTH,
    )
    .await;
  test
    .assert_field_settings(
      vec![primary_field_id.clone()],
      FieldVisibility::AlwaysShown,
      DEFAULT_WIDTH,
    )
    .await;
}

#[tokio::test]
async fn get_default_calendar_field_settings() {
  // calendar
  let mut test = FieldSettingsTest::new_calendar().await;
  let non_primary_field_ids: Vec<String> = test
    .get_fields()
    .into_iter()
    .filter(|field| !field.is_primary)
    .map(|field| field.id)
    .collect();
  let primary_field_id = test.get_first_field(FieldType::RichText).id;
  test
    .assert_field_settings(
      non_primary_field_ids.clone(),
      FieldVisibility::HideWhenEmpty,
      DEFAULT_WIDTH,
    )
    .await;
  test
    .assert_field_settings(
      vec![primary_field_id.clone()],
      FieldVisibility::AlwaysShown,
      DEFAULT_WIDTH,
    )
    .await;
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

  test
    .assert_field_settings(
      non_primary_field_ids.clone(),
      FieldVisibility::HideWhenEmpty,
      DEFAULT_WIDTH,
    )
    .await;
  test
    .assert_field_settings(
      vec![primary_field_id.clone()],
      FieldVisibility::AlwaysShown,
      DEFAULT_WIDTH,
    )
    .await;

  test
    .update_field_settings(
      primary_field_id.clone(),
      Some(FieldVisibility::HideWhenEmpty),
      None,
    )
    .await;
  test
    .assert_field_settings(
      non_primary_field_ids.clone(),
      FieldVisibility::HideWhenEmpty,
      DEFAULT_WIDTH,
    )
    .await;
  test
    .assert_field_settings(
      vec![primary_field_id.clone()],
      FieldVisibility::HideWhenEmpty,
      DEFAULT_WIDTH,
    )
    .await;
}
