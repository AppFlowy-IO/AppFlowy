use std::collections::HashMap;

use collab_folder::ViewLayout;

use crate::entities::CreateViewParams;
use crate::manager::FolderManager;

#[cfg(feature = "test_helper")]
impl FolderManager {
  pub async fn create_test_grid_view(
    &self,
    app_id: &str,
    name: &str,
    ext: HashMap<String, String>,
  ) -> String {
    self
      .create_test_view(app_id, name, ViewLayout::Grid, ext)
      .await
  }

  pub async fn create_test_board_view(
    &self,
    app_id: &str,
    name: &str,
    ext: HashMap<String, String>,
  ) -> String {
    self
      .create_test_view(app_id, name, ViewLayout::Board, ext)
      .await
  }

  async fn create_test_view(
    &self,
    app_id: &str,
    name: &str,
    layout: ViewLayout,
    ext: HashMap<String, String>,
  ) -> String {
    let params = CreateViewParams {
      parent_view_id: app_id.to_string(),
      name: name.to_string(),
      desc: "".to_string(),
      layout,
      initial_data: vec![],
      meta: ext,
      set_as_current: true,
      index: None,
    };
    let view = self.create_view_with_params(params).await.unwrap();
    view.id
  }
}
