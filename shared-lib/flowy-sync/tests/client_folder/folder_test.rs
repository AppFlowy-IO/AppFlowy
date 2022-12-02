use flowy_sync::client_folder::FolderNodePad;
use folder_rev_model::WorkspaceRevision;

#[test]
fn client_folder_create_default_folder_test() {
    let folder_pad = FolderNodePad::default();
    let json = folder_pad.to_json(false).unwrap();
    assert_eq!(
        json,
        r#"{"type":"folder","children":[{"type":"workspaces"},{"type":"trash"}]}"#
    );
}

#[test]
fn client_folder_create_default_folder_with_workspace_test() {
    let mut folder_pad = FolderNodePad::default();
    let workspace = WorkspaceRevision {
        id: "1".to_string(),
        name: "workspace name".to_string(),
        desc: "".to_string(),
        apps: vec![],
        modified_time: 0,
        create_time: 0,
    };
    folder_pad.add_workspace(workspace).unwrap();
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
    let mut folder_pad = FolderNodePad::default();
    let workspace = WorkspaceRevision {
        id: "1".to_string(),
        name: "workspace name".to_string(),
        desc: "".to_string(),
        apps: vec![],
        modified_time: 0,
        create_time: 0,
    };
    folder_pad.add_workspace(workspace).unwrap();
    folder_pad.remove_workspace("1");
    let json = folder_pad.to_json(false).unwrap();
    assert_eq!(
        json,
        r#"{"type":"folder","children":[{"type":"workspaces"},{"type":"trash"}]}"#
    );
}

#[test]
fn client_folder_update_workspace_name_test() {
    let mut folder_pad = FolderNodePad::default();
    let workspace = WorkspaceRevision {
        id: "1".to_string(),
        name: "workspace name".to_string(),
        desc: "".to_string(),
        apps: vec![],
        modified_time: 0,
        create_time: 0,
    };
    folder_pad.add_workspace(workspace).unwrap();
    folder_pad
        .get_workspace("1")
        .unwrap()
        .set_name("My first workspace")
        .unwrap();
    assert_eq!(
        folder_pad.get_workspace("1").unwrap().get_name().unwrap(),
        "My first workspace"
    );
}
