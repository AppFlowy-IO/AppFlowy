use crate::{
    entities::doc::{NewDocUser, RevId, Revision},
    errors::{DocError, DocResult},
    services::ws::WsDocumentSender,
    sql_tables::RevState,
};
use flowy_infra::retry::Action;
use futures::future::BoxFuture;
use std::{future, sync::Arc};
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

pub(crate) struct NotifyOpenDocAction {
    user_id: String,
    rev_id: RevId,
    doc_id: String,
    ws: Arc<dyn WsDocumentSender>,
}

impl NotifyOpenDocAction {
    pub(crate) fn new(user_id: &str, doc_id: &str, rev_id: &RevId, ws: &Arc<dyn WsDocumentSender>) -> Self {
        Self {
            user_id: user_id.to_owned(),
            rev_id: rev_id.clone(),
            doc_id: doc_id.to_owned(),
            ws: ws.clone(),
        }
    }
}

impl Action for NotifyOpenDocAction {
    type Future = BoxFuture<'static, Result<Self::Item, Self::Error>>;
    type Item = ();
    type Error = DocError;

    fn run(&mut self) -> Self::Future {
        let new_doc_user = NewDocUser {
            user_id: self.user_id.clone(),
            rev_id: self.rev_id.clone().into(),
            doc_id: self.doc_id.clone(),
        };

        match self.ws.send(new_doc_user.into()) {
            Ok(_) => Box::pin(future::ready(Ok::<(), DocError>(()))),
            Err(e) => Box::pin(future::ready(Err::<(), DocError>(e))),
        }
    }
}
