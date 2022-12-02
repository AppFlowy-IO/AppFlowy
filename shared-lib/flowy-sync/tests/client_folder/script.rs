use flowy_sync::client_folder::FolderNodePad;
use folder_rev_model::{AppRevision, WorkspaceRevision};
use std::sync::Arc;

pub enum FolderNodePadScript {
    CreateApp { id: String, name: String },
    DeleteApp { id: String },
    AssertApp { id: String, expected: Option<AppRevision> },
    AssertAppContent { id: String, name: String },
    AssertNumberOfApps { expected: usize },
}

pub struct FolderNodePadTest {
    folder_pad: FolderNodePad,
}

impl FolderNodePadTest {
    pub fn new() -> FolderNodePadTest {
        let mut folder_pad = FolderNodePad::default();
        let workspace = WorkspaceRevision {
            id: "1".to_string(),
            name: "workspace name".to_string(),
            desc: "".to_string(),
            apps: vec![],
            modified_time: 0,
            create_time: 0,
        };
        let _ = folder_pad.add_workspace(workspace).unwrap();
        Self { folder_pad }
    }

    pub fn run_scripts(&mut self, scripts: Vec<FolderNodePadScript>) {
        for script in scripts {
            self.run_script(script);
        }
    }

    pub fn run_script(&mut self, script: FolderNodePadScript) {
        match script {
            FolderNodePadScript::CreateApp { id, name } => {
                let revision = AppRevision {
                    id,
                    workspace_id: "1".to_string(),
                    name,
                    desc: "".to_string(),
                    belongings: vec![],
                    version: 0,
                    modified_time: 0,
                    create_time: 0,
                };

                let workspace_node = self.folder_pad.get_mut_workspace("1").unwrap();
                let workspace_node = Arc::make_mut(workspace_node);
                let _ = workspace_node.add_app(revision).unwrap();
            }
            FolderNodePadScript::DeleteApp { id } => {
                let workspace_node = self.folder_pad.get_mut_workspace("1").unwrap();
                let workspace_node = Arc::make_mut(workspace_node);
                workspace_node.remove_app(&id);
            }

            FolderNodePadScript::AssertApp { id, expected } => {
                let workspace_node = self.folder_pad.get_workspace("1").unwrap();
                let app = workspace_node.get_app(&id);
                match expected {
                    None => assert!(app.is_none()),
                    Some(expected_app) => {
                        let app_node = app.unwrap();
                        assert_eq!(expected_app.name, app_node.get_name().unwrap());
                        assert_eq!(expected_app.id, app_node.id);
                    }
                }
            }
            FolderNodePadScript::AssertAppContent { id, name } => {
                let workspace_node = self.folder_pad.get_workspace("1").unwrap();
                let app = workspace_node.get_app(&id).unwrap();
                assert_eq!(app.get_name().unwrap(), name)
            }
            FolderNodePadScript::AssertNumberOfApps { expected } => {
                let workspace_node = self.folder_pad.get_workspace("1").unwrap();
                assert_eq!(workspace_node.get_all_apps().len(), expected);
            }
        }
    }
}
