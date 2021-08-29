use crate::helper::*;
use flowy_workspace::{
    entities::workspace::{
        CreateWorkspaceRequest,
        QueryWorkspaceRequest,
        RepeatedWorkspace,
        Workspace,
    },
    event::WorkspaceEvent::*,
    prelude::*,
};

#[test]
fn workspace_create_success() { let _ = create_workspace("First workspace", ""); }

#[test]
fn workspace_get_success() {
    let builder = SingleUserTestBuilder::new();

    let _workspaces = SingleUserTestBuilder::new()
        .event(ReadAllWorkspace)
        .sync_send()
        .parse::<RepeatedWorkspace>();

    let workspace = builder
        .event(ReadCurWorkspace)
        .sync_send()
        .parse::<Workspace>();

    dbg!(&workspace);
}

#[test]
fn workspace_read_all_success() {
    let workspaces = SingleUserTestBuilder::new()
        .event(ReadAllWorkspace)
        .sync_send()
        .parse::<RepeatedWorkspace>();

    dbg!(&workspaces);
}

#[test]
fn workspace_create_and_then_get_workspace_success() {
    let (user_id, workspace) = create_workspace(
        "Workspace A",
        "workspace_create_and_then_get_workspace_success",
    );
    let request = QueryWorkspaceRequest {
        workspace_id: Some(workspace.id.clone()),
        user_id,
    };

    let workspace_from_db = read_workspaces(request).unwrap();
    assert_eq!(workspace.name, workspace_from_db.name);
}

#[test]
fn workspace_create_with_apps_success() {
    let (user_id, workspace) = create_workspace("Workspace", "");
    let app = create_app("App A", "AppFlowy Github Project", &workspace.id);

    let query_workspace_request = QueryWorkspaceRequest {
        workspace_id: Some(workspace.id),
        user_id,
    };

    let workspace_from_db = read_workspaces(query_workspace_request).unwrap();
    assert_eq!(&app, workspace_from_db.apps.first_or_crash());
}

#[test]
fn workspace_create_with_invalid_name_test() {
    for name in invalid_workspace_name_test_case() {
        let builder = SingleUserTestBuilder::new();
        let user_id = builder.user_detail.as_ref().unwrap().id.clone();

        let request = CreateWorkspaceRequest {
            name,
            desc: "".to_owned(),
            user_id: user_id.clone(),
        };

        assert_eq!(
            builder
                .event(CreateWorkspace)
                .request(request)
                .sync_send()
                .error()
                .code,
            WsErrCode::WorkspaceNameInvalid
        )
    }
}

#[test]
fn workspace_update_with_invalid_name_test() {
    for name in invalid_workspace_name_test_case() {
        let builder = SingleUserTestBuilder::new();
        let user_id = builder.user_detail.as_ref().unwrap().id.clone();

        let request = CreateWorkspaceRequest {
            name,
            desc: "".to_owned(),
            user_id: user_id.clone(),
        };

        assert_eq!(
            builder
                .event(CreateWorkspace)
                .request(request)
                .sync_send()
                .error()
                .code,
            WsErrCode::WorkspaceNameInvalid
        )
    }
}

// TODO 1) delete workspace, but can't delete the last workspace
