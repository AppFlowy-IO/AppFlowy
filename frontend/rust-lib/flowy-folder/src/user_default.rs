use std::sync::Arc;

use collab_folder::hierarchy_builder::{FlattedViews, NestedViewBuilder, ParentChildViews};
use collab_folder::{FolderData, RepeatedViewIdentifier, ViewIdentifier, Workspace};
use tokio::sync::RwLock;

use lib_infra::util::timestamp;

use crate::entities::{ViewPB, view_pb_with_child_views};
use crate::view_operation::{FolderOperationHandler, FolderOperationHandlers};

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

    // Collect all handlers from the DashMap into a vector.
    //
    // - `DashMap::iter()` returns references to the stored values, which are not `Send`
    //   and can cause issues in an `async` context where thread-safety is required.
    // - By cloning the values into a `Vec`, we ensure they are owned and implement
    //   `Send + Sync`, making them safe to use in asynchronous operations.
    // - This avoids lifetime conflicts and allows the handlers to be used in the
    //   asynchronous loop without tying their lifetimes to the DashMap.
    //
    let handler_clones: Vec<Arc<dyn FolderOperationHandler + Send + Sync>> =
      handlers.iter().map(|entry| entry.value().clone()).collect();
    for handler in handler_clones {
      let _ = handler
        .create_workspace_view(uid, workspace_view_builder.clone())
        .await;
    }

    let views = workspace_view_builder.write().await.build();
    // Safe to unwrap because we have at least one view. check out the DocumentFolderOperation.
    let first_view = views.first().unwrap().view.clone();

    let first_level_views = views
      .iter()
      .map(|value| ViewIdentifier {
        id: value.view.id.clone(),
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
      views: FlattedViews::flatten_views(views.into_inner()),
      favorites: Default::default(),
      recent: Default::default(),
      trash: Default::default(),
      private: Default::default(),
    }
  }
}

impl From<&ParentChildViews> for ViewPB {
  fn from(value: &ParentChildViews) -> Self {
    view_pb_with_child_views(
      Arc::new(value.view.clone()),
      value
        .children
        .iter()
        .map(|v| Arc::new(v.view.clone()))
        .collect(),
    )
  }
}
