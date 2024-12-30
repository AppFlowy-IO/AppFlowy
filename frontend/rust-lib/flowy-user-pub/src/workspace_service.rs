use collab_folder::hierarchy_builder::ParentChildViews;
use flowy_error::FlowyResult;
use flowy_folder_pub::entities::ImportFrom;
use lib_infra::async_trait::async_trait;
use std::collections::HashMap;

#[async_trait]
pub trait UserWorkspaceService: Send + Sync {
  async fn import_views(
    &self,
    source: &ImportFrom,
    views: Vec<ParentChildViews>,
    orphan_views: Vec<ParentChildViews>,
    parent_view_id: Option<String>,
  ) -> FlowyResult<()>;
  async fn import_database_views(
    &self,
    ids_by_database_id: HashMap<String, Vec<String>>,
  ) -> FlowyResult<()>;

  /// Removes local indexes when a workspace is left/deleted
  fn did_delete_workspace(&self, workspace_id: String) -> FlowyResult<()>;
}
