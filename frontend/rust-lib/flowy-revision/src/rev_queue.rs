use crate::{RevIdCounter, RevisionMergeable, RevisionPersistence};
use async_stream::stream;
use bytes::Bytes;
use flowy_error::FlowyError;
use flowy_http_model::revision::Revision;
use futures::stream::StreamExt;
use std::sync::Arc;
use tokio::sync::mpsc::{Receiver, Sender};
use tokio::sync::oneshot;

#[derive(Debug)]
pub(crate) enum RevCommand {
    RevisionData {
        data: Bytes,
        object_md5: String,
        ret: Ret<i64>,
    },
}

pub(crate) struct RevQueue<Connection> {
    object_id: String,
    rev_id_counter: Arc<RevIdCounter>,
    rev_persistence: Arc<RevisionPersistence<Connection>>,
    rev_compress: Arc<dyn RevisionMergeable>,
    receiver: Option<RevCommandReceiver>,
}

impl<Connection> RevQueue<Connection>
where
    Connection: 'static,
{
    pub fn new(
        object_id: String,
        rev_id_counter: Arc<RevIdCounter>,
        rev_persistence: Arc<RevisionPersistence<Connection>>,
        rev_compress: Arc<dyn RevisionMergeable>,
        receiver: RevCommandReceiver,
    ) -> Self {
        Self {
            object_id,
            rev_id_counter,
            rev_persistence,
            rev_compress,
            receiver: Some(receiver),
        }
    }

    pub async fn run(mut self) {
        let mut receiver = self.receiver.take().expect("Only take once");
        let object_id = self.object_id.clone();
        let stream = stream! {
            loop {
                match receiver.recv().await {
                    Some(msg) => yield msg,
                    None => {
                        tracing::trace!("{}'s RevQueue exist", &object_id);
                        break
                    },
                }
            }
        };
        stream
            .for_each(|command| async {
                match self.handle_command(command).await {
                    Ok(_) => {}
                    Err(e) => tracing::debug!("[RevQueue]: {}", e),
                }
            })
            .await;
    }

    async fn handle_command(&self, command: RevCommand) -> Result<(), FlowyError> {
        match command {
            RevCommand::RevisionData {
                data,
                object_md5: data_md5,
                ret,
            } => {
                let base_rev_id = self.rev_id_counter.value();
                let rev_id = self.rev_id_counter.next_id();
                let revision = Revision::new(&self.object_id, base_rev_id, rev_id, data, data_md5);

                let rev_id = self
                    .rev_persistence
                    .add_local_revision(revision, &self.rev_compress)
                    .await?;
                self.rev_id_counter.set(rev_id);
                let _ = ret.send(Ok(rev_id));
            }
        }
        Ok(())
    }
}

pub(crate) type RevCommandSender = Sender<RevCommand>;
pub(crate) type RevCommandReceiver = Receiver<RevCommand>;
pub(crate) type Ret<T> = oneshot::Sender<Result<T, FlowyError>>;
