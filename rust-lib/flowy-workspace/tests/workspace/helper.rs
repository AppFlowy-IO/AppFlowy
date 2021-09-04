use flowy_test::prelude::*;
use flowy_workspace::{
    entities::{app::*, view::*, workspace::*},
    event::WorkspaceEvent::*,
};

pub(crate) fn invalid_workspace_name_test_case() -> Vec<String> {
    vec!["", "1234".repeat(100).as_str()]
        .iter()
        .map(|s| s.to_string())
        .collect::<Vec<_>>()
}

pub fn create_workspace(sdk: &FlowyTestSDK, name: &str, desc: &str) -> Workspace {
    let request = CreateWorkspaceRequest {
        name: name.to_owned(),
        desc: desc.to_owned(),
    };

    let workspace = WorkspaceTestBuilder::new(sdk.clone())
        .event(CreateWorkspace)
        .request(request)
        .sync_send()
        .parse::<Workspace>();
    workspace
}

pub fn read_workspaces(sdk: &FlowyTestSDK, request: QueryWorkspaceRequest) -> Option<Workspace> {
    let mut repeated_workspace = WorkspaceTestBuilder::new(sdk.clone())
        .event(ReadWorkspaces)
        .request(request)
        .sync_send()
        .parse::<RepeatedWorkspace>();

    debug_assert_eq!(repeated_workspace.len(), 1, "Default workspace not found");
    repeated_workspace.drain(..1).collect::<Vec<Workspace>>().pop()
}

pub fn create_app(sdk: &FlowyTestSDK, name: &str, desc: &str, workspace_id: &str) -> App {
    let create_app_request = CreateAppRequest {
        workspace_id: workspace_id.to_owned(),
        name: name.to_string(),
        desc: desc.to_string(),
        color_style: Default::default(),
    };

    let app = WorkspaceTestBuilder::new(sdk.clone())
        .event(CreateApp)
        .request(create_app_request)
        .sync_send()
        .parse::<App>();
    app
}

pub fn delete_app(sdk: &FlowyTestSDK, app_id: &str) {
    let delete_app_request = DeleteAppRequest {
        app_id: app_id.to_string(),
    };

    WorkspaceTestBuilder::new(sdk.clone())
        .event(DeleteApp)
        .request(delete_app_request)
        .sync_send();
}

pub fn update_app(sdk: &FlowyTestSDK, request: UpdateAppRequest) {
    WorkspaceTestBuilder::new(sdk.clone()).event(UpdateApp).request(request).sync_send();
}

pub fn read_app(sdk: &FlowyTestSDK, request: QueryAppRequest) -> App {
    let app = WorkspaceTestBuilder::new(sdk.clone())
        .event(ReadApp)
        .request(request)
        .sync_send()
        .parse::<App>();

    app
}

pub fn create_view_with_request(sdk: &FlowyTestSDK, request: CreateViewRequest) -> View {
    let view = WorkspaceTestBuilder::new(sdk.clone())
        .event(CreateView)
        .request(request)
        .sync_send()
        .parse::<View>();

    view
}

pub fn create_view(sdk: &FlowyTestSDK, workspace_id: &str) -> View {
    let app = create_app(sdk, "App A", "AppFlowy Github Project", workspace_id);
    let request = CreateViewRequest {
        belong_to_id: app.id.clone(),
        name: "View A".to_string(),
        desc: "".to_string(),
        thumbnail: Some("http://1.png".to_string()),
        view_type: ViewType::Doc,
    };

    create_view_with_request(sdk, request)
}

pub fn update_view(sdk: &FlowyTestSDK, request: UpdateViewRequest) {
    WorkspaceTestBuilder::new(sdk.clone())
        .event(UpdateView)
        .request(request)
        .sync_send();
}

pub fn read_view(sdk: &FlowyTestSDK, request: QueryViewRequest) -> View {
    WorkspaceTestBuilder::new(sdk.clone())
        .event(ReadView)
        .request(request)
        .sync_send()
        .parse::<View>()
}
