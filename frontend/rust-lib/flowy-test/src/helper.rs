use crate::prelude::*;
use flowy_folder::entities::WorkspaceIdPB;
use flowy_folder::{
    entities::{
        app::*,
        view::*,
        workspace::{CreateWorkspacePayloadPB, WorkspacePB},
    },
    event_map::FolderEvent::{CreateWorkspace, OpenWorkspace, *},
};
use flowy_user::{
    entities::{SignInPayloadPB, SignUpPayloadPB, UserProfilePB},
    errors::FlowyError,
    event_map::UserEvent::{InitUser, SignIn, SignOut, SignUp},
};
use lib_dispatch::prelude::{EventDispatcher, ModuleRequest, ToBytes};
use std::{fs, path::PathBuf, sync::Arc};

pub struct ViewTest {
    pub sdk: FlowySDKTest,
    pub workspace: WorkspacePB,
    pub app: AppPB,
    pub view: ViewPB,
}

impl ViewTest {
    #[allow(dead_code)]
    pub async fn new(sdk: &FlowySDKTest, data_type: ViewDataFormatPB, layout: ViewLayoutTypePB, data: Vec<u8>) -> Self {
        let workspace = create_workspace(sdk, "Workspace", "").await;
        open_workspace(sdk, &workspace.id).await;
        let app = create_app(sdk, "App", "AppFlowy GitHub Project", &workspace.id).await;
        let view = create_view(sdk, &app.id, data_type, layout, data).await;
        Self {
            sdk: sdk.clone(),
            workspace,
            app,
            view,
        }
    }

    pub async fn new_grid_view(sdk: &FlowySDKTest, data: Vec<u8>) -> Self {
        Self::new(sdk, ViewDataFormatPB::DatabaseFormat, ViewLayoutTypePB::Grid, data).await
    }

    pub async fn new_board_view(sdk: &FlowySDKTest, data: Vec<u8>) -> Self {
        Self::new(sdk, ViewDataFormatPB::DatabaseFormat, ViewLayoutTypePB::Board, data).await
    }

    pub async fn new_document_view(sdk: &FlowySDKTest) -> Self {
        Self::new(sdk, ViewDataFormatPB::DeltaFormat, ViewLayoutTypePB::Document, vec![]).await
    }
}

async fn create_workspace(sdk: &FlowySDKTest, name: &str, desc: &str) -> WorkspacePB {
    let request = CreateWorkspacePayloadPB {
        name: name.to_owned(),
        desc: desc.to_owned(),
    };

    let workspace = FolderEventBuilder::new(sdk.clone())
        .event(CreateWorkspace)
        .payload(request)
        .async_send()
        .await
        .parse::<WorkspacePB>();
    workspace
}

async fn open_workspace(sdk: &FlowySDKTest, workspace_id: &str) {
    let payload = WorkspaceIdPB {
        value: Some(workspace_id.to_owned()),
    };
    let _ = FolderEventBuilder::new(sdk.clone())
        .event(OpenWorkspace)
        .payload(payload)
        .async_send()
        .await;
}

async fn create_app(sdk: &FlowySDKTest, name: &str, desc: &str, workspace_id: &str) -> AppPB {
    let create_app_request = CreateAppPayloadPB {
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
        .parse::<AppPB>();
    app
}

async fn create_view(
    sdk: &FlowySDKTest,
    app_id: &str,
    data_type: ViewDataFormatPB,
    layout: ViewLayoutTypePB,
    data: Vec<u8>,
) -> ViewPB {
    let request = CreateViewPayloadPB {
        belong_to_id: app_id.to_string(),
        name: "View A".to_string(),
        desc: "".to_string(),
        thumbnail: Some("http://1.png".to_string()),
        data_type,
        layout,
        view_content_data: data,
    };

    let view = FolderEventBuilder::new(sdk.clone())
        .event(CreateView)
        .payload(request)
        .async_send()
        .await
        .parse::<ViewPB>();
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
    format!("{}@appflowy.io", nanoid!(20))
}

pub fn login_email() -> String {
    "annie2@appflowy.io".to_string()
}

pub fn login_password() -> String {
    "HelloWorld!123".to_string()
}

pub struct SignUpContext {
    pub user_profile: UserProfilePB,
    pub password: String,
}

pub fn sign_up(dispatch: Arc<EventDispatcher>) -> SignUpContext {
    let password = login_password();
    let payload = SignUpPayloadPB {
        email: random_email(),
        name: "app flowy".to_string(),
        password: password.clone(),
    }
    .into_bytes()
    .unwrap();

    let request = ModuleRequest::new(SignUp).payload(payload);
    let user_profile = EventDispatcher::sync_send(dispatch, request)
        .parse::<UserProfilePB, FlowyError>()
        .unwrap()
        .unwrap();

    SignUpContext { user_profile, password }
}

pub async fn async_sign_up(dispatch: Arc<EventDispatcher>) -> SignUpContext {
    let password = login_password();
    let email = random_email();
    let payload = SignUpPayloadPB {
        email,
        name: "app flowy".to_string(),
        password: password.clone(),
    }
    .into_bytes()
    .unwrap();

    let request = ModuleRequest::new(SignUp).payload(payload);
    let user_profile = EventDispatcher::async_send(dispatch.clone(), request)
        .await
        .parse::<UserProfilePB, FlowyError>()
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
fn sign_in(dispatch: Arc<EventDispatcher>) -> UserProfilePB {
    let payload = SignInPayloadPB {
        email: login_email(),
        password: login_password(),
        name: "rust".to_owned(),
    }
    .into_bytes()
    .unwrap();

    let request = ModuleRequest::new(SignIn).payload(payload);
    EventDispatcher::sync_send(dispatch, request)
        .parse::<UserProfilePB, FlowyError>()
        .unwrap()
        .unwrap()
}

#[allow(dead_code)]
fn logout(dispatch: Arc<EventDispatcher>) {
    let _ = EventDispatcher::sync_send(dispatch, ModuleRequest::new(SignOut));
}
