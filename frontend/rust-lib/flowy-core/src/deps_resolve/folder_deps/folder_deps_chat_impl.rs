use bytes::Bytes;
use collab::entity::EncodedCollab;
use collab_folder::ViewLayout;
use flowy_ai::ai_manager::AIManager;
use flowy_error::FlowyError;
use flowy_folder::entities::CreateViewParams;
use flowy_folder::share::ImportType;
use flowy_folder::view_operation::{FolderOperationHandler, ImportedData};
use lib_infra::async_trait::async_trait;
use std::sync::Arc;

pub struct ChatFolderOperation(pub Arc<AIManager>);

#[async_trait]
impl FolderOperationHandler for ChatFolderOperation {
  fn name(&self) -> &str {
    "ChatFolderOperationHandler"
  }

  async fn open_view(&self, view_id: &str) -> Result<(), FlowyError> {
    self.0.open_chat(view_id).await
  }

  async fn close_view(&self, view_id: &str) -> Result<(), FlowyError> {
    self.0.close_chat(view_id).await
  }

  async fn delete_view(&self, view_id: &str) -> Result<(), FlowyError> {
    self.0.delete_chat(view_id).await
  }

  async fn duplicate_view(&self, _view_id: &str) -> Result<Bytes, FlowyError> {
    Err(FlowyError::not_support())
  }

  async fn create_view_with_view_data(
    &self,
    _user_id: i64,
    _params: CreateViewParams,
  ) -> Result<Option<EncodedCollab>, FlowyError> {
    Err(FlowyError::not_support())
  }

  async fn create_default_view(
    &self,
    user_id: i64,
    parent_view_id: &str,
    view_id: &str,
    _name: &str,
    _layout: ViewLayout,
  ) -> Result<(), FlowyError> {
    self
      .0
      .create_chat(&user_id, parent_view_id, view_id)
      .await?;
    Ok(())
  }

  async fn import_from_bytes(
    &self,
    _uid: i64,
    _view_id: &str,
    _name: &str,
    _import_type: ImportType,
    _bytes: Vec<u8>,
  ) -> Result<Vec<ImportedData>, FlowyError> {
    Err(FlowyError::not_support())
  }

  async fn import_from_file_path(
    &self,
    _view_id: &str,
    _name: &str,
    _path: String,
  ) -> Result<(), FlowyError> {
    Err(FlowyError::not_support())
  }
}
