use bytes::Bytes;
use flowy_dispatch::prelude::{EventDispatch, ModuleRequest, ToBytes};
use flowy_infra::{kv::KV, uuid};

use flowy_user::{
    entities::{SignInRequest, SignUpRequest, UserProfile},
    errors::{ErrorBuilder, ErrorCode, UserError},
    event::UserEvent::{SignIn, SignOut, SignUp},
};
use flowy_workspace::{
    entities::workspace::{CreateWorkspaceRequest, QueryWorkspaceRequest, Workspace},
    errors::WorkspaceError,
    event::WorkspaceEvent::{CreateWorkspace, OpenWorkspace},
};
use std::{fs, path::PathBuf, sync::Arc};

pub fn root_dir() -> String {
    // https://doc.rust-lang.org/cargo/reference/environment-variables.html
    let manifest_dir = std::env::var("CARGO_MANIFEST_DIR").unwrap_or("./".to_owned());
    let mut path_buf = fs::canonicalize(&PathBuf::from(&manifest_dir)).unwrap();
    path_buf.pop(); // rust-lib
    path_buf.push("flowy-test");
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

const DEFAULT_WORKSPACE_NAME: &'static str = "My workspace";
const DEFAULT_WORKSPACE_DESC: &'static str = "This is your first workspace";
const DEFAULT_WORKSPACE: &'static str = "Default_Workspace";

pub(crate) fn create_default_workspace_if_need(dispatch: Arc<EventDispatch>, user_id: &str) -> Result<(), UserError> {
    let key = format!("{}{}", user_id, DEFAULT_WORKSPACE);
    if KV::get_bool(&key).unwrap_or(false) {
        return Err(ErrorBuilder::new(ErrorCode::InternalError).build());
    }
    KV::set_bool(&key, true);

    let payload: Bytes = CreateWorkspaceRequest {
        name: DEFAULT_WORKSPACE_NAME.to_string(),
        desc: DEFAULT_WORKSPACE_DESC.to_string(),
    }
    .into_bytes()
    .unwrap();

    let request = ModuleRequest::new(CreateWorkspace).payload(payload);
    let result = EventDispatch::sync_send(dispatch.clone(), request)
        .parse::<Workspace, WorkspaceError>()
        .map_err(|e| ErrorBuilder::new(ErrorCode::InternalError).error(e).build())?;

    let workspace = result.map_err(|e| ErrorBuilder::new(ErrorCode::InternalError).error(e).build())?;
    let query: Bytes = QueryWorkspaceRequest {
        workspace_id: Some(workspace.id.clone()),
    }
    .into_bytes()
    .unwrap();

    let request = ModuleRequest::new(OpenWorkspace).payload(query);
    let _result = EventDispatch::sync_send(dispatch.clone(), request)
        .parse::<Workspace, WorkspaceError>()
        .unwrap()
        .unwrap();

    Ok(())
}

pub struct SignUpContext {
    pub user_profile: UserProfile,
    pub password: String,
}

pub fn sign_up(dispatch: Arc<EventDispatch>) -> SignUpContext {
    let password = login_password();
    let payload = SignUpRequest {
        email: random_email(),
        name: "app flowy".to_string(),
        password: password.clone(),
    }
    .into_bytes()
    .unwrap();

    let request = ModuleRequest::new(SignUp).payload(payload);
    let user_profile = EventDispatch::sync_send(dispatch.clone(), request)
        .parse::<UserProfile, UserError>()
        .unwrap()
        .unwrap();

    let _ = create_default_workspace_if_need(dispatch.clone(), &user_profile.id);
    SignUpContext { user_profile, password }
}

#[allow(dead_code)]
fn sign_in(dispatch: Arc<EventDispatch>) -> UserProfile {
    let payload = SignInRequest {
        email: login_email(),
        password: login_password(),
    }
    .into_bytes()
    .unwrap();

    let request = ModuleRequest::new(SignIn).payload(payload);
    let user_profile = EventDispatch::sync_send(dispatch, request)
        .parse::<UserProfile, UserError>()
        .unwrap()
        .unwrap();

    user_profile
}

#[allow(dead_code)]
fn logout(dispatch: Arc<EventDispatch>) { let _ = EventDispatch::sync_send(dispatch, ModuleRequest::new(SignOut)); }
