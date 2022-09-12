use crate::entities::revision::{RepeatedRevision, Revision};
use crate::{
    entities::{
        revision::RevisionRange,
        ws_data::{ServerRevisionWSData, ServerRevisionWSDataBuilder},
    },
    errors::CollaborateError,
    protobuf::Revision as RevisionPB,
    util::*,
};
use lib_infra::future::BoxResultFuture;
use lib_ot::core::{OperationAttributes, Operations};
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

    fn save_revisions(&self, repeated_revision: RepeatedRevision) -> BoxResultFuture<(), CollaborateError>;

    fn reset_object(
        &self,
        object_id: &str,
        repeated_revision: RepeatedRevision,
    ) -> BoxResultFuture<(), CollaborateError>;
}

pub trait RevisionSyncObject<T: OperationAttributes>: Send + Sync + 'static {
    fn id(&self) -> &str;
    fn compose(&mut self, other: &Operations<T>) -> Result<(), CollaborateError>;
    fn transform(&self, other: &Operations<T>) -> Result<(Operations<T>, Operations<T>), CollaborateError>;
    fn to_json(&self) -> String;
    fn set_delta(&mut self, new_delta: Operations<T>);
}

pub enum RevisionSyncResponse {
    Pull(ServerRevisionWSData),
    Push(ServerRevisionWSData),
    Ack(ServerRevisionWSData),
}

pub struct RevisionSynchronizer<T: OperationAttributes> {
    object_id: String,
    rev_id: AtomicI64,
    object: Arc<RwLock<dyn RevisionSyncObject<T>>>,
    persistence: Arc<dyn RevisionSyncPersistence>,
}

impl<T> RevisionSynchronizer<T>
where
    T: OperationAttributes + DeserializeOwned + serde::Serialize + 'static,
{
    pub fn new<S, P>(rev_id: i64, sync_object: S, persistence: P) -> RevisionSynchronizer<T>
    where
        S: RevisionSyncObject<T>,
        P: RevisionSyncPersistence,
    {
        let object = Arc::new(RwLock::new(sync_object));
        let persistence = Arc::new(persistence);
        let object_id = object.read().id().to_owned();
        RevisionSynchronizer {
            object_id,
            rev_id: AtomicI64::new(rev_id),
            object,
            persistence,
        }
    }

    #[tracing::instrument(level = "trace", skip(self, user, repeated_revision), err)]
    pub async fn sync_revisions(
        &self,
        user: Arc<dyn RevisionUser>,
        repeated_revision: RepeatedRevision,
    ) -> Result<(), CollaborateError> {
        let object_id = self.object_id.clone();
        if repeated_revision.is_empty() {
            // Return all the revisions to client
            let revisions = self.persistence.read_revisions(&object_id, None).await?;
            let repeated_revision = RepeatedRevision::from(revisions);
            let data = ServerRevisionWSDataBuilder::build_push_message(&object_id, repeated_revision);
            user.receive(RevisionSyncResponse::Push(data));
            return Ok(());
        }

        let server_base_rev_id = self.rev_id.load(SeqCst);
        let first_revision = repeated_revision.first().unwrap().clone();
        if self.is_applied_before(&first_revision, &self.persistence).await {
            // Server has received this revision before, so ignore the following revisions
            return Ok(());
        }

        match server_base_rev_id.cmp(&first_revision.rev_id) {
            Ordering::Less => {
                let server_rev_id = next(server_base_rev_id);
                if server_base_rev_id == first_revision.base_rev_id || server_rev_id == first_revision.rev_id {
                    // The rev is in the right order, just compose it.
                    for revision in repeated_revision.iter() {
                        let _ = self.compose_revision(revision)?;
                    }
                    let _ = self.persistence.save_revisions(repeated_revision).await?;
                } else {
                    // The server delta is outdated, pull the missing revision from the client.
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
                // The client delta is outdated. Transform the client revision delta and then
                // send the prime delta to the client. Client should compose the this prime
                // delta.
                let from_rev_id = first_revision.rev_id;
                let to_rev_id = server_base_rev_id;
                let _ = self.push_revisions_to_user(user, from_rev_id, to_rev_id).await;
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
                // The client delta is outdated. Transform the client revision delta and then
                // send the prime delta to the client. Client should compose the this prime
                // delta.
                let from_rev_id = client_rev_id;
                let to_rev_id = server_rev_id;
                tracing::trace!("Push revisions to user");
                let _ = self.push_revisions_to_user(user, from_rev_id, to_rev_id).await;
            }
        }
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self, repeated_revision), fields(object_id), err)]
    pub async fn reset(&self, repeated_revision: RepeatedRevision) -> Result<(), CollaborateError> {
        let object_id = self.object_id.clone();
        tracing::Span::current().record("object_id", &object_id.as_str());
        let revisions: Vec<Revision> = repeated_revision.clone().into_inner();
        let (_, rev_id) = pair_rev_id_from_revision_pbs(&revisions);
        let delta = make_delta_from_revision_pb(revisions)?;
        let _ = self.persistence.reset_object(&object_id, repeated_revision).await?;
        self.object.write().set_delta(delta);
        let _ = self.rev_id.fetch_update(SeqCst, SeqCst, |_e| Some(rev_id));
        Ok(())
    }

    pub fn object_json(&self) -> String {
        self.object.read().to_json()
    }

    fn compose_revision(&self, revision: &Revision) -> Result<(), CollaborateError> {
        let delta = Operations::<T>::from_bytes(&revision.delta_data)?;
        let _ = self.compose_delta(delta)?;
        let _ = self.rev_id.fetch_update(SeqCst, SeqCst, |_e| Some(revision.rev_id));
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self, revision))]
    fn transform_revision(&self, revision: &RevisionPB) -> Result<(Operations<T>, Operations<T>), CollaborateError> {
        let cli_delta = Operations::<T>::from_bytes(&revision.delta_data)?;
        let result = self.object.read().transform(&cli_delta)?;
        Ok(result)
    }

    fn compose_delta(&self, delta: Operations<T>) -> Result<(), CollaborateError> {
        if delta.is_empty() {
            log::warn!("Composed delta is empty");
        }

        match self.object.try_write_for(Duration::from_millis(300)) {
            None => log::error!("Failed to acquire write lock of object"),
            Some(mut write_guard) => {
                let _ = write_guard.compose(&delta)?;
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

                let repeated_revision = RepeatedRevision::from(revisions);
                let data = ServerRevisionWSDataBuilder::build_push_message(&self.object_id, repeated_revision);
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
