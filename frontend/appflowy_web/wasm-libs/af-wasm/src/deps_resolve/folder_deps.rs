use crate::integrate::server::ServerProviderWASM;
use af_user::authenticate_user::AuthenticateUser;
use collab_integrate::collab_builder::AppFlowyCollabBuilder;
use flowy_document::manager::DocumentManager;
use flowy_folder::manager::FolderManager;
use std::rc::{Rc, Weak};
use std::sync::Arc;

pub struct FolderDepsResolver;

impl FolderDepsResolver {
  pub async fn resolve(
    authenticate_user: Weak<AuthenticateUser>,
    document_manager: Rc<DocumentManager>,
    collab_builder: Arc<AppFlowyCollabBuilder>,
    server_provider: Rc<ServerProviderWASM>,
  ) -> Rc<FolderManager> {
    todo!()
  }
}
