use crate::prelude::*;
use flowy_folder::prelude::WorkspaceId;
use flowy_folder::{
    entities::{
        app::*,
        view::*,
        workspace::{CreateWorkspacePayload, Workspace},
    },
    event_map::FolderEvent::{CreateWorkspace, OpenWorkspace, *},
};
use flowy_user::{
    entities::{SignInPayload, SignUpPayload, UserProfile},
    errors::FlowyError,
    event_map::UserEvent::{InitUser, SignIn, SignOut, SignUp},
};
use lib_dispatch::prelude::{EventDispatcher, ModuleRequest, ToBytes};
use lib_infra::uuid_string;
use std::{fs, path::PathBuf, sync::Arc};

pub struct ViewTest {
    pub sdk: FlowySDKTest,
    pub workspace: Workspace,
    pub app: App,
    pub view: View,
}

impl ViewTest {
    pub async fn new(sdk: &FlowySDKTest) -> Self {
        let workspace = create_workspace(sdk, "Workspace", "").await;
        open_workspace(sdk, &workspace.id).await;
        let app = create_app(sdk, "App", "AppFlowy GitHub Project", &workspace.id).await;
        let view = create_view(sdk, &app.id).await;
        Self {
            sdk: sdk.clone(),
            workspace,
            app,
            view,
        }
    }
}

async fn create_workspace(sdk: &FlowySDKTest, name: &str, desc: &str) -> Workspace {
    let request = CreateWorkspacePayload {
        name: name.to_owned(),
        desc: desc.to_owned(),
    };

    let workspace = FolderEventBuilder::new(sdk.clone())
        .event(CreateWorkspace)
        .payload(request)
        .async_send()
        .await
        .parse::<Workspace>();
    workspace
}

async fn open_workspace(sdk: &FlowySDKTest, workspace_id: &str) {
    let payload = WorkspaceId {
        value: Some(workspace_id.to_owned()),
    };
    let _ = FolderEventBuilder::new(sdk.clone())
        .event(OpenWorkspace)
        .payload(payload)
        .async_send()
        .await;
}

async fn create_app(sdk: &FlowySDKTest, name: &str, desc: &str, workspace_id: &str) -> App {
    let create_app_request = CreateAppPayload {
        workspace_id: workspace_id.to_owned(),
        name: name.to_string(),
        desc: desc.to_string(),
        color_style: Default::default(),
    };

    let app = FolderEventBuilder::new(sdk.clone())
        .event(CreateApp)
        .payload(create_app_request)
        .async_send()
        .await
        .parse::<App>();
    app
}

async fn create_view(sdk: &FlowySDKTest, app_id: &str) -> View {
    let request = CreateViewPayload {
        belong_to_id: app_id.to_string(),
        name: "View A".to_string(),
        desc: "".to_string(),
        thumbnail: Some("http://1.png".to_string()),
        view_type: ViewType::QuillDocument,
    };

    let view = FolderEventBuilder::new(sdk.clone())
        .event(CreateView)
        .payload(request)
        .async_send()
        .await
        .parse::<View>();
    view
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

pub fn random_email() -> String {
    format!("{}@appflowy.io", uuid_string())
}

pub fn login_email() -> String {
    "annie2@appflowy.io".to_string()
}

pub fn login_password() -> String {
    "HelloWorld!123".to_string()
}

pub struct SignUpContext {
    pub user_profile: UserProfile,
    pub password: String,
}

pub fn sign_up(dispatch: Arc<EventDispatcher>) -> SignUpContext {
    let password = login_password();
    let payload = SignUpPayload {
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
    let payload = SignUpPayload {
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
    let payload = SignInPayload {
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
fn logout(dispatch: Arc<EventDispatcher>) {
    let _ = EventDispatcher::sync_send(dispatch, ModuleRequest::new(SignOut));
}
