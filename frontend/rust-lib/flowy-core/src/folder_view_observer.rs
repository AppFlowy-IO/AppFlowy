use collab::core::collab::{IndexContent, IndexContentReceiver};
use collab_folder::ViewIndexContent;
use flowy_error::{FlowyError, FlowyResult};
use flowy_search::document::local_search_handler::DocumentTantivyState;
use flowy_search_pub::entities::FolderViewObserver;
use lib_infra::async_trait::async_trait;
use std::sync::{Arc, Weak};
use tokio::sync::RwLock;
use tracing::error;
use uuid::Uuid;

pub struct FolderViewObserverImpl {
  state: Weak<RwLock<DocumentTantivyState>>,
}

impl FolderViewObserverImpl {
  pub fn new(_workspace_id: &Uuid, state: Weak<RwLock<DocumentTantivyState>>) -> Self {
    Self { state }
  }

  fn get_state(&self) -> FlowyResult<Arc<RwLock<DocumentTantivyState>>> {
    let state = self.state.upgrade().ok_or_else(FlowyError::ref_drop)?;
    Ok(state)
  }
}

#[async_trait]
impl FolderViewObserver for FolderViewObserverImpl {
  async fn set_observer_rx(&self, mut rx: IndexContentReceiver) {
    let state = self.state.clone();
    tokio::spawn(async move {
      while let Ok(msg) = rx.recv().await {
        let state = match state.upgrade() {
          Some(state) => state,
          None => {
            return;
          },
        };

        match msg {
          IndexContent::Create(value) => match serde_json::from_value::<ViewIndexContent>(value) {
            Ok(view) => {
              let _ = state.write().await.add_document_metadata(
                &view.id,
                view.name.clone(),
                view.icon.clone(),
              );
            },
            Err(err) => error!("FolderIndexManager error deserialize (create): {:?}", err),
          },
          IndexContent::Update(value) => match serde_json::from_value::<ViewIndexContent>(value) {
            Ok(view) => {
              let _ = state.write().await.add_document_metadata(
                &view.id,
                view.name.clone(),
                view.icon.clone(),
              );
            },
            Err(err) => error!("FolderIndexManager error deserialize (update): {:?}", err),
          },
          IndexContent::Delete(ids) => {
            let _ = state.write().await.delete_documents(&ids);
          },
        }
      }
    });
  }

  async fn delete_views_for_workspace(&self, workspace_id: Uuid) -> Result<(), FlowyError> {
    let state = self.get_state()?;
    state.write().await.delete_workspace(&workspace_id)?;
    Ok(())
  }
}
