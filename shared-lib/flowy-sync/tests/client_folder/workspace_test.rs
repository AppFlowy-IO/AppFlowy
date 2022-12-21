use crate::client_folder::script::FolderNodePadScript::*;
use crate::client_folder::script::FolderNodePadTest;

#[test]
fn client_folder_create_multi_workspaces_test() {
    let mut test = FolderNodePadTest::new();
    test.run_scripts(vec![
        AssertPathOfWorkspace {
            id: "1".to_string(),
            expected_path: vec![0, 0, 0].into(),
        },
        CreateWorkspace {
            id: "a".to_string(),
            name: "workspace a".to_string(),
        },
        AssertPathOfWorkspace {
            id: "a".to_string(),
            expected_path: vec![0, 0, 1].into(),
        },
        CreateWorkspace {
            id: "b".to_string(),
            name: "workspace b".to_string(),
        },
        AssertPathOfWorkspace {
            id: "b".to_string(),
            expected_path: vec![0, 0, 2].into(),
        },
        AssertNumberOfWorkspace { expected: 3 },
        // The path of the workspace 'b' will be changed after deleting the 'a' workspace.
        DeleteWorkspace { id: "a".to_string() },
        AssertPathOfWorkspace {
            id: "b".to_string(),
            expected_path: vec![0, 0, 1].into(),
        },
    ]);
}

#[test]
fn client_folder_create_app_test() {
    let mut test = FolderNodePadTest::new();
    test.run_scripts(vec![
        CreateApp {
            id: "1".to_string(),
            name: "my first app".to_string(),
        },
        AssertAppContent {
            id: "1".to_string(),
            name: "my first app".to_string(),
        },
    ]);
}

#[test]
fn client_folder_delete_app_test() {
    let mut test = FolderNodePadTest::new();
    test.run_scripts(vec![
        CreateApp {
            id: "1".to_string(),
            name: "my first app".to_string(),
        },
        DeleteApp { id: "1".to_string() },
        AssertApp {
            id: "1".to_string(),
            expected: None,
        },
    ]);
}

#[test]
fn client_folder_update_app_test() {
    let mut test = FolderNodePadTest::new();
    test.run_scripts(vec![
        CreateApp {
            id: "1".to_string(),
            name: "my first app".to_string(),
        },
        UpdateApp {
            id: "1".to_string(),
            name: "TODO".to_string(),
        },
        AssertAppContent {
            id: "1".to_string(),
            name: "TODO".to_string(),
        },
    ]);
}
