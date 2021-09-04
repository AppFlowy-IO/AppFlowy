use flowy_test::builder::{UserTestBuilder, WorkspaceTestBuilder};
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

pub fn create_workspace(name: &str, desc: &str) -> Workspace {
    let request = CreateWorkspaceRequest {
        name: name.to_owned(),
        desc: desc.to_owned(),
    };

    let workspace = WorkspaceTestBuilder::new()
        .event(CreateWorkspace)
        .request(request)
        .sync_send()
        .parse::<Workspace>();
    workspace
}

pub fn read_workspaces(request: QueryWorkspaceRequest) -> Option<Workspace> {
    let mut repeated_workspace = WorkspaceTestBuilder::new()
        .event(ReadWorkspaces)
        .request(request)
        .sync_send()
        .parse::<RepeatedWorkspace>();

    debug_assert_eq!(repeated_workspace.len(), 1, "Default workspace not found");
    repeated_workspace.drain(..1).collect::<Vec<Workspace>>().pop()
}

pub fn create_app(name: &str, desc: &str, workspace_id: &str) -> App {
    let create_app_request = CreateAppRequest {
        workspace_id: workspace_id.to_owned(),
        name: name.to_string(),
        desc: desc.to_string(),
        color_style: Default::default(),
    };

    let app = WorkspaceTestBuilder::new()
        .event(CreateApp)
        .request(create_app_request)
        .sync_send()
        .parse::<App>();
    app
}

pub fn delete_app(app_id: &str) {
    let delete_app_request = DeleteAppRequest {
        app_id: app_id.to_string(),
    };

    WorkspaceTestBuilder::new().event(DeleteApp).request(delete_app_request).sync_send();
}

pub fn update_app(request: UpdateAppRequest) { WorkspaceTestBuilder::new().event(UpdateApp).request(request).sync_send(); }

pub fn read_app(request: QueryAppRequest) -> App {
    let app = WorkspaceTestBuilder::new()
        .event(ReadApp)
        .request(request)
        .sync_send()
        .parse::<App>();

    app
}

pub fn create_view_with_request(request: CreateViewRequest) -> View {
    let view = WorkspaceTestBuilder::new()
        .event(CreateView)
        .request(request)
        .sync_send()
        .parse::<View>();

    view
}

pub fn create_view(workspace_id: &str) -> View {
    let app = create_app("App A", "AppFlowy Github Project", workspace_id);
    let request = CreateViewRequest {
        belong_to_id: app.id.clone(),
        name: "View A".to_string(),
        desc: "".to_string(),
        thumbnail: Some("http://1.png".to_string()),
        view_type: ViewType::Doc,
    };

    create_view_with_request(request)
}

pub fn update_view(request: UpdateViewRequest) { WorkspaceTestBuilder::new().event(UpdateView).request(request).sync_send(); }

pub fn read_view(request: QueryViewRequest) -> View {
    WorkspaceTestBuilder::new()
        .event(ReadView)
        .request(request)
        .sync_send()
        .parse::<View>()
}
