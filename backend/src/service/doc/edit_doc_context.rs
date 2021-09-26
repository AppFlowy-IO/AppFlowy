use crate::service::{
    doc::update_doc,
    util::md5,
    ws::{entities::Socket, WsClientData, WsMessageAdaptor, WsUser},
};
use actix_web::web::Data;
use byteorder::{BigEndian, WriteBytesExt};
use bytes::Bytes;
use dashmap::DashMap;
use flowy_document::{
    entities::ws::{WsDataType, WsDocumentData},
    protobuf::{Doc, RevType, Revision, UpdateDocParams},
    services::doc::Document,
};
use flowy_net::errors::{internal_error, ServerError};
use flowy_ot::{
    core::{Delta, OperationTransformable},
    errors::OTError,
};
use flowy_ws::WsMessage;
use parking_lot::RwLock;
use protobuf::Message;
use sqlx::PgPool;
use std::{
    convert::TryInto,
    sync::{
        atomic::{AtomicI64, Ordering::SeqCst},
        Arc,
    },
    time::Duration,
};

struct EditUser {
    user: Arc<WsUser>,
    socket: Socket,
}

pub(crate) struct EditDocContext {
    doc_id: String,
    rev_id: AtomicI64,
    document: Arc<RwLock<Document>>,
    pg_pool: Data<PgPool>,
    users: DashMap<String, EditUser>,
}

impl EditDocContext {
    pub(crate) fn new(doc: Doc, pg_pool: Data<PgPool>) -> Result<Self, ServerError> {
        let delta = Delta::from_bytes(&doc.data).map_err(internal_error)?;
        let document = Arc::new(RwLock::new(Document::from_delta(delta)));
        let users = DashMap::new();
        Ok(Self {
            doc_id: doc.id.clone(),
            rev_id: AtomicI64::new(doc.rev_id),
            document,
            pg_pool,
            users,
        })
    }

    #[tracing::instrument(level = "debug", skip(self, client_data, revision))]
    pub(crate) async fn apply_revision(
        &self,
        client_data: WsClientData,
        revision: Revision,
    ) -> Result<(), ServerError> {
        let _ = self.verify_md5(&revision)?;
        // Rest EditUser for each client websocket message to keep the socket available.
        let user = EditUser {
            user: client_data.user.clone(),
            socket: client_data.socket.clone(),
        };
        self.users.insert(client_data.user.id().to_owned(), user);

        log::debug!(
            "cur_base_rev_id: {}, expect_base_rev_id: {} rev_id: {}",
            self.rev_id.load(SeqCst),
            revision.base_rev_id,
            revision.rev_id
        );

        let cli_socket = client_data.socket;
        let cur_rev_id = self.rev_id.load(SeqCst);
        // Transform the revision if client rev_id less than server rev_id. Sending the
        // prime delta to client.
        if cur_rev_id > revision.rev_id {
            let (cli_prime, server_prime) = self.transform(&revision.delta).map_err(internal_error)?;
            let _ = self.update_document_delta(server_prime)?;

            log::debug!("{} client delta: {}", self.doc_id, cli_prime.to_json());
            let cli_revision = self.mk_revision(revision.rev_id, cli_prime);
            let ws_cli_revision = mk_rev_ws_message(&self.doc_id, cli_revision);
            cli_socket.do_send(ws_cli_revision).map_err(internal_error)?;
            Ok(())
        } else if cur_rev_id < revision.rev_id {
            if cur_rev_id != revision.base_rev_id {
                let missing_rev_range = revision.rev_id - cur_rev_id;
                // TODO: pull the missing revs from client
            } else {
                let delta = Delta::from_bytes(&revision.delta).map_err(internal_error)?;
                let _ = self.update_document_delta(delta)?;
                cli_socket.do_send(mk_acked_ws_message(&revision));
                self.rev_id.fetch_update(SeqCst, SeqCst, |_e| Some(revision.rev_id));

                // Opti: save with multiple revisions
                let _ = self.save_revision(&revision).await?;
            }

            Ok(())
        } else {
            log::error!("Client rev_id should not equal to server rev_id");
        }
    }

    fn mk_revision(&self, base_rev_id: i64, delta: Delta) -> Revision {
        let delta_data = delta.into_bytes();
        let md5 = md5(&delta_data);
        let revision = Revision {
            base_rev_id,
            rev_id: self.rev_id.load(SeqCst),
            delta: delta_data,
            md5,
            doc_id: self.doc_id.to_string(),
            ty: RevType::Remote,
            ..Default::default()
        };
        revision
    }

    #[tracing::instrument(level = "debug", skip(self, delta_data))]
    fn transform(&self, delta_data: &Vec<u8>) -> Result<(Delta, Delta), OTError> {
        log::debug!("Document: {}", self.document.read().to_json());
        let doc_delta = self.document.read().delta().clone();
        let cli_delta = Delta::from_bytes(delta_data)?;

        log::debug!("Compose delta: {}", cli_delta);
        let (cli_prime, server_prime) = doc_delta.transform(&cli_delta)?;

        Ok((cli_prime, server_prime))
    }

    #[tracing::instrument(level = "debug", skip(self, delta))]
    fn update_document_delta(&self, delta: Delta) -> Result<(), ServerError> {
        // Opti: push each revision into queue and process it one by one.
        match self.document.try_write_for(Duration::from_millis(300)) {
            None => {
                log::error!("Failed to acquire write lock of document");
            },
            Some(mut write_guard) => {
                let _ = write_guard.compose_delta(&delta).map_err(internal_error)?;
                log::debug!("Document: {}", write_guard.to_json());
            },
        }
        Ok(())
    }

    fn verify_md5(&self, revision: &Revision) -> Result<(), ServerError> {
        if md5(&revision.delta) != revision.md5 {
            return Err(ServerError::internal().context("Delta md5 not match"));
        }
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self, revision))]
    async fn save_revision(&self, revision: &Revision) -> Result<(), ServerError> {
        let mut params = UpdateDocParams::new();
        params.set_doc_id(self.doc_id.clone());
        params.set_data(self.document.read().to_json());
        params.set_rev_id(revision.rev_id);

        let _ = update_doc(self.pg_pool.get_ref(), params).await?;

        Ok(())
    }
}

fn mk_rev_ws_message(doc_id: &str, revision: Revision) -> WsMessageAdaptor {
    let bytes = revision.write_to_bytes().unwrap();

    let data = WsDocumentData {
        id: doc_id.to_string(),
        ty: WsDataType::Rev,
        data: bytes,
    };

    let msg: WsMessage = data.into();
    let bytes: Bytes = msg.try_into().unwrap();
    WsMessageAdaptor(bytes)
}

fn mk_acked_ws_message(revision: &Revision) -> WsMessageAdaptor {
    let mut wtr = vec![];
    let _ = wtr.write_i64::<BigEndian>(revision.rev_id);

    let data = WsDocumentData {
        id: revision.doc_id.clone(),
        ty: WsDataType::Acked,
        data: wtr,
    };

    let msg: WsMessage = data.into();
    let bytes: Bytes = msg.try_into().unwrap();
    WsMessageAdaptor(bytes)
}
