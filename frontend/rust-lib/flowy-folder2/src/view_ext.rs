use crate::entities::{CreateViewParams, ViewLayoutPB};
use bytes::Bytes;
use collab_folder::core::{View, ViewLayout};
use flowy_error::FlowyError;
use lib_infra::future::FutureResult;
use lib_infra::util::timestamp;

use std::collections::HashMap;
use std::sync::Arc;

pub trait ViewDataProcessor {
  /// Closes the view and releases the resources that this view has in
  /// the backend
  fn close_view(&self, view_id: &str) -> FutureResult<(), FlowyError>;

  /// Gets the data of the this view.
  /// For example, the data can be used to duplicate the view.
  fn get_view_data(&self, view_id: &str) -> FutureResult<Bytes, FlowyError>;

  /// Create a view with the pre-defined data.
  /// For example, the initial data of the grid/calendar/kanban board when
  /// you create a new view.
  fn create_view_with_built_in_data(
    &self,
    user_id: i64,
    view_id: &str,
    name: &str,
    layout: ViewLayout,
    ext: HashMap<String, String>,
  ) -> FutureResult<(), FlowyError>;

  /// Create a view with custom data
  fn create_view_with_custom_data(
    &self,
    user_id: i64,
    view_id: &str,
    name: &str,
    data: Vec<u8>,
    layout: ViewLayout,
    ext: HashMap<String, String>,
  ) -> FutureResult<(), FlowyError>;
}

pub type ViewDataProcessorMap = Arc<HashMap<ViewLayout, Arc<dyn ViewDataProcessor + Send + Sync>>>;

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

pub fn view_from_create_view_params(params: CreateViewParams, layout: ViewLayout) -> View {
  let time = timestamp();
  View {
    id: params.view_id,
    bid: params.belong_to_id,
    name: params.name,
    desc: params.desc,
    belongings: Default::default(),
    created_at: time,
    layout,
    database_id: None,
  }
}
pub fn gen_view_id() -> String {
  uuid::Uuid::new_v4().to_string()
}
