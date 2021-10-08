use crate::{
    entities::doc::{Revision, RevisionRange},
    errors::{internal_error, DocError, DocResult},
    sql_tables::{RevState, RevTableSql},
};
use async_stream::stream;
use flowy_database::ConnectionPool;
use flowy_infra::future::ResultFuture;
use futures::{stream::StreamExt, TryFutureExt};
use std::{sync::Arc, time::Duration};
use tokio::sync::{broadcast, mpsc};

pub type RevIdReceiver = broadcast::Receiver<i64>;
pub type RevIdSender = broadcast::Sender<i64>;

pub struct RevisionContext {
    pub revision: Revision,
    pub state: RevState,
}

impl RevisionContext {
    pub fn new(revision: Revision) -> Self {
        Self {
            revision,
            state: RevState::Local,
        }
    }
}

pub(crate) struct PendingRevId {
    pub rev_id: i64,
    pub sender: RevIdSender,
}

impl PendingRevId {
    pub(crate) fn new(rev_id: i64, sender: RevIdSender) -> Self { Self { rev_id, sender } }

    pub(crate) fn finish(&self, rev_id: i64) -> bool {
        if self.rev_id > rev_id {
            false
        } else {
            self.sender.send(self.rev_id);
            true
        }
    }
}

pub(crate) struct Persistence {
    pub(crate) rev_sql: Arc<RevTableSql>,
    pub(crate) pool: Arc<ConnectionPool>,
}

impl Persistence {
    pub(crate) fn new(pool: Arc<ConnectionPool>) -> Self {
        let rev_sql = Arc::new(RevTableSql {});
        Self { rev_sql, pool }
    }

    pub(crate) fn create_revs(&self, revisions_state: Vec<(Revision, RevState)>) -> DocResult<()> {
        let conn = &*self.pool.get().map_err(internal_error)?;
        conn.immediate_transaction::<_, DocError, _>(|| {
            let _ = self.rev_sql.create_rev_table(revisions_state, conn)?;
            Ok(())
        })
    }

    pub(crate) fn read_rev_with_range(&self, doc_id: &str, range: RevisionRange) -> DocResult<Vec<Revision>> {
        let conn = &*self.pool.get().map_err(internal_error).unwrap();
        let revisions = self.rev_sql.read_rev_tables_with_range(doc_id, range, conn)?;
        Ok(revisions)
    }

    pub(crate) fn read_rev(&self, doc_id: &str, rev_id: &i64) -> DocResult<Option<Revision>> {
        let conn = self.pool.get().map_err(internal_error)?;
        let some = self.rev_sql.read_rev_table(&doc_id, rev_id, &*conn)?;
        Ok(some)
    }
}

pub trait RevisionIterator: Send + Sync {
    fn next(&self) -> ResultFuture<Option<Revision>, DocError>;
}

pub(crate) enum PendingMsg {
    Revision { ret: RevIdReceiver },
}

pub(crate) type PendingSender = mpsc::UnboundedSender<PendingMsg>;
pub(crate) type PendingReceiver = mpsc::UnboundedReceiver<PendingMsg>;

pub(crate) struct PendingRevisionStream {
    revisions: Arc<dyn RevisionIterator>,
    receiver: Option<PendingReceiver>,
    next_revision: mpsc::Sender<Revision>,
}

impl PendingRevisionStream {
    pub(crate) fn new(
        revisions: Arc<dyn RevisionIterator>,
        pending_rx: PendingReceiver,
        next_revision: mpsc::Sender<Revision>,
    ) -> Self {
        Self {
            revisions,
            receiver: Some(pending_rx),
            next_revision,
        }
    }

    pub async fn run(mut self) {
        let mut receiver = self.receiver.take().expect("Should only call once");
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
                match self.handle_msg(msg).await {
                    Ok(_) => {},
                    Err(e) => log::error!("{:?}", e),
                }
            })
            .await;
    }

    async fn handle_msg(&self, msg: PendingMsg) -> DocResult<()> {
        match msg {
            PendingMsg::Revision { ret } => self.prepare_next_pending_rev(ret).await,
        }
    }

    async fn prepare_next_pending_rev(&self, mut ret: RevIdReceiver) -> DocResult<()> {
        match self.revisions.next().await? {
            None => Ok(()),
            Some(revision) => {
                self.next_revision.send(revision).await.map_err(internal_error);
                let _ = tokio::time::timeout(Duration::from_millis(2000), ret.recv()).await;
                Ok(())
            },
        }
    }
}
