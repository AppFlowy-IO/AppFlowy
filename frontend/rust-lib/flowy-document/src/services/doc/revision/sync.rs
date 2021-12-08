use crate::{
    errors::{internal_error, DocResult},
    services::{
        doc::{
            edit::ClientDocEditor,
            revision::{RevisionIterator, RevisionManager},
        },
        ws::DocumentWebSocket,
    },
};
use async_stream::stream;
use bytes::Bytes;
use flowy_document_infra::entities::ws::{WsDataType, WsDocumentData};
use futures::stream::StreamExt;
use lib_ot::revision::{RevId, RevisionRange};
use std::{convert::TryFrom, sync::Arc};
use tokio::{
    sync::mpsc,
    task::spawn_blocking,
    time::{interval, Duration},
};

pub(crate) struct RevisionDownStream {
    editor: Arc<ClientDocEditor>,
    rev_manager: Arc<RevisionManager>,
    receiver: Option<mpsc::UnboundedReceiver<WsDocumentData>>,
    ws_sender: Arc<dyn DocumentWebSocket>,
}

impl RevisionDownStream {
    pub(crate) fn new(
        editor: Arc<ClientDocEditor>,
        rev_manager: Arc<RevisionManager>,
        receiver: mpsc::UnboundedReceiver<WsDocumentData>,
        ws_sender: Arc<dyn DocumentWebSocket>,
    ) -> Self {
        RevisionDownStream {
            editor,
            rev_manager,
            receiver: Some(receiver),
            ws_sender,
        }
    }

    pub async fn run(mut self) {
        let mut receiver = self.receiver.take().expect("Only take once");
        let stream = stream! {
            loop {
                match receiver.recv().await {
                    Some(msg) => yield msg,
                    None => break,
                }
            }
        };
        stream
            .for_each(|msg| async {
                match self.handle_message(msg).await {
                    Ok(_) => {},
                    Err(e) => log::error!("RevisionDownStream error: {}", e),
                }
            })
            .await;
    }

    async fn handle_message(&self, msg: WsDocumentData) -> DocResult<()> {
        let WsDocumentData { doc_id: _, ty, data } = msg;
        let bytes = spawn_blocking(move || Bytes::from(data))
            .await
            .map_err(internal_error)?;
        log::debug!("[RevisionDownStream]: receives new message: {:?}", ty);

        match ty {
            WsDataType::PushRev => {
                let _ = self.editor.handle_push_rev(bytes).await?;
            },
            WsDataType::PullRev => {
                let range = RevisionRange::try_from(bytes)?;
                let revision = self.rev_manager.mk_revisions(range).await?;
                let _ = self.ws_sender.send(revision.into());
            },
            WsDataType::Acked => {
                let rev_id = RevId::try_from(bytes)?;
                let _ = self.rev_manager.ack_revision(rev_id).await?;
            },
            WsDataType::Conflict => {},
            WsDataType::NewDocUser => {},
        }

        Ok(())
    }
}

// RevisionUpStream
pub(crate) enum UpStreamMsg {
    Tick,
}

pub(crate) struct RevisionUpStream {
    revisions: Arc<dyn RevisionIterator>,
    ws_sender: Arc<dyn DocumentWebSocket>,
}

impl RevisionUpStream {
    pub(crate) fn new(revisions: Arc<dyn RevisionIterator>, ws_sender: Arc<dyn DocumentWebSocket>) -> Self {
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

    async fn handle_msg(&self, msg: UpStreamMsg) -> DocResult<()> {
        match msg {
            UpStreamMsg::Tick => self.send_next_revision().await,
        }
    }

    async fn send_next_revision(&self) -> DocResult<()> {
        match self.revisions.next().await? {
            None => Ok(()),
            Some(record) => {
                log::debug!(
                    "[RevisionUpStream]: processes revision: {}:{:?}",
                    record.revision.doc_id,
                    record.revision.rev_id
                );
                let _ = self.ws_sender.send(record.revision.into()).map_err(internal_error);
                // let _ = tokio::time::timeout(Duration::from_millis(2000), ret.recv()).await;
                Ok(())
            },
        }
    }
}

async fn tick(sender: mpsc::UnboundedSender<UpStreamMsg>) {
    let mut i = interval(Duration::from_secs(2));
    loop {
        match sender.send(UpStreamMsg::Tick) {
            Ok(_) => {},
            Err(e) => log::error!("RevisionUploadStream tick error: {}", e),
        }
        i.tick().await;
    }
}
