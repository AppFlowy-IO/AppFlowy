use crate::entities::{ReorderAllRowsPB, ReorderSingleRowPB, ViewRowsVisibilityChangesetPB};
use crate::notification::{send_notification, DatabaseNotification};
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
}

pub type GridViewChangedNotifier = broadcast::Sender<DatabaseViewChanged>;

pub(crate) struct GridViewChangedReceiverRunner(
  pub(crate) Option<broadcast::Receiver<DatabaseViewChanged>>,
);
impl GridViewChangedReceiverRunner {
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
            let changeset = ViewRowsVisibilityChangesetPB {
              view_id: notification.view_id,
              visible_rows: notification.visible_rows,
              invisible_rows: notification.invisible_rows,
            };

            send_notification(
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
            send_notification(&notification.view_id, DatabaseNotification::DidReorderRows)
              .payload(row_orders)
              .send()
          },
          DatabaseViewChanged::ReorderSingleRowNotification(notification) => {
            let reorder_row = ReorderSingleRowPB {
              row_id: notification.row_id,
              old_index: notification.old_index as i32,
              new_index: notification.new_index as i32,
            };
            send_notification(
              &notification.view_id,
              DatabaseNotification::DidReorderSingleRow,
            )
            .payload(reorder_row)
            .send()
          },
        }
      })
      .await;
  }
}
