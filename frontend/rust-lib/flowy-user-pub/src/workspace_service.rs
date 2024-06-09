use flowy_error::FlowyResult;
use flowy_folder_pub::folder_builder::ParentChildViews;
use lib_infra::async_trait::async_trait;
use std::collections::HashMap;

#[async_trait]
pub trait UserWorkspaceService: Send + Sync {
  async fn did_import_views(&self, views: Vec<ParentChildViews>) -> FlowyResult<()>;
  async fn did_import_database_views(
    &self,
    ids_by_database_id: HashMap<String, Vec<String>>,
  ) -> FlowyResult<()>;

  /// Removes local indexes when a workspace is left/deleted
  fn did_delete_workspace(&self, workspace_id: String) -> FlowyResult<()>;
}
