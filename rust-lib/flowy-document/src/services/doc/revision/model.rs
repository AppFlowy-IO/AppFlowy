use crate::{entities::doc::Revision, errors::DocResult, services::ws::DocumentWebSocket, sql_tables::RevState};

use tokio::sync::oneshot;

pub type PendingRevSender = oneshot::Sender<DocResult<()>>;
pub type PendingRevReceiver = oneshot::Receiver<DocResult<()>>;

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
    pub sender: PendingRevSender,
}

impl PendingRevId {
    pub(crate) fn new(rev_id: i64, sender: PendingRevSender) -> Self { Self { rev_id, sender } }
}
