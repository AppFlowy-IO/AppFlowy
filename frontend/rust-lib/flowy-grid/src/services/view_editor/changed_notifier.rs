use crate::dart_notification::{send_dart_notification, GridDartNotification};
use crate::entities::{GridRowsVisibilityChangesetPB, ReorderAllRowsPB, ReorderSingleRowPB};
use crate::services::filter::FilterResultNotification;
use crate::services::sort::{ReorderAllRowsResult, ReorderSingleRowResult};
use async_stream::stream;
use futures::stream::StreamExt;
use tokio::sync::broadcast;

#[derive(Clone)]
pub enum GridViewChanged {
    FilterNotification(FilterResultNotification),
    ReorderAllRowsNotification(ReorderAllRowsResult),
    ReorderSingleRowNotification(ReorderSingleRowResult),
}

pub type GridViewChangedNotifier = broadcast::Sender<GridViewChanged>;

pub(crate) struct GridViewChangedReceiverRunner(pub(crate) Option<broadcast::Receiver<GridViewChanged>>);
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
                    GridViewChanged::FilterNotification(notification) => {
                        let changeset = GridRowsVisibilityChangesetPB {
                            view_id: notification.view_id,
                            visible_rows: notification.visible_rows,
                            invisible_rows: notification.invisible_rows,
                        };

                        send_dart_notification(
                            &changeset.view_id,
                            GridDartNotification::DidUpdateGridViewRowsVisibility,
                        )
                        .payload(changeset)
                        .send()
                    }
                    GridViewChanged::ReorderAllRowsNotification(notification) => {
                        let row_orders = ReorderAllRowsPB {
                            row_orders: notification.row_orders,
                        };
                        send_dart_notification(&notification.view_id, GridDartNotification::DidReorderRows)
                            .payload(row_orders)
                            .send()
                    }
                    GridViewChanged::ReorderSingleRowNotification(notification) => {
                        let reorder_row = ReorderSingleRowPB {
                            row_id: notification.row_id,
                            old_index: notification.old_index as i32,
                            new_index: notification.new_index as i32,
                        };
                        send_dart_notification(&notification.view_id, GridDartNotification::DidReorderSingleRow)
                            .payload(reorder_row)
                            .send()
                    }
                }
            })
            .await;
    }
}
