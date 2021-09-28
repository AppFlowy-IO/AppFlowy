use flowy_test::{builder::*, workspace::*, FlowyTest};
use flowy_workspace::{
    entities::workspace::{CreateWorkspaceRequest, QueryWorkspaceRequest},
    event::WorkspaceEvent::*,
    prelude::*,
};

#[tokio::test]
async fn workspace_read_all() {
    let test = WorkspaceTest::new().await;
    let workspace = read_workspace(&test.sdk, QueryWorkspaceRequest::new()).unwrap();
    assert_eq!(test.workspace, workspace);
}

#[tokio::test]
async fn workspace_read() {
    let test = WorkspaceTest::new().await;
    let request = QueryWorkspaceRequest::new().workspace_id(&test.workspace.id);
    let workspace = read_workspace(&test.sdk, request).unwrap();
    assert_eq!(test.workspace, workspace);
}

#[tokio::test]
async fn workspace_create_with_apps() {
    let test = WorkspaceTest::new().await;
    let app = create_app(&test.sdk, "App A", "AppFlowy Github Project", &test.workspace.id).await;
    let request = QueryWorkspaceRequest::new().workspace_id(&test.workspace.id);
    let workspace_from_db = read_workspace(&test.sdk, request).unwrap();
    assert_eq!(&app, workspace_from_db.apps.first_or_crash());
}

#[test]
fn workspace_create_with_invalid_name() {
    for name in invalid_workspace_name_test_case() {
        let sdk = FlowyTest::setup().sdk;
        let request = CreateWorkspaceRequest {
            name,
            desc: "".to_owned(),
        };
        assert_eq!(
            FlowyWorkspaceTest::new(sdk)
                .event(CreateWorkspace)
                .request(request)
                .sync_send()
                .error()
                .code,
            ErrorCode::WorkspaceNameInvalid
        )
    }
}

#[test]
fn workspace_update_with_invalid_name() {
    let sdk = FlowyTest::setup().sdk;
    for name in invalid_workspace_name_test_case() {
        let request = CreateWorkspaceRequest {
            name,
            desc: "".to_owned(),
        };
        assert_eq!(
            FlowyWorkspaceTest::new(sdk.clone())
                .event(CreateWorkspace)
                .request(request)
                .sync_send()
                .error()
                .code,
            ErrorCode::WorkspaceNameInvalid
        )
    }
}

// TODO 1) delete workspace, but can't delete the last workspace
