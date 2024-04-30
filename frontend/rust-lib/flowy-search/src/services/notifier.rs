use async_stream::stream;
use flowy_notification::NotificationBuilder;
use futures::stream::StreamExt;
use tokio::sync::broadcast;

use crate::entities::{SearchNotification, SearchResultNotificationPB};

const SEARCH_OBSERVABLE_SOURCE: &str = "Search";
const SEARCH_ID: &str = "SEARCH_IDENTIFIER";

#[derive(Clone)]
pub enum SearchResultChanged {
  SearchResultUpdate(SearchResultNotificationPB),
}

pub type SearchNotifier = broadcast::Sender<SearchResultChanged>;

pub(crate) struct SearchResultReceiverRunner(
  pub(crate) Option<broadcast::Receiver<SearchResultChanged>>,
);

impl SearchResultReceiverRunner {
  pub(crate) async fn run(mut self) {
    let mut receiver = self.0.take().expect("Only take once");
    let stream = stream! {
        while let Ok(changed) = receiver.recv().await {
            yield changed;
        }
    };
    stream
      .for_each(|changed| async {
        match changed {
          SearchResultChanged::SearchResultUpdate(notification) => {
            let ty = if notification.closed {
              SearchNotification::DidCloseResults
            } else {
              SearchNotification::DidUpdateResults
            };

            send_notification(SEARCH_ID, ty, notification.channel.clone())
              .payload(notification)
              .send();
          },
        }
      })
      .await;
  }
}

#[tracing::instrument(level = "trace")]
pub fn send_notification(
  id: &str,
  ty: SearchNotification,
  channel: Option<String>,
) -> NotificationBuilder {
  let observable_source = &format!(
    "{}{}",
    SEARCH_OBSERVABLE_SOURCE,
    channel.unwrap_or_default()
  );

  NotificationBuilder::new(id, ty, observable_source)
}
