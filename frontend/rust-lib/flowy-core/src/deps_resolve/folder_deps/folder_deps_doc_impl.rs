use crate::deps_resolve::folder_deps::get_encoded_collab_v1_from_disk;
use bytes::Bytes;
use collab::entity::EncodedCollab;
use collab_entity::CollabType;
use collab_folder::hierarchy_builder::NestedViewBuilder;
use collab_folder::ViewLayout;
use flowy_document::entities::DocumentDataPB;
use flowy_document::manager::DocumentManager;
use flowy_document::parser::json::parser::JsonToDocumentParser;
use flowy_error::FlowyError;
use flowy_folder::entities::{CreateViewParams, ViewLayoutPB};
use flowy_folder::manager::FolderUser;
use flowy_folder::share::ImportType;
use flowy_folder::view_operation::{
  FolderOperationHandler, GatherEncodedCollab, ImportedData, ViewData,
};
use lib_dispatch::prelude::ToBytes;
use lib_infra::async_trait::async_trait;
use std::convert::TryFrom;
use std::sync::Arc;
use tokio::sync::RwLock;

pub struct DocumentFolderOperation(pub Arc<DocumentManager>);
#[async_trait]
impl FolderOperationHandler for DocumentFolderOperation {
  fn name(&self) -> &str {
    "DocumentFolderOperationHandler"
  }

  async fn create_workspace_view(
    &self,
    uid: i64,
    workspace_view_builder: Arc<RwLock<NestedViewBuilder>>,
  ) -> Result<(), FlowyError> {
    let manager = self.0.clone();
    let mut write_guard = workspace_view_builder.write().await;
    // Create a view named "Getting started" with an icon ⭐️ and the built-in README data.
    // Don't modify this code unless you know what you are doing.
    write_guard
      .with_view_builder(|view_builder| async {
        let view = view_builder
          .with_name("Getting started")
          .with_icon("⭐️")
          .build();
        // create a empty document
        let json_str = include_str!("../../../assets/read_me.json");
        let document_pb = JsonToDocumentParser::json_str_to_document(json_str).unwrap();
        manager
          .create_document(uid, &view.view.id, Some(document_pb.into()))
          .await
          .unwrap();
        view
      })
      .await;
    Ok(())
  }

  async fn open_view(&self, view_id: &str) -> Result<(), FlowyError> {
    self.0.open_document(view_id).await?;
    Ok(())
  }

  /// Close the document view.
  async fn close_view(&self, view_id: &str) -> Result<(), FlowyError> {
    self.0.close_document(view_id).await?;
    Ok(())
  }

  async fn delete_view(&self, view_id: &str) -> Result<(), FlowyError> {
    match self.0.delete_document(view_id).await {
      Ok(_) => tracing::trace!("Delete document: {}", view_id),
      Err(e) => tracing::error!("🔴delete document failed: {}", e),
    }
    Ok(())
  }

  async fn duplicate_view(&self, view_id: &str) -> Result<Bytes, FlowyError> {
    let data: DocumentDataPB = self.0.get_document_data(view_id).await?.into();
    let data_bytes = data.into_bytes().map_err(|_| FlowyError::invalid_data())?;
    Ok(data_bytes)
  }

  async fn gather_publish_encode_collab(
    &self,
    user: &Arc<dyn FolderUser>,
    view_id: &str,
  ) -> Result<GatherEncodedCollab, FlowyError> {
    let encoded_collab =
      get_encoded_collab_v1_from_disk(user, view_id, CollabType::Document).await?;
    Ok(GatherEncodedCollab::Document(encoded_collab))
  }

  async fn create_view_with_view_data(
    &self,
    user_id: i64,
    params: CreateViewParams,
  ) -> Result<Option<EncodedCollab>, FlowyError> {
    debug_assert_eq!(params.layout, ViewLayoutPB::Document);
    let data = match params.initial_data {
      ViewData::DuplicateData(data) => Some(DocumentDataPB::try_from(data)?),
      ViewData::Data(data) => Some(DocumentDataPB::try_from(data)?),
      ViewData::Empty => None,
    };
    let encoded_collab = self
      .0
      .create_document(user_id, &params.view_id, data.map(|d| d.into()))
      .await?;
    Ok(Some(encoded_collab))
  }

  /// Create a view with built-in data.
  async fn create_default_view(
    &self,
    user_id: i64,
    _parent_view_id: &str,
    view_id: &str,
    _name: &str,
    layout: ViewLayout,
  ) -> Result<(), FlowyError> {
    debug_assert_eq!(layout, ViewLayout::Document);
    match self.0.create_document(user_id, view_id, None).await {
      Ok(_) => Ok(()),
      Err(err) => {
        if err.is_already_exists() {
          Ok(())
        } else {
          Err(err)
        }
      },
    }
  }

  async fn import_from_bytes(
    &self,
    uid: i64,
    view_id: &str,
    _name: &str,
    _import_type: ImportType,
    bytes: Vec<u8>,
  ) -> Result<Vec<ImportedData>, FlowyError> {
    let data = DocumentDataPB::try_from(Bytes::from(bytes))?;
    let encoded_collab = self
      .0
      .create_document(uid, view_id, Some(data.into()))
      .await?;
    Ok(vec![(
      view_id.to_string(),
      CollabType::Document,
      encoded_collab,
    )])
  }

  async fn import_from_file_path(
    &self,
    _view_id: &str,
    _name: &str,
    _path: String,
  ) -> Result<(), FlowyError> {
    // TODO(lucas): import file from local markdown file
    Ok(())
  }
}
