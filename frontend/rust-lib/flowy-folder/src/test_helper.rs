use crate::entities::{data_format_from_layout, CreateViewParams, ViewLayoutTypePB};
use crate::manager::FolderManager;
use crate::services::folder_editor::FolderEditor;
use folder_model::gen_view_id;
use std::collections::HashMap;
use std::sync::Arc;

#[cfg(feature = "flowy_unit_test")]
impl FolderManager {
  pub async fn folder_editor(&self) -> Arc<FolderEditor> {
    self.folder_editor.read().await.clone().unwrap()
  }

  pub async fn create_test_grid_view(
    &self,
    app_id: &str,
    name: &str,
    ext: HashMap<String, String>,
  ) -> String {
    self
      .create_test_view(app_id, name, ViewLayoutTypePB::Grid, ext)
      .await
  }

  pub async fn create_test_board_view(
    &self,
    app_id: &str,
    name: &str,
    ext: HashMap<String, String>,
  ) -> String {
    self
      .create_test_view(app_id, name, ViewLayoutTypePB::Board, ext)
      .await
  }

  async fn create_test_view(
    &self,
    app_id: &str,
    name: &str,
    layout: ViewLayoutTypePB,
    ext: HashMap<String, String>,
  ) -> String {
    let view_id = gen_view_id();
    let data_format = data_format_from_layout(&layout);
    let params = CreateViewParams {
      belong_to_id: app_id.to_string(),
      name: name.to_string(),
      desc: "".to_string(),
      thumbnail: "".to_string(),
      data_format,
      layout,
      view_id: view_id.clone(),
      initial_data: vec![],
      ext,
    };
    self
      .view_controller
      .create_view_from_params(params)
      .await
      .unwrap();
    view_id
  }
}
