use crate::entities::{DatabaseSyncStatePB, DidFetchRowPB, RowsChangePB};
use crate::notification::{send_notification, DatabaseNotification, DATABASE_OBSERVABLE_SOURCE};
use crate::services::database::{DatabaseEditor, UpdatedRow};
use collab_database::blocks::BlockEvent;
use collab_database::database::Database;
use collab_database::fields::FieldChange;
use collab_database::rows::{RowChange, RowId};
use collab_database::views::DatabaseViewChange;
use flowy_notification::{DebounceNotificationSender, NotificationBuilder};
use futures::StreamExt;
use lib_dispatch::prelude::af_spawn;
use std::sync::Arc;
use std::time::Duration;
use tokio::sync::RwLock;
use tokio_util::sync::CancellationToken;
use tracing::{trace, warn};

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

#[allow(dead_code)]
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
pub(crate) async fn observe_view_change(database_id: &str, database: &Arc<RwLock<Database>>) {
  let database_id = database_id.to_string();
  let weak_database = Arc::downgrade(database);
  let mut view_change = database.read().await.subscribe_view_change();
  af_spawn(async move {
    while let Ok(view_change) = view_change.recv().await {
      if weak_database.upgrade().is_none() {
        break;
      }

      trace!(
        "[Database Observe]: {} view change:{:?}",
        database_id,
        view_change
      );
      match view_change {
        DatabaseViewChange::DidCreateView { .. } => {},
        DatabaseViewChange::DidUpdateView { .. } => {},
        DatabaseViewChange::DidDeleteView { .. } => {},
        DatabaseViewChange::LayoutSettingChanged { .. } => {},
        DatabaseViewChange::DidInsertRowOrders { .. } => {},
        DatabaseViewChange::DidDeleteRowAtIndex { .. } => {},
        DatabaseViewChange::DidCreateFilters { .. } => {},
        DatabaseViewChange::DidUpdateFilter { .. } => {},
        DatabaseViewChange::DidCreateGroupSettings { .. } => {},
        DatabaseViewChange::DidUpdateGroupSetting { .. } => {},
        DatabaseViewChange::DidCreateSorts { .. } => {},
        DatabaseViewChange::DidUpdateSort { .. } => {},
        DatabaseViewChange::DidCreateFieldOrder { .. } => {},
        DatabaseViewChange::DidDeleteFieldOrder { .. } => {},
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
    let token = CancellationToken::new();
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

          // let cloned_token = token.clone();
          // tokio::spawn(async move {
          //   tokio::time::sleep(Duration::from_secs(2)).await;
          //   if cloned_token.is_cancelled() {
          //   }
          //   // if let Some(database_editor) = cloned_database_editor.upgrade() {
          //   // TODO(nathan): calculate inserted row with RowsVisibilityChangePB
          //   // for view_editor in database_editor.database_views.editors().await {
          //   // }
          //   // }
          // });
        },
      }
    }
  });
}

#[allow(dead_code)]
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
