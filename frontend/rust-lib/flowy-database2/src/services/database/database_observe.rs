use crate::entities::{DatabaseSyncStatePB, DidFetchRowPB, InsertedRowPB, RowMetaPB, RowsChangePB};
use crate::notification::{send_notification, DatabaseNotification, DATABASE_OBSERVABLE_SOURCE};
use crate::services::database::{DatabaseEditor, UpdatedRow};
use crate::services::database_view::LazyRow;
use collab::lock::RwLock;
use collab_database::blocks::BlockEvent;
use collab_database::database::Database;
use collab_database::fields::FieldChange;
use collab_database::rows::{RowChange, RowId};
use collab_database::views::DatabaseViewChange;
use dashmap::DashMap;
use flowy_notification::{DebounceNotificationSender, NotificationBuilder};
use futures::StreamExt;
use lib_dispatch::prelude::af_spawn;
use std::sync::Arc;
use tracing::{error, info, trace, warn};

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
  let mut row_change = database.read().await.subscribe_row_change();
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
#[allow(dead_code)]
pub(crate) async fn observe_field_change(database_id: &str, database: &Arc<RwLock<Database>>) {
  let database_id = database_id.to_string();
  let weak_database = Arc::downgrade(database);
  let mut field_change = database.read().await.subscribe_field_change();
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

#[allow(dead_code)]
pub(crate) async fn observe_view_change(database_id: &str, database_editor: &Arc<DatabaseEditor>) {
  let database_id = database_id.to_string();
  let weak_database_editor = Arc::downgrade(database_editor);
  let mut view_change = database_editor
    .database
    .read()
    .await
    .subscribe_view_change();
  af_spawn(async move {
    while let Ok(view_change) = view_change.recv().await {
      trace!(
        "[Database View Observe]: {} view change:{:?}",
        database_id,
        view_change
      );
      match weak_database_editor.upgrade() {
        None => break,
        Some(database_editor) => {
          match view_change {
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
              let database_view_rows = DashMap::new();
              // 1. handle insert row orders
              for (row_order, index) in insert_row_orders {
                if let Err(err) = database_editor.init_database_row(&row_order.id).await {
                  error!("Failed to init row: {:?}", err);
                }

                for view in database_editor.database_views.editors().await {
                  trace!("[RowOrder]: insert row:{} at index:{}", row_order.id, index);
                  if let Some(row) = database_editor.get_row(&view.view_id, &row_order.id).await {
                    view.v_did_create_row(&row, index).await;
                  }

                  // insert row order
                  {
                    let mut view_row_orders = view.row_orders.write().await;
                    if view_row_orders.len() >= index as usize {
                      view_row_orders.insert(index as usize, LazyRow::new(row_order.clone()));
                      info!(
                        "[RowOrder]: view row orders after:{:?}",
                        view_row_orders
                          .iter()
                          .map(|x| x.row_id().to_string())
                          .collect::<Vec<String>>()
                      );
                    } else {
                      warn!(
                        "[RowOrder]: insert row at index:{} out of range:{}",
                        index,
                        view_row_orders.len()
                      );
                    }
                  }

                  // gather changes for notification
                  if let Some((index, row_detail)) = view.v_get_row(&row_order.id).await {
                    database_view_rows
                      .entry(view.view_id.clone())
                      .or_insert(RowsChangePB::default())
                      .inserted_rows
                      .push(
                        InsertedRowPB::new(RowMetaPB::from(row_detail.as_ref()))
                          .with_index(index as i32),
                      );
                  }
                }
              }
              // handle delete row orders
              for index in delete_row_indexes {
                for database_view in database_editor.database_views.editors().await {
                  let mut view_row_orders = database_view.row_orders.write().await;
                  if view_row_orders.len() > index as usize {
                    let lazy_row = view_row_orders.remove(index as usize);
                    // Update changeset in RowsChangePB
                    let row_id = lazy_row.row_id().to_string();
                    let mut row_change = database_view_rows
                      .entry(database_view.view_id.clone())
                      .or_default();

                    row_change.is_move_row = row_change
                      .inserted_rows
                      .first()
                      .map_or(false, |row_change| row_change.row_meta.id == row_id);
                    row_change.deleted_rows.push(row_id);

                    // notify the view
                    if let Some(row) = database_editor
                      .get_row(&database_view.view_id, lazy_row.row_id())
                      .await
                    {
                      trace!(
                        "[RowOrder]: Did delete row:{} at index:{}, is_move_row: {}",
                        row.id,
                        index,
                        row_change.is_move_row
                      );
                      database_view
                        .v_did_delete_row(&row, row_change.is_move_row, is_local_change)
                        .await;
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
              for entry in database_view_rows.into_iter() {
                let (view_id, changes) = entry;
                trace!("[RowOrder]: changes {}", changes);
                send_notification(&view_id, DatabaseNotification::DidUpdateRow)
                  .payload(changes)
                  .send();
              }
            },
            DatabaseViewChange::DidCreateFilters { .. } => {},
            DatabaseViewChange::DidUpdateFilter { .. } => {},
            DatabaseViewChange::DidCreateGroupSettings { .. } => {},
            DatabaseViewChange::DidUpdateGroupSetting { .. } => {},
            DatabaseViewChange::DidCreateSorts { .. } => {},
            DatabaseViewChange::DidUpdateSort { .. } => {},
            DatabaseViewChange::DidCreateFieldOrder { .. } => {},
            DatabaseViewChange::DidDeleteFieldOrder { .. } => {},
          }
        },
      }
    }
  });
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
