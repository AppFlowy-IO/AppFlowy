use crate::helper::*;
use flowy_workspace::{
    entities::workspace::{CreateWorkspaceRequest, UserWorkspaceDetail, WorkspaceDetail},
    event::WorkspaceEvent::*,
    prelude::*,
};

#[test]
fn workspace_create_success() {
    let request = CreateWorkspaceRequest {
        name: "123".to_owned(),
        desc: "".to_owned(),
    };

    let response = WorkspaceTestBuilder::new()
        .event(CreateWorkspace)
        .request(request)
        .sync_send()
        .parse::<WorkspaceDetail>();
    dbg!(&response);
}

#[test]
fn workspace_get_detail_success() {
    let user_workspace = WorkspaceTestBuilder::new()
        .event(GetWorkspaceDetail)
        .sync_send()
        .parse::<UserWorkspaceDetail>();

    dbg!(&user_workspace);
}

#[test]
fn workspace_create_and_then_get_detail_success() {
    let request = CreateWorkspaceRequest {
        name: "Team A".to_owned(),
        desc: "Team A Description".to_owned(),
    };

    let workspace = WorkspaceTestBuilder::new()
        .event(CreateWorkspace)
        .request(request)
        .sync_send()
        .parse::<WorkspaceDetail>();

    let user_workspace = WorkspaceTestBuilder::new()
        .event(GetWorkspaceDetail)
        .sync_send()
        .parse::<UserWorkspaceDetail>();

    assert_eq!(workspace.name, user_workspace.workspace.name);
}

#[test]
fn workspace_create_with_invalid_name_test() {
    for name in invalid_workspace_name_test_case() {
        let request = CreateWorkspaceRequest {
            name,
            desc: "".to_owned(),
        };

        assert_eq!(
            WorkspaceTestBuilder::new()
                .event(CreateWorkspace)
                .request(request)
                .sync_send()
                .error()
                .code,
            WorkspaceErrorCode::WorkspaceNameInvalid
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
            WorkspaceTestBuilder::new()
                .event(CreateWorkspace)
                .request(request)
                .sync_send()
                .error()
                .code,
            WorkspaceErrorCode::WorkspaceNameInvalid
        )
    }
}

// TODO 1) delete workspace, but can't delete the last workspace
