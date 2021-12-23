use crate::{errors::FlowyError, services::doc::revision::RevisionCache};
use bytes::Bytes;
use flowy_collaboration::{
    entities::{
        doc::Doc,
        revision::{RevState, RevType, Revision, RevisionRange},
    },
    util::{md5, RevIdCounter},
};
use flowy_error::FlowyResult;
use lib_infra::future::FutureResult;
use lib_ot::{
    core::{Operation, OperationTransformable},
    rich_text::RichTextDelta,
};
use std::sync::Arc;

pub trait RevisionServer: Send + Sync {
    fn fetch_document(&self, doc_id: &str) -> FutureResult<Doc, FlowyError>;
}

pub struct RevisionManager {
    doc_id: String,
    user_id: String,
    rev_id_counter: RevIdCounter,
    cache: Arc<RevisionCache>,
}

impl RevisionManager {
    pub fn new(user_id: &str, doc_id: &str, cache: Arc<RevisionCache>) -> Self {
        let rev_id_counter = RevIdCounter::new(0);
        Self {
            doc_id: doc_id.to_string(),
            user_id: user_id.to_owned(),
            rev_id_counter,
            cache,
        }
    }

    pub async fn load_document(&mut self, server: Arc<dyn RevisionServer>) -> FlowyResult<RichTextDelta> {
        let revisions = RevisionLoader {
            doc_id: self.doc_id.clone(),
            user_id: self.user_id.clone(),
            server,
            cache: self.cache.clone(),
        }
        .load()
        .await?;
        let doc = mk_doc_from_revisions(&self.doc_id, revisions)?;
        self.update_rev_id_counter_value(doc.rev_id);
        Ok(doc.delta()?)
    }

    pub async fn add_remote_revision(&self, revision: &Revision) -> Result<(), FlowyError> {
        let _ = self.cache.add_remote_revision(revision.clone()).await?;
        Ok(())
    }

    pub async fn add_local_revision(&self, revision: &Revision) -> Result<(), FlowyError> {
        let _ = self.cache.add_local_revision(revision.clone()).await?;
        Ok(())
    }

    pub async fn ack_revision(&self, rev_id: i64) -> Result<(), FlowyError> {
        self.cache.ack_revision(rev_id).await;
        Ok(())
    }

    pub fn rev_id(&self) -> i64 { self.rev_id_counter.value() }

    pub fn next_rev_id(&self) -> (i64, i64) {
        let cur = self.rev_id_counter.value();
        let next = self.rev_id_counter.next();
        (cur, next)
    }

    pub fn update_rev_id_counter_value(&self, rev_id: i64) { self.rev_id_counter.set(rev_id); }

    pub async fn mk_revisions(&self, range: RevisionRange) -> Result<Revision, FlowyError> {
        debug_assert!(range.doc_id == self.doc_id);
        let revisions = self.cache.revisions_in_range(range.clone()).await?;
        let mut new_delta = RichTextDelta::new();
        // TODO: generate delta from revision should be wrapped into function.
        for revision in revisions {
            match RichTextDelta::from_bytes(revision.delta_data) {
                Ok(delta) => {
                    new_delta = new_delta.compose(&delta)?;
                },
                Err(e) => log::error!("{}", e),
            }
        }

        let delta_data = new_delta.to_bytes();
        let md5 = md5(&delta_data);
        let revision = Revision::new(
            &self.doc_id,
            range.start,
            range.end,
            delta_data,
            RevType::Remote,
            &self.user_id,
            md5,
        );

        Ok(revision)
    }

    pub fn next_sync_revision(&self) -> FutureResult<Option<Revision>, FlowyError> { self.cache.next_sync_revision() }

    pub async fn latest_revision(&self) -> Revision { self.cache.latest_revision().await }
}

#[cfg(feature = "flowy_unit_test")]
impl RevisionManager {
    pub fn revision_cache(&self) -> Arc<RevisionCache> { self.cache.clone() }
}

struct RevisionLoader {
    doc_id: String,
    user_id: String,
    server: Arc<dyn RevisionServer>,
    cache: Arc<RevisionCache>,
}

impl RevisionLoader {
    async fn load(&self) -> Result<Vec<Revision>, FlowyError> {
        let records = self.cache.disk_cache.read_revisions(&self.doc_id)?;
        let revisions: Vec<Revision>;
        if records.is_empty() {
            let doc = self.server.fetch_document(&self.doc_id).await?;
            let delta_data = Bytes::from(doc.text.clone());
            let doc_md5 = md5(&delta_data);
            let revision = Revision::new(
                &doc.id,
                doc.base_rev_id,
                doc.rev_id,
                delta_data,
                RevType::Remote,
                &self.user_id,
                doc_md5,
            );
            let _ = self.cache.add_local_revision(revision.clone()).await?;
            revisions = vec![revision];
        } else {
            for record in &records {
                match record.state {
                    RevState::StateLocal => match self.cache.add_local_revision(record.revision.clone()).await {
                        Ok(_) => {},
                        Err(e) => tracing::error!("{}", e),
                    },
                    RevState::Ack => {},
                }
            }
            revisions = records.into_iter().map(|record| record.revision).collect::<_>();
        }

        Ok(revisions)
    }
}

fn mk_doc_from_revisions(doc_id: &str, revisions: Vec<Revision>) -> FlowyResult<Doc> {
    let (base_rev_id, rev_id) = revisions.last().unwrap().pair_rev_id();
    let mut delta = RichTextDelta::new();
    for (_, revision) in revisions.into_iter().enumerate() {
        match RichTextDelta::from_bytes(revision.delta_data) {
            Ok(local_delta) => {
                delta = delta.compose(&local_delta)?;
            },
            Err(e) => {
                tracing::error!("Deserialize delta from revision failed: {}", e);
            },
        }
    }
    correct_delta_if_need(&mut delta);

    Result::<Doc, FlowyError>::Ok(Doc {
        id: doc_id.to_owned(),
        text: delta.to_json(),
        rev_id,
        base_rev_id,
    })
}
fn correct_delta_if_need(delta: &mut RichTextDelta) {
    if delta.ops.last().is_none() {
        return;
    }

    let data = delta.ops.last().as_ref().unwrap().get_data();
    if !data.ends_with('\n') {
        log::error!("❌The op must end with newline. Correcting it by inserting newline op");
        delta.ops.push(Operation::Insert("\n".into()));
    }
}
