use std::{fs, path::PathBuf, sync::Arc};

use flowy_collaboration::entities::doc::DocumentInfo;
use flowy_core::{
    entities::{
        app::*,
        trash::{RepeatedTrash, TrashIdentifier},
        view::*,
        workspace::{CreateWorkspaceRequest, QueryWorkspaceRequest, Workspace, *},
    },
    errors::ErrorCode,
    event::WorkspaceEvent::{CreateWorkspace, OpenWorkspace, *},
};
use flowy_user::{
    entities::{SignInRequest, SignUpRequest, UserProfile},
    errors::FlowyError,
    event::UserEvent::{InitUser, SignIn, SignOut, SignUp},
};
use lib_dispatch::prelude::{EventDispatcher, ModuleRequest, ToBytes};
use lib_infra::uuid;

use crate::prelude::*;

pub struct WorkspaceTest {
    pub sdk: FlowySDKTest,
    pub workspace: Workspace,
}

impl WorkspaceTest {
    pub async fn new() -> Self {
        let sdk = FlowySDKTest::setup();
        let _ = sdk.init_user().await;
        let workspace = create_workspace(&sdk, "Workspace", "").await;
        open_workspace(&sdk, &workspace.id).await;

        Self { sdk, workspace }
    }
}

pub struct AppTest {
    pub sdk: FlowySDKTest,
    pub workspace: Workspace,
    pub app: App,
}

impl AppTest {
    pub async fn new() -> Self {
        let sdk = FlowySDKTest::setup();
        let _ = sdk.init_user().await;
        let workspace = create_workspace(&sdk, "Workspace", "").await;
        open_workspace(&sdk, &workspace.id).await;
        let app = create_app(&sdk, "App", "AppFlowy GitHub Project", &workspace.id).await;
        Self { sdk, workspace, app }
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
    pub sdk: FlowySDKTest,
    pub workspace: Workspace,
    pub app: App,
    pub view: View,
}

impl ViewTest {
    pub async fn new(sdk: &FlowySDKTest) -> Self {
        let workspace = create_workspace(&sdk, "Workspace", "").await;
        open_workspace(&sdk, &workspace.id).await;
        let app = create_app(&sdk, "App", "AppFlowy GitHub Project", &workspace.id).await;
        let view = create_view(&sdk, &app.id).await;
        Self {
            sdk: sdk.clone(),
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

        CoreModuleEventBuilder::new(self.sdk.clone())
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

pub async fn create_workspace(sdk: &FlowySDKTest, name: &str, desc: &str) -> Workspace {
    let request = CreateWorkspaceRequest {
        name: name.to_owned(),
        desc: desc.to_owned(),
    };

    let workspace = CoreModuleEventBuilder::new(sdk.clone())
        .event(CreateWorkspace)
        .request(request)
        .async_send()
        .await
        .parse::<Workspace>();
    workspace
}

async fn open_workspace(sdk: &FlowySDKTest, workspace_id: &str) {
    let request = QueryWorkspaceRequest {
        workspace_id: Some(workspace_id.to_owned()),
    };
    let _ = CoreModuleEventBuilder::new(sdk.clone())
        .event(OpenWorkspace)
        .request(request)
        .async_send()
        .await;
}

pub async fn read_workspace(sdk: &FlowySDKTest, request: QueryWorkspaceRequest) -> Vec<Workspace> {
    let repeated_workspace = CoreModuleEventBuilder::new(sdk.clone())
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

pub async fn create_app(sdk: &FlowySDKTest, name: &str, desc: &str, workspace_id: &str) -> App {
    let create_app_request = CreateAppRequest {
        workspace_id: workspace_id.to_owned(),
        name: name.to_string(),
        desc: desc.to_string(),
        color_style: Default::default(),
    };

    let app = CoreModuleEventBuilder::new(sdk.clone())
        .event(CreateApp)
        .request(create_app_request)
        .async_send()
        .await
        .parse::<App>();
    app
}

pub async fn delete_app(sdk: &FlowySDKTest, app_id: &str) {
    let delete_app_request = AppIdentifier {
        app_id: app_id.to_string(),
    };

    CoreModuleEventBuilder::new(sdk.clone())
        .event(DeleteApp)
        .request(delete_app_request)
        .async_send()
        .await;
}

pub async fn update_app(sdk: &FlowySDKTest, request: UpdateAppRequest) {
    CoreModuleEventBuilder::new(sdk.clone())
        .event(UpdateApp)
        .request(request)
        .async_send()
        .await;
}

pub async fn read_app(sdk: &FlowySDKTest, request: QueryAppRequest) -> App {
    let app = CoreModuleEventBuilder::new(sdk.clone())
        .event(ReadApp)
        .request(request)
        .async_send()
        .await
        .parse::<App>();

    app
}

pub async fn create_view_with_request(sdk: &FlowySDKTest, request: CreateViewRequest) -> View {
    let view = CoreModuleEventBuilder::new(sdk.clone())
        .event(CreateView)
        .request(request)
        .async_send()
        .await
        .parse::<View>();
    view
}

pub async fn create_view(sdk: &FlowySDKTest, app_id: &str) -> View {
    let request = CreateViewRequest {
        belong_to_id: app_id.to_string(),
        name: "View A".to_string(),
        desc: "".to_string(),
        thumbnail: Some("http://1.png".to_string()),
        view_type: ViewType::Doc,
    };

    create_view_with_request(sdk, request).await
}

pub async fn update_view(sdk: &FlowySDKTest, request: UpdateViewRequest) {
    CoreModuleEventBuilder::new(sdk.clone())
        .event(UpdateView)
        .request(request)
        .async_send()
        .await;
}

pub async fn read_view(sdk: &FlowySDKTest, request: QueryViewRequest) -> View {
    CoreModuleEventBuilder::new(sdk.clone())
        .event(ReadView)
        .request(request)
        .async_send()
        .await
        .parse::<View>()
}

pub async fn delete_view(sdk: &FlowySDKTest, request: QueryViewRequest) {
    CoreModuleEventBuilder::new(sdk.clone())
        .event(DeleteView)
        .request(request)
        .async_send()
        .await;
}

pub async fn read_trash(sdk: &FlowySDKTest) -> RepeatedTrash {
    CoreModuleEventBuilder::new(sdk.clone())
        .event(ReadTrash)
        .async_send()
        .await
        .parse::<RepeatedTrash>()
}

pub async fn putback_trash(sdk: &FlowySDKTest, id: TrashIdentifier) {
    CoreModuleEventBuilder::new(sdk.clone())
        .event(PutbackTrash)
        .request(id)
        .async_send()
        .await;
}

pub async fn open_view(sdk: &FlowySDKTest, request: QueryViewRequest) -> DocumentInfo {
    CoreModuleEventBuilder::new(sdk.clone())
        .event(OpenView)
        .request(request)
        .async_send()
        .await
        .parse::<DocumentInfo>()
}

pub fn root_dir() -> String {
    // https://doc.rust-lang.org/cargo/reference/environment-variables.html
    let manifest_dir = std::env::var("CARGO_MANIFEST_DIR").unwrap_or_else(|_| "./".to_owned());
    let mut path_buf = fs::canonicalize(&PathBuf::from(&manifest_dir)).unwrap();
    path_buf.pop(); // rust-lib
    path_buf.push("temp");
    path_buf.push("flowy");

    let root_dir = path_buf.to_str().unwrap().to_string();
    if !std::path::Path::new(&root_dir).exists() {
        std::fs::create_dir_all(&root_dir).unwrap();
    }
    root_dir
}

pub fn random_email() -> String { format!("{}@appflowy.io", uuid()) }

pub fn login_email() -> String { "annie2@appflowy.io".to_string() }

pub fn login_password() -> String { "HelloWorld!123".to_string() }

pub struct SignUpContext {
    pub user_profile: UserProfile,
    pub password: String,
}

pub fn sign_up(dispatch: Arc<EventDispatcher>) -> SignUpContext {
    let password = login_password();
    let payload = SignUpRequest {
        email: random_email(),
        name: "app flowy".to_string(),
        password: password.clone(),
    }
    .into_bytes()
    .unwrap();

    let request = ModuleRequest::new(SignUp).payload(payload);
    let user_profile = EventDispatcher::sync_send(dispatch, request)
        .parse::<UserProfile, FlowyError>()
        .unwrap()
        .unwrap();

    SignUpContext { user_profile, password }
}

pub async fn async_sign_up(dispatch: Arc<EventDispatcher>) -> SignUpContext {
    let password = login_password();
    let payload = SignUpRequest {
        email: random_email(),
        name: "app flowy".to_string(),
        password: password.clone(),
    }
    .into_bytes()
    .unwrap();

    let request = ModuleRequest::new(SignUp).payload(payload);
    let user_profile = EventDispatcher::async_send(dispatch.clone(), request)
        .await
        .parse::<UserProfile, FlowyError>()
        .unwrap()
        .unwrap();

    // let _ = create_default_workspace_if_need(dispatch.clone(), &user_profile.id);
    SignUpContext { user_profile, password }
}

pub async fn init_user_setting(dispatch: Arc<EventDispatcher>) {
    let request = ModuleRequest::new(InitUser);
    let _ = EventDispatcher::async_send(dispatch.clone(), request).await;
}

#[allow(dead_code)]
fn sign_in(dispatch: Arc<EventDispatcher>) -> UserProfile {
    let payload = SignInRequest {
        email: login_email(),
        password: login_password(),
        name: "rust".to_owned(),
    }
    .into_bytes()
    .unwrap();

    let request = ModuleRequest::new(SignIn).payload(payload);
    EventDispatcher::sync_send(dispatch, request)
        .parse::<UserProfile, FlowyError>()
        .unwrap()
        .unwrap()
}

#[allow(dead_code)]
fn logout(dispatch: Arc<EventDispatcher>) { let _ = EventDispatcher::sync_send(dispatch, ModuleRequest::new(SignOut)); }
