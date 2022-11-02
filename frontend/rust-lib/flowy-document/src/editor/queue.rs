use crate::editor::document::Document;
use crate::DocumentUser;
use async_stream::stream;
use bytes::Bytes;
use flowy_error::FlowyError;
use flowy_revision::RevisionManager;
use flowy_sync::entities::revision::{RevId, Revision};
use futures::stream::StreamExt;
use lib_ot::core::Transaction;

use flowy_database::ConnectionPool;
use std::sync::Arc;
use tokio::sync::mpsc::{Receiver, Sender};
use tokio::sync::{oneshot, RwLock};

pub struct DocumentQueue {
    #[allow(dead_code)]
    user: Arc<dyn DocumentUser>,
    document: Arc<RwLock<Document>>,
    #[allow(dead_code)]
    rev_manager: Arc<RevisionManager<Arc<ConnectionPool>>>,
    receiver: Option<CommandReceiver>,
}

impl DocumentQueue {
    pub fn new(
        user: Arc<dyn DocumentUser>,
        rev_manager: Arc<RevisionManager<Arc<ConnectionPool>>>,
        document: Document,
        receiver: CommandReceiver,
    ) -> Self {
        let document = Arc::new(RwLock::new(document));
        Self {
            user,
            document,
            rev_manager,
            receiver: Some(receiver),
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
            .for_each(|command| async {
                match self.handle_command(command).await {
                    Ok(_) => {}
                    Err(e) => tracing::debug!("[DocumentQueue]: {}", e),
                }
            })
            .await;
    }

    async fn handle_command(&self, command: Command) -> Result<(), FlowyError> {
        match command {
            Command::ComposeTransaction { transaction, ret } => {
                self.document.write().await.apply_transaction(transaction.clone())?;
                let _ = self
                    .save_local_operations(transaction, self.document.read().await.document_md5())
                    .await?;
                let _ = ret.send(Ok(()));
            }
            Command::GetDocumentContent { pretty, ret } => {
                let content = self.document.read().await.get_content(pretty)?;
                let _ = ret.send(Ok(content));
            }
        }
        Ok(())
    }

    #[tracing::instrument(level = "trace", skip(self, transaction, md5), err)]
    async fn save_local_operations(&self, transaction: Transaction, md5: String) -> Result<RevId, FlowyError> {
        let bytes = Bytes::from(transaction.to_bytes()?);
        let (base_rev_id, rev_id) = self.rev_manager.next_rev_id_pair();
        let user_id = self.user.user_id()?;
        let revision = Revision::new(&self.rev_manager.object_id, base_rev_id, rev_id, bytes, &user_id, md5);
        let _ = self.rev_manager.add_local_revision(&revision).await?;
        Ok(rev_id.into())
    }
}

pub(crate) type CommandSender = Sender<Command>;
pub(crate) type CommandReceiver = Receiver<Command>;
pub(crate) type Ret<T> = oneshot::Sender<Result<T, FlowyError>>;

pub enum Command {
    ComposeTransaction { transaction: Transaction, ret: Ret<()> },
    GetDocumentContent { pretty: bool, ret: Ret<String> },
}
