use crate::RevisionManager;
use bytes::Bytes;
use flowy_error::{FlowyError, FlowyResult};
use flowy_sync::entities::{
    revision::{RepeatedRevision, Revision, RevisionRange},
    ws_data::ServerRevisionWSDataType,
};
use lib_infra::future::BoxResultFuture;

use diesel::SqliteConnection;
use flowy_database::ConnectionPool;
use std::{convert::TryFrom, sync::Arc};

pub type OperationsMD5 = String;

pub struct TransformOperations<Operations> {
    pub client_operations: Operations,
    pub server_operations: Option<Operations>,
}

pub trait OperationsDeserializer<T>: Send + Sync {
    fn deserialize_revisions(revisions: Vec<Revision>) -> FlowyResult<T>;
}

pub trait OperationsSerializer: Send + Sync {
    fn serialize_operations(&self) -> Bytes;
}

pub struct ConflictOperations<T>(T);
pub trait ConflictResolver<Operations>
where
    Operations: Send + Sync,
{
    fn compose_operations(&self, operations: Operations) -> BoxResultFuture<OperationsMD5, FlowyError>;
    fn transform_operations(
        &self,
        operations: Operations,
    ) -> BoxResultFuture<TransformOperations<Operations>, FlowyError>;
    fn reset_operations(&self, operations: Operations) -> BoxResultFuture<OperationsMD5, FlowyError>;
}

pub trait ConflictRevisionSink: Send + Sync + 'static {
    fn send(&self, revisions: Vec<Revision>) -> BoxResultFuture<(), FlowyError>;
    fn ack(&self, rev_id: String, ty: ServerRevisionWSDataType) -> BoxResultFuture<(), FlowyError>;
}

pub struct ConflictController<Operations>
where
    Operations: Send + Sync,
{
    user_id: String,
    resolver: Arc<dyn ConflictResolver<Operations> + Send + Sync>,
    rev_sink: Arc<dyn ConflictRevisionSink>,
    rev_manager: Arc<RevisionManager<Arc<ConnectionPool>>>,
}

impl<Operations> ConflictController<Operations>
where
    Operations: Clone + Send + Sync,
{
    pub fn new(
        user_id: &str,
        resolver: Arc<dyn ConflictResolver<Operations> + Send + Sync>,
        rev_sink: Arc<dyn ConflictRevisionSink>,
        rev_manager: Arc<RevisionManager<Arc<ConnectionPool>>>,
    ) -> Self {
        let user_id = user_id.to_owned();
        Self {
            user_id,
            resolver,
            rev_sink,
            rev_manager,
        }
    }
}

impl<Operations> ConflictController<Operations>
where
    Operations: OperationsSerializer + OperationsDeserializer<Operations> + Clone + Send + Sync,
{
    pub async fn receive_bytes(&self, bytes: Bytes) -> FlowyResult<()> {
        let repeated_revision = RepeatedRevision::try_from(bytes)?;
        if repeated_revision.is_empty() {
            return Ok(());
        }

        match self.handle_revision(repeated_revision).await? {
            None => {}
            Some(server_revision) => {
                self.rev_sink.send(vec![server_revision]).await?;
            }
        }
        Ok(())
    }

    pub async fn ack_revision(&self, rev_id: String, ty: ServerRevisionWSDataType) -> FlowyResult<()> {
        let _ = self.rev_sink.ack(rev_id, ty).await?;
        Ok(())
    }

    pub async fn send_revisions(&self, range: RevisionRange) -> FlowyResult<()> {
        let revisions = self.rev_manager.get_revisions_in_range(range).await?;
        let _ = self.rev_sink.send(revisions).await?;
        Ok(())
    }

    async fn handle_revision(&self, repeated_revision: RepeatedRevision) -> FlowyResult<Option<Revision>> {
        let mut revisions = repeated_revision.into_inner();
        let first_revision = revisions.first().unwrap();
        if let Some(local_revision) = self.rev_manager.get_revision(first_revision.rev_id).await {
            if local_revision.md5 == first_revision.md5 {
                // The local revision is equal to the pushed revision. Just ignore it.
                revisions = revisions.split_off(1);
                if revisions.is_empty() {
                    return Ok(None);
                }
            } else {
                return Ok(None);
            }
        }

        let new_operations = Operations::deserialize_revisions(revisions.clone())?;
        let TransformOperations {
            client_operations,
            server_operations,
        } = self.resolver.transform_operations(new_operations).await?;

        match server_operations {
            None => {
                // The server_prime is None means the client local revisions conflict with the
                // // server, and it needs to override the client delta.
                let md5 = self.resolver.reset_operations(client_operations).await?;
                let repeated_revision = RepeatedRevision::new(revisions);
                assert_eq!(repeated_revision.last().unwrap().md5, md5);
                let _ = self.rev_manager.reset_object(repeated_revision).await?;
                Ok(None)
            }
            Some(server_operations) => {
                let md5 = self.resolver.compose_operations(client_operations.clone()).await?;
                for revision in &revisions {
                    let _ = self.rev_manager.add_remote_revision(revision).await?;
                }
                let (client_revision, server_revision) = make_client_and_server_revision(
                    &self.user_id,
                    &self.rev_manager,
                    client_operations,
                    Some(server_operations),
                    md5,
                );
                let _ = self.rev_manager.add_remote_revision(&client_revision).await?;
                Ok(server_revision)
            }
        }
    }
}

fn make_client_and_server_revision<Operations>(
    user_id: &str,
    rev_manager: &Arc<RevisionManager<Arc<ConnectionPool>>>,
    client_operations: Operations,
    server_operations: Option<Operations>,
    md5: String,
) -> (Revision, Option<Revision>)
where
    Operations: OperationsSerializer,
{
    let (base_rev_id, rev_id) = rev_manager.next_rev_id_pair();
    let bytes = client_operations.serialize_operations();
    let client_revision = Revision::new(&rev_manager.object_id, base_rev_id, rev_id, bytes, user_id, md5.clone());

    match server_operations {
        None => (client_revision, None),
        Some(operations) => {
            let bytes = operations.serialize_operations();
            let server_revision = Revision::new(&rev_manager.object_id, base_rev_id, rev_id, bytes, user_id, md5);
            (client_revision, Some(server_revision))
        }
    }
}
