use std::sync::Arc;

use anyhow::Error;
use collab_entity::CollabObject;
use lazy_static::lazy_static;
use parking_lot::Mutex;

use flowy_user_deps::cloud::UserCloudService;
use flowy_user_deps::entities::*;
use flowy_user_deps::DEFAULT_USER_NAME;
use lib_infra::box_any::BoxAny;
use lib_infra::future::FutureResult;

use crate::local_server::uid::UserIDGenerator;
use crate::local_server::LocalServerDB;

lazy_static! {
  static ref ID_GEN: Mutex<UserIDGenerator> = Mutex::new(UserIDGenerator::new(1));
}

pub(crate) struct LocalServerUserAuthServiceImpl {
  #[allow(dead_code)]
  pub db: Arc<dyn LocalServerDB>,
}

impl UserCloudService for LocalServerUserAuthServiceImpl {
  fn sign_up(&self, params: BoxAny) -> FutureResult<AuthResponse, Error> {
    FutureResult::new(async move {
      let params = params.unbox_or_error::<SignUpParams>()?;
      let uid = ID_GEN.lock().next_id();
      let workspace_id = uuid::Uuid::new_v4().to_string();
      let user_workspace = UserWorkspace::new(&workspace_id, uid);
      let user_name = if params.name.is_empty() {
        DEFAULT_USER_NAME()
      } else {
        params.name.clone()
      };
      Ok(AuthResponse {
        user_id: uid,
        name: user_name,
        latest_workspace: user_workspace.clone(),
        user_workspaces: vec![user_workspace],
        is_new_user: true,
        email: Some(params.email),
        token: None,
        device_id: params.device_id,
        encryption_type: EncryptionType::NoEncryption,
      })
    })
  }

  fn sign_in(&self, params: BoxAny) -> FutureResult<AuthResponse, Error> {
    let db = self.db.clone();
    FutureResult::new(async move {
      let params: SignInParams = params.unbox_or_error::<SignInParams>()?;
      let uid = ID_GEN.lock().next_id();

      let user_workspace = db
        .get_user_workspace(uid)?
        .unwrap_or_else(make_user_workspace);
      Ok(AuthResponse {
        user_id: uid,
        name: params.name,
        latest_workspace: user_workspace.clone(),
        user_workspaces: vec![user_workspace],
        is_new_user: false,
        email: Some(params.email),
        token: None,
        device_id: params.device_id,
        encryption_type: EncryptionType::NoEncryption,
      })
    })
  }

  fn sign_out(&self, _token: Option<String>) -> FutureResult<(), Error> {
    FutureResult::new(async { Ok(()) })
  }

  fn generate_sign_in_url_with_email(&self, _email: &str) -> FutureResult<String, Error> {
    FutureResult::new(async {
      Err(anyhow::anyhow!(
        "Can't generate callback url when using offline mode"
      ))
    })
  }

  fn generate_oauth_url_with_provider(&self, _provider: &str) -> FutureResult<String, Error> {
    FutureResult::new(async { Err(anyhow::anyhow!("Can't oauth url when using offline mode")) })
  }

  fn update_user(
    &self,
    _credential: UserCredentials,
    _params: UpdateUserProfileParams,
  ) -> FutureResult<(), Error> {
    FutureResult::new(async { Ok(()) })
  }

  fn get_user_profile(
    &self,
    _credential: UserCredentials,
  ) -> FutureResult<Option<UserProfile>, Error> {
    FutureResult::new(async { Ok(None) })
  }

  fn get_user_workspaces(&self, _uid: i64) -> FutureResult<Vec<UserWorkspace>, Error> {
    FutureResult::new(async { Ok(vec![]) })
  }

  fn check_user(&self, _credential: UserCredentials) -> FutureResult<(), Error> {
    FutureResult::new(async { Ok(()) })
  }

  fn add_workspace_member(
    &self,
    _user_email: String,
    _workspace_id: String,
  ) -> FutureResult<(), Error> {
    FutureResult::new(async { Ok(()) })
  }

  fn remove_workspace_member(
    &self,
    _user_email: String,
    _workspace_id: String,
  ) -> FutureResult<(), Error> {
    FutureResult::new(async { Ok(()) })
  }

  fn get_user_awareness_updates(&self, _uid: i64) -> FutureResult<Vec<Vec<u8>>, Error> {
    FutureResult::new(async { Ok(vec![]) })
  }

  fn reset_workspace(&self, _collab_object: CollabObject) -> FutureResult<(), Error> {
    FutureResult::new(async { Ok(()) })
  }

  fn create_collab_object(
    &self,
    _collab_object: &CollabObject,
    _data: Vec<u8>,
  ) -> FutureResult<(), Error> {
    FutureResult::new(async { Ok(()) })
  }
}

fn make_user_workspace() -> UserWorkspace {
  UserWorkspace {
    id: uuid::Uuid::new_v4().to_string(),
    name: "My Workspace".to_string(),
    created_at: Default::default(),
    database_views_aggregate_id: uuid::Uuid::new_v4().to_string(),
  }
}
