use crate::{
    errors::{internal_error, DocResult},
    services::doc::revision::RevisionIterator,
};
use async_stream::stream;
use futures::stream::StreamExt;
use lib_ot::revision::Revision;
use std::sync::Arc;
use tokio::{
    sync::mpsc,
    time::{interval, Duration},
};

pub(crate) enum RevisionMsg {
    Tick,
}

pub(crate) struct RevisionUploadStream {
    revisions: Arc<dyn RevisionIterator>,
    ws_sender: mpsc::UnboundedSender<Revision>,
}

impl RevisionUploadStream {
    pub(crate) fn new(revisions: Arc<dyn RevisionIterator>, ws_sender: mpsc::UnboundedSender<Revision>) -> Self {
        Self { revisions, ws_sender }
    }

    pub async fn run(self) {
        let (tx, mut rx) = mpsc::unbounded_channel();
        tokio::spawn(tick(tx));
        let stream = stream! {
            loop {
                match rx.recv().await {
                    Some(msg) => yield msg,
                    None => break,
                }
            }
        };
        stream
            .for_each(|msg| async {
                match self.handle_msg(msg).await {
                    Ok(_) => {},
                    Err(e) => log::error!("{:?}", e),
                }
            })
            .await;
    }

    async fn handle_msg(&self, msg: RevisionMsg) -> DocResult<()> {
        match msg {
            RevisionMsg::Tick => self.send_next_revision().await,
        }
    }

    async fn send_next_revision(&self) -> DocResult<()> {
        match self.revisions.next().await? {
            None => Ok(()),
            Some(record) => {
                let _ = self.ws_sender.send(record.revision).map_err(internal_error);
                // let _ = tokio::time::timeout(Duration::from_millis(2000), ret.recv()).await;
                Ok(())
            },
        }
    }
}

async fn tick(sender: mpsc::UnboundedSender<RevisionMsg>) {
    let mut i = interval(Duration::from_secs(2));
    loop {
        match sender.send(RevisionMsg::Tick) {
            Ok(_) => {},
            Err(e) => log::error!("RevisionUploadStream tick error: {}", e),
        }
        i.tick().await;
    }
}
