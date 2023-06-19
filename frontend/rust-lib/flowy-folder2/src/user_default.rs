use std::sync::Arc;

use collab_folder::core::{FolderData, RepeatedView, ViewIdentifier, Workspace};
use tokio::sync::RwLock;

use lib_infra::util::timestamp;

use crate::entities::{view_pb_with_child_views, ViewPB, WorkspacePB};
use crate::view_operation::{
  FlattedViews, FolderOperationHandlers, ParentChildViews, WorkspaceViewBuilder,
};

pub struct DefaultFolderBuilder();
impl DefaultFolderBuilder {
  pub async fn build(
    _uid: i64,
    workspace_id: String,
    handlers: &FolderOperationHandlers,
  ) -> (FolderData, WorkspacePB) {
    let workspace_view_builder =
      Arc::new(RwLock::new(WorkspaceViewBuilder::new(workspace_id.clone())));
    for handler in handlers.values() {
      let _ = handler
        .create_workspace_view(workspace_view_builder.clone())
        .await;
    }

    let views = workspace_view_builder.write().await.build();
    // Safe to unwrap because we have at least one view. check out the DocumentFolderOperation.
    let first_view = views
      .first()
      .unwrap()
      .child_views
      .first()
      .unwrap()
      .parent_view
      .clone();

    let first_level_views = views
      .iter()
      .map(|value| ViewIdentifier {
        id: value.parent_view.id.clone(),
      })
      .collect::<Vec<_>>();

    let workspace = Workspace {
      id: workspace_id,
      name: "Workspace".to_string(),
      child_views: RepeatedView::new(first_level_views),
      created_at: timestamp(),
    };

    let first_level_view_pbs = views.iter().map(ViewPB::from).collect::<Vec<_>>();

    let workspace_pb = WorkspacePB {
      id: workspace.id.clone(),
      name: workspace.name.clone(),
      views: first_level_view_pbs,
      create_time: workspace.created_at,
    };

    (
      FolderData {
        current_workspace: workspace.id.clone(),
        current_view: first_view.id,
        workspaces: vec![workspace],
        views: FlattedViews::flatten_views(views),
      },
      workspace_pb,
    )
  }
}

pub fn gen_workspace_id() -> String {
  uuid::Uuid::new_v4().to_string()
}

impl From<&ParentChildViews> for ViewPB {
  fn from(value: &ParentChildViews) -> Self {
    view_pb_with_child_views(
      value.parent_view.clone(),
      value
        .child_views
        .iter()
        .map(|v| v.parent_view.clone())
        .collect(),
    )
  }
}
