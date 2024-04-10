use std::future::Future;

use crate::cloud::gen_view_id;
use collab_folder::{RepeatedViewIdentifier, View, ViewIcon, ViewIdentifier, ViewLayout};
use lib_infra::util::timestamp;

/// A builder for creating views, each able to have children views of
/// their own.
pub struct NestedViewBuilder {
  pub uid: i64,
  pub parent_view_id: String,
  pub views: Vec<ParentChildViews>,
}

impl NestedViewBuilder {
  pub fn new(parent_view_id: String, uid: i64) -> Self {
    Self {
      uid,
      parent_view_id,
      views: vec![],
    }
  }

  pub async fn with_view_builder<F, O>(&mut self, view_builder: F)
  where
    F: Fn(ViewBuilder) -> O,
    O: Future<Output = ParentChildViews>,
  {
    let builder = ViewBuilder::new(self.uid, self.parent_view_id.clone());
    self.views.push(view_builder(builder).await);
  }

  pub fn build(&mut self) -> Vec<ParentChildViews> {
    std::mem::take(&mut self.views)
  }
}

/// A builder for creating a view.
/// The default layout of the view is [ViewLayout::Document]
pub struct ViewBuilder {
  uid: i64,
  parent_view_id: String,
  view_id: String,
  name: String,
  desc: String,
  layout: ViewLayout,
  child_views: Vec<ParentChildViews>,
  is_favorite: bool,
  icon: Option<ViewIcon>,
}

impl ViewBuilder {
  pub fn new(uid: i64, parent_view_id: String) -> Self {
    Self {
      uid,
      parent_view_id,
      view_id: gen_view_id().to_string(),
      name: Default::default(),
      desc: Default::default(),
      layout: ViewLayout::Document,
      child_views: vec![],
      is_favorite: false,

      icon: None,
    }
  }

  pub fn view_id(&self) -> &str {
    &self.view_id
  }

  pub fn with_view_id<T: ToString>(mut self, view_id: T) -> Self {
    self.view_id = view_id.to_string();
    self
  }

  pub fn with_layout(mut self, layout: ViewLayout) -> Self {
    self.layout = layout;
    self
  }

  pub fn with_name<T: ToString>(mut self, name: T) -> Self {
    self.name = name.to_string();
    self
  }

  pub fn with_desc(mut self, desc: &str) -> Self {
    self.desc = desc.to_string();
    self
  }

  pub fn with_icon(mut self, icon: &str) -> Self {
    self.icon = Some(ViewIcon {
      ty: collab_folder::IconType::Emoji,
      value: icon.to_string(),
    });
    self
  }

  pub fn with_view(mut self, view: ParentChildViews) -> Self {
    self.child_views.push(view);
    self
  }

  pub fn with_child_views(mut self, mut views: Vec<ParentChildViews>) -> Self {
    self.child_views.append(&mut views);
    self
  }

  /// Create a child view for the current view.
  /// The view created by this builder will be the next level view of the current view.
  pub async fn with_child_view_builder<F, O>(mut self, child_view_builder: F) -> Self
  where
    F: Fn(ViewBuilder) -> O,
    O: Future<Output = ParentChildViews>,
  {
    let builder = ViewBuilder::new(self.uid, self.view_id.clone());
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
      is_favorite: self.is_favorite,
      layout: self.layout,
      icon: self.icon,
      created_by: Some(self.uid),
      last_edited_time: 0,
      children: RepeatedViewIdentifier::new(
        self
          .child_views
          .iter()
          .map(|v| ViewIdentifier {
            id: v.parent_view.id.clone(),
          })
          .collect(),
      ),
      last_edited_by: Some(self.uid),
    };
    ParentChildViews {
      parent_view: view,
      child_views: self.child_views,
    }
  }
}

#[derive(Clone)]
pub struct ParentChildViews {
  pub parent_view: View,
  pub child_views: Vec<ParentChildViews>,
}

impl ParentChildViews {
  pub fn new(view: View) -> Self {
    Self {
      parent_view: view,
      child_views: vec![],
    }
  }

  pub fn flatten(self) -> Vec<View> {
    FlattedViews::flatten_views(vec![self])
  }
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

#[cfg(test)]
mod tests {
  use crate::folder_builder::{FlattedViews, NestedViewBuilder};

  #[tokio::test]
  async fn create_first_level_views_test() {
    let workspace_id = "w1".to_string();
    let mut builder = NestedViewBuilder::new(workspace_id, 1);
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
    let mut builder = NestedViewBuilder::new(workspace_id, 1);
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
    let mut builder = NestedViewBuilder::new(workspace_id, 1);
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
