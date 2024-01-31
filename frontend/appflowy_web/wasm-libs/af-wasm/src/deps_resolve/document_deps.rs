use crate::integrate::server::ServerProviderWASM;
use af_user::authenticate_user::AuthenticateUser;
use collab_integrate::collab_builder::AppFlowyCollabBuilder;
use flowy_document::manager::DocumentManager;
use flowy_storage::ObjectStorageService;
use std::rc::{Rc, Weak};
use std::sync::Arc;

pub struct DocumentDepsResolver;
impl DocumentDepsResolver {
  pub async fn resolve(
    authenticate_user: Weak<AuthenticateUser>,
    collab_builder: Arc<AppFlowyCollabBuilder>,
    server_provider: Rc<ServerProviderWASM>,
    storage_service: Weak<dyn ObjectStorageService>,
  ) -> Rc<DocumentManager> {
    todo!()
  }
}
