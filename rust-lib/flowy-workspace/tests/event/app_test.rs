use flowy_test::builder::WorkspaceTestBuilder;
use flowy_workspace::{
    entities::{
        app::{App, CreateAppRequest},
        workspace::Workspace,
    },
    event::WorkspaceEvent::{CreateApp, GetCurWorkspace},
};

#[test]
fn app_create_success() {
    let user_workspace = WorkspaceTestBuilder::new()
        .event(GetCurWorkspace)
        .sync_send()
        .parse::<Workspace>();

    let request = CreateAppRequest {
        workspace_id: user_workspace.id,
        name: "Github".to_owned(),
        desc: "AppFlowy Github Project".to_owned(),
        color_style: Default::default(),
    };

    let app_detail = WorkspaceTestBuilder::new()
        .event(CreateApp)
        .request(request)
        .sync_send()
        .parse::<App>();

    dbg!(&app_detail);
}

#[test]
fn app_list_from_cur_workspace_test() {
    let user_workspace = WorkspaceTestBuilder::new()
        .event(GetCurWorkspace)
        .sync_send()
        .parse::<Workspace>();

    let request = CreateAppRequest {
        workspace_id: user_workspace.id,
        name: "Github".to_owned(),
        desc: "AppFlowy Github Project".to_owned(),
        color_style: Default::default(),
    };

    let app_detail = WorkspaceTestBuilder::new()
        .event(CreateApp)
        .request(request)
        .sync_send()
        .parse::<App>();

    dbg!(&app_detail);
}

// TODO 1) test update app 2) delete app
