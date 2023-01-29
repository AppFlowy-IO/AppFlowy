use flowy_sync::client_folder::{FolderNodePad, WorkspaceNode};

#[test]
fn client_folder_create_default_folder_test() {
    let folder_pad = FolderNodePad::new();
    let json = folder_pad.to_json(false).unwrap();
    assert_eq!(
        json,
        r#"{"type":"folder","children":[{"type":"workspaces"},{"type":"trash"}]}"#
    );
}

#[test]
fn client_folder_create_default_folder_with_workspace_test() {
    let mut folder_pad = FolderNodePad::new();
    let workspace = WorkspaceNode::new(folder_pad.tree.clone(), "1".to_string(), "workspace name".to_string());
    folder_pad.workspaces.add_workspace(workspace).unwrap();
    let json = folder_pad.to_json(false).unwrap();
    assert_eq!(
        json,
        r#"{"type":"folder","children":[{"type":"workspaces","children":[{"type":"workspace","attributes":{"id":"1","name":"workspace name"}}]},{"type":"trash"}]}"#
    );

    assert_eq!(
        folder_pad.get_workspace("1").unwrap().get_name().unwrap(),
        "workspace name"
    );
}

#[test]
fn client_folder_delete_workspace_test() {
    let mut folder_pad = FolderNodePad::new();
    let workspace = WorkspaceNode::new(folder_pad.tree.clone(), "1".to_string(), "workspace name".to_string());
    folder_pad.workspaces.add_workspace(workspace).unwrap();
    folder_pad.workspaces.remove_workspace("1");
    let json = folder_pad.to_json(false).unwrap();
    assert_eq!(
        json,
        r#"{"type":"folder","children":[{"type":"workspaces"},{"type":"trash"}]}"#
    );
}

#[test]
fn client_folder_update_workspace_name_test() {
    let mut folder_pad = FolderNodePad::new();
    let workspace = WorkspaceNode::new(folder_pad.tree.clone(), "1".to_string(), "workspace name".to_string());
    folder_pad.workspaces.add_workspace(workspace).unwrap();
    folder_pad
        .workspaces
        .get_mut_workspace("1")
        .unwrap()
        .set_name("my first workspace".to_string());

    assert_eq!(
        folder_pad.workspaces.get_workspace("1").unwrap().get_name().unwrap(),
        "my first workspace"
    );
}
