use crate::editor::document::Document;
use crate::DocumentUser;
use async_stream::stream;
use flowy_error::FlowyError;
use flowy_revision::RevisionManager;
use futures::stream::StreamExt;
use lib_ot::core::Transaction;
use std::sync::Arc;
use tokio::sync::mpsc::{Receiver, Sender};
use tokio::sync::{oneshot, RwLock};
pub struct DocumentQueue {
    user: Arc<dyn DocumentUser>,
    document: Arc<RwLock<Document>>,
    rev_manager: Arc<RevisionManager>,
    receiver: Option<CommandReceiver>,
}

impl DocumentQueue {
    pub fn new(
        user: Arc<dyn DocumentUser>,
        rev_manager: Arc<RevisionManager>,
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
                self.document.write().await.apply_transaction(transaction)?;
                let _ = ret.send(Ok(()));
            }
            Command::GetDocumentContent { ret } => {
                let content = self.document.read().await.get_content()?;
                let _ = ret.send(Ok(content));
            }
        }
        Ok(())
    }
}

pub(crate) type CommandSender = Sender<Command>;
pub(crate) type CommandReceiver = Receiver<Command>;
pub(crate) type Ret<T> = oneshot::Sender<Result<T, FlowyError>>;

pub enum Command {
    ComposeTransaction { transaction: Transaction, ret: Ret<()> },
    GetDocumentContent { ret: Ret<String> },
}
