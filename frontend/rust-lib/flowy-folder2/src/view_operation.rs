use std::collections::HashMap;
use std::future::Future;
use std::sync::Arc;

use bytes::Bytes;
pub use collab_folder::core::View;
use collab_folder::core::{RepeatedView, ViewIdentifier, ViewLayout};
use tokio::sync::RwLock;

use flowy_error::FlowyError;
use lib_infra::future::FutureResult;
use lib_infra::util::timestamp;

use crate::entities::{CreateViewParams, ViewLayoutPB};
use crate::share::ImportType;

pub type ViewData = Bytes;

/// A builder for creating a view for a workspace.
/// The views created by this builder will be the first level views of the workspace.
pub struct WorkspaceViewBuilder {
  pub workspace_id: String,
  pub views: Vec<ParentChildViews>,
}

impl WorkspaceViewBuilder {
  pub fn new(workspace_id: String) -> Self {
    Self {
      workspace_id,
      views: vec![],
    }
  }

  pub async fn with_view_builder<F, O>(&mut self, view_builder: F)
  where
    F: Fn(ViewBuilder) -> O,
    O: Future<Output = ParentChildViews>,
  {
    let builder = ViewBuilder::new(self.workspace_id.clone());
    self.views.push(view_builder(builder).await);
  }

  pub fn build(&mut self) -> Vec<ParentChildViews> {
    std::mem::take(&mut self.views)
  }
}

/// A builder for creating a view.
/// The default layout of the view is [ViewLayout::Document]
pub struct ViewBuilder {
  parent_view_id: String,
  view_id: String,
  name: String,
  desc: String,
  layout: ViewLayout,
  child_views: Vec<ParentChildViews>,
}

impl ViewBuilder {
  pub fn new(parent_view_id: String) -> Self {
    Self {
      parent_view_id,
      view_id: gen_view_id(),
      name: Default::default(),
      desc: Default::default(),
      layout: ViewLayout::Document,
      child_views: vec![],
    }
  }

  pub fn view_id(&self) -> &str {
    &self.view_id
  }

  pub fn with_layout(mut self, layout: ViewLayout) -> Self {
    self.layout = layout;
    self
  }

  pub fn with_name(mut self, name: &str) -> Self {
    self.name = name.to_string();
    self
  }

  pub fn with_desc(mut self, desc: &str) -> Self {
    self.desc = desc.to_string();
    self
  }

  /// Create a child view for the current view.
  /// The view created by this builder will be the next level view of the current view.
  pub async fn with_child_view_builder<F, O>(mut self, child_view_builder: F) -> Self
  where
    F: Fn(ViewBuilder) -> O,
    O: Future<Output = ParentChildViews>,
  {
    let builder = ViewBuilder::new(self.view_id.clone());
    self.child_views.push(child_view_builder(builder).await);
    self
  }

  pub fn build(self) -> ParentChildViews {
    let view = View {
      id: self.view_id,
      parent_view_id: self.parent_view_id,
      name: self.name,
      desc: self.desc,
      created_at: timestamp(),
      layout: self.layout,
      children: RepeatedView::new(
        self
          .child_views
          .iter()
          .map(|v| ViewIdentifier {
            id: v.parent_view.id.clone(),
          })
          .collect(),
      ),
    };
    ParentChildViews {
      parent_view: view,
      child_views: self.child_views,
    }
  }
}

pub struct ParentChildViews {
  pub parent_view: View,
  pub child_views: Vec<ParentChildViews>,
}

pub struct FlattedViews;

impl FlattedViews {
  pub fn flatten_views(views: Vec<ParentChildViews>) -> Vec<View> {
    let mut result = vec![];
    for view in views {
      result.push(view.parent_view);
      result.append(&mut Self::flatten_views(view.child_views));
    }
    result
  }
}

/// The handler will be used to handler the folder operation for a specific
/// view layout. Each [ViewLayout] will have a handler. So when creating a new
/// view, the [ViewLayout] will be used to get the handler.
///
pub trait FolderOperationHandler {
  /// Create the view for the workspace of new user.
  /// Only called once when the user is created.
  fn create_workspace_view(
    &self,
    _workspace_view_builder: Arc<RwLock<WorkspaceViewBuilder>>,
  ) -> FutureResult<(), FlowyError> {
    FutureResult::new(async { Ok(()) })
  }

  /// Closes the view and releases the resources that this view has in
  /// the backend
  fn close_view(&self, view_id: &str) -> FutureResult<(), FlowyError>;

  /// Called when the view is deleted.
  /// This will called after the view is deleted from the trash.
  fn delete_view(&self, view_id: &str) -> FutureResult<(), FlowyError>;

  /// Returns the [ViewData] that can be used to create the same view.
  fn duplicate_view(&self, view_id: &str) -> FutureResult<ViewData, FlowyError>;

  /// Create a view with the data.
  ///
  /// # Arguments
  ///
  /// * `user_id`: the user id
  /// * `view_id`: the view id
  /// * `name`: the name of the view
  /// * `data`: initial data of the view. The data should be parsed by the [FolderOperationHandler]
  /// implementation. For example, the data of the database will be [DatabaseData].
  /// * `layout`: the layout of the view
  /// * `meta`: use to carry extra information. For example, the database view will use this
  /// to carry the reference database id.
  fn create_view_with_view_data(
    &self,
    user_id: i64,
    view_id: &str,
    name: &str,
    data: Vec<u8>,
    layout: ViewLayout,
    meta: HashMap<String, String>,
  ) -> FutureResult<(), FlowyError>;

  /// Create a view with the pre-defined data.
  /// For example, the initial data of the grid/calendar/kanban board when
  /// you create a new view.
  fn create_built_in_view(
    &self,
    user_id: i64,
    view_id: &str,
    name: &str,
    layout: ViewLayout,
  ) -> FutureResult<(), FlowyError>;

  /// Create a view by importing data
  fn import_from_bytes(
    &self,
    view_id: &str,
    name: &str,
    import_type: ImportType,
    bytes: Vec<u8>,
  ) -> FutureResult<(), FlowyError>;

  /// Create a view by importing data from a file
  fn import_from_file_path(
    &self,
    view_id: &str,
    name: &str,
    path: String,
  ) -> FutureResult<(), FlowyError>;

  /// Called when the view is updated. The handler is the `old` registered handler.
  fn did_update_view(&self, _old: &View, _new: &View) -> FutureResult<(), FlowyError> {
    FutureResult::new(async move { Ok(()) })
  }
}

pub type FolderOperationHandlers =
  Arc<HashMap<ViewLayout, Arc<dyn FolderOperationHandler + Send + Sync>>>;

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

pub(crate) fn create_view(params: CreateViewParams, layout: ViewLayout) -> View {
  let time = timestamp();
  View {
    id: params.view_id,
    parent_view_id: params.parent_view_id,
    name: params.name,
    desc: params.desc,
    children: Default::default(),
    created_at: time,
    layout,
  }
}

pub fn gen_view_id() -> String {
  uuid::Uuid::new_v4().to_string()
}

#[cfg(test)]
mod tests {
  use crate::view_operation::{FlattedViews, WorkspaceViewBuilder};

  #[tokio::test]
  async fn create_first_level_views_test() {
    let workspace_id = "w1".to_string();
    let mut builder = WorkspaceViewBuilder::new(workspace_id);
    builder
      .with_view_builder(|view_builder| async { view_builder.with_name("1").build() })
      .await;
    builder
      .with_view_builder(|view_builder| async { view_builder.with_name("2").build() })
      .await;
    builder
      .with_view_builder(|view_builder| async { view_builder.with_name("3").build() })
      .await;
    let workspace_views = builder.build();
    assert_eq!(workspace_views.len(), 3);

    let views = FlattedViews::flatten_views(workspace_views);
    assert_eq!(views.len(), 3);
  }

  #[tokio::test]
  async fn create_view_with_child_views_test() {
    let workspace_id = "w1".to_string();
    let mut builder = WorkspaceViewBuilder::new(workspace_id);
    builder
      .with_view_builder(|view_builder| async {
        view_builder
          .with_name("1")
          .with_child_view_builder(|child_view_builder| async {
            child_view_builder.with_name("1_1").build()
          })
          .await
          .with_child_view_builder(|child_view_builder| async {
            child_view_builder.with_name("1_2").build()
          })
          .await
          .build()
      })
      .await;
    builder
      .with_view_builder(|view_builder| async {
        view_builder
          .with_name("2")
          .with_child_view_builder(|child_view_builder| async {
            child_view_builder.with_name("2_1").build()
          })
          .await
          .build()
      })
      .await;
    let workspace_views = builder.build();
    assert_eq!(workspace_views.len(), 2);

    assert_eq!(workspace_views[0].parent_view.name, "1");
    assert_eq!(workspace_views[0].child_views.len(), 2);
    assert_eq!(workspace_views[0].child_views[0].parent_view.name, "1_1");
    assert_eq!(workspace_views[0].child_views[1].parent_view.name, "1_2");
    assert_eq!(workspace_views[1].child_views.len(), 1);
    assert_eq!(workspace_views[1].child_views[0].parent_view.name, "2_1");

    let views = FlattedViews::flatten_views(workspace_views);
    assert_eq!(views.len(), 5);
  }
  #[tokio::test]
  async fn create_three_level_view_test() {
    let workspace_id = "w1".to_string();
    let mut builder = WorkspaceViewBuilder::new(workspace_id);
    builder
      .with_view_builder(|view_builder| async {
        view_builder
          .with_name("1")
          .with_child_view_builder(|child_view_builder| async {
            child_view_builder
              .with_name("1_1")
              .with_child_view_builder(|b| async { b.with_name("1_1_1").build() })
              .await
              .with_child_view_builder(|b| async { b.with_name("1_1_2").build() })
              .await
              .build()
          })
          .await
          .with_child_view_builder(|child_view_builder| async {
            child_view_builder
              .with_name("1_2")
              .with_child_view_builder(|b| async { b.with_name("1_2_1").build() })
              .await
              .with_child_view_builder(|b| async { b.with_name("1_2_2").build() })
              .await
              .build()
          })
          .await
          .build()
      })
      .await;
    let workspace_views = builder.build();
    assert_eq!(workspace_views.len(), 1);

    assert_eq!(workspace_views[0].parent_view.name, "1");
    assert_eq!(workspace_views[0].child_views.len(), 2);
    assert_eq!(workspace_views[0].child_views[0].parent_view.name, "1_1");
    assert_eq!(workspace_views[0].child_views[1].parent_view.name, "1_2");

    assert_eq!(
      workspace_views[0].child_views[0].child_views[0]
        .parent_view
        .name,
      "1_1_1"
    );
    assert_eq!(
      workspace_views[0].child_views[0].child_views[1]
        .parent_view
        .name,
      "1_1_2"
    );

    assert_eq!(
      workspace_views[0].child_views[1].child_views[0]
        .parent_view
        .name,
      "1_2_1"
    );
    assert_eq!(
      workspace_views[0].child_views[1].child_views[1]
        .parent_view
        .name,
      "1_2_2"
    );

    let views = FlattedViews::flatten_views(workspace_views);
    assert_eq!(views.len(), 7);
  }
}
