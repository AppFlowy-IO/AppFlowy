use crate::entities::{view_pb_with_child_views, WorkspacePB};

use crate::view_ext::{gen_view_id, ViewDataProcessorMap};
use chrono::Utc;
use collab_folder::core::{Belonging, Belongings, FolderData, View, ViewLayout, Workspace};
use flowy_document::editor::initial_read_me;
use nanoid::nanoid;
use std::collections::HashMap;

pub struct DefaultFolderBuilder();
impl DefaultFolderBuilder {
  pub async fn build(
    uid: i64,
    view_processors: &ViewDataProcessorMap,
  ) -> (FolderData, WorkspacePB) {
    let time = Utc::now().timestamp();
    let workspace_id = gen_workspace_id();
    let view_id = gen_view_id();
    let child_view_id = gen_view_id();

    let child_view_layout = ViewLayout::Document;
    let child_view = View {
      id: child_view_id.clone(),
      bid: view_id.clone(),
      name: "Read me".to_string(),
      desc: "".to_string(),
      belongings: Default::default(),
      created_at: time,
      layout: child_view_layout.clone(),
      database_id: None,
    };

    // create the document
    let data = initial_read_me().into_bytes();
    let processor = view_processors.get(&child_view_layout).unwrap();
    processor
      .create_view_with_custom_data(
        uid,
        &child_view.id,
        &child_view.name,
        data,
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
      belongings: Belongings::new(vec![Belonging {
        id: child_view.id.clone(),
        name: child_view.name.clone(),
      }]),
      created_at: time,
      layout: ViewLayout::Document,
      database_id: None,
    };

    let workspace = Workspace {
      id: workspace_id,
      name: "Workspace".to_string(),
      belongings: Belongings::new(vec![Belonging {
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
