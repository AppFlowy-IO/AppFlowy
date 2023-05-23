use flowy_folder2::deps::FolderCloudService;
use std::sync::Arc;

use flowy_user::event_map::UserAuthService;

pub mod local_server;
mod request;
mod response;
pub mod self_host;
pub mod supabase;

/// In order to run this the supabase test, you need to create a .env file in the root directory of this project
/// and add the following environment variables:
/// - SUPABASE_URL
/// - SUPABASE_ANON_KEY
/// - SUPABASE_KEY
/// - SUPABASE_JWT_SECRET
///
/// the .env file should look like this:
/// SUPABASE_URL=https://<your-supabase-url>.supabase.co
/// SUPABASE_ANON_KEY=<your-supabase-anon-key>
/// SUPABASE_KEY=<your-supabase-key>
/// SUPABASE_JWT_SECRET=<your-supabase-jwt-secret>
///

pub trait AppFlowyServer: Send + Sync + 'static {
  fn user_service(&self) -> Arc<dyn UserAuthService>;
  fn folder_service(&self) -> Arc<dyn FolderCloudService>;
}
