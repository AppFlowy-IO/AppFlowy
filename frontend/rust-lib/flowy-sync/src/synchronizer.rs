use crate::{errors::CollaborateError, util::*};
use flowy_http_model::revision::{Revision, RevisionRange};
use flowy_http_model::ws_data::{ServerRevisionWSData, ServerRevisionWSDataBuilder};
use lib_infra::future::BoxResultFuture;
use lib_ot::core::{DeltaOperations, OperationAttributes};
use parking_lot::RwLock;
use serde::de::DeserializeOwned;
use std::{
    cmp::Ordering,
    fmt::Debug,
    sync::{
        atomic::{AtomicI64, Ordering::SeqCst},
        Arc,
    },
    time::Duration,
};

pub type RevisionOperations<Attribute> = DeltaOperations<Attribute>;

pub trait RevisionOperations2<Attribute>: Send + Sync {
    fn from_bytes<B: AsRef<[u8]>>(bytes: B) -> Result<Self, CollaborateError>
    where
        Self: Sized;
}

pub trait RevisionUser: Send + Sync + Debug {
    fn user_id(&self) -> String;
    fn receive(&self, resp: RevisionSyncResponse);
}

pub trait RevisionSyncPersistence: Send + Sync + 'static {
    fn read_revisions(
        &self,
        object_id: &str,
        rev_ids: Option<Vec<i64>>,
    ) -> BoxResultFuture<Vec<Revision>, CollaborateError>;

    fn save_revisions(&self, revisions: Vec<Revision>) -> BoxResultFuture<(), CollaborateError>;

    fn reset_object(&self, object_id: &str, revisions: Vec<Revision>) -> BoxResultFuture<(), CollaborateError>;
}

pub trait RevisionSyncObject<Attribute: OperationAttributes>: Send + Sync + 'static {
    fn object_id(&self) -> &str;

    fn object_json(&self) -> String;

    fn compose(&mut self, other: &RevisionOperations<Attribute>) -> Result<(), CollaborateError>;

    fn transform(
        &self,
        other: &RevisionOperations<Attribute>,
    ) -> Result<(RevisionOperations<Attribute>, RevisionOperations<Attribute>), CollaborateError>;

    fn set_operations(&mut self, operations: RevisionOperations<Attribute>);
}

pub enum RevisionSyncResponse {
    Pull(ServerRevisionWSData),
    Push(ServerRevisionWSData),
    Ack(ServerRevisionWSData),
}

pub struct RevisionSynchronizer<Attribute: OperationAttributes> {
    object_id: String,
    rev_id: AtomicI64,
    object: Arc<RwLock<dyn RevisionSyncObject<Attribute>>>,
    persistence: Arc<dyn RevisionSyncPersistence>,
}

impl<Attribute> RevisionSynchronizer<Attribute>
where
    Attribute: OperationAttributes + DeserializeOwned + serde::Serialize + 'static,
{
    pub fn new<S, P>(rev_id: i64, sync_object: S, persistence: P) -> RevisionSynchronizer<Attribute>
    where
        S: RevisionSyncObject<Attribute>,
        P: RevisionSyncPersistence,
    {
        let object = Arc::new(RwLock::new(sync_object));
        let persistence = Arc::new(persistence);
        let object_id = object.read().object_id().to_owned();
        RevisionSynchronizer {
            object_id,
            rev_id: AtomicI64::new(rev_id),
            object,
            persistence,
        }
    }

    #[tracing::instrument(level = "trace", skip(self, user, revisions), err)]
    pub async fn sync_revisions(
        &self,
        user: Arc<dyn RevisionUser>,
        revisions: Vec<Revision>,
    ) -> Result<(), CollaborateError> {
        let object_id = self.object_id.clone();
        if revisions.is_empty() {
            // Return all the revisions to client
            let revisions = self.persistence.read_revisions(&object_id, None).await?;
            let data = ServerRevisionWSDataBuilder::build_push_message(&object_id, revisions);
            user.receive(RevisionSyncResponse::Push(data));
            return Ok(());
        }

        let server_base_rev_id = self.rev_id.load(SeqCst);
        let first_revision = revisions.first().unwrap().clone();
        if self.is_applied_before(&first_revision, &self.persistence).await {
            // Server has received this revision before, so ignore the following revisions
            return Ok(());
        }

        match server_base_rev_id.cmp(&first_revision.rev_id) {
            Ordering::Less => {
                let server_rev_id = next(server_base_rev_id);
                if server_base_rev_id == first_revision.base_rev_id || server_rev_id == first_revision.rev_id {
                    // The rev is in the right order, just compose it.
                    for revision in revisions.iter() {
                        self.compose_revision(revision)?;
                    }
                    self.persistence.save_revisions(revisions).await?;
                } else {
                    // The server ops is outdated, pull the missing revision from the client.
                    let range = RevisionRange {
                        start: server_rev_id,
                        end: first_revision.rev_id,
                    };
                    let msg = ServerRevisionWSDataBuilder::build_pull_message(&self.object_id, range);
                    user.receive(RevisionSyncResponse::Pull(msg));
                }
            }
            Ordering::Equal => {
                // Do nothing
                tracing::trace!("Applied {} revision rev_id is the same as cur_rev_id", self.object_id);
            }
            Ordering::Greater => {
                // The client ops is outdated. Transform the client revision ops and then
                // send the prime ops to the client. Client should compose the this prime
                // ops.
                let from_rev_id = first_revision.rev_id;
                let to_rev_id = server_base_rev_id;
                self.push_revisions_to_user(user, from_rev_id, to_rev_id).await;
            }
        }
        Ok(())
    }

    #[tracing::instrument(level = "trace", skip(self, user), fields(server_rev_id), err)]
    pub async fn pong(&self, user: Arc<dyn RevisionUser>, client_rev_id: i64) -> Result<(), CollaborateError> {
        let object_id = self.object_id.clone();
        let server_rev_id = self.rev_id();
        tracing::Span::current().record("server_rev_id", &server_rev_id);
        match server_rev_id.cmp(&client_rev_id) {
            Ordering::Less => {
                tracing::trace!("Client should not send ping and the server should pull the revisions from the client")
            }
            Ordering::Equal => tracing::trace!("{} is up to date.", object_id),
            Ordering::Greater => {
                // The client ops is outdated. Transform the client revision ops and then
                // send the prime ops to the client. Client should compose the this prime
                // ops.
                let from_rev_id = client_rev_id;
                let to_rev_id = server_rev_id;
                tracing::trace!("Push revisions to user");
                self.push_revisions_to_user(user, from_rev_id, to_rev_id).await;
            }
        }
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self, revisions), fields(object_id), err)]
    pub async fn reset(&self, revisions: Vec<Revision>) -> Result<(), CollaborateError> {
        let object_id = self.object_id.clone();
        tracing::Span::current().record("object_id", &object_id.as_str());
        let (_, rev_id) = pair_rev_id_from_revision_pbs(&revisions);
        let operations = make_operations_from_revisions(revisions.clone())?;
        self.persistence.reset_object(&object_id, revisions).await?;
        self.object.write().set_operations(operations);
        let _ = self.rev_id.fetch_update(SeqCst, SeqCst, |_e| Some(rev_id));
        Ok(())
    }

    pub fn object_json(&self) -> String {
        self.object.read().object_json()
    }

    fn compose_revision(&self, revision: &Revision) -> Result<(), CollaborateError> {
        let operations = RevisionOperations::<Attribute>::from_bytes(&revision.bytes)?;
        self.compose_operations(operations)?;
        let _ = self.rev_id.fetch_update(SeqCst, SeqCst, |_e| Some(revision.rev_id));
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self, revision))]
    fn transform_revision(
        &self,
        revision: &Revision,
    ) -> Result<(RevisionOperations<Attribute>, RevisionOperations<Attribute>), CollaborateError> {
        let client_operations = RevisionOperations::<Attribute>::from_bytes(&revision.bytes)?;
        let result = self.object.read().transform(&client_operations)?;
        Ok(result)
    }

    fn compose_operations(&self, operations: RevisionOperations<Attribute>) -> Result<(), CollaborateError> {
        if operations.is_empty() {
            log::warn!("Composed operations is empty");
        }

        match self.object.try_write_for(Duration::from_millis(300)) {
            None => log::error!("Failed to acquire write lock of object"),
            Some(mut write_guard) => {
                write_guard.compose(&operations)?;
            }
        }
        Ok(())
    }

    pub(crate) fn rev_id(&self) -> i64 {
        self.rev_id.load(SeqCst)
    }

    async fn is_applied_before(&self, new_revision: &Revision, persistence: &Arc<dyn RevisionSyncPersistence>) -> bool {
        let rev_ids = Some(vec![new_revision.rev_id]);
        if let Ok(revisions) = persistence.read_revisions(&self.object_id, rev_ids).await {
            if let Some(revision) = revisions.first() {
                if revision.md5 == new_revision.md5 {
                    return true;
                }
            }
        };

        false
    }

    async fn push_revisions_to_user(&self, user: Arc<dyn RevisionUser>, from: i64, to: i64) {
        let rev_ids: Vec<i64> = (from..=to).collect();
        tracing::debug!("Push revision: {} -> {} to client", from, to);
        match self
            .persistence
            .read_revisions(&self.object_id, Some(rev_ids.clone()))
            .await
        {
            Ok(revisions) => {
                if !rev_ids.is_empty() && revisions.is_empty() {
                    tracing::trace!("{}: can not read the revisions in range {:?}", self.object_id, rev_ids);
                    // assert_eq!(revisions.is_empty(), rev_ids.is_empty(),);
                }

                let data = ServerRevisionWSDataBuilder::build_push_message(&self.object_id, revisions);
                user.receive(RevisionSyncResponse::Push(data));
            }
            Err(e) => {
                tracing::error!("{}", e);
            }
        };
    }
}

#[inline]
fn next(rev_id: i64) -> i64 {
    rev_id + 1
}
