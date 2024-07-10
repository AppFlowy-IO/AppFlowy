use std::sync::Arc;

use collab_folder::{FolderData, RepeatedViewIdentifier, ViewIdentifier, Workspace};
use flowy_folder_pub::folder_builder::{FlattedViews, NestedViewBuilder, ParentChildViews};
use tokio::sync::RwLock;

use lib_infra::util::timestamp;

use crate::entities::{view_pb_with_child_views, ViewPB};
use crate::view_operation::FolderOperationHandlers;

pub struct DefaultFolderBuilder();
impl DefaultFolderBuilder {
  pub async fn build(
    uid: i64,
    workspace_id: String,
    handlers: &FolderOperationHandlers,
  ) -> FolderData {
    let workspace_view_builder = Arc::new(RwLock::new(NestedViewBuilder::new(
      workspace_id.clone(),
      uid,
    )));
    for handler in handlers.values() {
      let _ = handler
        .create_workspace_view(uid, workspace_view_builder.clone())
        .await;
    }

    let views = workspace_view_builder.write().await.build();
    // Safe to unwrap because we have at least one view. check out the DocumentFolderOperation.
    let first_view = views.first().unwrap().parent_view.clone();

    let first_level_views = views
      .iter()
      .map(|value| ViewIdentifier {
        id: value.parent_view.id.clone(),
      })
      .collect::<Vec<_>>();

    let workspace = Workspace {
      id: workspace_id,
      name: "Workspace".to_string(),
      child_views: RepeatedViewIdentifier::new(first_level_views),
      created_at: timestamp(),
      created_by: Some(uid),
      last_edited_time: timestamp(),
      last_edited_by: Some(uid),
    };

    FolderData {
      workspace,
      current_view: first_view.id,
      views: FlattedViews::flatten_views(views),
      favorites: Default::default(),
      recent: Default::default(),
      trash: Default::default(),
      private: Default::default(),
      section_view_relations: Default::default(),
    }
  }
}

impl From<&ParentChildViews> for ViewPB {
  fn from(value: &ParentChildViews) -> Self {
    view_pb_with_child_views(
      Arc::new(value.parent_view.clone()),
      value
        .child_views
        .iter()
        .map(|v| Arc::new(v.parent_view.clone()))
        .collect(),
    )
  }
}
