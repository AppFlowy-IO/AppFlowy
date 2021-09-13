use flowy_document::entities::doc::Doc;
use flowy_test::prelude::*;
use flowy_workspace::{
    entities::{app::*, view::*, workspace::*},
    event::WorkspaceEvent::*,
};

pub struct WorkspaceTest {
    pub sdk: FlowyTestSDK,
    pub workspace: Workspace,
}

impl WorkspaceTest {
    pub fn new() -> Self {
        let sdk = FlowyEnv::setup().sdk;
        let workspace = create_workspace(&sdk, "Workspace", "");
        open_workspace(&sdk, &workspace.id);

        Self { sdk, workspace }
    }
}

pub struct AppTest {
    pub sdk: FlowyTestSDK,
    pub workspace: Workspace,
    pub app: App,
}

impl AppTest {
    pub fn new() -> Self {
        let sdk = FlowyEnv::setup().sdk;
        let workspace = create_workspace(&sdk, "Workspace", "");
        open_workspace(&sdk, &workspace.id);
        let app = create_app(&sdk, "App", "AppFlowy Github Project", &workspace.id);
        Self { sdk, workspace, app }
    }

    pub fn move_app_to_trash(&self) {
        let request = UpdateAppRequest {
            app_id: self.app.id.clone(),
            name: None,
            desc: None,
            color_style: None,
            is_trash: Some(true),
        };
        update_app(&self.sdk, request);
    }
}

pub(crate) struct ViewTest {
    pub sdk: FlowyTestSDK,
    pub workspace: Workspace,
    pub app: App,
    pub view: View,
}

impl ViewTest {
    pub fn new() -> Self {
        let sdk = FlowyEnv::setup().sdk;
        let workspace = create_workspace(&sdk, "Workspace", "");
        open_workspace(&sdk, &workspace.id);
        let app = create_app(&sdk, "App", "AppFlowy Github Project", &workspace.id);
        let view = create_view(&sdk, &app.id);
        Self { sdk, workspace, app, view }
    }

    pub fn move_view_to_trash(&self) {
        let request = UpdateViewRequest {
            view_id: self.view.id.clone(),
            name: None,
            desc: None,
            thumbnail: None,
            is_trash: Some(true),
        };
        update_view(&self.sdk, request);
    }
}

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

    let workspace = FlowyWorkspaceTest::new(sdk.clone())
        .event(CreateWorkspace)
        .request(request)
        .sync_send()
        .parse::<Workspace>();
    workspace
}

fn open_workspace(sdk: &FlowyTestSDK, workspace_id: &str) {
    let request = QueryWorkspaceRequest {
        workspace_id: Some(workspace_id.to_owned()),
    };
    let _ = FlowyWorkspaceTest::new(sdk.clone())
        .event(OpenWorkspace)
        .request(request)
        .sync_send();
}

pub fn read_workspace(sdk: &FlowyTestSDK, request: QueryWorkspaceRequest) -> Option<Workspace> {
    let mut repeated_workspace = FlowyWorkspaceTest::new(sdk.clone())
        .event(ReadWorkspaces)
        .request(request.clone())
        .sync_send()
        .parse::<RepeatedWorkspace>();

    let mut workspaces;
    if let Some(workspace_id) = &request.workspace_id {
        workspaces = repeated_workspace
            .take_items()
            .into_iter()
            .filter(|workspace| &workspace.id == workspace_id)
            .collect::<Vec<Workspace>>();
        debug_assert_eq!(workspaces.len(), 1);
    } else {
        workspaces = repeated_workspace.items;
    }

    workspaces.drain(..1).collect::<Vec<Workspace>>().pop()
}

pub fn create_app(sdk: &FlowyTestSDK, name: &str, desc: &str, workspace_id: &str) -> App {
    let create_app_request = CreateAppRequest {
        workspace_id: workspace_id.to_owned(),
        name: name.to_string(),
        desc: desc.to_string(),
        color_style: Default::default(),
    };

    let app = FlowyWorkspaceTest::new(sdk.clone())
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

    FlowyWorkspaceTest::new(sdk.clone())
        .event(DeleteApp)
        .request(delete_app_request)
        .sync_send();
}

pub fn update_app(sdk: &FlowyTestSDK, request: UpdateAppRequest) {
    FlowyWorkspaceTest::new(sdk.clone()).event(UpdateApp).request(request).sync_send();
}

pub fn read_app(sdk: &FlowyTestSDK, request: QueryAppRequest) -> App {
    let app = FlowyWorkspaceTest::new(sdk.clone())
        .event(ReadApp)
        .request(request)
        .sync_send()
        .parse::<App>();

    app
}

pub fn create_view_with_request(sdk: &FlowyTestSDK, request: CreateViewRequest) -> View {
    let view = FlowyWorkspaceTest::new(sdk.clone())
        .event(CreateView)
        .request(request)
        .sync_send()
        .parse::<View>();

    view
}

pub fn create_view(sdk: &FlowyTestSDK, app_id: &str) -> View {
    let request = CreateViewRequest {
        belong_to_id: app_id.to_string(),
        name: "View A".to_string(),
        desc: "".to_string(),
        thumbnail: Some("http://1.png".to_string()),
        view_type: ViewType::Doc,
    };

    create_view_with_request(sdk, request)
}

pub fn update_view(sdk: &FlowyTestSDK, request: UpdateViewRequest) {
    FlowyWorkspaceTest::new(sdk.clone()).event(UpdateView).request(request).sync_send();
}

pub fn read_view(sdk: &FlowyTestSDK, request: QueryViewRequest) -> View {
    FlowyWorkspaceTest::new(sdk.clone())
        .event(ReadView)
        .request(request)
        .sync_send()
        .parse::<View>()
}

pub fn open_view(sdk: &FlowyTestSDK, request: OpenViewRequest) -> Doc {
    FlowyWorkspaceTest::new(sdk.clone())
        .event(OpenView)
        .request(request)
        .sync_send()
        .parse::<Doc>()
}

pub fn update_view_data(sdk: &FlowyTestSDK, request: UpdateViewDataRequest) {
    FlowyWorkspaceTest::new(sdk.clone())
        .event(UpdateViewData)
        .request(request)
        .sync_send();
}
