use crate::{RevIdCounter, RevisionMergeable, RevisionPersistence};
use async_stream::stream;
use bytes::Bytes;
use flowy_error::FlowyError;
use futures::stream::StreamExt;
use revision_model::Revision;
use std::sync::Arc;
use tokio::sync::mpsc::{Receiver, Sender};
use tokio::sync::oneshot;

#[derive(Debug)]
pub(crate) enum RevisionCommand {
  RevisionData {
    data: Bytes,
    object_md5: String,
    ret: Ret<i64>,
  },
}

/// [RevisionQueue] is used to keep the [RevisionCommand] processing in order.
pub(crate) struct RevisionQueue<Connection> {
  object_id: String,
  rev_id_counter: Arc<RevIdCounter>,
  rev_persistence: Arc<RevisionPersistence<Connection>>,
  rev_compress: Arc<dyn RevisionMergeable>,
  receiver: Option<RevCommandReceiver>,
}

impl<Connection> RevisionQueue<Connection>
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
          Ok(_) => {},
          Err(e) => tracing::error!("[RevQueue]: {}", e),
        }
      })
      .await;
  }

  async fn handle_command(&self, command: RevisionCommand) -> Result<(), FlowyError> {
    match command {
      RevisionCommand::RevisionData {
        data,
        object_md5: data_md5,
        ret,
      } => {
        let base_rev_id = self.rev_id_counter.value();
        let rev_id = self.rev_id_counter.next_id();
        let revision = Revision::new(&self.object_id, base_rev_id, rev_id, data, data_md5);

        let new_rev_id = self
          .rev_persistence
          .add_local_revision(revision, &self.rev_compress)
          .await?;

        self.rev_id_counter.set(new_rev_id);
        let _ = ret.send(Ok(new_rev_id));
      },
    }
    Ok(())
  }
}

pub(crate) type RevCommandSender = Sender<RevisionCommand>;
pub(crate) type RevCommandReceiver = Receiver<RevisionCommand>;
pub(crate) type Ret<T> = oneshot::Sender<Result<T, FlowyError>>;
