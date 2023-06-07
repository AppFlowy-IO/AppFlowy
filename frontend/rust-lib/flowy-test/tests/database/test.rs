use flowy_database2::entities::{DatabaseLayoutPB, DatabaseViewIdPB, FieldType};
use flowy_test::event_builder::EventBuilder;
use flowy_test::FlowyCoreTest;

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
