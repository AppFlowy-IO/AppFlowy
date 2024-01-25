use collab_integrate::collab_builder::AppFlowyCollabBuilder;
use flowy_error::{FlowyError, FlowyResult};
use flowy_user_pub::cloud::UserCloudServiceProvider;
use flowy_user_pub::entities::{AuthResponse, Authenticator, UserAuthResponse, UserProfile};
use flowy_user_pub::session::Session;
use lib_infra::box_any::BoxAny;
use std::sync::{Arc, Weak};
use tracing::{event, instrument};

pub struct UserManagerWASM {
  pub(crate) cloud_services: Arc<dyn UserCloudServiceProvider>,
  pub(crate) collab_builder: Weak<AppFlowyCollabBuilder>,
}

impl UserManagerWASM {
  pub fn new(
    cloud_services: Arc<dyn UserCloudServiceProvider>,
    collab_builder: Weak<AppFlowyCollabBuilder>,
  ) -> Self {
    Self {
      cloud_services,
      collab_builder,
    }
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
    Ok(new_user_profile)
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
    // save_user_workspaces(uid, self.db_pool(uid)?, response.user_workspaces())?;
    // event!(tracing::Level::INFO, "Save new user profile to disk");
    // self.authenticate_user.set_session(Some(session.clone()))?;
    // self
    //     .save_user(uid, (user_profile, authenticator.clone()).into())
    //     .await?;
    Ok(())
  }
}
