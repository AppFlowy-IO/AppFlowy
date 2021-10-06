use crate::{
    entities::doc::{NewDocUser, RevId},
    errors::DocError,
    services::ws::DocumentWebSocket,
};
use flowy_infra::retry::Action;
use futures::future::BoxFuture;
use std::{future, sync::Arc};

pub(crate) struct OpenDocAction {
    user_id: String,
    rev_id: RevId,
    doc_id: String,
    ws: Arc<dyn DocumentWebSocket>,
}

impl OpenDocAction {
    pub(crate) fn new(user_id: &str, doc_id: &str, rev_id: &RevId, ws: &Arc<dyn DocumentWebSocket>) -> Self {
        Self {
            user_id: user_id.to_owned(),
            rev_id: rev_id.clone(),
            doc_id: doc_id.to_owned(),
            ws: ws.clone(),
        }
    }
}

impl Action for OpenDocAction {
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
