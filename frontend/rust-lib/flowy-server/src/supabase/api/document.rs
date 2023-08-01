use anyhow::Error;
use collab::core::origin::CollabOrigin;
use collab_document::blocks::DocumentData;
use collab_document::document::Document;
use collab_plugins::cloud_storage::CollabType;
use tokio::sync::oneshot::channel;

use flowy_document_deps::cloud::{DocumentCloudService, DocumentSnapshot};
use lib_infra::future::FutureResult;

use crate::supabase::api::request::{get_latest_snapshot_from_server, FetchObjectUpdateAction};
use crate::supabase::api::SupabaseServerService;

pub struct RESTfulSupabaseDocumentServiceImpl<T>(T);
impl<T> RESTfulSupabaseDocumentServiceImpl<T> {
  pub fn new(server: T) -> Self {
    Self(server)
  }
}

impl<T> DocumentCloudService for RESTfulSupabaseDocumentServiceImpl<T>
where
  T: SupabaseServerService,
{
  fn get_document_updates(&self, document_id: &str) -> FutureResult<Vec<Vec<u8>>, Error> {
    let try_get_postgrest = self.0.try_get_weak_postgrest();
    let document_id = document_id.to_string();
    let (tx, rx) = channel();
    tokio::spawn(async move {
      tx.send(
        async move {
          let postgrest = try_get_postgrest?;
          let action = FetchObjectUpdateAction::new(document_id, CollabType::Document, postgrest);
          action.run_with_fix_interval(5, 5).await
        }
        .await,
      )
    });
    FutureResult::new(async { rx.await? })
  }

  fn get_document_latest_snapshot(
    &self,
    document_id: &str,
  ) -> FutureResult<Option<DocumentSnapshot>, Error> {
    let try_get_postgrest = self.0.try_get_postgrest();
    let document_id = document_id.to_string();
    FutureResult::new(async move {
      let postgrest = try_get_postgrest?;
      let snapshot = get_latest_snapshot_from_server(&document_id, postgrest)
        .await?
        .map(|snapshot| DocumentSnapshot {
          snapshot_id: snapshot.sid,
          document_id: snapshot.oid,
          data: snapshot.blob,
          created_at: snapshot.created_at,
        });
      Ok(snapshot)
    })
  }

  fn get_document_data(&self, document_id: &str) -> FutureResult<Option<DocumentData>, Error> {
    let try_get_postgrest = self.0.try_get_weak_postgrest();
    let document_id = document_id.to_string();
    let (tx, rx) = channel();
    tokio::spawn(async move {
      tx.send(
        async move {
          let postgrest = try_get_postgrest?;
          let action =
            FetchObjectUpdateAction::new(document_id.clone(), CollabType::Document, postgrest);
          let updates = action.run_with_fix_interval(5, 10).await?;
          let document =
            Document::from_updates(CollabOrigin::Empty, updates, &document_id, vec![])?;
          Ok(document.get_document_data().ok())
        }
        .await,
      )
    });
    FutureResult::new(async { rx.await? })
  }
}
