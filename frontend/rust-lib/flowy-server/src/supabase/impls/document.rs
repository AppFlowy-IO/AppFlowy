use std::sync::Arc;

use tokio::sync::oneshot::channel;

use flowy_document2::deps::{DocumentCloudService, DocumentSnapshot};
use flowy_error::{internal_error, FlowyError};
use lib_infra::future::FutureResult;

use crate::supabase::impls::{get_latest_snapshot_from_server, get_updates_from_server};
use crate::supabase::PostgresServer;

pub struct SupabaseDocumentCloudServiceImpl {
  server: Arc<PostgresServer>,
}

impl SupabaseDocumentCloudServiceImpl {
  pub fn new(server: Arc<PostgresServer>) -> Self {
    Self { server }
  }
}

impl DocumentCloudService for SupabaseDocumentCloudServiceImpl {
  fn get_document_updates(&self, document_id: &str) -> FutureResult<Vec<Vec<u8>>, FlowyError> {
    let server = Arc::downgrade(&self.server);
    let (tx, rx) = channel();
    let document_id = document_id.to_string();
    tokio::spawn(async move { tx.send(get_updates_from_server(&document_id, server).await) });
    FutureResult::new(async { rx.await.map_err(internal_error)?.map_err(internal_error) })
  }

  fn get_document_latest_snapshot(
    &self,
    document_id: &str,
  ) -> FutureResult<Option<DocumentSnapshot>, FlowyError> {
    let server = Arc::downgrade(&self.server);
    let (tx, rx) = channel();
    let document_id = document_id.to_string();
    tokio::spawn(
      async move { tx.send(get_latest_snapshot_from_server(&document_id, server).await) },
    );

    FutureResult::new(async {
      {
        Ok(
          rx.await
            .map_err(internal_error)?
            .map_err(internal_error)?
            .map(|snapshot| DocumentSnapshot {
              snapshot_id: snapshot.snapshot_id,
              document_id: snapshot.oid,
              data: snapshot.data,
              created_at: snapshot.created_at,
            }),
        )
      }
    })
  }
}
