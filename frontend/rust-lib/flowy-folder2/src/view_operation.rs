use crate::entities::{CreateViewParams, ViewLayoutPB};
use bytes::Bytes;
use collab_folder::core::ViewLayout;
use flowy_error::FlowyError;
use lib_infra::future::FutureResult;
use lib_infra::util::timestamp;

use std::collections::HashMap;
use std::sync::Arc;

pub type ViewData = Bytes;
pub use collab_folder::core::View;

/// The handler will be used to handler the folder operation for a specific
/// view layout. Each [ViewLayout] will have a handler. So when creating a new
/// view, the [ViewLayout] will be used to get the handler.
///
pub trait FolderOperationHandler {
  /// Closes the view and releases the resources that this view has in
  /// the backend
  fn close_view(&self, view_id: &str) -> FutureResult<(), FlowyError>;

  /// Returns the [ViewData] that can be used to create the same view.
  fn duplicate_view(&self, view_id: &str) -> FutureResult<ViewData, FlowyError>;

  /// Create a view with custom data
  fn create_view_with_view_data(
    &self,
    user_id: i64,
    view_id: &str,
    name: &str,
    data: Vec<u8>,
    layout: ViewLayout,
    ext: HashMap<String, String>,
  ) -> FutureResult<(), FlowyError>;

  /// Create a view with the pre-defined data.
  /// For example, the initial data of the grid/calendar/kanban board when
  /// you create a new view.
  fn create_built_in_view(
    &self,
    user_id: i64,
    view_id: &str,
    name: &str,
    layout: ViewLayout,
    meta: HashMap<String, String>,
  ) -> FutureResult<(), FlowyError>;

  /// Create a view by importing data
  fn import_from_bytes(
    &self,
    view_id: &str,
    name: &str,
    bytes: Vec<u8>,
  ) -> FutureResult<(), FlowyError>;

  /// Create a view by importing data from a file
  fn import_from_file_path(
    &self,
    view_id: &str,
    name: &str,
    path: String,
  ) -> FutureResult<(), FlowyError>;

  /// Called when the view is updated. The handler is the `old` registered handler.
  fn did_update_view(&self, _old: &View, _new: &View) -> FutureResult<(), FlowyError> {
    FutureResult::new(async move { Ok(()) })
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
    }
  }
}

pub(crate) fn create_view(params: CreateViewParams, layout: ViewLayout) -> View {
  let time = timestamp();
  View {
    id: params.view_id,
    parent_view_id: params.parent_view_id,
    name: params.name,
    desc: params.desc,
    children: Default::default(),
    created_at: time,
    layout,
  }
}
pub fn gen_view_id() -> String {
  uuid::Uuid::new_v4().to_string()
}
