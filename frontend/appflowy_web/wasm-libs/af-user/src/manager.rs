use crate::authenticate_user::AuthenticateUser;
use crate::define::{user_profile_key, user_workspace_key, AF_USER_SESSION_KEY};
use af_persistence::store::{AppFlowyWASMStore, IndexddbStore};
use anyhow::Context;
use collab::core::collab::DataSource;
use collab_entity::CollabType;
use collab_integrate::collab_builder::{AppFlowyCollabBuilder, CollabBuilderConfig};
use collab_integrate::{CollabKVDB, MutexCollab};
use collab_user::core::{MutexUserAwareness, UserAwareness};
use flowy_error::{ErrorCode, FlowyError, FlowyResult};
use flowy_user_pub::cloud::{UserCloudConfig, UserCloudServiceProvider};
use flowy_user_pub::entities::{
  user_awareness_object_id, AuthResponse, Authenticator, UserAuthResponse, UserProfile,
  UserWorkspace,
};
use flowy_user_pub::session::Session;
use lib_infra::box_any::BoxAny;
use lib_infra::future::Fut;
use std::rc::Rc;
use std::sync::{Arc, Mutex, Weak};
use tracing::{error, instrument, trace};

pub trait UserCallback {
  fn did_init(
    &self,
    user_id: i64,
    cloud_config: &Option<UserCloudConfig>,
    user_workspace: &UserWorkspace,
    device_id: &str,
  ) -> Fut<FlowyResult<()>>;
  fn did_sign_in(&self, uid: i64, workspace: &UserWorkspace, device_id: &str) -> FlowyResult<()>;
  fn did_sign_up(
    &self,
    is_new_user: bool,
    user_profile: &UserProfile,
    user_workspace: &UserWorkspace,
    device_id: &str,
  ) -> Fut<FlowyResult<()>>;
}

pub struct UserManager {
  device_id: String,
  pub(crate) store: Rc<AppFlowyWASMStore>,
  pub(crate) cloud_services: Rc<dyn UserCloudServiceProvider>,
  pub(crate) collab_builder: Weak<AppFlowyCollabBuilder>,
  pub(crate) authenticate_user: Rc<AuthenticateUser>,

  #[allow(dead_code)]
  pub(crate) user_awareness: Rc<Mutex<Option<MutexUserAwareness>>>,
  pub(crate) collab_db: Arc<CollabKVDB>,

  user_callbacks: Vec<Rc<dyn UserCallback>>,
}

impl UserManager {
  pub async fn new(
    device_id: &str,
    store: Rc<AppFlowyWASMStore>,
    cloud_services: Rc<dyn UserCloudServiceProvider>,
    authenticate_user: Rc<AuthenticateUser>,
    collab_builder: Weak<AppFlowyCollabBuilder>,
  ) -> Result<Self, FlowyError> {
    let device_id = device_id.to_string();
    let store = Rc::new(AppFlowyWASMStore::new().await?);
    let collab_db = Arc::new(CollabKVDB::new().await?);
    Ok(Self {
      device_id,
      cloud_services,
      collab_builder,
      store,
      authenticate_user,
      user_callbacks: vec![],
      user_awareness: Rc::new(Default::default()),
      collab_db,
    })
  }

  pub async fn sign_up(&self, params: BoxAny) -> FlowyResult<UserProfile> {
    let auth_service = self.cloud_services.get_user_service()?;
    let response: AuthResponse = auth_service.sign_up(params).await?;
    let new_user_profile = UserProfile::from((&response, &Authenticator::AppFlowyCloud));
    let new_session = Session::from(&response);

    self.prepare_collab(&new_session);
    self
      .save_auth_data(&response, &new_user_profile, &new_session)
      .await?;

    for callback in self.user_callbacks.iter() {
      if let Err(e) = callback
        .did_sign_up(
          response.is_new_user,
          &new_user_profile,
          &new_session.user_workspace,
          &self.device_id,
        )
        .await
      {
        error!("Failed to call did_sign_up callback: {:?}", e);
      }
    }

    // TODO(nathan): send notification
    // send_auth_state_notification(AuthStateChangedPB {
    //   state: AuthStatePB::AuthStateSignIn,
    //   message: "Sign in success".to_string(),
    // });
    Ok(new_user_profile)
  }

  pub(crate) async fn add_user(&self, email: &str, password: &str) -> Result<(), FlowyError> {
    let auth_service = self.cloud_services.get_user_service()?;
    auth_service.create_user(email, password).await?;
    Ok(())
  }

  pub(crate) async fn sign_in_with_password(
    &self,
    email: &str,
    password: &str,
  ) -> Result<UserProfile, FlowyError> {
    let auth_service = self.cloud_services.get_user_service()?;
    let user_profile = auth_service.sign_in_with_password(email, password).await?;
    Ok(user_profile)
  }

  fn prepare_collab(&self, session: &Session) {
    let collab_builder = self.collab_builder.upgrade().unwrap();
    collab_builder.initialize(session.user_workspace.id.clone());
  }

  #[instrument(level = "info", skip_all, err)]
  async fn save_auth_data(
    &self,
    response: &impl UserAuthResponse,
    user_profile: &UserProfile,
    session: &Session,
  ) -> Result<(), FlowyError> {
    let uid = user_profile.uid;
    let user_profile = user_profile.clone();
    let session = session.clone();
    let user_workspace = response.user_workspaces().to_vec();
    self
      .store
      .begin_write_transaction(|store| {
        Box::pin(async move {
          store.set(&user_workspace_key(uid), &user_workspace).await?;
          store.set(AF_USER_SESSION_KEY, session).await?;
          store.set(&user_profile_key(uid), user_profile).await?;
          Ok(())
        })
      })
      .await?;

    Ok(())
  }

  pub async fn save_user_session(&self, session: &Session) -> FlowyResult<()> {
    self.store.set(AF_USER_SESSION_KEY, session).await?;
    Ok(())
  }

  pub async fn save_user_workspaces(
    &self,
    uid: i64,
    user_workspaces: &[UserWorkspace],
  ) -> FlowyResult<()> {
    self
      .store
      .set(&user_workspace_key(uid), &user_workspaces.to_vec())
      .await?;
    Ok(())
  }

  pub async fn save_user_profile(&self, user_profile: &UserProfile) -> FlowyResult<()> {
    let uid = user_profile.uid;
    self.store.set(&user_profile_key(uid), user_profile).await?;
    Ok(())
  }

  async fn collab_for_user_awareness(
    &self,
    uid: i64,
    object_id: &str,
    collab_db: Weak<CollabKVDB>,
    raw_data: Vec<u8>,
  ) -> Result<Arc<MutexCollab>, FlowyError> {
    let collab_builder = self.collab_builder.upgrade().ok_or(FlowyError::new(
      ErrorCode::Internal,
      "Unexpected error: collab builder is not available",
    ))?;
    let collab = collab_builder
      .build(
        uid,
        object_id,
        CollabType::UserAwareness,
        DataSource::DocStateV1(raw_data),
        collab_db,
        CollabBuilderConfig::default().sync_enable(true),
      )
      .await
      .context("Build collab for user awareness failed")?;
    Ok(collab)
  }
}
