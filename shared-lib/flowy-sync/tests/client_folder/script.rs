use flowy_sync::client_folder::{AppNode, FolderNodePad, WorkspaceNode};
use folder_rev_model::AppRevision;
use lib_ot::core::Path;

pub enum FolderNodePadScript {
    CreateWorkspace { id: String, name: String },
    DeleteWorkspace { id: String },
    AssertPathOfWorkspace { id: String, expected_path: Path },
    AssertNumberOfWorkspace { expected: usize },
    CreateApp { id: String, name: String },
    DeleteApp { id: String },
    UpdateApp { id: String, name: String },
    AssertApp { id: String, expected: Option<AppRevision> },
    AssertAppContent { id: String, name: String },
    // AssertNumberOfApps { expected: usize },
}

pub struct FolderNodePadTest {
    folder_pad: FolderNodePad,
}

impl FolderNodePadTest {
    pub fn new() -> FolderNodePadTest {
        let mut folder_pad = FolderNodePad::default();
        let workspace = WorkspaceNode::new(folder_pad.tree.clone(), "1".to_string(), "workspace name".to_string());
        let _ = folder_pad.workspaces.add_workspace(workspace).unwrap();
        Self { folder_pad }
    }

    pub fn run_scripts(&mut self, scripts: Vec<FolderNodePadScript>) {
        for script in scripts {
            self.run_script(script);
        }
    }

    pub fn run_script(&mut self, script: FolderNodePadScript) {
        match script {
            FolderNodePadScript::CreateWorkspace { id, name } => {
                let workspace = WorkspaceNode::new(self.folder_pad.tree.clone(), id, name);
                self.folder_pad.workspaces.add_workspace(workspace).unwrap();
            }
            FolderNodePadScript::DeleteWorkspace { id } => {
                self.folder_pad.workspaces.remove_workspace(id);
            }
            FolderNodePadScript::AssertPathOfWorkspace { id, expected_path } => {
                let workspace_node: &WorkspaceNode = self.folder_pad.workspaces.get_workspace(id).unwrap();
                let node_id = workspace_node.node_id.unwrap();
                let path = self.folder_pad.tree.read().path_from_node_id(node_id);
                assert_eq!(path, expected_path);
            }
            FolderNodePadScript::AssertNumberOfWorkspace { expected } => {
                assert_eq!(self.folder_pad.workspaces.len(), expected);
            }
            FolderNodePadScript::CreateApp { id, name } => {
                let app_node = AppNode::new(self.folder_pad.tree.clone(), id, name);
                let workspace_node = self.folder_pad.get_mut_workspace("1").unwrap();
                let _ = workspace_node.add_app(app_node).unwrap();
            }
            FolderNodePadScript::DeleteApp { id } => {
                let workspace_node = self.folder_pad.get_mut_workspace("1").unwrap();
                workspace_node.remove_app(&id);
            }
            FolderNodePadScript::UpdateApp { id, name } => {
                let workspace_node = self.folder_pad.get_mut_workspace("1").unwrap();
                workspace_node.get_mut_app(&id).unwrap().set_name(name);
            }
            FolderNodePadScript::AssertApp { id, expected } => {
                let workspace_node = self.folder_pad.get_workspace("1").unwrap();
                let app = workspace_node.get_app(&id);
                match expected {
                    None => assert!(app.is_none()),
                    Some(expected_app) => {
                        let app_node = app.unwrap();
                        assert_eq!(expected_app.name, app_node.get_name().unwrap());
                        assert_eq!(expected_app.id, app_node.get_id().unwrap());
                    }
                }
            }
            FolderNodePadScript::AssertAppContent { id, name } => {
                let workspace_node = self.folder_pad.get_workspace("1").unwrap();
                let app = workspace_node.get_app(&id).unwrap();
                assert_eq!(app.get_name().unwrap(), name)
            } // FolderNodePadScript::AssertNumberOfApps { expected } => {
              //     let workspace_node = self.folder_pad.get_workspace("1").unwrap();
              //     assert_eq!(workspace_node.apps.len(), expected);
              // }
        }
    }
}
