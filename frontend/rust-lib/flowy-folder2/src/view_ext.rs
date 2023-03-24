use crate::entities::{ViewDataFormatPB, ViewLayoutTypePB, ViewPB};
use bytes::Bytes;
use collab_folder::core::ViewLayout;
use flowy_error::FlowyError;
use lib_infra::future::FutureResult;
use std::collections::HashMap;
use std::sync::Arc;

pub trait ViewDataProcessor {
  /// Closes the view and releases the resources that this view has in
  /// the backend
  fn close_view(&self, view_id: &str) -> FutureResult<(), FlowyError>;

  /// Gets the data of the this view.
  /// For example, the data can be used to duplicate the view.
  fn get_view_data(&self, view: &ViewPB) -> FutureResult<Bytes, FlowyError>;

  /// Create a view with the pre-defined data.
  /// For example, the initial data of the grid/calendar/kanban board when
  /// you create a new view.
  fn create_view_with_build_in_data(
    &self,
    user_id: &str,
    view_id: &str,
    name: &str,
    layout: ViewLayoutTypePB,
    data_format: ViewDataFormatPB,
    ext: HashMap<String, String>,
  ) -> FutureResult<(), FlowyError>;

  /// Create a view with custom data
  fn create_view_with_custom_data(
    &self,
    user_id: &str,
    view_id: &str,
    name: &str,
    data: Vec<u8>,
    layout: ViewLayout,
    ext: HashMap<String, String>,
  ) -> FutureResult<(), FlowyError>;

  fn data_types(&self) -> Vec<ViewDataFormatPB>;
}

pub type ViewDataProcessorMap = Arc<HashMap<ViewLayout, Arc<dyn ViewDataProcessor + Send + Sync>>>;

impl From<ViewLayoutTypePB> for ViewLayout {
  fn from(pb: ViewLayoutTypePB) -> Self {
    match pb {
      ViewLayoutTypePB::Document => ViewLayout::Document,
      ViewLayoutTypePB::Grid => ViewLayout::Grid,
      ViewLayoutTypePB::Board => ViewLayout::Board,
      ViewLayoutTypePB::Calendar => ViewLayout::Calendar,
    }
  }
}
