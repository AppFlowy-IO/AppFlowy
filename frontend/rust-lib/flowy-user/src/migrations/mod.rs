use flowy_user_pub::session::Session;
use std::sync::Arc;

pub mod document_empty_content;
pub mod migration;
pub mod session_migration;
mod util;
pub mod workspace_and_favorite_v1;
pub mod workspace_trash_v1;

#[derive(Clone, Debug)]
pub struct AnonUser {
  pub session: Arc<Session>,
}
