use anyhow::Error;
use collab::core::origin::CollabOrigin;
use collab_document::blocks::DocumentData;
use collab_document::document::Document;
use collab_plugins::cloud_storage::CollabType;
use tokio::sync::oneshot::channel;

use flowy_document_deps::cloud::*;

use lib_infra::future::FutureResult;

use crate::supabase::storage_impls::pooler::postgres_server::SupabaseServerService;
use crate::supabase::storage_impls::pooler::util::execute_async;
use crate::supabase::storage_impls::pooler::{
  get_latest_snapshot_from_server, FetchObjectUpdateAction,
};

pub struct SupabaseDocumentCloudServiceImpl<T> {
  server: T,
}

impl<T> SupabaseDocumentCloudServiceImpl<T> {
  pub fn new(server: T) -> Self {
    Self { server }
  }
}

impl<T> DocumentCloudService for SupabaseDocumentCloudServiceImpl<T>
where
  T: SupabaseServerService,
{
  fn get_document_updates(&self, document_id: &str) -> FutureResult<Vec<Vec<u8>>, Error> {
    let weak_server = self.server.get_pg_server();
    let pg_mode = self.server.get_pg_mode();
    let (tx, rx) = channel();
    let document_id = document_id.to_string();
    tokio::spawn(async move {
      tx.send(
        async move {
          match weak_server {
            None => Ok(vec![]),
            Some(weak_server) => {
              FetchObjectUpdateAction::new(document_id, CollabType::Document, pg_mode, weak_server)
                .run_with_fix_interval(5, 5)
                .await
            },
          }
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
    let document_id = document_id.to_string();
    let fut = execute_async(&self.server, move |mut pg_client, pg_mode| {
      Box::pin(async move {
        get_latest_snapshot_from_server(&document_id, pg_mode, &mut pg_client).await
      })
    });
    FutureResult::new(async move {
      let snapshot = fut.await?.map(|snapshot| DocumentSnapshot {
        snapshot_id: snapshot.sid,
        document_id: snapshot.oid,
        data: snapshot.blob,
        created_at: snapshot.created_at,
      });
      Ok(snapshot)
    })
  }

  fn get_document_data(&self, document_id: &str) -> FutureResult<Option<DocumentData>, Error> {
    let weak_server = self.server.get_pg_server();
    let pg_mode = self.server.get_pg_mode();
    let (tx, rx) = channel();
    let document_id = document_id.to_string();
    tokio::spawn(async move {
      tx.send(
        async move {
          match weak_server {
            None => Ok(Ok(None)),
            Some(weak_server) => {
              let action = FetchObjectUpdateAction::new(
                document_id.clone(),
                CollabType::Document,
                pg_mode,
                weak_server,
              );
              action.run().await.map(|updates| {
                let document =
                  Document::from_updates(CollabOrigin::Empty, updates, &document_id, vec![])?;
                Ok(document.get_document_data().ok())
              })
            },
          }
        }
        .await,
      )
    });
    FutureResult::new(async { rx.await?? })
  }
}
