use crate::script::{invalid_workspace_name_test_case, FolderScript::*, FolderTest};
use flowy_collaboration::{client_document::default::initial_delta_string, entities::revision::RevisionState};
use flowy_core::entities::workspace::CreateWorkspaceRequest;
use flowy_test::{event_builder::*, FlowySDKTest};

#[tokio::test]
async fn workspace_read_all() {
    let mut test = FolderTest::new().await;
    test.run_scripts(vec![ReadAllWorkspaces]).await;
    // The first workspace will be the default workspace
    // The second workspace will be created by FolderTest
    assert_eq!(test.all_workspace.len(), 2);

    let new_name = "My new workspace".to_owned();
    test.run_scripts(vec![
        CreateWorkspace {
            name: new_name.clone(),
            desc: "Daily routines".to_owned(),
        },
        ReadAllWorkspaces,
    ])
    .await;
    assert_eq!(test.all_workspace.len(), 3);
    assert_eq!(test.all_workspace[2].name, new_name);
}

#[tokio::test]
async fn workspace_create() {
    let mut test = FolderTest::new().await;
    let name = "My new workspace".to_owned();
    let desc = "Daily routines".to_owned();
    test.run_scripts(vec![CreateWorkspace {
        name: name.clone(),
        desc: desc.clone(),
    }])
    .await;

    let workspace = test.workspace.clone();
    assert_eq!(workspace.name, name);
    assert_eq!(workspace.desc, desc);

    test.run_scripts(vec![
        ReadWorkspace(Some(workspace.id.clone())),
        AssertWorkspace(workspace),
    ])
    .await;
}

#[tokio::test]
async fn workspace_read() {
    let mut test = FolderTest::new().await;
    let workspace = test.workspace.clone();
    let json = serde_json::to_string(&workspace).unwrap();

    test.run_scripts(vec![
        ReadWorkspace(Some(workspace.id.clone())),
        AssertWorkspaceJson(json),
        AssertWorkspace(workspace),
    ])
    .await;
}

#[tokio::test]
async fn workspace_create_with_apps() {
    let mut test = FolderTest::new().await;
    test.run_scripts(vec![CreateApp {
        name: "App",
        desc: "App description",
    }])
    .await;

    let app = test.app.clone();
    let json = serde_json::to_string(&app).unwrap();
    test.run_scripts(vec![ReadApp(app.id), AssertAppJson(json)]).await;
}

#[tokio::test]
async fn workspace_create_with_invalid_name() {
    for (name, code) in invalid_workspace_name_test_case() {
        let sdk = FlowySDKTest::default();
        let request = CreateWorkspaceRequest {
            name,
            desc: "".to_owned(),
        };
        assert_eq!(
            FolderEventBuilder::new(sdk)
                .event(flowy_core::event::WorkspaceEvent::CreateWorkspace)
                .request(request)
                .async_send()
                .await
                .error()
                .code,
            code.value()
        )
    }
}

#[tokio::test]
#[should_panic]
async fn app_delete() {
    let mut test = FolderTest::new().await;
    let app = test.app.clone();
    test.run_scripts(vec![DeleteApp, ReadApp(app.id)]).await;
}

#[tokio::test]
async fn app_delete_then_restore() {
    let mut test = FolderTest::new().await;
    let app = test.app.clone();
    test.run_scripts(vec![
        DeleteApp,
        RestoreAppFromTrash,
        ReadApp(app.id.clone()),
        AssertApp(app),
    ])
    .await;
}

#[tokio::test]
async fn app_read() {
    let mut test = FolderTest::new().await;
    let app = test.app.clone();
    test.run_scripts(vec![ReadApp(app.id.clone()), AssertApp(app)]).await;
}

#[tokio::test]
async fn app_update() {
    let mut test = FolderTest::new().await;
    let app = test.app.clone();
    let new_name = "😁 hell world".to_owned();
    assert_ne!(app.name, new_name);

    test.run_scripts(vec![
        UpdateApp {
            name: Some(new_name.clone()),
            desc: None,
        },
        ReadApp(app.id),
    ])
    .await;
    assert_eq!(test.app.name, new_name);
}

#[tokio::test]
async fn app_create_with_view() {
    let mut test = FolderTest::new().await;
    let mut app = test.app.clone();
    test.run_scripts(vec![
        CreateView {
            name: "View A",
            desc: "View A description",
        },
        CreateView {
            name: "View B",
            desc: "View B description",
        },
        ReadApp(app.id),
    ])
    .await;

    app = test.app.clone();
    assert_eq!(app.belongings.len(), 3);
    assert_eq!(app.belongings[1].name, "View A");
    assert_eq!(app.belongings[2].name, "View B")
}

#[tokio::test]
async fn view_update() {
    let mut test = FolderTest::new().await;
    let view = test.view.clone();
    let new_name = "😁 123".to_owned();
    assert_ne!(view.name, new_name);

    test.run_scripts(vec![
        UpdateView {
            name: Some(new_name.clone()),
            desc: None,
        },
        ReadView(view.id),
    ])
    .await;
    assert_eq!(test.view.name, new_name);
}

#[tokio::test]
async fn open_document_view() {
    let mut test = FolderTest::new().await;
    assert_eq!(test.document_info, None);

    test.run_scripts(vec![OpenDocument]).await;
    let document_info = test.document_info.unwrap();
    assert_eq!(document_info.text, initial_delta_string());
}

#[tokio::test]
#[should_panic]
async fn view_delete() {
    let mut test = FolderTest::new().await;
    let view = test.view.clone();
    test.run_scripts(vec![DeleteView, ReadView(view.id)]).await;
}

#[tokio::test]
async fn view_delete_then_restore() {
    let mut test = FolderTest::new().await;
    let view = test.view.clone();
    test.run_scripts(vec![
        DeleteView,
        RestoreViewFromTrash,
        ReadView(view.id.clone()),
        AssertView(view),
    ])
    .await;
}

#[tokio::test]
async fn view_delete_all() {
    let mut test = FolderTest::new().await;
    let app = test.app.clone();
    test.run_scripts(vec![
        CreateView {
            name: "View A",
            desc: "View A description",
        },
        CreateView {
            name: "View B",
            desc: "View B description",
        },
        ReadApp(app.id.clone()),
    ])
    .await;

    assert_eq!(test.app.belongings.len(), 3);
    let view_ids = test
        .app
        .belongings
        .iter()
        .map(|view| view.id.clone())
        .collect::<Vec<String>>();
    test.run_scripts(vec![DeleteViews(view_ids), ReadApp(app.id), ReadTrash])
        .await;

    assert_eq!(test.app.belongings.len(), 0);
    assert_eq!(test.trash.len(), 3);
}

#[tokio::test]
async fn view_delete_all_permanent() {
    let mut test = FolderTest::new().await;
    let app = test.app.clone();
    test.run_scripts(vec![
        CreateView {
            name: "View A",
            desc: "View A description",
        },
        ReadApp(app.id.clone()),
    ])
    .await;

    let view_ids = test
        .app
        .belongings
        .iter()
        .map(|view| view.id.clone())
        .collect::<Vec<String>>();
    test.run_scripts(vec![DeleteViews(view_ids), ReadApp(app.id), DeleteAllTrash, ReadTrash])
        .await;

    assert_eq!(test.app.belongings.len(), 0);
    assert_eq!(test.trash.len(), 0);
}

#[tokio::test]
async fn folder_sync_revision_state() {
    let mut test = FolderTest::new().await;
    test.run_scripts(vec![
        AssertRevisionState {
            rev_id: 1,
            state: RevisionState::Sync,
        },
        AssertNextSyncRevId(Some(1)),
        AssertRevisionState {
            rev_id: 1,
            state: RevisionState::Ack,
        },
    ])
    .await;
}

#[tokio::test]
async fn folder_sync_revision_seq() {
    let mut test = FolderTest::new().await;
    test.run_scripts(vec![
        AssertRevisionState {
            rev_id: 1,
            state: RevisionState::Sync,
        },
        AssertRevisionState {
            rev_id: 2,
            state: RevisionState::Sync,
        },
        AssertRevisionState {
            rev_id: 3,
            state: RevisionState::Sync,
        },
        AssertNextSyncRevId(Some(1)),
        AssertNextSyncRevId(Some(2)),
        AssertNextSyncRevId(Some(3)),
        AssertRevisionState {
            rev_id: 1,
            state: RevisionState::Ack,
        },
        AssertRevisionState {
            rev_id: 2,
            state: RevisionState::Ack,
        },
        AssertRevisionState {
            rev_id: 3,
            state: RevisionState::Ack,
        },
    ])
    .await;
}

#[tokio::test]
async fn folder_sync_revision_with_new_app() {
    let mut test = FolderTest::new().await;
    test.run_scripts(vec![
        AssertNextSyncRevId(Some(1)),
        AssertNextSyncRevId(Some(2)),
        AssertNextSyncRevId(Some(3)),
        CreateApp {
            name: "New App",
            desc: "",
        },
        AssertCurrentRevId(4),
        AssertNextSyncRevId(Some(4)),
        AssertNextSyncRevId(None),
    ])
    .await;
}

#[tokio::test]
async fn folder_sync_revision_with_new_view() {
    let mut test = FolderTest::new().await;
    test.run_scripts(vec![
        AssertNextSyncRevId(Some(1)),
        AssertNextSyncRevId(Some(2)),
        AssertNextSyncRevId(Some(3)),
        CreateView {
            name: "New App",
            desc: "",
        },
        AssertCurrentRevId(4),
        AssertNextSyncRevId(Some(4)),
        AssertNextSyncRevId(None),
    ])
    .await;
}
