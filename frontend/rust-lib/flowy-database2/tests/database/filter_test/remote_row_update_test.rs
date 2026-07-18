use std::time::Duration;

use collab_database::rows::RowId;
use lib_infra::box_any::BoxAny;

use flowy_database2::entities::{FieldType, SelectOptionFilterConditionPB, SelectOptionFilterPB};
use flowy_database2::services::cell::insert_select_option_cell;
use flowy_database2::services::database_view::DatabaseViewChanged;
use flowy_database2::services::filter::FilterResultNotification;

use crate::database::filter_test::script::DatabaseFilterTest;
use crate::database::mock_data::{COMPLETED, PLANNED};

/// A cell that is modified without going through `DatabaseEditor::update_cell`,
/// e.g. when a remote user's edit is applied through synchronization, must still
/// trigger a filter recalculation so that the filtered view refreshes.
///
/// See https://github.com/AppFlowy-IO/AppFlowy/issues/8806.
///
/// `DatabaseEditor::update_row` writes the cell directly to the underlying
/// collab document, bypassing the local edit path. Both this and a synced remote
/// edit reach the database editor exclusively through the row-change observer,
/// making it a faithful stand-in for a remote update.
#[tokio::test]
async fn remote_cell_update_shows_row_in_filtered_view_test() {
  let mut test = DatabaseFilterTest::new().await;
  let expected = 2;

  // Create a "Status is Completed" filter. Rows 2 and 3 are Completed.
  let field = test.get_first_field(FieldType::SingleSelect).await;
  let options = test.get_single_select_type_option(&field.id).await;
  let completed_option_id = options
    .iter()
    .find(|option| option.name == COMPLETED)
    .unwrap()
    .id
    .clone();
  test
    .create_data_filter(
      None,
      FieldType::SingleSelect,
      BoxAny::new(SelectOptionFilterPB {
        condition: SelectOptionFilterConditionPB::OptionIs,
        option_ids: vec![completed_option_id.clone()],
      }),
      None,
    )
    .await;
  test.assert_number_of_visible_rows(expected).await;

  // Simulate a remote edit: assign "Completed" to row 0 (whose status is empty)
  // by writing the cell directly to the underlying collab document, bypassing
  // the DatabaseEditor::update_cell path.
  let row_id = test.rows[0].id.clone();
  let cell = insert_select_option_cell(vec![completed_option_id], &field);
  let recv = test
    .editor
    .subscribe_view_changed(&test.view_id)
    .await
    .unwrap();
  test
    .editor
    .update_row(row_id.clone(), |row_update| {
      row_update.update_cells(|cell_update| {
        cell_update.insert(&field.id, cell);
      });
    })
    .await
    .unwrap();

  // The filtered view must be notified that the row became visible.
  let notification = wait_for_filter_notification(recv, &row_id, true).await;
  assert_eq!(
    notification.visible_rows.len(),
    1,
    "expected the remotely updated row to become visible"
  );
  assert_eq!(notification.visible_rows[0].row_meta.id, row_id.to_string());
  assert!(notification.invisible_rows.is_empty());
}

/// The counterpart of the test above: a remote cell update that makes a row stop
/// matching the filter must hide the row in the filtered view.
#[tokio::test]
async fn remote_cell_update_hides_row_in_filtered_view_test() {
  let mut test = DatabaseFilterTest::new().await;
  let expected = 2;

  // Create a "Status is Completed" filter. Rows 2 and 3 are Completed.
  let field = test.get_first_field(FieldType::SingleSelect).await;
  let options = test.get_single_select_type_option(&field.id).await;
  let completed_option_id = options
    .iter()
    .find(|option| option.name == COMPLETED)
    .unwrap()
    .id
    .clone();
  let planned_option_id = options
    .iter()
    .find(|option| option.name == PLANNED)
    .unwrap()
    .id
    .clone();
  test
    .create_data_filter(
      None,
      FieldType::SingleSelect,
      BoxAny::new(SelectOptionFilterPB {
        condition: SelectOptionFilterConditionPB::OptionIs,
        option_ids: vec![completed_option_id],
      }),
      None,
    )
    .await;
  test.assert_number_of_visible_rows(expected).await;

  // Simulate a remote edit: change row 2 from "Completed" to "Planned" by
  // writing the cell directly to the underlying collab document, bypassing the
  // DatabaseEditor::update_cell path.
  let row_id = test.rows[2].id.clone();
  let cell = insert_select_option_cell(vec![planned_option_id], &field);
  let recv = test
    .editor
    .subscribe_view_changed(&test.view_id)
    .await
    .unwrap();
  test
    .editor
    .update_row(row_id.clone(), |row_update| {
      row_update.update_cells(|cell_update| {
        cell_update.insert(&field.id, cell);
      });
    })
    .await
    .unwrap();

  // The filtered view must be notified that the row became invisible.
  let notification = wait_for_filter_notification(recv, &row_id, false).await;
  assert_eq!(
    notification.invisible_rows.len(),
    1,
    "expected the remotely updated row to become invisible"
  );
  assert_eq!(notification.invisible_rows[0], row_id);
  assert!(notification.visible_rows.is_empty());
}

async fn wait_for_filter_notification(
  mut recv: tokio::sync::broadcast::Receiver<DatabaseViewChanged>,
  row_id: &RowId,
  expect_visible: bool,
) -> FilterResultNotification {
  let row_id = row_id.clone();
  let row_id_string = row_id.to_string();
  tokio::time::timeout(Duration::from_secs(2), async move {
    loop {
      match recv.recv().await {
        Ok(DatabaseViewChanged::FilterNotification(notification)) => {
          if expect_visible
            && notification
              .visible_rows
              .iter()
              .any(|row| row.row_meta.id == row_id_string)
          {
            break notification;
          }
          if !expect_visible && notification.invisible_rows.iter().any(|id| id == &row_id) {
            break notification;
          }
        },
        Ok(_) => continue,
        Err(err) => panic!("view changed channel closed: {:?}", err),
      }
    }
  })
  .await
  .expect("the filter was not recalculated after a remote row update")
}
