use crate::service::{
    doc::{edit::edit_actor::EditUser, update_doc},
    util::md5,
    ws::WsMessageAdaptor,
};
use actix_web::web::Data;

use bytes::Bytes;
use dashmap::DashMap;
use flowy_document::{
    entities::ws::{WsDataType, WsDocumentData},
    protobuf::{Doc, RevId, RevType, Revision, RevisionRange, UpdateDocParams},
    services::doc::Document,
};
use flowy_net::errors::{internal_error, ServerError};
use flowy_ot::core::{Delta, OperationTransformable};
use flowy_ws::WsMessage;
use parking_lot::RwLock;
use protobuf::Message;
use sqlx::PgPool;
use std::{
    cmp::Ordering,
    convert::TryInto,
    sync::{
        atomic::{AtomicI64, Ordering::SeqCst},
        Arc,
    },
    time::Duration,
};

pub struct ServerEditDoc {
    pub doc_id: String,
    pub rev_id: AtomicI64,
    document: Arc<RwLock<Document>>,
    users: DashMap<String, EditUser>,
}

impl ServerEditDoc {
    pub fn new(doc: Doc) -> Result<Self, ServerError> {
        let delta = Delta::from_bytes(&doc.data).map_err(internal_error)?;
        let document = Arc::new(RwLock::new(Document::from_delta(delta)));
        let users = DashMap::new();
        Ok(Self {
            doc_id: doc.id.clone(),
            rev_id: AtomicI64::new(doc.rev_id),
            document,
            users,
        })
    }

    pub fn document_json(&self) -> String { self.document.read().to_json() }

    #[tracing::instrument(
        level = "debug",
        skip(self, user),
        fields(
            user_id = %user.id(),
            rev_id = %rev_id,
        )
    )]
    pub async fn new_doc_user(&self, user: EditUser, rev_id: i64) -> Result<(), ServerError> {
        self.users.insert(user.id(), user.clone());
        let cur_rev_id = self.rev_id.load(SeqCst);

        match cur_rev_id.cmp(&rev_id) {
            Ordering::Less => {
                user.socket
                    .do_send(mk_pull_rev_ws_message(&self.doc_id, cur_rev_id, rev_id))
                    .map_err(internal_error)?;
            },
            Ordering::Equal => {},
            Ordering::Greater => {
                let doc_delta = self.document.read().delta().clone();
                let cli_revision = self.mk_revision(rev_id, doc_delta);
                let ws_cli_revision = mk_push_rev_ws_message(&self.doc_id, cli_revision);
                user.socket.do_send(ws_cli_revision).map_err(internal_error)?;
            },
        }

        Ok(())
    }

    #[tracing::instrument(
        level = "debug",
        skip(self, user, pg_pool, revision),
        fields(
            rev_id = %self.rev_id.load(SeqCst),
            revision_rev_id = %revision.rev_id,
            revision_base_rev_id = %revision.base_rev_id
        )
    )]
    pub async fn apply_revision(
        &self,
        user: EditUser,
        revision: Revision,
        pg_pool: Data<PgPool>,
    ) -> Result<(), ServerError> {
        // Opti: find out another way to keep the user socket available.
        self.users.insert(user.id(), user.clone());
        let cur_rev_id = self.rev_id.load(SeqCst);
        match cur_rev_id.cmp(&revision.rev_id) {
            Ordering::Less => {
                if cur_rev_id != revision.base_rev_id {
                    // The server document is outdated, try to get the missing revision from the
                    // client.
                    user.socket
                        .do_send(mk_pull_rev_ws_message(&self.doc_id, cur_rev_id, revision.rev_id))
                        .map_err(internal_error)?;
                } else {
                    let _ = self.compose_revision(&revision, pg_pool).await?;
                    user.socket
                        .do_send(mk_acked_ws_message(&revision))
                        .map_err(internal_error)?;
                }
            },
            Ordering::Equal => {},
            Ordering::Greater => {
                // The client document is outdated. Transform the client revision delta and then
                // send the prime delta to the client. Client should compose the this prime
                // delta.
                let cli_revision = self.transform_revision(&revision)?;
                let ws_cli_revision = mk_push_rev_ws_message(&self.doc_id, cli_revision);
                user.socket.do_send(ws_cli_revision).map_err(internal_error)?;
            },
        }
        Ok(())
    }

    async fn compose_revision(&self, revision: &Revision, pg_pool: Data<PgPool>) -> Result<(), ServerError> {
        let delta = Delta::from_bytes(&revision.delta_data).map_err(internal_error)?;
        let _ = self.compose_delta(delta)?;
        let _ = self.rev_id.fetch_update(SeqCst, SeqCst, |_e| Some(revision.rev_id));
        let _ = self.save_revision(&revision, pg_pool).await?;
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self, revision))]
    fn transform_revision(&self, revision: &Revision) -> Result<Revision, ServerError> {
        let cli_delta = Delta::from_bytes(&revision.delta_data).map_err(internal_error)?;
        let (cli_prime, server_prime) = self
            .document
            .read()
            .delta()
            .transform(&cli_delta)
            .map_err(internal_error)?;

        let _ = self.compose_delta(server_prime)?;
        let cli_revision = self.mk_revision(revision.rev_id, cli_prime);
        Ok(cli_revision)
    }

    fn mk_revision(&self, base_rev_id: i64, delta: Delta) -> Revision {
        let delta_data = delta.to_bytes().to_vec();
        let md5 = md5(&delta_data);
        let revision = Revision {
            base_rev_id,
            rev_id: self.rev_id.load(SeqCst),
            delta_data,
            md5,
            doc_id: self.doc_id.to_string(),
            ty: RevType::Remote,
            ..Default::default()
        };
        revision
    }

    #[tracing::instrument(
        level = "debug",
        skip(self, delta),
        fields(
            delta = %delta.to_json(),
            result,
        )
    )]
    fn compose_delta(&self, delta: Delta) -> Result<(), ServerError> {
        // Opti: push each revision into queue and process it one by one.
        match self.document.try_write_for(Duration::from_millis(300)) {
            None => {
                log::error!("Failed to acquire write lock of document");
            },
            Some(mut write_guard) => {
                let _ = write_guard.compose_delta(&delta).map_err(internal_error)?;
                tracing::Span::current().record("result", &write_guard.to_json().as_str());
            },
        }
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self, revision, pg_pool), err)]
    async fn save_revision(&self, revision: &Revision, pg_pool: Data<PgPool>) -> Result<(), ServerError> {
        // Opti: save with multiple revisions
        let mut params = UpdateDocParams::new();
        params.set_doc_id(self.doc_id.clone());
        params.set_data(self.document.read().to_json());
        params.set_rev_id(revision.rev_id);
        let _ = update_doc(pg_pool.get_ref(), params).await?;
        Ok(())
    }
}

fn mk_push_rev_ws_message(doc_id: &str, revision: Revision) -> WsMessageAdaptor {
    let bytes = revision.write_to_bytes().unwrap();
    let data = WsDocumentData {
        doc_id: doc_id.to_string(),
        ty: WsDataType::PushRev,
        data: bytes,
    };
    mk_ws_message(data)
}

fn mk_pull_rev_ws_message(doc_id: &str, from_rev_id: i64, to_rev_id: i64) -> WsMessageAdaptor {
    let range = RevisionRange {
        doc_id: doc_id.to_string(),
        from_rev_id,
        to_rev_id,
        ..Default::default()
    };

    let bytes = range.write_to_bytes().unwrap();
    let data = WsDocumentData {
        doc_id: doc_id.to_string(),
        ty: WsDataType::PullRev,
        data: bytes,
    };
    mk_ws_message(data)
}

fn mk_acked_ws_message(revision: &Revision) -> WsMessageAdaptor {
    // let mut wtr = vec![];
    // let _ = wtr.write_i64::<BigEndian>(revision.rev_id);

    let mut rev_id = RevId::new();
    rev_id.set_value(revision.rev_id);
    let data = rev_id.write_to_bytes().unwrap();

    let data = WsDocumentData {
        doc_id: revision.doc_id.clone(),
        ty: WsDataType::Acked,
        data,
    };

    mk_ws_message(data)
}

fn mk_ws_message<T: Into<WsMessage>>(data: T) -> WsMessageAdaptor {
    let msg: WsMessage = data.into();
    let bytes: Bytes = msg.try_into().unwrap();
    WsMessageAdaptor(bytes)
}
