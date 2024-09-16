use crate::entities::{DatabaseSyncStatePB, DidFetchRowPB, RowsChangePB};
use crate::notification::{send_notification, DatabaseNotification, DATABASE_OBSERVABLE_SOURCE};
use crate::services::database::{DatabaseEditor, UpdatedRow};
use crate::services::database_view::DatabaseViewEditor;
use collab::lock::RwLock;
use collab_database::blocks::BlockEvent;
use collab_database::database::Database;
use collab_database::fields::FieldChange;
use collab_database::rows::{RowChange, RowId};
use collab_database::views::{DatabaseViewChange, RowOrder};
use dashmap::DashMap;
use flowy_notification::{DebounceNotificationSender, NotificationBuilder};
use futures::StreamExt;
use lib_dispatch::prelude::af_spawn;
use std::sync::Arc;
use tracing::{error, trace, warn};

pub(crate) async fn observe_sync_state(database_id: &str, database: &Arc<RwLock<Database>>) {
  let weak_database = Arc::downgrade(database);
  let mut sync_state = database.read().await.subscribe_sync_state();
  let database_id = database_id.to_string();
  af_spawn(async move {
    while let Some(sync_state) = sync_state.next().await {
      if weak_database.upgrade().is_none() {
        break;
      }

      send_notification(
        &database_id,
        DatabaseNotification::DidUpdateDatabaseSyncUpdate,
      )
      .payload(DatabaseSyncStatePB::from(sync_state))
      .send();
    }
  });
}

pub(crate) async fn observe_rows_change(
  database_id: &str,
  database: &Arc<RwLock<Database>>,
  notification_sender: &Arc<DebounceNotificationSender>,
) {
  let notification_sender = notification_sender.clone();
  let database_id = database_id.to_string();
  let weak_database = Arc::downgrade(database);
  let sub = database.read().await.subscribe_row_change();
  if let Some(mut row_change) = sub {
    af_spawn(async move {
      while let Ok(row_change) = row_change.recv().await {
        if let Some(database) = weak_database.upgrade() {
          trace!(
            "[Database Observe]: {} row change:{:?}",
            database_id,
            row_change
          );
          match row_change {
            RowChange::DidUpdateCell {
              field_id,
              row_id,
              value: _,
            } => {
              let cell_id = format!("{}:{}", row_id, field_id);
              notify_cell(&notification_sender, &cell_id);

              let views = database.read().await.get_all_database_views_meta();
              for view in views {
                notify_row(&notification_sender, &view.id, &field_id, &row_id);
              }
            },
            _ => {
              warn!("unhandled row change: {:?}", row_change);
            },
          }
        } else {
          break;
        }
      }
    });
  }
}
#[allow(dead_code)]
pub(crate) async fn observe_field_change(database_id: &str, database: &Arc<RwLock<Database>>) {
  let database_id = database_id.to_string();
  let weak_database = Arc::downgrade(database);
  let sub = database.read().await.subscribe_field_change();
  if let Some(mut field_change) = sub {
    af_spawn(async move {
      while let Ok(field_change) = field_change.recv().await {
        if weak_database.upgrade().is_none() {
          break;
        }

        trace!(
          "[Database Observe]: {} field change:{:?}",
          database_id,
          field_change
        );
        match field_change {
          FieldChange::DidUpdateField { .. } => {},
          FieldChange::DidCreateField { .. } => {},
          FieldChange::DidDeleteField { .. } => {},
        }
      }
    });
  }
}

#[allow(dead_code)]
pub(crate) async fn observe_view_change(database_id: &str, database_editor: &Arc<DatabaseEditor>) {
  let database_id = database_id.to_string();
  let weak_database_editor = Arc::downgrade(database_editor);
  let view_change = database_editor
    .database
    .read()
    .await
    .subscribe_view_change();

  if let Some(mut view_change) = view_change {
    af_spawn(async move {
      while let Ok(view_change) = view_change.recv().await {
        trace!(
          "[Database View Observe]: {} view change:{:?}",
          database_id,
          view_change
        );
        match weak_database_editor.upgrade() {
          None => break,
          Some(database_editor) => match view_change {
            DatabaseViewChange::DidCreateView { .. } => {},
            DatabaseViewChange::DidUpdateView { .. } => {},
            DatabaseViewChange::DidDeleteView { .. } => {},
            DatabaseViewChange::LayoutSettingChanged { .. } => {},
            DatabaseViewChange::DidUpdateRowOrders {
              database_view_id: _,
              is_local_change,
              insert_row_orders,
              delete_row_indexes,
            } => {
              handle_did_update_row_orders(
                database_editor,
                is_local_change,
                insert_row_orders,
                delete_row_indexes,
              )
              .await;
            },
            DatabaseViewChange::DidCreateFilters { .. } => {},
            DatabaseViewChange::DidUpdateFilter { .. } => {},
            DatabaseViewChange::DidCreateGroupSettings { .. } => {},
            DatabaseViewChange::DidUpdateGroupSetting { .. } => {},
            DatabaseViewChange::DidCreateSorts { .. } => {},
            DatabaseViewChange::DidUpdateSort { .. } => {},
            DatabaseViewChange::DidCreateFieldOrder { .. } => {},
            DatabaseViewChange::DidDeleteFieldOrder { .. } => {},
          },
        }
      }
    });
  }
}

async fn handle_did_update_row_orders(
  database_editor: Arc<DatabaseEditor>,
  is_local_change: bool,
  insert_row_orders: Vec<(RowOrder, u32)>,
  delete_row_indexes: Vec<u32>,
) {
  // DidUpdateRowOrders is triggered whenever a user performs operations such as
  // deleting, inserting, or moving a row in the database.
  //
  // Before DidUpdateRowOrders is called, the changes (insert/move/delete) have already been
  // applied to the underlying database. This means the current order of rows reflects these updates.
  //
  // Example:
  // Imagine the current state of rows is:
  // Before any changes: [a, b, c]
  //
  // Operation: Move 'a' before 'c'
  // Initial state: [a, b, c]
  //
  // Move 'a' to before 'c': This operation is divided into two parts:
  //     Insert row orders: Insert a at position 2 (right before c).
  //     Delete row indexes: Delete a from its original position (index 0).
  //     The steps are:
  //
  //     Insert row: After inserting a at position 2, the rows temporarily look like this:
  //     Insert row orders: [(a, 2)]
  // State after insert: [a, b, a, c]
  // Delete row: Next, we delete a from its original position at index 0.
  // Delete row indexes: [0]
  // Final state after delete: [b, a, c]
  let row_changes = DashMap::new();
  // 1. handle insert row orders
  for (row_order, index) in insert_row_orders {
    if let Err(err) = database_editor.init_database_row(&row_order.id).await {
      error!("Failed to init row: {:?}", err);
    }

    for database_view in database_editor.database_views.editors().await {
      trace!(
        "[RowOrder]: insert row:{} at index:{}, is_local:{}",
        row_order.id,
        index,
        is_local_change
      );

      // insert row order in database view cache
      {
        let mut view_row_orders = database_view.row_orders.write().await;
        if view_row_orders.len() >= index as usize {
          view_row_orders.insert(index as usize, row_order.clone());
        } else {
          warn!(
            "[RowOrder]: insert row at index:{} out of range:{}",
            index,
            view_row_orders.len()
          );
        }
      }

      let is_move_row = is_move_row(&database_view, &row_order, &delete_row_indexes).await;

      if let Some((index, row_detail)) = database_view.v_get_row(&row_order.id).await {
        database_view
          .v_did_create_row(
            &row_detail,
            index as u32,
            is_move_row,
            is_local_change,
            &row_changes,
          )
          .await;
      }
    }
  }

  // handle delete row orders
  for index in delete_row_indexes {
    let index = index as usize;
    for database_view in database_editor.database_views.editors().await {
      let mut view_row_orders = database_view.row_orders.write().await;
      if view_row_orders.len() > index {
        let lazy_row = view_row_orders.remove(index);
        // Update changeset in RowsChangePB
        let row_id = lazy_row.id.to_string();
        let mut row_change = row_changes
          .entry(database_view.view_id.clone())
          .or_default();
        row_change.deleted_rows.push(row_id);

        // notify the view
        if let Some(row) = database_view.row_by_row_id.get(lazy_row.id.as_str()) {
          trace!(
            "[RowOrder]: delete row:{} at index:{}, is_move_row: {}, is_local:{}",
            row.id,
            index,
            row_change.is_move_row,
            is_local_change
          );
          database_view
            .v_did_delete_row(&row, row_change.is_move_row, is_local_change)
            .await;
        } else {
          error!("[RowOrder]: row not found: {} in cache", lazy_row.id);
        }
      } else {
        warn!(
          "[RowOrder]: delete row at index:{} out of range:{}",
          index,
          view_row_orders.len()
        );
      }
    }
  }

  // 3. notify the view
  for entry in row_changes.into_iter() {
    let (view_id, changes) = entry;
    trace!("[RowOrder]: {}", changes);
    send_notification(&view_id, DatabaseNotification::DidUpdateRow)
      .payload(changes)
      .send();
  }
}

pub(crate) async fn observe_block_event(database_id: &str, database_editor: &Arc<DatabaseEditor>) {
  let database_id = database_id.to_string();
  let mut block_event_rx = database_editor
    .database
    .read()
    .await
    .subscribe_block_event();
  let database_editor = Arc::downgrade(database_editor);
  af_spawn(async move {
    while let Ok(event) = block_event_rx.recv().await {
      if database_editor.upgrade().is_none() {
        break;
      }

      trace!(
        "[Database Observe]: {} block event: {:?}",
        database_id,
        event
      );
      match event {
        BlockEvent::DidFetchRow(row_details) => {
          for row_detail in row_details {
            trace!("Did fetch row: {:?}", row_detail.row.id);
            let row_id = row_detail.row.id.clone();
            let pb = DidFetchRowPB::from(row_detail);
            send_notification(&row_id, DatabaseNotification::DidFetchRow)
              .payload(pb)
              .send();
          }
        },
      }
    }
  });
}

fn notify_row(
  notification_sender: &Arc<DebounceNotificationSender>,
  view_id: &str,
  field_id: &str,
  row_id: &RowId,
) {
  let update_row = UpdatedRow::new(row_id).with_field_ids(vec![field_id.to_string()]);
  let update_changeset = RowsChangePB::from_update(update_row.into());
  let subject = NotificationBuilder::new(
    view_id,
    DatabaseNotification::DidUpdateRow,
    DATABASE_OBSERVABLE_SOURCE,
  )
  .payload(update_changeset)
  .build();
  notification_sender.send_subject(subject);
}

fn notify_cell(notification_sender: &Arc<DebounceNotificationSender>, cell_id: &str) {
  let subject = NotificationBuilder::new(
    cell_id,
    DatabaseNotification::DidUpdateCell,
    DATABASE_OBSERVABLE_SOURCE,
  )
  .build();
  notification_sender.send_subject(subject);
}

async fn is_move_row(
  database_view: &Arc<DatabaseViewEditor>,
  insert_row_order: &RowOrder,
  delete_row_indexes: &[u32],
) -> bool {
  let mut is_move_row = false;
  for index in delete_row_indexes.iter() {
    is_move_row = database_view
      .row_orders
      .read()
      .await
      .get(*index as usize)
      .map(|deleted_row_order| deleted_row_order == insert_row_order)
      .unwrap_or(false);

    if is_move_row {
      break;
    }
  }

  is_move_row
}
