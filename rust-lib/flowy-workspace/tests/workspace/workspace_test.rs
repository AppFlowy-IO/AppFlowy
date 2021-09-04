use crate::helper::*;
use flowy_test::{builder::*, FlowyEnv};
use flowy_workspace::{
    entities::workspace::{CreateWorkspaceRequest, QueryWorkspaceRequest, RepeatedWorkspace},
    event::WorkspaceEvent::*,
    prelude::*,
};

#[test]
fn workspace_create_success() {
    let sdk = FlowyEnv::setup().sdk;
    let _ = create_workspace(&sdk, "First workspace", "");
}

#[test]
fn workspace_read_all() {
    let sdk = FlowyEnv::setup().sdk;
    let _ = create_workspace(&sdk, "Workspace A", "workspace_create_and_then_get_workspace_success");

    let workspaces = WorkspaceTest::new(sdk.clone())
        .event(ReadWorkspaces)
        .request(QueryWorkspaceRequest::new())
        .sync_send()
        .parse::<RepeatedWorkspace>();

    dbg!(&workspaces);
}

#[test]
fn workspace_create_and_then_get_workspace() {
    let sdk = FlowyEnv::setup().sdk;
    let workspace = create_workspace(&sdk, "Workspace A", "workspace_create_and_then_get_workspace_success");
    let request = QueryWorkspaceRequest::new().workspace_id(&workspace.id);
    let workspace_from_db = read_workspaces(&sdk, request).unwrap();
    assert_eq!(workspace.name, workspace_from_db.name);
}

#[test]
fn workspace_create_with_apps() {
    let sdk = FlowyEnv::setup().sdk;
    let workspace = create_workspace(&sdk, "Workspace", "");
    let app = create_app(&sdk, "App A", "AppFlowy Github Project", &workspace.id);

    let request = QueryWorkspaceRequest::new().workspace_id(&workspace.id);
    let workspace_from_db = read_workspaces(&sdk, request).unwrap();
    assert_eq!(&app, workspace_from_db.apps.first_or_crash());
}

#[test]
fn workspace_create_with_invalid_name() {
    for name in invalid_workspace_name_test_case() {
        let sdk = FlowyEnv::setup().sdk;
        let request = CreateWorkspaceRequest { name, desc: "".to_owned() };
        assert_eq!(
            WorkspaceTest::new(sdk)
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
    let sdk = FlowyEnv::setup().sdk;
    for name in invalid_workspace_name_test_case() {
        let request = CreateWorkspaceRequest { name, desc: "".to_owned() };
        assert_eq!(
            WorkspaceTest::new(sdk.clone())
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
