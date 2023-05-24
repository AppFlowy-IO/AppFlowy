use std::collections::HashMap;

use chrono::Utc;
use collab_folder::core::{ChildView, ChildViews, FolderData, View, ViewLayout, Workspace};
use nanoid::nanoid;

use crate::entities::{view_pb_with_child_views, WorkspacePB};
use crate::view_ext::{gen_view_id, ViewDataProcessorMap};

pub struct DefaultFolderBuilder();
impl DefaultFolderBuilder {
  pub async fn build(
    uid: i64,
    workspace_id: String,
    view_processors: &ViewDataProcessorMap,
  ) -> (FolderData, WorkspacePB) {
    let time = Utc::now().timestamp();
    let view_id = gen_view_id();
    let child_view_id = gen_view_id();

    let child_view_layout = ViewLayout::Document;
    let child_view = View {
      id: child_view_id.clone(),
      bid: view_id.clone(),
      name: "Read me".to_string(),
      desc: "".to_string(),
      created_at: time,
      layout: child_view_layout.clone(),
      children: Default::default(),
    };

    // create the document
    // TODO: use the initial data from the view processor
    // let data = initial_read_me().into_bytes();
    let processor = view_processors.get(&child_view_layout).unwrap();
    processor
      .create_view_with_built_in_data(
        uid,
        &child_view.id,
        &child_view.name,
        child_view_layout.clone(),
        HashMap::default(),
      )
      .await
      .unwrap();

    let view = View {
      id: view_id,
      bid: workspace_id.clone(),
      name: "⭐️ Getting started".to_string(),
      desc: "".to_string(),
      children: ChildViews::new(vec![ChildView {
        id: child_view.id.clone(),
        name: child_view.name.clone(),
      }]),
      created_at: time,
      layout: ViewLayout::Document,
    };

    let workspace = Workspace {
      id: workspace_id,
      name: "Workspace".to_string(),
      child_views: ChildViews::new(vec![ChildView {
        id: view.id.clone(),
        name: view.name.clone(),
      }]),
      created_at: time,
    };

    let workspace_pb = workspace_pb_from_workspace(&workspace, &view, &child_view);

    (
      FolderData {
        current_workspace: workspace.id.clone(),
        current_view: child_view_id,
        workspaces: vec![workspace],
        views: vec![view, child_view],
      },
      workspace_pb,
    )
  }
}

pub fn gen_workspace_id() -> String {
  nanoid!(10)
}

fn workspace_pb_from_workspace(
  workspace: &Workspace,
  view: &View,
  child_view: &View,
) -> WorkspacePB {
  let view_pb = view_pb_with_child_views(view.clone(), vec![child_view.clone()]);
  WorkspacePB {
    id: workspace.id.clone(),
    name: workspace.name.clone(),
    views: vec![view_pb],
    create_time: workspace.created_at,
  }
}
