use crate::{
    services::doc::update_doc,
    web_socket::{entities::Socket, WsMessageAdaptor, WsUser},
};
use actix_web::web::Data;
use backend_service::errors::internal_error;

use flowy_collaboration::{
    core::sync::{RevisionUser, SyncResponse},
    protobuf::UpdateDocParams,
};

use sqlx::PgPool;
use std::sync::Arc;

#[derive(Clone, Debug)]
pub struct DocUser {
    pub user: Arc<WsUser>,
    pub(crate) socket: Socket,
    pub pg_pool: Data<PgPool>,
}

impl RevisionUser for DocUser {
    fn user_id(&self) -> String { self.user.id().to_string() }

    fn recv(&self, resp: SyncResponse) {
        let result = match resp {
            SyncResponse::Pull(data) => {
                let msg: WsMessageAdaptor = data.into();
                self.socket.try_send(msg).map_err(internal_error)
            },
            SyncResponse::Push(data) => {
                let msg: WsMessageAdaptor = data.into();
                self.socket.try_send(msg).map_err(internal_error)
            },
            SyncResponse::Ack(data) => {
                let msg: WsMessageAdaptor = data.into();
                self.socket.try_send(msg).map_err(internal_error)
            },
            SyncResponse::NewRevision {
                rev_id,
                doc_id,
                doc_json,
            } => {
                let pg_pool = self.pg_pool.clone();
                tokio::task::spawn(async move {
                    let mut params = UpdateDocParams::new();
                    params.set_doc_id(doc_id);
                    params.set_data(doc_json);
                    params.set_rev_id(rev_id);
                    match update_doc(pg_pool.get_ref(), params).await {
                        Ok(_) => {},
                        Err(e) => log::error!("{}", e),
                    }
                });
                Ok(())
            },
        };

        match result {
            Ok(_) => {},
            Err(e) => log::error!("{}", e),
        }
    }
}
