use crate::{
    core::document::Document,
    entities::ws::{DocumentWSData, DocumentWSDataType, WsDocumentDataBuilder},
};
use bytes::Bytes;
use lib_ot::{
    core::OperationTransformable,
    errors::OTError,
    protobuf::RevId,
    revision::{RevType, Revision, RevisionRange},
    rich_text::RichTextDelta,
};
use parking_lot::RwLock;
use protobuf::Message;
use std::{
    cmp::Ordering,
    convert::TryInto,
    fmt::Debug,
    sync::{
        atomic::{AtomicI64, Ordering::SeqCst},
        Arc,
    },
    time::Duration,
};

pub trait RevisionUser: Send + Sync + Debug {
    fn user_id(&self) -> String;
    fn recv(&self, resp: SyncResponse);
}

pub enum SyncResponse {
    Pull(DocumentWSData),
    Push(DocumentWSData),
    Ack(DocumentWSData),
    NewRevision {
        rev_id: i64,
        doc_json: String,
        doc_id: String,
    },
}

pub struct RevisionSynchronizer {
    pub doc_id: String,
    pub rev_id: AtomicI64,
    document: Arc<RwLock<Document>>,
}

impl RevisionSynchronizer {
    pub fn new(doc_id: &str, rev_id: i64, document: Document) -> RevisionSynchronizer {
        let document = Arc::new(RwLock::new(document));
        RevisionSynchronizer {
            doc_id: doc_id.to_string(),
            rev_id: AtomicI64::new(rev_id),
            document,
        }
    }

    pub fn apply_revision(&self, user: Arc<dyn RevisionUser>, revision: Revision) -> Result<(), OTError> {
        let server_base_rev_id = self.rev_id.load(SeqCst);
        match server_base_rev_id.cmp(&revision.rev_id) {
            Ordering::Less => {
                let server_rev_id = next(server_base_rev_id);
                if server_base_rev_id == revision.base_rev_id || server_rev_id == revision.rev_id {
                    // The rev is in the right order, just compose it.
                    let _ = self.compose_revision(&revision)?;
                    user.recv(SyncResponse::Ack(WsDocumentDataBuilder::build_acked_message(
                        &revision.doc_id,
                        revision.rev_id,
                    )));
                    let rev_id = revision.rev_id;
                    let doc_id = self.doc_id.clone();
                    let doc_json = self.doc_json();
                    user.recv(SyncResponse::NewRevision {
                        rev_id,
                        doc_id,
                        doc_json,
                    });
                } else {
                    // The server document is outdated, pull the missing revision from the client.
                    let range = RevisionRange {
                        doc_id: self.doc_id.clone(),
                        start: server_rev_id,
                        end: revision.rev_id,
                    };
                    let msg = WsDocumentDataBuilder::build_push_pull_message(&self.doc_id, range);
                    user.recv(SyncResponse::Pull(msg));
                }
            },
            Ordering::Equal => {
                // Do nothing
                log::warn!("Applied revision rev_id is the same as cur_rev_id");
                let data = WsDocumentDataBuilder::build_acked_message(&revision.doc_id, revision.rev_id);
                user.recv(SyncResponse::Ack(data));
            },
            Ordering::Greater => {
                // The client document is outdated. Transform the client revision delta and then
                // send the prime delta to the client. Client should compose the this prime
                // delta.
                let cli_revision = self.transform_revision(&revision)?;
                let data = WsDocumentDataBuilder::build_push_rev_message(&self.doc_id, cli_revision);
                user.recv(SyncResponse::Push(data));
            },
        }
        Ok(())
    }

    pub fn doc_json(&self) -> String { self.document.read().to_json() }

    fn compose_revision(&self, revision: &Revision) -> Result<(), OTError> {
        let delta = RichTextDelta::from_bytes(&revision.delta_data)?;
        let _ = self.compose_delta(delta)?;
        let _ = self.rev_id.fetch_update(SeqCst, SeqCst, |_e| Some(revision.rev_id));
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self, revision))]
    fn transform_revision(&self, revision: &Revision) -> Result<Revision, OTError> {
        let cli_delta = RichTextDelta::from_bytes(&revision.delta_data)?;
        let (cli_prime, server_prime) = self.document.read().delta().transform(&cli_delta)?;

        let _ = self.compose_delta(server_prime)?;
        let cli_revision = self.mk_revision(revision.rev_id, cli_prime);
        Ok(cli_revision)
    }

    fn compose_delta(&self, delta: RichTextDelta) -> Result<(), OTError> {
        if delta.is_empty() {
            log::warn!("Composed delta is empty");
        }

        match self.document.try_write_for(Duration::from_millis(300)) {
            None => log::error!("Failed to acquire write lock of document"),
            Some(mut write_guard) => {
                let _ = write_guard.compose_delta(delta);
            },
        }
        Ok(())
    }

    fn mk_revision(&self, base_rev_id: i64, delta: RichTextDelta) -> Revision {
        let delta_data = delta.to_bytes().to_vec();
        let md5 = md5(&delta_data);
        Revision {
            base_rev_id,
            rev_id: self.rev_id.load(SeqCst),
            delta_data,
            md5,
            doc_id: self.doc_id.to_string(),
            ty: RevType::Remote,
            user_id: "".to_string(),
        }
    }
}

#[inline]
fn next(rev_id: i64) -> i64 { rev_id + 1 }

#[inline]
fn md5<T: AsRef<[u8]>>(data: T) -> String {
    let md5 = format!("{:x}", md5::compute(data));
    md5
}
