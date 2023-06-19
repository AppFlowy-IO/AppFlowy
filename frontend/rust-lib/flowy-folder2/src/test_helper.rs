use crate::entities::{CreateViewParams, ViewLayoutPB};
use crate::manager::Folder2Manager;
use crate::view_operation::gen_view_id;
use std::collections::HashMap;

#[cfg(feature = "test_helper")]
impl Folder2Manager {
  pub async fn create_test_grid_view(
    &self,
    app_id: &str,
    name: &str,
    ext: HashMap<String, String>,
  ) -> String {
    self
      .create_test_view(app_id, name, ViewLayoutPB::Grid, ext)
      .await
  }

  pub async fn create_test_board_view(
    &self,
    app_id: &str,
    name: &str,
    ext: HashMap<String, String>,
  ) -> String {
    self
      .create_test_view(app_id, name, ViewLayoutPB::Board, ext)
      .await
  }

  async fn create_test_view(
    &self,
    app_id: &str,
    name: &str,
    layout: ViewLayoutPB,
    ext: HashMap<String, String>,
  ) -> String {
    let view_id = gen_view_id();
    let params = CreateViewParams {
      parent_view_id: app_id.to_string(),
      name: name.to_string(),
      desc: "".to_string(),
      layout,
      view_id: view_id.clone(),
      initial_data: vec![],
      meta: ext,
      set_as_current: true,
    };
    self.create_view_with_params(params).await.unwrap();
    view_id
  }
}
