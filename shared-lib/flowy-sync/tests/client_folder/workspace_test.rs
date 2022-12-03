use crate::client_folder::script::FolderNodePadScript::*;
use crate::client_folder::script::FolderNodePadTest;
use flowy_sync::client_folder::FolderNodePad;

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
