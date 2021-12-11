use crate::{
    services::doc::update_doc,
    web_socket::{entities::Socket, WsMessageAdaptor, WsUser},
};
use actix_web::web::Data;
use backend_service::errors::{internal_error, ServerError};
use dashmap::DashMap;
use flowy_collaboration::{
    core::{
        document::Document,
        sync::{RevisionSynchronizer, RevisionUser, SyncResponse},
    },
    protobuf::{Doc, UpdateDocParams},
};
use lib_ot::{protobuf::Revision, rich_text::RichTextDelta};
use sqlx::PgPool;
use std::{
    convert::TryInto,
    sync::{
        atomic::{AtomicI64, Ordering::SeqCst},
        Arc,
    },
};

#[rustfmt::skip]
//                            ┌──────────────────────┐     ┌────────────┐
//                       ┌───▶│ RevisionSynchronizer │────▶│  Document  │
//                       │    └──────────────────────┘     └────────────┘
// ┌────────────────┐    │
// │ServerDocEditor │────┤                                          ┌───────────┐
// └────────────────┘    │                                     ┌───▶│  WsUser   │
//                       │                                     │    └───────────┘
//                       │    ┌────────┐       ┌───────────┐   │    ┌───────────┐
//                       └───▶│ Users  │◆──────│  DocUser  ├───┼───▶│  Socket   │
//                            └────────┘       └───────────┘   │    └───────────┘
//                                                             │    ┌───────────┐
//                                                             └───▶│  PgPool   │
//                                                                  └───────────┘
pub struct ServerDocEditor {
    pub doc_id: String,
    pub rev_id: AtomicI64,
    synchronizer: Arc<RevisionSynchronizer>,
    users: DashMap<String, DocUser>,
}

impl ServerDocEditor {
    pub fn new(doc: Doc) -> Result<Self, ServerError> {
        let delta = RichTextDelta::from_bytes(&doc.data).map_err(internal_error)?;
        let users = DashMap::new();
        let synchronizer = Arc::new(RevisionSynchronizer::new(
            &doc.id,
            doc.rev_id,
            Document::from_delta(delta),
        ));

        Ok(Self {
            doc_id: doc.id.clone(),
            rev_id: AtomicI64::new(doc.rev_id),
            synchronizer,
            users,
        })
    }

    #[tracing::instrument(
        level = "debug",
        skip(self, user),
        fields(
            user_id = %user.id(),
            rev_id = %rev_id,
        )
    )]
    pub async fn new_doc_user(&self, user: DocUser, rev_id: i64) -> Result<(), ServerError> {
        self.users.insert(user.id(), user.clone());
        self.synchronizer.new_conn(user, rev_id);
        Ok(())
    }

    #[tracing::instrument(
        level = "debug",
        skip(self, user, revision),
        fields(
            cur_rev_id = %self.rev_id.load(SeqCst),
            base_rev_id = %revision.base_rev_id,
            rev_id = %revision.rev_id,
        ),
        err
    )]
    pub async fn apply_revision(&self, user: DocUser, mut revision: Revision) -> Result<(), ServerError> {
        self.users.insert(user.id(), user.clone());
        let revision = (&mut revision).try_into().map_err(internal_error)?;
        self.synchronizer.apply_revision(user, revision).unwrap();
        Ok(())
    }

    pub fn document_json(&self) -> String { self.synchronizer.doc_json() }
}

#[derive(Clone)]
pub struct DocUser {
    pub user: Arc<WsUser>,
    pub(crate) socket: Socket,
    pub pg_pool: Data<PgPool>,
}

impl DocUser {
    pub fn id(&self) -> String { self.user.id().to_string() }
}

impl RevisionUser for DocUser {
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
