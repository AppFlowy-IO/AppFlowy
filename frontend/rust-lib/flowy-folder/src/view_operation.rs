use async_trait::async_trait;
use bytes::Bytes;
use collab::entity::EncodedCollab;
use collab_entity::CollabType;
use collab_folder::hierarchy_builder::NestedViewBuilder;
pub use collab_folder::View;
use collab_folder::ViewLayout;
use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::RwLock;

use flowy_error::FlowyError;

use lib_infra::util::timestamp;

use crate::entities::{CreateViewParams, ViewLayoutPB};
use crate::manager::FolderUser;
use crate::share::ImportType;

pub type ViewData = Bytes;

#[derive(Debug, Clone)]
pub enum EncodedCollabWrapper {
  Document(DocumentEncodedCollab),
  Database(DatabaseEncodedCollab),
  Unknown,
}

#[derive(Debug, Clone)]
pub struct DocumentEncodedCollab {
  pub document_encoded_collab: EncodedCollab,
}

#[derive(Debug, Clone)]
pub struct DatabaseEncodedCollab {
  pub database_encoded_collab: EncodedCollab,
  pub database_row_encoded_collabs: HashMap<String, EncodedCollab>,
  pub database_row_document_encoded_collabs: HashMap<String, EncodedCollab>,
  pub database_relations: HashMap<String, String>,
}

pub type ImportedData = (String, CollabType, EncodedCollab);

/// The handler will be used to handler the folder operation for a specific
/// view layout. Each [ViewLayout] will have a handler. So when creating a new
/// view, the [ViewLayout] will be used to get the handler.
#[async_trait]
pub trait FolderOperationHandler {
  /// Create the view for the workspace of new user.
  /// Only called once when the user is created.
  async fn create_workspace_view(
    &self,
    _uid: i64,
    _workspace_view_builder: Arc<RwLock<NestedViewBuilder>>,
  ) -> Result<(), FlowyError> {
    Ok(())
  }

  async fn open_view(&self, view_id: &str) -> Result<(), FlowyError>;
  /// Closes the view and releases the resources that this view has in
  /// the backend
  async fn close_view(&self, view_id: &str) -> Result<(), FlowyError>;

  /// Called when the view is deleted.
  /// This will called after the view is deleted from the trash.
  async fn delete_view(&self, view_id: &str) -> Result<(), FlowyError>;

  /// Returns the [ViewData] that can be used to create the same view.
  async fn duplicate_view(&self, view_id: &str) -> Result<ViewData, FlowyError>;

  /// get the encoded collab data from the disk.
  async fn get_encoded_collab_v1_from_disk(
    &self,
    _user: Arc<dyn FolderUser>,
    _view_id: &str,
  ) -> Result<EncodedCollabWrapper, FlowyError> {
    Err(FlowyError::not_support())
  }

  /// Create a view with the data.
  ///
  /// # Arguments
  ///
  /// * `user_id`: the user id
  /// * `view_id`: the view id
  /// * `name`: the name of the view
  /// * `data`: initial data of the view. The data should be parsed by the [FolderOperationHandler]
  /// implementation.
  /// For example,
  /// 1. the data of the database will be [DatabaseData] that is serialized to JSON
  /// 2. the data of the document will be [DocumentData] that is serialized to JSON
  /// * `layout`: the layout of the view
  /// * `meta`: use to carry extra information. For example, the database view will use this
  /// to carry the reference database id.
  ///
  /// The return value is the [Option<EncodedCollab>] that can be used to create the view.
  /// It can be used in syncing the view data to cloud.
  async fn create_view_with_view_data(
    &self,
    user_id: i64,
    params: CreateViewParams,
  ) -> Result<Option<EncodedCollab>, FlowyError>;

  /// Create a view with the pre-defined data.
  /// For example, the initial data of the grid/calendar/kanban board when
  /// you create a new view.
  async fn create_built_in_view(
    &self,
    user_id: i64,
    view_id: &str,
    name: &str,
    layout: ViewLayout,
  ) -> Result<(), FlowyError>;

  /// Create a view by importing data
  ///
  /// The return value
  async fn import_from_bytes(
    &self,
    uid: i64,
    view_id: &str,
    name: &str,
    import_type: ImportType,
    bytes: Vec<u8>,
  ) -> Result<Vec<ImportedData>, FlowyError>;

  /// Create a view by importing data from a file
  async fn import_from_file_path(
    &self,
    view_id: &str,
    name: &str,
    path: String,
  ) -> Result<(), FlowyError>;

  /// Called when the view is updated. The handler is the `old` registered handler.
  async fn did_update_view(&self, _old: &View, _new: &View) -> Result<(), FlowyError> {
    Ok(())
  }
}

pub type FolderOperationHandlers =
  Arc<HashMap<ViewLayout, Arc<dyn FolderOperationHandler + Send + Sync>>>;

impl From<ViewLayoutPB> for ViewLayout {
  fn from(pb: ViewLayoutPB) -> Self {
    match pb {
      ViewLayoutPB::Document => ViewLayout::Document,
      ViewLayoutPB::Grid => ViewLayout::Grid,
      ViewLayoutPB::Board => ViewLayout::Board,
      ViewLayoutPB::Calendar => ViewLayout::Calendar,
      ViewLayoutPB::Chat => ViewLayout::Chat,
      ViewLayoutPB::Gallery => ViewLayout::Gallery,
    }
  }
}

pub(crate) fn create_view(uid: i64, params: CreateViewParams, layout: ViewLayout) -> View {
  let time = timestamp();
  View {
    id: params.view_id,
    parent_view_id: params.parent_view_id,
    name: params.name,
    desc: params.desc,
    created_at: time,
    is_favorite: false,
    layout,
    icon: params.icon,
    created_by: Some(uid),
    last_edited_time: 0,
    last_edited_by: Some(uid),
    extra: params.extra,
    children: Default::default(),
  }
}
