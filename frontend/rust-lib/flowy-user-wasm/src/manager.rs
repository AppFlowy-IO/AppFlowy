use collab_integrate::collab_builder::AppFlowyCollabBuilder;
use flowy_error::FlowyResult;
use flowy_user_pub::cloud::UserCloudServiceProvider;
use flowy_user_pub::entities::{AuthResponse, Authenticator, UserProfile};
use lib_infra::box_any::BoxAny;
use std::sync::{Arc, Weak};

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
  }
}
