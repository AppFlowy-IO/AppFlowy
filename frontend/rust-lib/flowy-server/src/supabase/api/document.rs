use anyhow::Error;
use collab::core::collab::DataSource;
use collab::core::origin::CollabOrigin;
use collab_document::blocks::DocumentData;
use collab_document::document::Document;
use collab_entity::CollabType;
use tokio::sync::oneshot::channel;

use flowy_document_pub::cloud::{DocumentCloudService, DocumentSnapshot};
use flowy_error::FlowyError;
use lib_dispatch::prelude::af_spawn;
use lib_infra::future::FutureResult;

use crate::supabase::api::request::{get_snapshots_from_server, FetchObjectUpdateAction};
use crate::supabase::api::SupabaseServerService;

pub struct SupabaseDocumentServiceImpl<T> {
  server: T,
}

impl<T> SupabaseDocumentServiceImpl<T> {
  pub fn new(server: T) -> Self {
    Self { server }
  }
}

impl<T> DocumentCloudService for SupabaseDocumentServiceImpl<T>
where
  T: SupabaseServerService,
{
  #[tracing::instrument(level = "debug", skip(self))]
  fn get_document_doc_state(
    &self,
    document_id: &str,
    workspace_id: &str,
  ) -> FutureResult<Vec<u8>, FlowyError> {
    let try_get_postgrest = self.server.try_get_weak_postgrest();
    let document_id = document_id.to_string();
    let (tx, rx) = channel();
    af_spawn(async move {
      tx.send(
        async move {
          let postgrest = try_get_postgrest?;
          let action = FetchObjectUpdateAction::new(document_id, CollabType::Document, postgrest);
          let collab_doc_state = action.run_with_fix_interval(5, 10).await?;
          if collab_doc_state.is_empty() {
            return Err(FlowyError::collab_not_sync());
          }
          Ok(collab_doc_state)
        }
        .await,
      )
    });
    FutureResult::new(async { rx.await? })
  }

  fn get_document_snapshots(
    &self,
    document_id: &str,
    limit: usize,
    _workspace_id: &str,
  ) -> FutureResult<Vec<DocumentSnapshot>, Error> {
    let try_get_postgrest = self.server.try_get_postgrest();
    let document_id = document_id.to_string();
    FutureResult::new(async move {
      let postgrest = try_get_postgrest?;
      let snapshots = get_snapshots_from_server(&document_id, postgrest, limit)
        .await?
        .into_iter()
        .map(|snapshot| DocumentSnapshot {
          snapshot_id: snapshot.sid,
          document_id: snapshot.oid,
          data: snapshot.blob,
          created_at: snapshot.created_at,
        })
        .collect::<Vec<_>>();
      Ok(snapshots)
    })
  }

  #[tracing::instrument(level = "debug", skip(self))]
  fn get_document_data(
    &self,
    document_id: &str,
    _workspace_id: &str,
  ) -> FutureResult<Option<DocumentData>, Error> {
    let try_get_postgrest = self.server.try_get_weak_postgrest();
    let document_id = document_id.to_string();
    let (tx, rx) = channel();
    af_spawn(async move {
      tx.send(
        async move {
          let postgrest = try_get_postgrest?;
          let action =
            FetchObjectUpdateAction::new(document_id.clone(), CollabType::Document, postgrest);
          let doc_state = action.run_with_fix_interval(5, 10).await?;
          let document = Document::from_doc_state(
            CollabOrigin::Empty,
            DataSource::DocStateV1(doc_state),
            &document_id,
            vec![],
          )?;
          Ok(document.get_document_data().ok())
        }
        .await,
      )
    });
    FutureResult::new(async { rx.await? })
  }
}
