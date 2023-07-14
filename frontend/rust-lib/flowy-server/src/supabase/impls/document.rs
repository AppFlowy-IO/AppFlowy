use collab_document::document::Document;
use collab_folder::core::CollabOrigin;
use tokio::sync::oneshot::channel;

use flowy_document2::deps::{DocumentCloudService, DocumentData, DocumentSnapshot};
use flowy_error::{internal_error, FlowyError};
use lib_infra::future::FutureResult;

use crate::supabase::impls::{get_latest_snapshot_from_server, FetchObjectUpdateAction};
use crate::supabase::SupabaseServerService;

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
  fn get_document_updates(&self, document_id: &str) -> FutureResult<Vec<Vec<u8>>, FlowyError> {
    let weak_server = self.server.get_pg_server();
    let (tx, rx) = channel();
    let document_id = document_id.to_string();
    tokio::spawn(async move {
      tx.send(
        async move {
          match weak_server {
            None => Ok(vec![]),
            Some(weak_server) => FetchObjectUpdateAction::new(&document_id, weak_server)
              .run_with_fix_interval(5, 5)
              .await
              .map_err(internal_error),
          }
        }
        .await,
      )
    });
    FutureResult::new(async { rx.await.map_err(internal_error)? })
  }

  fn get_document_latest_snapshot(
    &self,
    document_id: &str,
  ) -> FutureResult<Option<DocumentSnapshot>, FlowyError> {
    let weak_server = self.server.get_pg_server();
    let (tx, rx) = channel();
    let document_id = document_id.to_string();
    tokio::spawn(async move {
      tx.send(
        async move {
          match weak_server {
            None => Ok(None),
            Some(weak_server) => get_latest_snapshot_from_server(&document_id, weak_server)
              .await
              .map_err(internal_error),
          }
        }
        .await,
      )
    });

    FutureResult::new(async {
      {
        Ok(
          rx.await
            .map_err(internal_error)??
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

  fn get_document_data(&self, document_id: &str) -> FutureResult<Option<DocumentData>, FlowyError> {
    let weak_server = self.server.get_pg_server();
    let (tx, rx) = channel();
    let document_id = document_id.to_string();
    tokio::spawn(async move {
      tx.send(
        async move {
          match weak_server {
            None => Ok(Ok(None)),
            Some(weak_server) => {
              let action = FetchObjectUpdateAction::new(&document_id, weak_server);
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
    FutureResult::new(async { rx.await.map_err(internal_error)?.map_err(internal_error)? })
  }
}
