use flowy_chat::manager::{ChatManager, ChatUserService};
use flowy_chat_pub::cloud::ChatCloudService;
use flowy_error::FlowyError;
use flowy_sqlite::DBConnection;
use flowy_user::services::authenticate_user::AuthenticateUser;
use std::sync::{Arc, Weak};

pub struct ChatDepsResolver;

impl ChatDepsResolver {
  pub fn resolve(
    authenticate_user: Weak<AuthenticateUser>,
    cloud_service: Arc<dyn ChatCloudService>,
  ) -> Arc<ChatManager> {
    let user_service = ChatUserServiceImpl(authenticate_user);
    Arc::new(ChatManager::new(cloud_service, user_service))
  }
}

struct ChatUserServiceImpl(Weak<AuthenticateUser>);
impl ChatUserServiceImpl {
  fn upgrade_user(&self) -> Result<Arc<AuthenticateUser>, FlowyError> {
    let user = self
      .0
      .upgrade()
      .ok_or(FlowyError::internal().with_context("Unexpected error: UserSession is None"))?;
    Ok(user)
  }
}

impl ChatUserService for ChatUserServiceImpl {
  fn user_id(&self) -> Result<i64, FlowyError> {
    self.upgrade_user()?.user_id()
  }

  fn device_id(&self) -> Result<String, FlowyError> {
    self.upgrade_user()?.device_id()
  }

  fn workspace_id(&self) -> Result<String, FlowyError> {
    self.upgrade_user()?.workspace_id()
  }

  fn sqlite_connection(&self, uid: i64) -> Result<DBConnection, FlowyError> {
    self.upgrade_user()?.get_sqlite_connection(uid)
  }
}
