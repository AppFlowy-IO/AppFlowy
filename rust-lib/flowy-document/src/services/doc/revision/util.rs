use crate::{entities::doc::Revision, errors::DocResult, sql_tables::RevState};
use tokio::sync::oneshot;

pub type Sender = oneshot::Sender<DocResult<()>>;
pub type Receiver = oneshot::Receiver<DocResult<()>>;

pub struct RevisionOperation {
    inner: Revision,
    ret: Option<Sender>,
    receiver: Option<Receiver>,
    pub state: RevState,
}

impl RevisionOperation {
    pub fn new(revision: &Revision) -> Self {
        let (ret, receiver) = oneshot::channel::<DocResult<()>>();

        Self {
            inner: revision.clone(),
            ret: Some(ret),
            receiver: Some(receiver),
            state: RevState::Local,
        }
    }

    pub fn receiver(&mut self) -> Receiver { self.receiver.take().expect("Receiver should not be called twice") }

    pub fn finish(&mut self) {
        self.state = RevState::Acked;
        match self.ret.take() {
            None => {},
            Some(ret) => {
                let _ = ret.send(Ok(()));
            },
        }
    }
}

impl std::ops::Deref for RevisionOperation {
    type Target = Revision;

    fn deref(&self) -> &Self::Target { &self.inner }
}
