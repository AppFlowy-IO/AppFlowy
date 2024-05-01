use crate::entities::{DatabaseSyncStatePB, DidFetchRowPB, RowsChangePB};
use crate::notification::{send_notification, DatabaseNotification, DATABASE_OBSERVABLE_SOURCE};
use crate::services::database::UpdatedRow;
use collab_database::blocks::BlockEvent;
use collab_database::database::MutexDatabase;
use collab_database::fields::FieldChange;
use collab_database::rows::{RowChange, RowId};
use collab_database::views::DatabaseViewChange;
use flowy_notification::{DebounceNotificationSender, NotificationBuilder};
use futures::StreamExt;
use lib_dispatch::prelude::af_spawn;
use std::sync::Arc;
use tracing::{trace, warn};

pub(crate) async fn observe_sync_state(database_id: &str, database: &Arc<MutexDatabase>) {
  let weak_database = Arc::downgrade(database);
  let mut sync_state = database.lock().subscribe_sync_state();
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
  database: &Arc<MutexDatabase>,
  notification_sender: &Arc<DebounceNotificationSender>,
) {
  let notification_sender = notification_sender.clone();
  let database_id = database_id.to_string();
  let weak_database = Arc::downgrade(database);
  let mut row_change = database.lock().subscribe_row_change();
  af_spawn(async move {
    while let Ok(row_change) = row_change.recv().await {
      if weak_database.upgrade().is_none() {
        break;
      }

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
          // In the old logic, it will notify the row when the cell is updated. But in the new logic,
          // it will notify the cell only. Enable the following code if needed.
          // notify_row(&notification_sender, &database_id, field_id, &row_id);
        },
        _ => {
          warn!("unhandled row change: {:?}", row_change);
        },
      }
    }
  });
}
#[allow(dead_code)]
pub(crate) async fn observe_field_change(database_id: &str, database: &Arc<MutexDatabase>) {
  let database_id = database_id.to_string();
  let weak_database = Arc::downgrade(database);
  let mut field_change = database.lock().subscribe_field_change();
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
pub(crate) async fn observe_view_change(database_id: &str, database: &Arc<MutexDatabase>) {
  let database_id = database_id.to_string();
  let weak_database = Arc::downgrade(database);
  let mut view_change = database.lock().subscribe_view_change();
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

#[allow(dead_code)]
pub(crate) async fn observe_block_event(database_id: &str, database: &Arc<MutexDatabase>) {
  let database_id = database_id.to_string();
  let weak_database = Arc::downgrade(database);
  let mut block_event_rx = database.lock().subscribe_block_event();
  af_spawn(async move {
    while let Ok(event) = block_event_rx.recv().await {
      if weak_database.upgrade().is_none() {
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

#[allow(dead_code)]
fn notify_row(
  notification_sender: &Arc<DebounceNotificationSender>,
  _database_id: &str,
  field_id: String,
  row_id: &RowId,
) {
  let update_row = UpdatedRow::new(&row_id).with_field_ids(vec![field_id]);
  let update_changeset = RowsChangePB::from_update(update_row.into());
  let subject = NotificationBuilder::new(
    row_id,
    DatabaseNotification::DidUpdateRow,
    DATABASE_OBSERVABLE_SOURCE,
  )
  .payload(update_changeset)
  .build();
  notification_sender.send_subject(subject);
}

fn notify_cell(notification_sender: &Arc<DebounceNotificationSender>, cell_id: &String) {
  let subject = NotificationBuilder::new(
    &cell_id,
    DatabaseNotification::DidUpdateCell,
    DATABASE_OBSERVABLE_SOURCE,
  )
  .build();
  notification_sender.send_subject(subject);
}
