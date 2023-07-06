use std::convert::TryFrom;

use bytes::Bytes;

use flowy_database2::entities::{
  CellChangesetPB, CellIdPB, ChecklistCellDataChangesetPB, DatabaseLayoutPB,
  DatabaseSettingChangesetPB, DatabaseViewIdPB, DateChangesetPB, FieldType, SelectOptionCellDataPB,
  UpdateRowMetaChangesetPB,
};
use flowy_test::event_builder::EventBuilder;
use flowy_test::FlowyCoreTest;
use lib_infra::util::timestamp;

#[tokio::test]
async fn get_database_id_event_test() {
  let test = FlowyCoreTest::new_with_user().await;
  let current_workspace = test.get_current_workspace().await.workspace;
  let grid_view = test
    .create_grid(&current_workspace.id, "my grid view".to_owned(), vec![])
    .await;

  // The view id can be used to get the database id.
  let database_id = EventBuilder::new(test.clone())
    .event(flowy_database2::event_map::DatabaseEvent::GetDatabaseId)
    .payload(DatabaseViewIdPB {
      value: grid_view.id.clone(),
    })
    .async_send()
    .await
    .parse::<flowy_database2::entities::DatabaseIdPB>()
    .value;

  assert_ne!(database_id, grid_view.id);
}

#[tokio::test]
async fn get_database_event_test() {
  let test = FlowyCoreTest::new_with_user().await;
  let current_workspace = test.get_current_workspace().await.workspace;
  let grid_view = test
    .create_grid(&current_workspace.id, "my grid view".to_owned(), vec![])
    .await;

  let database = test.get_database(&grid_view.id).await;
  assert_eq!(database.fields.len(), 3);
  assert_eq!(database.rows.len(), 3);
  assert_eq!(database.layout_type, DatabaseLayoutPB::Grid);
}

#[tokio::test]
async fn get_field_event_test() {
  let test = FlowyCoreTest::new_with_user().await;
  let current_workspace = test.get_current_workspace().await.workspace;
  let grid_view = test
    .create_grid(&current_workspace.id, "my grid view".to_owned(), vec![])
    .await;

  let fields = test.get_all_database_fields(&grid_view.id).await.items;
  assert_eq!(fields[0].field_type, FieldType::RichText);
  assert_eq!(fields[1].field_type, FieldType::SingleSelect);
  assert_eq!(fields[2].field_type, FieldType::Checkbox);
  assert_eq!(fields.len(), 3);
}

#[tokio::test]
async fn create_field_event_test() {
  let test = FlowyCoreTest::new_with_user().await;
  let current_workspace = test.get_current_workspace().await.workspace;
  let grid_view = test
    .create_grid(&current_workspace.id, "my grid view".to_owned(), vec![])
    .await;

  test.create_field(&grid_view.id, FieldType::Checkbox).await;
  let fields = test.get_all_database_fields(&grid_view.id).await.items;
  assert_eq!(fields.len(), 4);
  assert_eq!(fields[3].field_type, FieldType::Checkbox);
}

#[tokio::test]
async fn delete_field_event_test() {
  let test = FlowyCoreTest::new_with_user().await;
  let current_workspace = test.get_current_workspace().await.workspace;
  let grid_view = test
    .create_grid(&current_workspace.id, "my grid view".to_owned(), vec![])
    .await;

  let fields = test.get_all_database_fields(&grid_view.id).await.items;
  assert_eq!(fields[0].field_type, FieldType::RichText);
  assert_eq!(fields[1].field_type, FieldType::SingleSelect);
  assert_eq!(fields[2].field_type, FieldType::Checkbox);

  let error = test.delete_field(&grid_view.id, &fields[1].id).await;
  assert!(error.is_none());

  let fields = test.get_all_database_fields(&grid_view.id).await.items;
  assert_eq!(fields.len(), 2);
}

// The primary field is not allowed to be deleted.
#[tokio::test]
async fn delete_primary_field_event_test() {
  let test = FlowyCoreTest::new_with_user().await;
  let current_workspace = test.get_current_workspace().await.workspace;
  let grid_view = test
    .create_grid(&current_workspace.id, "my grid view".to_owned(), vec![])
    .await;

  let fields = test.get_all_database_fields(&grid_view.id).await.items;
  // the primary field is not allowed to be deleted.
  assert!(fields[0].is_primary);
  let error = test.delete_field(&grid_view.id, &fields[0].id).await;
  assert!(error.is_some());
}

#[tokio::test]
async fn update_field_type_event_test() {
  let test = FlowyCoreTest::new_with_user().await;
  let current_workspace = test.get_current_workspace().await.workspace;
  let grid_view = test
    .create_grid(&current_workspace.id, "my grid view".to_owned(), vec![])
    .await;

  let fields = test.get_all_database_fields(&grid_view.id).await.items;
  let error = test
    .update_field_type(&grid_view.id, &fields[1].id, FieldType::Checklist)
    .await;
  assert!(error.is_none());

  let fields = test.get_all_database_fields(&grid_view.id).await.items;
  assert_eq!(fields[1].field_type, FieldType::Checklist);
}

#[tokio::test]
async fn update_primary_field_type_event_test() {
  let test = FlowyCoreTest::new_with_user().await;
  let current_workspace = test.get_current_workspace().await.workspace;
  let grid_view = test
    .create_grid(&current_workspace.id, "my grid view".to_owned(), vec![])
    .await;

  let fields = test.get_all_database_fields(&grid_view.id).await.items;
  // the primary field is not allowed to be deleted.
  assert!(fields[0].is_primary);

  // the primary field is not allowed to be updated.
  let error = test
    .update_field_type(&grid_view.id, &fields[0].id, FieldType::Checklist)
    .await;
  assert!(error.is_some());
}

#[tokio::test]
async fn duplicate_field_event_test() {
  let test = FlowyCoreTest::new_with_user().await;
  let current_workspace = test.get_current_workspace().await.workspace;
  let grid_view = test
    .create_grid(&current_workspace.id, "my grid view".to_owned(), vec![])
    .await;

  let fields = test.get_all_database_fields(&grid_view.id).await.items;
  // the primary field is not allowed to be updated.
  let error = test.duplicate_field(&grid_view.id, &fields[1].id).await;
  assert!(error.is_none());

  let fields = test.get_all_database_fields(&grid_view.id).await.items;
  assert_eq!(fields.len(), 4);
}

// The primary field is not allowed to be duplicated. So this test should return an error.
#[tokio::test]
async fn duplicate_primary_field_test() {
  let test = FlowyCoreTest::new_with_user().await;
  let current_workspace = test.get_current_workspace().await.workspace;
  let grid_view = test
    .create_grid(&current_workspace.id, "my grid view".to_owned(), vec![])
    .await;

  let fields = test.get_all_database_fields(&grid_view.id).await.items;
  // the primary field is not allowed to be duplicated.
  let error = test.duplicate_field(&grid_view.id, &fields[0].id).await;
  assert!(error.is_some());
}

#[tokio::test]
async fn get_primary_field_event_test() {
  let test = FlowyCoreTest::new_with_user().await;
  let current_workspace = test.get_current_workspace().await.workspace;
  let grid_view = test
    .create_grid(&current_workspace.id, "my grid view".to_owned(), vec![])
    .await;

  // By default the primary field type is RichText.
  let field = test.get_primary_field(&grid_view.id).await;
  assert_eq!(field.field_type, FieldType::RichText);
}

#[tokio::test]
async fn create_row_event_test() {
  let test = FlowyCoreTest::new_with_user().await;
  let current_workspace = test.get_current_workspace().await.workspace;
  let grid_view = test
    .create_grid(&current_workspace.id, "my grid view".to_owned(), vec![])
    .await;

  let _ = test.create_row(&grid_view.id, None, None).await;
  let database = test.get_database(&grid_view.id).await;
  assert_eq!(database.rows.len(), 4);
}

#[tokio::test]
async fn delete_row_event_test() {
  let test = FlowyCoreTest::new_with_user().await;
  let current_workspace = test.get_current_workspace().await.workspace;
  let grid_view = test
    .create_grid(&current_workspace.id, "my grid view".to_owned(), vec![])
    .await;

  // delete the row
  let database = test.get_database(&grid_view.id).await;
  let remove_row_id = database.rows[0].id.clone();
  assert_eq!(database.rows.len(), 3);
  let error = test.delete_row(&grid_view.id, &remove_row_id).await;
  assert!(error.is_none());

  let database = test.get_database(&grid_view.id).await;
  assert_eq!(database.rows.len(), 2);

  // get the row again and check if it is deleted.
  let optional_row = test.get_row(&grid_view.id, &remove_row_id).await;
  assert!(optional_row.row.is_none());
}

#[tokio::test]
async fn get_row_event_test() {
  let test = FlowyCoreTest::new_with_user().await;
  let current_workspace = test.get_current_workspace().await.workspace;
  let grid_view = test
    .create_grid(&current_workspace.id, "my grid view".to_owned(), vec![])
    .await;
  let database = test.get_database(&grid_view.id).await;

  let row = test.get_row(&grid_view.id, &database.rows[0].id).await.row;
  assert!(row.is_some());

  let row = test.get_row_meta(&grid_view.id, &database.rows[0].id).await;
  assert!(!row.document_id.is_empty());
}

#[tokio::test]
async fn update_row_meta_event_with_url_test() {
  let test = FlowyCoreTest::new_with_user().await;
  let current_workspace = test.get_current_workspace().await.workspace;
  let grid_view = test
    .create_grid(&current_workspace.id, "my grid view".to_owned(), vec![])
    .await;
  let database = test.get_database(&grid_view.id).await;

  // By default the row icon is None.
  let row = test.get_row_meta(&grid_view.id, &database.rows[0].id).await;
  assert_eq!(row.icon, None);

  // Insert icon url to the row.
  let changeset = UpdateRowMetaChangesetPB {
    id: database.rows[0].id.clone(),
    view_id: grid_view.id.clone(),
    icon_url: Some("icon_url".to_owned()),
    cover_url: None,
  };
  let error = test.update_row_meta(changeset).await;
  assert!(error.is_none());

  // Check if the icon is updated.
  let row = test.get_row_meta(&grid_view.id, &database.rows[0].id).await;
  assert_eq!(row.icon, Some("icon_url".to_owned()));
}

#[tokio::test]
async fn update_row_meta_event_with_cover_test() {
  let test = FlowyCoreTest::new_with_user().await;
  let current_workspace = test.get_current_workspace().await.workspace;
  let grid_view = test
    .create_grid(&current_workspace.id, "my grid view".to_owned(), vec![])
    .await;
  let database = test.get_database(&grid_view.id).await;

  // By default the row icon is None.
  let row = test.get_row_meta(&grid_view.id, &database.rows[0].id).await;
  assert_eq!(row.cover, None);

  // Insert cover to the row.
  let changeset = UpdateRowMetaChangesetPB {
    id: database.rows[0].id.clone(),
    view_id: grid_view.id.clone(),
    cover_url: Some("cover url".to_owned()),
    icon_url: None,
  };
  let error = test.update_row_meta(changeset).await;
  assert!(error.is_none());

  // Check if the icon is updated.
  let row = test.get_row_meta(&grid_view.id, &database.rows[0].id).await;
  assert_eq!(row.cover, Some("cover url".to_owned()));
}

#[tokio::test]
async fn delete_row_event_with_invalid_row_id_test() {
  let test = FlowyCoreTest::new_with_user().await;
  let current_workspace = test.get_current_workspace().await.workspace;
  let grid_view = test
    .create_grid(&current_workspace.id, "my grid view".to_owned(), vec![])
    .await;

  // delete the row with empty row_id. It should return an error.
  let error = test.delete_row(&grid_view.id, "").await;
  assert!(error.is_some());
}

#[tokio::test]
async fn duplicate_row_event_test() {
  let test = FlowyCoreTest::new_with_user().await;
  let current_workspace = test.get_current_workspace().await.workspace;
  let grid_view = test
    .create_grid(&current_workspace.id, "my grid view".to_owned(), vec![])
    .await;
  let database = test.get_database(&grid_view.id).await;
  let error = test
    .duplicate_row(&grid_view.id, &database.rows[0].id)
    .await;
  assert!(error.is_none());

  let database = test.get_database(&grid_view.id).await;
  assert_eq!(database.rows.len(), 4);
}

#[tokio::test]
async fn duplicate_row_event_with_invalid_row_id_test() {
  let test = FlowyCoreTest::new_with_user().await;
  let current_workspace = test.get_current_workspace().await.workspace;
  let grid_view = test
    .create_grid(&current_workspace.id, "my grid view".to_owned(), vec![])
    .await;
  let database = test.get_database(&grid_view.id).await;
  assert_eq!(database.rows.len(), 3);

  let error = test.duplicate_row(&grid_view.id, "").await;
  assert!(error.is_some());

  let database = test.get_database(&grid_view.id).await;
  assert_eq!(database.rows.len(), 3);
}

#[tokio::test]
async fn move_row_event_test() {
  let test = FlowyCoreTest::new_with_user().await;
  let current_workspace = test.get_current_workspace().await.workspace;
  let grid_view = test
    .create_grid(&current_workspace.id, "my grid view".to_owned(), vec![])
    .await;
  let database = test.get_database(&grid_view.id).await;
  let row_1 = database.rows[0].id.clone();
  let row_2 = database.rows[1].id.clone();
  let row_3 = database.rows[2].id.clone();
  let error = test.move_row(&grid_view.id, &row_1, &row_3).await;
  assert!(error.is_none());

  let database = test.get_database(&grid_view.id).await;
  assert_eq!(database.rows[0].id, row_2);
  assert_eq!(database.rows[1].id, row_3);
  assert_eq!(database.rows[2].id, row_1);
}

#[tokio::test]
async fn move_row_event_test2() {
  let test = FlowyCoreTest::new_with_user().await;
  let current_workspace = test.get_current_workspace().await.workspace;
  let grid_view = test
    .create_grid(&current_workspace.id, "my grid view".to_owned(), vec![])
    .await;
  let database = test.get_database(&grid_view.id).await;
  let row_1 = database.rows[0].id.clone();
  let row_2 = database.rows[1].id.clone();
  let row_3 = database.rows[2].id.clone();
  let error = test.move_row(&grid_view.id, &row_2, &row_1).await;
  assert!(error.is_none());

  let database = test.get_database(&grid_view.id).await;
  assert_eq!(database.rows[0].id, row_2);
  assert_eq!(database.rows[1].id, row_1);
  assert_eq!(database.rows[2].id, row_3);
}

#[tokio::test]
async fn move_row_event_with_invalid_row_id_test() {
  let test = FlowyCoreTest::new_with_user().await;
  let current_workspace = test.get_current_workspace().await.workspace;
  let grid_view = test
    .create_grid(&current_workspace.id, "my grid view".to_owned(), vec![])
    .await;
  let database = test.get_database(&grid_view.id).await;
  let row_1 = database.rows[0].id.clone();
  let row_2 = database.rows[1].id.clone();
  let row_3 = database.rows[2].id.clone();

  for i in 0..2 {
    if i == 0 {
      let error = test.move_row(&grid_view.id, &row_1, "").await;
      assert!(error.is_some());
    } else {
      let error = test.move_row(&grid_view.id, "", &row_1).await;
      assert!(error.is_some());
    }
    let database = test.get_database(&grid_view.id).await;
    assert_eq!(database.rows[0].id, row_1);
    assert_eq!(database.rows[1].id, row_2);
    assert_eq!(database.rows[2].id, row_3);
  }
}

#[tokio::test]
async fn update_text_cell_event_test() {
  let test = FlowyCoreTest::new_with_user().await;
  let current_workspace = test.get_current_workspace().await.workspace;
  let grid_view = test
    .create_grid(&current_workspace.id, "my grid view".to_owned(), vec![])
    .await;
  let database = test.get_database(&grid_view.id).await;
  let fields = test.get_all_database_fields(&grid_view.id).await.items;

  let row_id = database.rows[0].id.clone();
  let field_id = fields[0].id.clone();
  assert_eq!(fields[0].field_type, FieldType::RichText);

  // Update the first cell of the first row.
  let error = test
    .update_cell(CellChangesetPB {
      view_id: grid_view.id.clone(),
      row_id: row_id.clone(),
      field_id: field_id.clone(),
      cell_changeset: "hello world".to_string(),
    })
    .await;
  assert!(error.is_none());

  let cell = test.get_cell(&grid_view.id, &row_id, &field_id).await;
  let s = String::from_utf8(cell.data).unwrap();
  assert_eq!(s, "hello world");
}

#[tokio::test]
async fn update_checkbox_cell_event_test() {
  let test = FlowyCoreTest::new_with_user().await;
  let current_workspace = test.get_current_workspace().await.workspace;
  let grid_view = test
    .create_grid(&current_workspace.id, "my grid view".to_owned(), vec![])
    .await;
  let database = test.get_database(&grid_view.id).await;
  let fields = test.get_all_database_fields(&grid_view.id).await.items;

  let row_id = database.rows[0].id.clone();
  let field_id = fields[2].id.clone();
  assert_eq!(fields[2].field_type, FieldType::Checkbox);

  for input in &["yes", "true", "1"] {
    let error = test
      .update_cell(CellChangesetPB {
        view_id: grid_view.id.clone(),
        row_id: row_id.clone(),
        field_id: field_id.clone(),
        cell_changeset: input.to_string(),
      })
      .await;
    assert!(error.is_none());

    let cell = test.get_cell(&grid_view.id, &row_id, &field_id).await;
    let output = String::from_utf8(cell.data).unwrap();
    assert_eq!(output, "Yes");
  }
}

#[tokio::test]
async fn update_single_select_cell_event_test() {
  let test = FlowyCoreTest::new_with_user().await;
  let current_workspace = test.get_current_workspace().await.workspace;
  let grid_view = test
    .create_grid(&current_workspace.id, "my grid view".to_owned(), vec![])
    .await;
  let database = test.get_database(&grid_view.id).await;
  let fields = test.get_all_database_fields(&grid_view.id).await.items;
  let row_id = database.rows[0].id.clone();
  let field_id = fields[1].id.clone();
  assert_eq!(fields[1].field_type, FieldType::SingleSelect);

  // Insert a new option. This should update the cell with the new option.
  let error = test
    .insert_option(&grid_view.id, &field_id, &row_id, "task 1")
    .await;
  assert!(error.is_none());

  // Check that the cell data is updated.
  let cell = test.get_cell(&grid_view.id, &row_id, &field_id).await;
  let select_option_cell = SelectOptionCellDataPB::try_from(Bytes::from(cell.data)).unwrap();

  assert_eq!(select_option_cell.options.len(), 1);
  assert_eq!(select_option_cell.select_options.len(), 1);
}

#[tokio::test]
async fn update_date_cell_event_test() {
  let test = FlowyCoreTest::new_with_user().await;
  let current_workspace = test.get_current_workspace().await.workspace;
  let grid_view = test
    .create_grid(&current_workspace.id, "my grid view".to_owned(), vec![])
    .await;
  let database = test.get_database(&grid_view.id).await;

  // Create a date field
  let date_field = test.create_field(&grid_view.id, FieldType::DateTime).await;

  let cell_path = CellIdPB {
    view_id: grid_view.id.clone(),
    field_id: date_field.id.clone(),
    row_id: database.rows[0].id.clone(),
  };

  // Insert data into the date cell of the first row.
  let timestamp = 1686300557;
  let timestamp_str = 1686300557.to_string();
  let error = test
    .update_date_cell(DateChangesetPB {
      cell_id: cell_path,
      date: Some(timestamp_str.clone()),
      time: None,
      include_time: None,
    })
    .await;
  assert!(error.is_none());

  // Check that the cell data is updated.
  let cell = test
    .get_date_cell(&grid_view.id, &database.rows[0].id, &date_field.id)
    .await;
  assert_eq!(cell.date, "Jun 09, 2023");
  assert_eq!(cell.timestamp, timestamp);
}

#[tokio::test]
async fn update_date_cell_event_with_empty_time_str_test() {
  let test = FlowyCoreTest::new_with_user().await;
  let current_workspace = test.get_current_workspace().await.workspace;
  let grid_view = test
    .create_grid(&current_workspace.id, "my grid view".to_owned(), vec![])
    .await;
  let database = test.get_database(&grid_view.id).await;
  let row_id = database.rows[0].id.clone();

  // Create a date field
  let date_field = test.create_field(&grid_view.id, FieldType::DateTime).await;
  let cell_path = CellIdPB {
    view_id: grid_view.id.clone(),
    field_id: date_field.id.clone(),
    row_id: row_id.clone(),
  };

  // Insert empty timestamp string
  let error = test
    .update_date_cell(DateChangesetPB {
      cell_id: cell_path,
      date: Some("".to_string()),
      ..Default::default()
    })
    .await;
  assert!(error.is_none());

  // Check that the cell data is updated.
  let cell = test
    .get_date_cell(&grid_view.id, &row_id, &date_field.id)
    .await;
  assert_eq!(cell.date, "");
  assert_eq!(cell.timestamp, 0);
}

#[tokio::test]
async fn create_checklist_field_test() {
  let test = FlowyCoreTest::new_with_user().await;
  let current_workspace = test.get_current_workspace().await.workspace;
  let grid_view = test
    .create_grid(&current_workspace.id, "my grid view".to_owned(), vec![])
    .await;

  // create checklist field
  let checklist_field = test.create_field(&grid_view.id, FieldType::Checklist).await;
  let database = test.get_database(&grid_view.id).await;

  // Get the checklist cell
  let cell = test
    .get_checklist_cell(&grid_view.id, &checklist_field.id, &database.rows[0].id)
    .await;
  assert_eq!(cell.options.len(), 0);
  assert_eq!(cell.selected_options.len(), 0);
  assert_eq!(cell.percentage, 0.0);
}

#[tokio::test]
async fn update_checklist_cell_test() {
  let test = FlowyCoreTest::new_with_user().await;
  let current_workspace = test.get_current_workspace().await.workspace;
  let grid_view = test
    .create_grid(&current_workspace.id, "my grid view".to_owned(), vec![])
    .await;

  // create checklist field
  let checklist_field = test.create_field(&grid_view.id, FieldType::Checklist).await;
  let database = test.get_database(&grid_view.id).await;

  // update the checklist cell
  let changeset = ChecklistCellDataChangesetPB {
    view_id: grid_view.id.clone(),
    row_id: database.rows[0].id.clone(),
    field_id: checklist_field.id.clone(),
    insert_options: vec![
      "task 1".to_string(),
      "task 2".to_string(),
      "task 3".to_string(),
    ],
    selected_option_ids: vec![],
    delete_option_ids: vec![],
    update_options: vec![],
  };
  test.update_checklist_cell(changeset).await;

  // get the cell
  let cell = test
    .get_checklist_cell(&grid_view.id, &checklist_field.id, &database.rows[0].id)
    .await;

  assert_eq!(cell.options.len(), 3);
  assert_eq!(cell.selected_options.len(), 0);

  // select some options
  let changeset = ChecklistCellDataChangesetPB {
    view_id: grid_view.id.clone(),
    row_id: database.rows[0].id.clone(),
    field_id: checklist_field.id.clone(),
    selected_option_ids: vec![cell.options[0].id.clone(), cell.options[1].id.clone()],
    ..Default::default()
  };
  test.update_checklist_cell(changeset).await;

  // get the cell
  let cell = test
    .get_checklist_cell(&grid_view.id, &checklist_field.id, &database.rows[0].id)
    .await;

  assert_eq!(cell.options.len(), 3);
  assert_eq!(cell.selected_options.len(), 2);
  assert_eq!(cell.percentage, 0.6);
}

// The number of groups should be 0 if there is no group by field in grid
#[tokio::test]
async fn get_groups_event_with_grid_test() {
  let test = FlowyCoreTest::new_with_user().await;
  let current_workspace = test.get_current_workspace().await.workspace;
  let grid_view = test
    .create_grid(&current_workspace.id, "my board view".to_owned(), vec![])
    .await;

  let groups = test.get_groups(&grid_view.id).await;
  assert_eq!(groups.len(), 0);
}

#[tokio::test]
async fn get_groups_event_test() {
  let test = FlowyCoreTest::new_with_user().await;
  let current_workspace = test.get_current_workspace().await.workspace;
  let board_view = test
    .create_board(&current_workspace.id, "my board view".to_owned(), vec![])
    .await;

  let groups = test.get_groups(&board_view.id).await;
  assert_eq!(groups.len(), 4);
}

#[tokio::test]
async fn move_group_event_test() {
  let test = FlowyCoreTest::new_with_user().await;
  let current_workspace = test.get_current_workspace().await.workspace;
  let board_view = test
    .create_board(&current_workspace.id, "my board view".to_owned(), vec![])
    .await;

  let groups = test.get_groups(&board_view.id).await;
  assert_eq!(groups.len(), 4);
  let group_1 = groups[0].group_id.clone();
  let group_2 = groups[1].group_id.clone();
  let group_3 = groups[2].group_id.clone();
  let group_4 = groups[3].group_id.clone();

  let error = test.move_group(&board_view.id, &group_2, &group_3).await;
  assert!(error.is_none());

  let groups = test.get_groups(&board_view.id).await;
  assert_eq!(groups[0].group_id, group_1);
  assert_eq!(groups[1].group_id, group_3);
  assert_eq!(groups[2].group_id, group_2);
  assert_eq!(groups[3].group_id, group_4);

  let error = test.move_group(&board_view.id, &group_1, &group_4).await;
  assert!(error.is_none());

  let groups = test.get_groups(&board_view.id).await;
  assert_eq!(groups[0].group_id, group_3);
  assert_eq!(groups[1].group_id, group_2);
  assert_eq!(groups[2].group_id, group_4);
  assert_eq!(groups[3].group_id, group_1);
}

#[tokio::test]
async fn move_group_event_with_invalid_id_test() {
  let test = FlowyCoreTest::new_with_user().await;
  let current_workspace = test.get_current_workspace().await.workspace;
  let board_view = test
    .create_board(&current_workspace.id, "my board view".to_owned(), vec![])
    .await;

  // Empty to group id
  let groups = test.get_groups(&board_view.id).await;
  let error = test
    .move_group(&board_view.id, &groups[0].group_id, "")
    .await;
  assert!(error.is_some());

  // empty from group id
  let error = test
    .move_group(&board_view.id, "", &groups[1].group_id)
    .await;
  assert!(error.is_some());
}

#[tokio::test]
async fn rename_group_event_test() {
  let test = FlowyCoreTest::new_with_user().await;
  let current_workspace = test.get_current_workspace().await.workspace;
  let board_view = test
    .create_board(&current_workspace.id, "my board view".to_owned(), vec![])
    .await;

  // Empty to group id
  let groups = test.get_groups(&board_view.id).await;
  let error = test
    .update_group(
      &board_view.id,
      &groups[0].group_id,
      Some("new name".to_owned()),
      None,
    )
    .await;
  assert!(error.is_none());

  let groups = test.get_groups(&board_view.id).await;
  assert_eq!(groups[0].group_name, "new name".to_owned());
}

#[tokio::test]
async fn hide_group_event_test2() {
  let test = FlowyCoreTest::new_with_user().await;
  let current_workspace = test.get_current_workspace().await.workspace;
  let board_view = test
    .create_board(&current_workspace.id, "my board view".to_owned(), vec![])
    .await;

  // Empty to group id
  let groups = test.get_groups(&board_view.id).await;
  assert_eq!(groups.len(), 4);

  let error = test
    .update_group(&board_view.id, &groups[0].group_id, None, Some(false))
    .await;
  assert!(error.is_none());

  let groups = test.get_groups(&board_view.id).await;
  assert_eq!(groups.len(), 3);
}

// Update the database layout type from grid to board
#[tokio::test]
async fn update_database_layout_event_test() {
  let test = FlowyCoreTest::new_with_user().await;
  let current_workspace = test.get_current_workspace().await.workspace;
  let grid_view = test
    .create_grid(&current_workspace.id, "my grid view".to_owned(), vec![])
    .await;

  let error = test
    .update_setting(DatabaseSettingChangesetPB {
      view_id: grid_view.id.clone(),
      layout_type: Some(DatabaseLayoutPB::Board),
      ..Default::default()
    })
    .await;
  assert!(error.is_none());

  let database = test.get_database(&grid_view.id).await;
  assert_eq!(database.layout_type, DatabaseLayoutPB::Board);
}

// Update the database layout type from grid to board. Set the checkbox field as the grouping field
#[tokio::test]
async fn update_database_layout_event_test2() {
  let test = FlowyCoreTest::new_with_user().await;
  let current_workspace = test.get_current_workspace().await.workspace;
  let grid_view = test
    .create_grid(&current_workspace.id, "my grid view".to_owned(), vec![])
    .await;
  let fields = test.get_all_database_fields(&grid_view.id).await.items;

  let checkbox_field = fields
    .iter()
    .find(|field| field.field_type == FieldType::Checkbox)
    .unwrap();
  test
    .set_group_by_field(&grid_view.id, &checkbox_field.id)
    .await;

  let error = test
    .update_setting(DatabaseSettingChangesetPB {
      view_id: grid_view.id.clone(),
      layout_type: Some(DatabaseLayoutPB::Board),
      ..Default::default()
    })
    .await;
  assert!(error.is_none());

  // Empty to group id
  let groups = test.get_groups(&grid_view.id).await;
  assert_eq!(groups.len(), 2);
}

// Create a checkbox field in the default board and then set it as the grouping field.
#[tokio::test]
async fn set_group_by_checkbox_field_test() {
  let test = FlowyCoreTest::new_with_user().await;
  let current_workspace = test.get_current_workspace().await.workspace;
  let board_view = test
    .create_board(&current_workspace.id, "my board view".to_owned(), vec![])
    .await;

  let checkbox_field = test.create_field(&board_view.id, FieldType::Checkbox).await;
  test
    .set_group_by_field(&board_view.id, &checkbox_field.id)
    .await;

  let groups = test.get_groups(&board_view.id).await;
  assert_eq!(groups.len(), 2);
}

#[tokio::test]
async fn get_all_calendar_event_test() {
  let test = FlowyCoreTest::new_with_user().await;
  let current_workspace = test.get_current_workspace().await.workspace;
  let calendar_view = test
    .create_calendar(&current_workspace.id, "my calendar view".to_owned(), vec![])
    .await;

  // By default, there should be no events
  let events = test.get_all_calendar_events(&calendar_view.id).await;
  assert!(events.is_empty());
}

#[tokio::test]
async fn create_calendar_event_test() {
  let test = FlowyCoreTest::new_with_user().await;
  let current_workspace = test.get_current_workspace().await.workspace;
  let calendar_view = test
    .create_calendar(&current_workspace.id, "my calendar view".to_owned(), vec![])
    .await;
  let fields = test.get_all_database_fields(&calendar_view.id).await.items;
  let date_field = fields
    .iter()
    .find(|field| field.field_type == FieldType::DateTime)
    .unwrap();

  // create a new row
  let row = test.create_row(&calendar_view.id, None, None).await;

  // Insert data into the date cell of the first row.
  let timestamp_str = timestamp().to_string();
  let error = test
    .update_date_cell(DateChangesetPB {
      cell_id: CellIdPB {
        view_id: calendar_view.id.clone(),
        field_id: date_field.id.clone(),
        row_id: row.id,
      },
      date: Some(timestamp_str.clone()),
      time: None,
      include_time: None,
    })
    .await;
  assert!(error.is_none());

  let events = test.get_all_calendar_events(&calendar_view.id).await;
  assert_eq!(events.len(), 1);
}
