use bytes::Bytes;
use collab::entity::EncodedCollab;
use collab_folder::ViewLayout;
use flowy_ai::ai_manager::AIManager;
use flowy_error::FlowyError;
use flowy_folder::entities::CreateViewParams;
use flowy_folder::share::ImportType;
use flowy_folder::view_operation::{FolderOperationHandler, ImportedData};
use lib_infra::async_trait::async_trait;
use std::sync::{Arc, Weak};
use uuid::Uuid;

pub struct ChatFolderOperation(pub Weak<AIManager>);

impl ChatFolderOperation {
  fn ai_manager(&self) -> Result<Arc<AIManager>, FlowyError> {
    self.0.upgrade().ok_or_else(FlowyError::ref_drop)
  }
}

#[async_trait]
impl FolderOperationHandler for ChatFolderOperation {
  fn name(&self) -> &str {
    "ChatFolderOperationHandler"
  }

  async fn open_view(&self, view_id: &Uuid) -> Result<(), FlowyError> {
    self.ai_manager()?.open_chat(view_id).await
  }

  async fn close_view(&self, view_id: &Uuid) -> Result<(), FlowyError> {
    self.ai_manager()?.close_chat(view_id).await
  }

  async fn delete_view(&self, view_id: &Uuid) -> Result<(), FlowyError> {
    self.ai_manager()?.delete_chat(view_id).await
  }

  async fn duplicate_view(&self, _view_id: &Uuid) -> Result<Bytes, FlowyError> {
    Err(FlowyError::not_support().with_context("Duplicate view"))
  }

  async fn create_view_with_view_data(
    &self,
    _user_id: i64,
    _params: CreateViewParams,
  ) -> Result<Option<EncodedCollab>, FlowyError> {
    Err(FlowyError::not_support().with_context("Can't create view"))
  }

  async fn create_default_view(
    &self,
    user_id: i64,
    parent_view_id: &Uuid,
    view_id: &Uuid,
    _name: &str,
    _layout: ViewLayout,
  ) -> Result<(), FlowyError> {
    self
      .ai_manager()?
      .create_chat(&user_id, parent_view_id, view_id)
      .await?;
    Ok(())
  }

  async fn import_from_bytes(
    &self,
    _uid: i64,
    _view_id: &Uuid,
    _name: &str,
    _import_type: ImportType,
    _bytes: Vec<u8>,
  ) -> Result<Vec<ImportedData>, FlowyError> {
    Err(FlowyError::not_support().with_context("import from data"))
  }

  async fn import_from_file_path(
    &self,
    _view_id: &str,
    _name: &str,
    _path: String,
  ) -> Result<(), FlowyError> {
    Err(FlowyError::not_support().with_context("import file from path"))
  }
}
