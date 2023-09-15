use collab_database::views::DatabaseLayout;
use flowy_database2::entities::FieldType;
use flowy_database2::entities::FieldVisibility;

use crate::database::field_settings_test::script::FieldSettingsScript::*;
use crate::database::field_settings_test::script::FieldSettingsTest;

/// Check default field settings for grid, kanban and calendar
#[tokio::test]
async fn get_default_field_settings() {
  let mut test = FieldSettingsTest::new_grid().await;
  let scripts = vec![AssertAllFieldSettings {
    layout_ty: DatabaseLayout::Grid,
    visibility: FieldVisibility::AlwaysShown,
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
      layout_ty: DatabaseLayout::Board,
      visibility: FieldVisibility::HideWhenEmpty,
    },
    AssertFieldSettings {
      field_ids: vec![primary_field_id.clone()],
      layout_ty: DatabaseLayout::Board,
      visibility: FieldVisibility::AlwaysShown,
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
      layout_ty: DatabaseLayout::Calendar,
      visibility: FieldVisibility::HideWhenEmpty,
    },
    AssertFieldSettings {
      field_ids: vec![primary_field_id.clone()],
      layout_ty: DatabaseLayout::Calendar,
      visibility: FieldVisibility::AlwaysShown,
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
      layout_ty: DatabaseLayout::Board,
      visibility: FieldVisibility::HideWhenEmpty,
    },
    AssertFieldSettings {
      field_ids: vec![primary_field_id.clone()],
      layout_ty: DatabaseLayout::Board,
      visibility: FieldVisibility::AlwaysShown,
    },
    UpdateFieldSettings {
      field_id: primary_field_id,
      visibility: Some(FieldVisibility::HideWhenEmpty),
    },
    AssertAllFieldSettings {
      layout_ty: DatabaseLayout::Board,
      visibility: FieldVisibility::HideWhenEmpty,
    },
  ];
  test.run_scripts(scripts).await;
}
