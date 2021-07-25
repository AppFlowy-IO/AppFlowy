use crate::helper::*;
use flowy_workspace::{
    entities::workspace::{CreateWorkspaceRequest, QueryWorkspaceRequest, Workspace},
    event::WorkspaceEvent::*,
    prelude::*,
};

#[test]
fn workspace_create_success() { let _ = create_workspace("First workspace", ""); }

#[test]
fn workspace_get_success() {
    let workspace = SingleUserTestBuilder::new()
        .event(GetCurWorkspace)
        .sync_send()
        .parse::<Workspace>();

    dbg!(&workspace);
}

#[test]
fn workspace_create_and_then_get_workspace_success() {
    let workspace = create_workspace(
        "Workspace A",
        "workspace_create_and_then_get_workspace_success",
    );
    let request = QueryWorkspaceRequest {
        workspace_id: workspace.id.clone(),
        read_apps: false,
    };

    let workspace_from_db = get_workspace(request);
    assert_eq!(workspace.name, workspace_from_db.name);
}

#[test]
fn workspace_create_with_apps_success() {
    let workspace = create_workspace("Workspace B", "");
    let app = create_app("App A", "", &workspace.id);

    let query_workspace_request = QueryWorkspaceRequest {
        workspace_id: workspace.id.clone(),
        read_apps: true,
    };

    let workspace_from_db = get_workspace(query_workspace_request);
    assert_eq!(&app, workspace_from_db.apps.first_or_crash());
}

#[test]
fn workspace_create_with_invalid_name_test() {
    for name in invalid_workspace_name_test_case() {
        let request = CreateWorkspaceRequest {
            name,
            desc: "".to_owned(),
        };

        assert_eq!(
            SingleUserTestBuilder::new()
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
        let request = CreateWorkspaceRequest {
            name,
            desc: "".to_owned(),
        };

        assert_eq!(
            SingleUserTestBuilder::new()
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
