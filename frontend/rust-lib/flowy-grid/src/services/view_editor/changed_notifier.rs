use crate::dart_notification::{send_dart_notification, GridDartNotification};
use crate::entities::GridBlockChangesetPB;
use crate::services::filter::FilterResultNotification;
use async_stream::stream;
use futures::stream::StreamExt;
use tokio::sync::broadcast;

#[derive(Clone)]
pub enum GridViewChanged {
    DidReceiveFilterResult(FilterResultNotification),
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
                    GridViewChanged::DidReceiveFilterResult(notification) => {
                        let changeset = GridBlockChangesetPB {
                            block_id: notification.block_id,
                            visible_rows: notification.visible_rows,
                            invisible_rows: notification.invisible_rows,
                            ..Default::default()
                        };

                        send_dart_notification(&changeset.block_id, GridDartNotification::DidUpdateGridBlock)
                            .payload(changeset)
                            .send()
                    }
                }
            })
            .await;
    }
}
