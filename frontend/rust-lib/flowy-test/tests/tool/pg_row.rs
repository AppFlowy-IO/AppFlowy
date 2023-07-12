use std::sync::Arc;

use assert_json_diff::assert_json_eq;
use collab::core::collab::MutexCollab;
use collab::core::origin::CollabOrigin;
use collab::preclude::updates::decoder::Decode;
use collab::preclude::Update;
use parking_lot::RwLock;
use serde_json::json;

use flowy_database2::deps::DatabaseCloudService;
use flowy_document2::deps::DocumentCloudService;
use flowy_folder2::deps::{FolderCloudService, FolderSnapshot};
use flowy_server::supabase::impls::{
  SupabaseDatabaseCloudServiceImpl, SupabaseDocumentCloudServiceImpl,
  SupabaseFolderCloudServiceImpl,
};
use flowy_server::supabase::{PostgresServer, SupabaseServerServiceImpl};

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

  fn server_provider_impl(&self) -> SupabaseServerServiceImpl {
    SupabaseServerServiceImpl(Arc::new(RwLock::new(Some(self.inner.clone()))))
  }

  async fn get_folder(&self, workspace_id: &str) -> MutexCollab {
    let folder_service = SupabaseFolderCloudServiceImpl::new(self.server_provider_impl());
    let updates = folder_service
      .get_folder_updates(workspace_id, 0)
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
    let folder_service = SupabaseFolderCloudServiceImpl::new(self.server_provider_impl());
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

  async fn get_database_collab_object(&self, object_id: &str) -> MutexCollab {
    let database_service = SupabaseDatabaseCloudServiceImpl::new(self.server_provider_impl());
    let updates = database_service.get_collab_update(object_id).await.unwrap();
    let collab = MutexCollab::new(CollabOrigin::Server, object_id, vec![]);
    collab.lock().with_transact_mut(|txn| {
      for update in updates {
        txn.apply_update(Update::decode_v1(&update).unwrap());
      }
    });
    collab
  }

  async fn get_database_rows_object(&self, row_ids: Vec<String>) -> Vec<MutexCollab> {
    let database_service = SupabaseDatabaseCloudServiceImpl::new(self.server_provider_impl());
    let updates_by_oid = database_service
      .batch_get_collab_updates(row_ids)
      .await
      .unwrap();
    let mut collabs = vec![];
    for (oid, updates) in updates_by_oid {
      let collab = MutexCollab::new(CollabOrigin::Server, &oid, vec![]);
      collab.lock().with_transact_mut(|txn| {
        for update in updates {
          txn.apply_update(Update::decode_v1(&update).unwrap());
        }
      });
      collabs.push(collab);
    }
    collabs
  }

  async fn get_document(&self, document_id: &str) -> MutexCollab {
    let document_service = SupabaseDocumentCloudServiceImpl::new(self.server_provider_impl());
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

#[tokio::test]
async fn get_workspace_database_test() {
  if let Some(conn) = PostgresConnect::new() {
    let collab = conn
      .get_database_collab_object("MTp1c2VyOmRhdGFiYXNl")
      .await;
    let value = collab.to_json_value();
    assert_json_eq!(value, json!(""));
  }
}

#[tokio::test]
async fn batch_get_database_rows_test() {
  if let Some(conn) = PostgresConnect::new() {
    let row_ids = vec![
      "93cebb2d-4831-496c-adde-1a82bd745099".to_string(),
      "7989a12f-23b2-48ff-8d5f-9bdf651ad7aa".to_string(),
    ];
    let collabs = conn.get_database_rows_object(row_ids).await;
    for collab in collabs {
      let value = collab.to_json_value();
      println!("{}", value);
    }
  }
}
