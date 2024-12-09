#![allow(clippy::while_let_loop)]
use crate::entities::{
  CalculationChangesetNotificationPB, DatabaseViewSettingPB, FilterChangesetNotificationPB,
  GroupChangesPB, GroupRowsNotificationPB, ReorderAllRowsPB, ReorderSingleRowPB,
  RowsVisibilityChangePB, SortChangesetNotificationPB,
};
use crate::notification::{database_notification_builder, DatabaseNotification};
use crate::services::filter::FilterResultNotification;
use crate::services::sort::{ReorderAllRowsResult, ReorderSingleRowResult};
use async_stream::stream;
use futures::stream::StreamExt;
use tokio::sync::broadcast;

#[derive(Clone)]
pub enum DatabaseViewChanged {
  FilterNotification(FilterResultNotification),
  ReorderAllRowsNotification(ReorderAllRowsResult),
  ReorderSingleRowNotification(ReorderSingleRowResult),
  CalculationValueNotification(CalculationChangesetNotificationPB),
}

pub type DatabaseViewChangedNotifier = broadcast::Sender<DatabaseViewChanged>;

pub(crate) struct DatabaseViewChangedReceiverRunner(
  pub(crate) Option<broadcast::Receiver<DatabaseViewChanged>>,
);

impl DatabaseViewChangedReceiverRunner {
  pub(crate) async fn run(mut self) {
    let mut receiver = self.0.take().expect("Only take once");
    let stream = stream! {
        loop {
            match receiver.recv().await {
                Ok(changed) => yield changed,
                Err(_e) => break,
            }
        }
    };
    stream
      .for_each(|changed| async {
        match changed {
          DatabaseViewChanged::FilterNotification(notification) => {
            let changeset = RowsVisibilityChangePB {
              view_id: notification.view_id,
              visible_rows: notification.visible_rows,
              invisible_rows: notification
                .invisible_rows
                .into_iter()
                .map(|row| row.into_inner())
                .collect(),
            };

            database_notification_builder(
              &changeset.view_id,
              DatabaseNotification::DidUpdateViewRowsVisibility,
            )
            .payload(changeset)
            .send()
          },
          DatabaseViewChanged::ReorderAllRowsNotification(notification) => {
            let row_orders = ReorderAllRowsPB {
              row_orders: notification.row_orders,
            };
            database_notification_builder(
              &notification.view_id,
              DatabaseNotification::DidReorderRows,
            )
            .payload(row_orders)
            .send()
          },
          DatabaseViewChanged::ReorderSingleRowNotification(notification) => {
            let reorder_row = ReorderSingleRowPB {
              row_id: notification.row_id.into_inner(),
              old_index: notification.old_index as i32,
              new_index: notification.new_index as i32,
            };
            database_notification_builder(
              &notification.view_id,
              DatabaseNotification::DidReorderSingleRow,
            )
            .payload(reorder_row)
            .send()
          },
          DatabaseViewChanged::CalculationValueNotification(notification) => {
            database_notification_builder(
              &notification.view_id,
              DatabaseNotification::DidUpdateCalculation,
            )
            .payload(notification)
            .send()
          },
        }
      })
      .await;
  }
}

pub async fn notify_did_update_group_rows(payload: GroupRowsNotificationPB) {
  database_notification_builder(&payload.group_id, DatabaseNotification::DidUpdateGroupRow)
    .payload(payload)
    .send();
}

pub async fn notify_did_update_filter(notification: FilterChangesetNotificationPB) {
  database_notification_builder(&notification.view_id, DatabaseNotification::DidUpdateFilter)
    .payload(notification)
    .send();
}

pub async fn notify_did_update_calculation(notification: CalculationChangesetNotificationPB) {
  database_notification_builder(
    &notification.view_id,
    DatabaseNotification::DidUpdateCalculation,
  )
  .payload(notification)
  .send();
}

pub async fn notify_did_update_sort(notification: SortChangesetNotificationPB) {
  if !notification.is_empty() {
    database_notification_builder(&notification.view_id, DatabaseNotification::DidUpdateSort)
      .payload(notification)
      .send();
  }
}

pub(crate) async fn notify_did_update_num_of_groups(view_id: &str, changeset: GroupChangesPB) {
  database_notification_builder(view_id, DatabaseNotification::DidUpdateNumOfGroups)
    .payload(changeset)
    .send();
}

pub(crate) async fn notify_did_update_setting(view_id: &str, setting: DatabaseViewSettingPB) {
  database_notification_builder(view_id, DatabaseNotification::DidUpdateSettings)
    .payload(setting)
    .send();
}
