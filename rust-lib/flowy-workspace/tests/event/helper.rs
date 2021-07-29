pub use flowy_test::builder::SingleUserTestBuilder;
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

    let workspace = SingleUserTestBuilder::new()
        .event(CreateWorkspace)
        .request(request)
        .sync_send()
        .parse::<Workspace>();

    workspace
}

pub fn read_workspace(request: QueryWorkspaceRequest) -> Workspace {
    let workspace = SingleUserTestBuilder::new()
        .event(ReadWorkspace)
        .request(request)
        .sync_send()
        .parse::<Workspace>();

    workspace
}

pub fn create_app(name: &str, desc: &str) -> App {
    let workspace = create_workspace("Workspace", "");

    let create_app_request = CreateAppRequest {
        workspace_id: workspace.id,
        name: name.to_string(),
        desc: desc.to_string(),
        color_style: Default::default(),
    };

    let app = SingleUserTestBuilder::new()
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

    SingleUserTestBuilder::new()
        .event(DeleteApp)
        .request(delete_app_request)
        .sync_send();
}

pub fn update_app(request: UpdateAppRequest) {
    SingleUserTestBuilder::new()
        .event(UpdateApp)
        .request(request)
        .sync_send();
}

pub fn read_app(request: QueryAppRequest) -> App {
    let app = SingleUserTestBuilder::new()
        .event(ReadApp)
        .request(request)
        .sync_send()
        .parse::<App>();

    app
}

pub fn create_view_with_request(request: CreateViewRequest) -> View {
    let view = SingleUserTestBuilder::new()
        .event(CreateView)
        .request(request)
        .sync_send()
        .parse::<View>();

    view
}

pub fn create_view() -> View {
    let app = create_app("App A", "AppFlowy Github Project");
    let request = CreateViewRequest {
        belong_to_id: app.id.clone(),
        name: "View A".to_string(),
        desc: "".to_string(),
        thumbnail: None,
        view_type: ViewType::Doc,
    };

    create_view_with_request(request)
}

pub fn update_view(request: UpdateViewRequest) {
    SingleUserTestBuilder::new()
        .event(UpdateView)
        .request(request)
        .sync_send();
}

pub fn read_view(request: QueryViewRequest) -> View {
    SingleUserTestBuilder::new()
        .event(ReadView)
        .request(request)
        .sync_send()
        .parse::<View>()
}
