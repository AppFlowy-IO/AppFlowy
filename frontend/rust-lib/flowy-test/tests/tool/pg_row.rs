use std::sync::Arc;

use assert_json_diff::assert_json_eq;
use collab::core::collab::MutexCollab;
use collab::core::origin::CollabOrigin;
use collab::preclude::updates::decoder::Decode;
use collab::preclude::Update;
use serde_json::json;

use flowy_document2::deps::DocumentCloudService;
use flowy_folder2::deps::{FolderCloudService, FolderSnapshot};
use flowy_server::supabase::impls::{
  SupabaseDocumentCloudServiceImpl, SupabaseFolderCloudServiceImpl,
};
use flowy_server::supabase::PostgresServer;

use crate::util::get_supabase_config;

pub struct PostgresConnect {
  inner: Arc<PostgresServer>,
}

impl PostgresConnect {
  pub fn new() -> Option<Self> {
    let config = get_supabase_config()?;
    let inner = PostgresServer::new(config.postgres_config);
    Some(Self {
      inner: Arc::new(inner),
    })
  }

  async fn get_folder(&self, workspace_id: &str) -> MutexCollab {
    let folder_service = SupabaseFolderCloudServiceImpl::new(self.inner.clone());
    let updates = folder_service
      .get_folder_updates(workspace_id)
      .await
      .unwrap();
    let collab = MutexCollab::new(CollabOrigin::Server, workspace_id, vec![]);
    collab.lock().with_transact_mut(|txn| {
      for update in updates {
        txn.apply_update(Update::decode_v1(&update).unwrap());
      }
    });
    collab
  }

  async fn get_folder_snapshot(&self, workspace_id: &str) -> MutexCollab {
    let folder_service = SupabaseFolderCloudServiceImpl::new(self.inner.clone());
    let snapshot: FolderSnapshot = folder_service
      .get_folder_latest_snapshot(workspace_id)
      .await
      .unwrap()
      .unwrap();
    let collab = MutexCollab::new(CollabOrigin::Server, workspace_id, vec![]);
    collab.lock().with_transact_mut(|txn| {
      txn.apply_update(Update::decode_v1(&snapshot.data).unwrap());
    });
    collab
  }

  async fn get_document(&self, document_id: &str) -> MutexCollab {
    let document_service = SupabaseDocumentCloudServiceImpl::new(self.inner.clone());
    let updates = document_service
      .get_document_updates(document_id)
      .await
      .unwrap();
    let collab = MutexCollab::new(CollabOrigin::Server, document_id, vec![]);
    collab.lock().with_transact_mut(|txn| {
      for update in updates {
        txn.apply_update(Update::decode_v1(&update).unwrap());
      }
    });
    collab
  }
}

#[tokio::test]
async fn get_folder_test() {
  if let Some(conn) = PostgresConnect::new() {
    let collab = conn
      .get_folder("2ddf790f-18bb-4e9c-aacb-f29ca755f72a")
      .await;
    let value = collab.to_json_value();
    assert_json_eq!(value, json!(""));
  }
}

#[tokio::test]
async fn get_folder_snapshot() {
  if let Some(conn) = PostgresConnect::new() {
    let collab = conn
      .get_folder_snapshot("17f5e820-dcc8-4ca9-ab93-b45f17ca0948")
      .await;
    let value = collab.to_json_value();
    assert_json_eq!(value, json!(""));
  }
}

#[tokio::test]
async fn get_document_test() {
  if let Some(conn) = PostgresConnect::new() {
    let collab = conn
      .get_document("158c8275-ff6d-49e1-a2ed-82c71dea1126")
      .await;
    let value = collab.to_json_value();
    assert_json_eq!(value, json!(""));
  }
}
