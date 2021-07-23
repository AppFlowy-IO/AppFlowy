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

pub fn create_app(name: &str, desc: &str, workspace_id: &str) -> App {
    let create_app_request = CreateAppRequest {
        workspace_id: workspace_id.to_string(),
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

pub fn get_workspace(request: QueryWorkspaceRequest) -> Workspace {
    let workspace = SingleUserTestBuilder::new()
        .event(GetWorkspace)
        .request(request)
        .sync_send()
        .parse::<Workspace>();

    workspace
}

pub fn get_app(request: QueryAppRequest) -> App {
    let app = SingleUserTestBuilder::new()
        .event(GetApp)
        .request(request)
        .sync_send()
        .parse::<App>();

    app
}

pub fn create_view(request: CreateViewRequest) -> View {
    let view = SingleUserTestBuilder::new()
        .event(CreateView)
        .request(request)
        .sync_send()
        .parse::<View>();

    view
}
