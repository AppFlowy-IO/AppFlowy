use std::sync::Arc;

use collab_entity::CollabObject;
use lazy_static::lazy_static;
use parking_lot::Mutex;
use uuid::Uuid;

use flowy_error::FlowyError;
use flowy_user_pub::cloud::{UserCloudService, UserCollabParams};
use flowy_user_pub::entities::*;
use flowy_user_pub::DEFAULT_USER_NAME;
use lib_infra::box_any::BoxAny;
use lib_infra::future::FutureResult;
use lib_infra::util::timestamp;

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
  fn sign_up(&self, params: BoxAny) -> FutureResult<AuthResponse, FlowyError> {
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
        user_uuid: Uuid::new_v4(),
        name: user_name,
        latest_workspace: user_workspace.clone(),
        user_workspaces: vec![user_workspace],
        is_new_user: true,
        email: Some(params.email),
        token: None,
        encryption_type: EncryptionType::NoEncryption,
        updated_at: timestamp(),
        metadata: None,
      })
    })
  }

  fn sign_in(&self, params: BoxAny) -> FutureResult<AuthResponse, FlowyError> {
    let db = self.db.clone();
    FutureResult::new(async move {
      let params: SignInParams = params.unbox_or_error::<SignInParams>()?;
      let uid = ID_GEN.lock().next_id();

      let user_workspace = db
        .get_user_workspace(uid)?
        .unwrap_or_else(make_user_workspace);
      Ok(AuthResponse {
        user_id: uid,
        user_uuid: Uuid::new_v4(),
        name: params.name,
        latest_workspace: user_workspace.clone(),
        user_workspaces: vec![user_workspace],
        is_new_user: false,
        email: Some(params.email),
        token: None,
        encryption_type: EncryptionType::NoEncryption,
        updated_at: timestamp(),
        metadata: None,
      })
    })
  }

  fn sign_out(&self, _token: Option<String>) -> FutureResult<(), FlowyError> {
    FutureResult::new(async { Ok(()) })
  }

  fn generate_sign_in_url_with_email(&self, _email: &str) -> FutureResult<String, FlowyError> {
    FutureResult::new(async {
      Err(
        FlowyError::local_version_not_support()
          .with_context("Not support generate sign in url with email"),
      )
    })
  }

  fn create_user(&self, _email: &str, _password: &str) -> FutureResult<(), FlowyError> {
    FutureResult::new(async {
      Err(FlowyError::local_version_not_support().with_context("Not support create user"))
    })
  }

  fn sign_in_with_password(
    &self,
    _email: &str,
    _password: &str,
  ) -> FutureResult<UserProfile, FlowyError> {
    FutureResult::new(async {
      Err(FlowyError::local_version_not_support().with_context("Not support"))
    })
  }

  fn generate_oauth_url_with_provider(&self, _provider: &str) -> FutureResult<String, FlowyError> {
    FutureResult::new(async {
      Err(FlowyError::internal().with_context("Can't oauth url when using offline mode"))
    })
  }

  fn update_user(
    &self,
    _credential: UserCredentials,
    _params: UpdateUserProfileParams,
  ) -> FutureResult<(), FlowyError> {
    FutureResult::new(async { Ok(()) })
  }

  fn get_user_profile(&self, credential: UserCredentials) -> FutureResult<UserProfile, FlowyError> {
    let result = match credential.uid {
      None => Err(FlowyError::record_not_found()),
      Some(uid) => {
        self.db.get_user_profile(uid).map(|mut profile| {
          // We don't want to expose the email in the local server
          profile.email = "".to_string();
          profile
        })
      },
    };
    FutureResult::new(async { result })
  }

  fn open_workspace(&self, _workspace_id: &str) -> FutureResult<UserWorkspace, FlowyError> {
    FutureResult::new(async {
      Err(
        FlowyError::local_version_not_support()
          .with_context("local server doesn't support open workspace"),
      )
    })
  }

  fn get_all_workspace(&self, _uid: i64) -> FutureResult<Vec<UserWorkspace>, FlowyError> {
    FutureResult::new(async { Ok(vec![]) })
  }

  fn get_user_awareness_doc_state(
    &self,
    _uid: i64,
    _workspace_id: &str,
    _object_id: &str,
  ) -> FutureResult<Vec<u8>, FlowyError> {
    // must return record not found error
    FutureResult::new(async { Err(FlowyError::record_not_found()) })
  }

  fn reset_workspace(&self, _collab_object: CollabObject) -> FutureResult<(), FlowyError> {
    FutureResult::new(async { Ok(()) })
  }

  fn create_collab_object(
    &self,
    _collab_object: &CollabObject,
    _data: Vec<u8>,
  ) -> FutureResult<(), FlowyError> {
    FutureResult::new(async { Ok(()) })
  }

  fn batch_create_collab_object(
    &self,
    _workspace_id: &str,
    _objects: Vec<UserCollabParams>,
  ) -> FutureResult<(), FlowyError> {
    FutureResult::new(async {
      Err(
        FlowyError::local_version_not_support()
          .with_context("local server doesn't support batch create collab object"),
      )
    })
  }

  fn create_workspace(&self, _workspace_name: &str) -> FutureResult<UserWorkspace, FlowyError> {
    FutureResult::new(async {
      Err(
        FlowyError::local_version_not_support()
          .with_context("local server doesn't support multiple workspaces"),
      )
    })
  }

  fn delete_workspace(&self, _workspace_id: &str) -> FutureResult<(), FlowyError> {
    FutureResult::new(async {
      Err(
        FlowyError::local_version_not_support()
          .with_context("local server doesn't support multiple workspaces"),
      )
    })
  }

  fn patch_workspace(
    &self,
    _workspace_id: &str,
    _new_workspace_name: Option<&str>,
    _new_workspace_icon: Option<&str>,
  ) -> FutureResult<(), FlowyError> {
    FutureResult::new(async {
      Err(
        FlowyError::local_version_not_support()
          .with_context("local server doesn't support multiple workspaces"),
      )
    })
  }
}

fn make_user_workspace() -> UserWorkspace {
  UserWorkspace {
    id: uuid::Uuid::new_v4().to_string(),
    name: "My Workspace".to_string(),
    created_at: Default::default(),
    workspace_database_object_id: uuid::Uuid::new_v4().to_string(),
    icon: "".to_string(),
  }
}
