use crate::prelude::*;
use flowy_document::entities::doc::Doc;
use flowy_workspace::{
    entities::{
        app::*,
        trash::{RepeatedTrash, TrashIdentifier},
        view::*,
        workspace::*,
    },
    errors::ErrorCode,
    event::WorkspaceEvent::*,
};

pub struct WorkspaceTest {
    pub sdk: FlowyTestSDK,
    pub workspace: Workspace,
}

impl WorkspaceTest {
    pub async fn new() -> Self {
        let test = FlowyTest::setup();
        let _ = test.init_user().await;
        let workspace = create_workspace(&test.sdk, "Workspace", "").await;
        open_workspace(&test.sdk, &workspace.id).await;

        Self {
            sdk: test.sdk,
            workspace,
        }
    }
}

pub struct AppTest {
    pub sdk: FlowyTestSDK,
    pub workspace: Workspace,
    pub app: App,
}

impl AppTest {
    pub async fn new() -> Self {
        let test = FlowyTest::setup();
        let _ = test.init_user().await;
        let workspace = create_workspace(&test.sdk, "Workspace", "").await;
        open_workspace(&test.sdk, &workspace.id).await;
        let app = create_app(&test.sdk, "App", "AppFlowy Github Project", &workspace.id).await;
        Self {
            sdk: test.sdk,
            workspace,
            app,
        }
    }

    pub async fn move_app_to_trash(&self) {
        let request = UpdateAppRequest {
            app_id: self.app.id.clone(),
            name: None,
            desc: None,
            color_style: None,
            is_trash: Some(true),
        };
        update_app(&self.sdk, request).await;
    }
}

pub struct ViewTest {
    pub sdk: FlowyTestSDK,
    pub workspace: Workspace,
    pub app: App,
    pub view: View,
}

impl ViewTest {
    pub async fn new(test: &FlowyTest) -> Self {
        let workspace = create_workspace(&test.sdk, "Workspace", "").await;
        open_workspace(&test.sdk, &workspace.id).await;
        let app = create_app(&test.sdk, "App", "AppFlowy Github Project", &workspace.id).await;
        let view = create_view(&test.sdk, &app.id).await;
        Self {
            sdk: test.sdk.clone(),
            workspace,
            app,
            view,
        }
    }

    pub async fn delete_views(&self, view_ids: Vec<String>) {
        let request = QueryViewRequest { view_ids };
        delete_view(&self.sdk, request).await;
    }

    pub async fn delete_views_permanent(&self, view_ids: Vec<String>) {
        let request = QueryViewRequest { view_ids };
        delete_view(&self.sdk, request).await;

        FlowyWorkspaceTest::new(self.sdk.clone())
            .event(DeleteAll)
            .async_send()
            .await;
    }
}

pub fn invalid_workspace_name_test_case() -> Vec<(String, ErrorCode)> {
    vec![
        ("".to_owned(), ErrorCode::WorkspaceNameInvalid),
        ("1234".repeat(100), ErrorCode::WorkspaceNameTooLong),
    ]
}

pub async fn create_workspace(sdk: &FlowyTestSDK, name: &str, desc: &str) -> Workspace {
    let request = CreateWorkspaceRequest {
        name: name.to_owned(),
        desc: desc.to_owned(),
    };

    let workspace = FlowyWorkspaceTest::new(sdk.clone())
        .event(CreateWorkspace)
        .request(request)
        .async_send()
        .await
        .parse::<Workspace>();
    workspace
}

async fn open_workspace(sdk: &FlowyTestSDK, workspace_id: &str) {
    let request = QueryWorkspaceRequest {
        workspace_id: Some(workspace_id.to_owned()),
    };
    let _ = FlowyWorkspaceTest::new(sdk.clone())
        .event(OpenWorkspace)
        .request(request)
        .async_send()
        .await;
}

pub async fn read_workspace(sdk: &FlowyTestSDK, request: QueryWorkspaceRequest) -> Vec<Workspace> {
    let mut repeated_workspace = FlowyWorkspaceTest::new(sdk.clone())
        .event(ReadWorkspaces)
        .request(request.clone())
        .async_send()
        .await
        .parse::<RepeatedWorkspace>();

    let workspaces;
    if let Some(workspace_id) = &request.workspace_id {
        workspaces = repeated_workspace
            .into_inner()
            .into_iter()
            .filter(|workspace| &workspace.id == workspace_id)
            .collect::<Vec<Workspace>>();
        debug_assert_eq!(workspaces.len(), 1);
    } else {
        workspaces = repeated_workspace.items;
    }

    workspaces
}

pub async fn create_app(sdk: &FlowyTestSDK, name: &str, desc: &str, workspace_id: &str) -> App {
    let create_app_request = CreateAppRequest {
        workspace_id: workspace_id.to_owned(),
        name: name.to_string(),
        desc: desc.to_string(),
        color_style: Default::default(),
    };

    let app = FlowyWorkspaceTest::new(sdk.clone())
        .event(CreateApp)
        .request(create_app_request)
        .async_send()
        .await
        .parse::<App>();
    app
}

pub async fn delete_app(sdk: &FlowyTestSDK, app_id: &str) {
    let delete_app_request = AppIdentifier {
        app_id: app_id.to_string(),
    };

    FlowyWorkspaceTest::new(sdk.clone())
        .event(DeleteApp)
        .request(delete_app_request)
        .async_send()
        .await;
}

pub async fn update_app(sdk: &FlowyTestSDK, request: UpdateAppRequest) {
    FlowyWorkspaceTest::new(sdk.clone())
        .event(UpdateApp)
        .request(request)
        .async_send()
        .await;
}

pub async fn read_app(sdk: &FlowyTestSDK, request: QueryAppRequest) -> App {
    let app = FlowyWorkspaceTest::new(sdk.clone())
        .event(ReadApp)
        .request(request)
        .async_send()
        .await
        .parse::<App>();

    app
}

pub async fn create_view_with_request(sdk: &FlowyTestSDK, request: CreateViewRequest) -> View {
    let view = FlowyWorkspaceTest::new(sdk.clone())
        .event(CreateView)
        .request(request)
        .async_send()
        .await
        .parse::<View>();
    view
}

pub async fn create_view(sdk: &FlowyTestSDK, app_id: &str) -> View {
    let request = CreateViewRequest {
        belong_to_id: app_id.to_string(),
        name: "View A".to_string(),
        desc: "".to_string(),
        thumbnail: Some("http://1.png".to_string()),
        view_type: ViewType::Doc,
    };

    create_view_with_request(sdk, request).await
}

pub async fn update_view(sdk: &FlowyTestSDK, request: UpdateViewRequest) {
    FlowyWorkspaceTest::new(sdk.clone())
        .event(UpdateView)
        .request(request)
        .async_send()
        .await;
}

pub async fn read_view(sdk: &FlowyTestSDK, request: QueryViewRequest) -> View {
    FlowyWorkspaceTest::new(sdk.clone())
        .event(ReadView)
        .request(request)
        .async_send()
        .await
        .parse::<View>()
}

pub async fn delete_view(sdk: &FlowyTestSDK, request: QueryViewRequest) {
    FlowyWorkspaceTest::new(sdk.clone())
        .event(DeleteView)
        .request(request)
        .async_send()
        .await;
}

pub async fn read_trash(sdk: &FlowyTestSDK) -> RepeatedTrash {
    FlowyWorkspaceTest::new(sdk.clone())
        .event(ReadTrash)
        .async_send()
        .await
        .parse::<RepeatedTrash>()
}

pub async fn putback_trash(sdk: &FlowyTestSDK, id: TrashIdentifier) {
    FlowyWorkspaceTest::new(sdk.clone())
        .event(PutbackTrash)
        .request(id)
        .async_send()
        .await;
}

pub async fn open_view(sdk: &FlowyTestSDK, request: QueryViewRequest) -> Doc {
    FlowyWorkspaceTest::new(sdk.clone())
        .event(OpenView)
        .request(request)
        .async_send()
        .await
        .parse::<Doc>()
}
