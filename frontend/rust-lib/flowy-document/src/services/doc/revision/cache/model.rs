use lib_ot::revision::{RevState, Revision};
use tokio::sync::broadcast;

pub type RevIdReceiver = broadcast::Receiver<i64>;
pub type RevIdSender = broadcast::Sender<i64>;

#[derive(Clone)]
pub struct RevisionRecord {
    pub revision: Revision,
    pub state: RevState,
}

impl RevisionRecord {
    pub fn ack(&mut self) { self.state = RevState::Acked; }
}
