use std::sync::{Arc, Weak};

use collab::core::collab::{IndexContent, IndexContentReceiver};
use collab_folder::ViewIndexContent;
use flowy_error::FlowyError;
use flowy_user::services::authenticate_user::AuthenticateUser;
use lib_dispatch::prelude::af_spawn;

use crate::{
  services::indexer::{IndexManager, IndexableData},
  SearchIndexer,
};

#[derive(Clone)]
pub struct FolderIndexManager {
  auth_user: Weak<AuthenticateUser>,
  sqlite_indexer: Arc<SearchIndexer>,
}

impl FolderIndexManager {
  pub fn new(auth_user: Weak<AuthenticateUser>, sqlite_indexer: Arc<SearchIndexer>) -> Self {
    Self {
      auth_user,
      sqlite_indexer,
    }
  }

  fn get_uid(&self) -> Result<i64, FlowyError> {
    self
      .auth_user
      .upgrade()
      .ok_or(FlowyError::internal().with_context("The user is not available"))?
      .user_id()
  }
}

impl IndexManager for FolderIndexManager {
  fn set_index_content_receiver(&self, mut rx: IndexContentReceiver) {
    let indexer = self.clone();
    af_spawn(async move {
      while let Ok(msg) = rx.recv().await {
        match msg {
          IndexContent::Create(value) => match serde_json::from_value::<ViewIndexContent>(value) {
            Ok(view) => {
              let _ = indexer.add_index(IndexableData {
                id: view.id,
                data: view.name,
              });
            },
            Err(err) => tracing::error!("FolderIndexer error deserialize: {:?}", err),
          },
          IndexContent::Update(value) => match serde_json::from_value::<ViewIndexContent>(value) {
            Ok(view) => {
              let _ = indexer.update_index(IndexableData {
                id: view.id,
                data: view.name,
              });
            },
            Err(err) => tracing::error!("FolderIndexer error deserialize: {:?}", err),
          },
          IndexContent::Delete(ids) => {
            if let Err(e) = indexer.remove_indices(ids) {
              tracing::error!("FolderIndexer error deserialize: {:?}", e);
            }
          },
        }
      }
    });
  }

  fn update_index(&self, data: IndexableData) -> Result<(), FlowyError> {
    let uid = self.get_uid()?;
    self
      .sqlite_indexer
      .update_view_index(uid, &data.id, &data.data)
  }

  fn remove_indices(&self, ids: Vec<String>) -> Result<(), FlowyError> {
    let uid = self.get_uid()?;
    self.sqlite_indexer.delete_view_index(uid, &ids)?;
    Ok(())
  }

  fn add_index(&self, data: IndexableData) -> Result<(), FlowyError> {
    let uid = self.get_uid()?;
    self
      .sqlite_indexer
      .add_view_index(uid, &data.id, &data.data)?;
    Ok(())
  }
}
