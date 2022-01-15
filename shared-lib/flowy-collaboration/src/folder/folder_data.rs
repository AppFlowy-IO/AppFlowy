use dissimilar::*;
use flowy_core_data_model::entities::{
    app::{App, RepeatedApp},
    trash::{RepeatedTrash, Trash},
    view::{RepeatedView, View},
    workspace::{RepeatedWorkspace, Workspace},
};
use lib_ot::core::{
    Delta,
    FlowyStr,
    Operation,
    Operation::Retain,
    PlainDeltaBuilder,
    PlainTextAttributes,
    PlainTextOpBuilder,
};
use serde::{Deserialize, Serialize};
use std::sync::Arc;

#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct RootFolder {
    workspaces: Vec<Arc<Workspace>>,
    trash: Vec<Trash>,
}

impl RootFolder {
    pub fn add_workspace(&mut self, workspace: Workspace) -> Option<Delta<PlainTextAttributes>> {
        let workspace = Arc::new(workspace);
        if self.workspaces.contains(&workspace) {
            tracing::warn!("Duplicate workspace");
            return None;
        }

        let old = WorkspacesJson::new(self.workspaces.clone()).to_json().unwrap();
        self.workspaces.push(workspace);
        let new = WorkspacesJson::new(self.workspaces.clone()).to_json().unwrap();
        Some(cal_diff(old, new))
    }

    pub fn update_workspace(&mut self, workspace_id: &str, name: Option<String>, desc: Option<String>) {
        if let Some(mut workspace) = self
            .workspaces
            .iter_mut()
            .find(|workspace| workspace.id == workspace_id)
        {
            let m_workspace = Arc::make_mut(&mut workspace);
            if let Some(name) = name {
                m_workspace.name = name;
            }

            if let Some(desc) = desc {
                m_workspace.desc = desc;
            }
        }
    }

    pub fn delete_workspace(&mut self, workspace_id: &str) { self.workspaces.retain(|w| w.id != workspace_id) }
}

fn cal_diff(old: String, new: String) -> Delta<PlainTextAttributes> {
    let mut chunks = dissimilar::diff(&old, &new);
    let mut delta_builder = PlainDeltaBuilder::new();
    for chunk in &chunks {
        match chunk {
            Chunk::Equal(s) => {
                delta_builder = delta_builder.retain(FlowyStr::from(*s).utf16_size());
            },
            Chunk::Delete(s) => {
                delta_builder = delta_builder.delete(FlowyStr::from(*s).utf16_size());
            },
            Chunk::Insert(s) => {
                delta_builder = delta_builder.insert(*s);
            },
        }
    }
    delta_builder.build()
}

#[derive(Serialize, Deserialize)]
struct WorkspacesJson {
    workspaces: Vec<Arc<Workspace>>,
}

impl WorkspacesJson {
    fn new(workspaces: Vec<Arc<Workspace>>) -> Self { Self { workspaces } }

    fn to_json(self) -> Result<String, String> {
        serde_json::to_string(&self).map_err(|e| format!("format workspaces failed: {}", e))
    }
}

#[cfg(test)]
mod tests {
    use crate::folder::folder_data::RootFolder;
    use chrono::Utc;
    use flowy_core_data_model::{entities::prelude::Workspace, user_default};
    use std::{borrow::Cow, sync::Arc};

    #[test]
    fn folder_add_workspace_serde_test() {
        let mut folder = RootFolder {
            workspaces: vec![],
            trash: vec![],
        };

        let time = Utc::now();
        let workspace_1 = user_default::create_default_workspace(time);
        let delta_1 = folder.add_workspace(workspace_1).unwrap();
        println!("{}", delta_1);

        let workspace_2 = user_default::create_default_workspace(time);
        let delta_2 = folder.add_workspace(workspace_2).unwrap();
        println!("{}", delta_2);
    }

    #[test]
    fn serial_folder_test() {
        let time = Utc::now();
        let workspace = user_default::create_default_workspace(time);
        let id = workspace.id.clone();
        let mut folder = RootFolder {
            workspaces: vec![Arc::new(workspace)],
            trash: vec![],
        };

        let mut cloned = folder.clone();
        cloned.update_workspace(&id, Some("123".to_owned()), None);

        println!("{}", serde_json::to_string(&folder).unwrap());
        println!("{}", serde_json::to_string(&cloned).unwrap());
    }
}
