use crate::manager::Folder;
use crate::view_ext::gen_view_id;
use chrono::Utc;
use collab_folder::core::{Belonging, Belongings, FolderData, View, ViewLayout, Workspace};
use nanoid::nanoid;
use std::sync::Arc;
use tokio::sync::RwLock;

pub struct DefaultFolderBuilder();
impl DefaultFolderBuilder {
  pub fn build(folder: Folder) {
    let time = Utc::now().timestamp();
    let workspace_id = gen_workspace_id();
    let view_id = gen_view_id();
    let child_view_id = gen_view_id();

    let child_view = View {
      id: child_view_id,
      bid: view_id.clone(),
      name: "Read me".to_string(),
      desc: "".to_string(),
      belongings: Default::default(),
      created_at: time,
      layout: ViewLayout::Document,
      database_id: None,
    };

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

    let data = FolderData {
      current_workspace: workspace.id.clone(),
      current_view: view.id.clone(),
      workspaces: vec![workspace],
      views: vec![view, child_view],
    };

    folder.lock().create_with_data(data);
  }
}

pub fn gen_workspace_id() -> String {
  nanoid!(10)
}
