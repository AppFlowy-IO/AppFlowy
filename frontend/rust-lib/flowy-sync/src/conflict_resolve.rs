use crate::RevisionManager;
use bytes::Bytes;
use flowy_collaboration::{
    entities::{
        revision::{RepeatedRevision, Revision, RevisionRange},
        ws_data::ServerRevisionWSDataType,
    },
    util::make_delta_from_revisions,
};
use flowy_error::{FlowyError, FlowyResult};
use lib_infra::future::BoxResultFuture;
use lib_ot::core::{Attributes, Delta};
use serde::de::DeserializeOwned;
use std::{convert::TryFrom, sync::Arc};

pub type DeltaMD5 = String;

pub trait ConflictResolver<T>
where
    T: Attributes + Send + Sync,
{
    fn compose_delta(&self, delta: Delta<T>) -> BoxResultFuture<DeltaMD5, FlowyError>;
    fn transform_delta(&self, delta: Delta<T>) -> BoxResultFuture<TransformDeltas<T>, FlowyError>;
    fn reset_delta(&self, delta: Delta<T>) -> BoxResultFuture<DeltaMD5, FlowyError>;
}

pub trait ConflictRevisionSink: Send + Sync + 'static {
    fn send(&self, revisions: Vec<Revision>) -> BoxResultFuture<(), FlowyError>;
    fn ack(&self, rev_id: String, ty: ServerRevisionWSDataType) -> BoxResultFuture<(), FlowyError>;
}

pub struct ConflictController<T>
where
    T: Attributes + Send + Sync,
{
    user_id: String,
    resolver: Arc<dyn ConflictResolver<T> + Send + Sync>,
    rev_sink: Arc<dyn ConflictRevisionSink>,
    rev_manager: Arc<RevisionManager>,
}

impl<T> ConflictController<T>
where
    T: Attributes + Send + Sync + DeserializeOwned + serde::Serialize,
{
    pub fn new(
        user_id: &str,
        resolver: Arc<dyn ConflictResolver<T> + Send + Sync>,
        rev_sink: Arc<dyn ConflictRevisionSink>,
        rev_manager: Arc<RevisionManager>,
    ) -> Self {
        let user_id = user_id.to_owned();
        Self {
            user_id,
            resolver,
            rev_sink,
            rev_manager,
        }
    }

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

        let new_delta = make_delta_from_revisions(revisions.clone())?;

        let TransformDeltas {
            client_prime,
            server_prime,
        } = self.resolver.transform_delta(new_delta).await?;

        match server_prime {
            None => {
                // The server_prime is None means the client local revisions conflict with the
                // // server, and it needs to override the client delta.
                let md5 = self.resolver.reset_delta(client_prime).await?;
                let repeated_revision = RepeatedRevision::new(revisions);
                assert_eq!(repeated_revision.last().unwrap().md5, md5);
                let _ = self.rev_manager.reset_object(repeated_revision).await?;
                Ok(None)
            }
            Some(server_prime) => {
                let md5 = self.resolver.compose_delta(client_prime.clone()).await?;
                for revision in &revisions {
                    let _ = self.rev_manager.add_remote_revision(revision).await?;
                }
                let (client_revision, server_revision) = make_client_and_server_revision(
                    &self.user_id,
                    &self.rev_manager,
                    client_prime,
                    Some(server_prime),
                    md5,
                );
                let _ = self.rev_manager.add_remote_revision(&client_revision).await?;
                Ok(server_revision)
            }
        }
    }
}

fn make_client_and_server_revision<T>(
    user_id: &str,
    rev_manager: &Arc<RevisionManager>,
    client_delta: Delta<T>,
    server_delta: Option<Delta<T>>,
    md5: String,
) -> (Revision, Option<Revision>)
where
    T: Attributes + serde::Serialize,
{
    let (base_rev_id, rev_id) = rev_manager.next_rev_id_pair();
    let client_revision = Revision::new(
        &rev_manager.object_id,
        base_rev_id,
        rev_id,
        client_delta.to_bytes(),
        user_id,
        md5.clone(),
    );

    match server_delta {
        None => (client_revision, None),
        Some(server_delta) => {
            let server_revision = Revision::new(
                &rev_manager.object_id,
                base_rev_id,
                rev_id,
                server_delta.to_bytes(),
                user_id,
                md5,
            );
            (client_revision, Some(server_revision))
        }
    }
}

pub struct TransformDeltas<T>
where
    T: Attributes,
{
    pub client_prime: Delta<T>,
    pub server_prime: Option<Delta<T>>,
}
