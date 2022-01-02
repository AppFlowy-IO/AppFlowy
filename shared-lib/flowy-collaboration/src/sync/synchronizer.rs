use crate::{
    document::Document,
    entities::{
        revision::{Revision, RevisionRange},
        ws::{DocumentServerWSData, DocumentServerWSDataBuilder},
    },
    errors::CollaborateError,
    sync::DocumentPersistence,
};

use lib_ot::{core::OperationTransformable, rich_text::RichTextDelta};
use parking_lot::RwLock;
use std::{
    cmp::Ordering,
    fmt::Debug,
    sync::{
        atomic::{AtomicI64, Ordering::SeqCst},
        Arc,
    },
    time::Duration,
};

pub trait RevisionUser: Send + Sync + Debug {
    fn user_id(&self) -> String;
    fn receive(&self, resp: SyncResponse);
}

pub enum SyncResponse {
    Pull(DocumentServerWSData),
    Push(DocumentServerWSData),
    Ack(DocumentServerWSData),
    NewRevision(Vec<Revision>),
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

    #[tracing::instrument(level = "debug", skip(self, user, revisions, persistence), err)]
    pub async fn sync_revisions(
        &self,
        doc_id: String,
        user: Arc<dyn RevisionUser>,
        revisions: Vec<Revision>,
        persistence: Arc<dyn DocumentPersistence>,
    ) -> Result<(), CollaborateError> {
        if revisions.is_empty() {
            // Return all the revisions to client
            let revisions = persistence.get_doc_revisions(&doc_id).await?;
            let data = DocumentServerWSDataBuilder::build_push_message(&doc_id, revisions);
            user.receive(SyncResponse::Push(data));
            return Ok(());
        }

        let server_base_rev_id = self.rev_id.load(SeqCst);
        let first_revision = revisions.first().unwrap().clone();
        if self.is_applied_before(&first_revision, &persistence).await {
            // Server has received this revision before, so ignore the following revisions
            return Ok(());
        }

        match server_base_rev_id.cmp(&first_revision.rev_id) {
            Ordering::Less => {
                let server_rev_id = next(server_base_rev_id);
                if server_base_rev_id == first_revision.base_rev_id || server_rev_id == first_revision.rev_id {
                    // The rev is in the right order, just compose it.
                    for revision in &revisions {
                        let _ = self.compose_revision(revision)?;
                    }
                    user.receive(SyncResponse::NewRevision(revisions));
                } else {
                    // The server document is outdated, pull the missing revision from the client.
                    let range = RevisionRange {
                        doc_id: self.doc_id.clone(),
                        start: server_rev_id,
                        end: first_revision.rev_id,
                    };
                    let msg = DocumentServerWSDataBuilder::build_pull_message(&self.doc_id, range);
                    user.receive(SyncResponse::Pull(msg));
                }
            },
            Ordering::Equal => {
                // Do nothing
                log::warn!("Applied revision rev_id is the same as cur_rev_id");
            },
            Ordering::Greater => {
                // The client document is outdated. Transform the client revision delta and then
                // send the prime delta to the client. Client should compose the this prime
                // delta.
                let from_rev_id = first_revision.rev_id;
                let to_rev_id = server_base_rev_id;
                let _ = self.push_revisions_to_user(user, persistence, from_rev_id, to_rev_id);
            },
        }
        Ok(())
    }

    pub async fn pong(
        &self,
        doc_id: String,
        user: Arc<dyn RevisionUser>,
        persistence: Arc<dyn DocumentPersistence>,
        rev_id: i64,
    ) -> Result<(), CollaborateError> {
        let server_base_rev_id = self.rev_id.load(SeqCst);
        match server_base_rev_id.cmp(&rev_id) {
            Ordering::Less => tracing::error!(
                "[Pong] Client should not send ping and the server should pull the revisions from the client"
            ),
            Ordering::Equal => tracing::debug!("[Pong]: The document:{} is up to date.", doc_id),
            Ordering::Greater => {
                // The client document is outdated. Transform the client revision delta and then
                // send the prime delta to the client. Client should compose the this prime
                // delta.
                let from_rev_id = rev_id;
                let to_rev_id = server_base_rev_id;
                tracing::trace!("[Pong]: Push revisions to user");
                let _ = self.push_revisions_to_user(user, persistence, from_rev_id, to_rev_id);
            },
        }
        Ok(())
    }

    pub fn doc_json(&self) -> String { self.document.read().to_json() }

    fn compose_revision(&self, revision: &Revision) -> Result<(), CollaborateError> {
        let delta = RichTextDelta::from_bytes(&revision.delta_data)?;
        let _ = self.compose_delta(delta)?;
        let _ = self.rev_id.fetch_update(SeqCst, SeqCst, |_e| Some(revision.rev_id));
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self, revision))]
    fn transform_revision(&self, revision: &Revision) -> Result<(RichTextDelta, RichTextDelta), CollaborateError> {
        let cli_delta = RichTextDelta::from_bytes(&revision.delta_data)?;
        let result = self.document.read().delta().transform(&cli_delta)?;
        Ok(result)
    }

    fn compose_delta(&self, delta: RichTextDelta) -> Result<(), CollaborateError> {
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

    #[allow(dead_code)]
    pub(crate) fn rev_id(&self) -> i64 { self.rev_id.load(SeqCst) }

    async fn is_applied_before(&self, new_revision: &Revision, persistence: &Arc<dyn DocumentPersistence>) -> bool {
        if let Ok(revisions) = persistence.get_revisions(&self.doc_id, vec![new_revision.rev_id]).await {
            if let Some(revision) = revisions.first() {
                if revision.md5 == new_revision.md5 {
                    return true;
                }
            }
        };

        false
    }

    async fn push_revisions_to_user(
        &self,
        user: Arc<dyn RevisionUser>,
        persistence: Arc<dyn DocumentPersistence>,
        from: i64,
        to: i64,
    ) {
        let rev_ids: Vec<i64> = (from..=to).collect();
        let revisions = match persistence.get_revisions(&self.doc_id, rev_ids).await {
            Ok(revisions) => {
                assert_eq!(
                    revisions.is_empty(),
                    false,
                    "revisions should not be empty if the doc exists"
                );
                revisions
            },
            Err(e) => {
                tracing::error!("{}", e);
                vec![]
            },
        };

        let data = DocumentServerWSDataBuilder::build_push_message(&self.doc_id, revisions);
        user.receive(SyncResponse::Push(data));
    }
}

#[inline]
fn next(rev_id: i64) -> i64 { rev_id + 1 }
// #[inline]
// fn md5<T: AsRef<[u8]>>(data: T) -> String {
//     let md5 = format!("{:x}", md5::compute(data));
//     md5
// }
