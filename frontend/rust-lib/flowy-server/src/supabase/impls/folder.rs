use crate::supabase::request::create_workspace_with_uid;
use flowy_error::FlowyError;
use flowy_folder2::deps::{FolderCloudService, Workspace};
use lib_infra::future::FutureResult;
use postgrest::Postgrest;
use std::sync::Arc;

pub(crate) const WORKSPACE_TABLE: &str = "af_workspace";
pub(crate) const WORKSPACE_NAME_COLUMN: &str = "workspace_name";
pub(crate) struct SupabaseFolderCloudServiceImpl {
  postgrest: Arc<Postgrest>,
}

impl FolderCloudService for SupabaseFolderCloudServiceImpl {
  fn create_workspace(&self, uid: i64, name: &str) -> FutureResult<Workspace, FlowyError> {
    let name = name.to_string();
    let postgrest = self.postgrest.clone();
    FutureResult::new(async move { create_workspace_with_uid(postgrest, uid, &name).await })
  }
}

#[cfg(test)]
mod tests {
  use crate::supabase::request::{
    create_user_with_uuid, create_workspace_with_uid, get_user_workspace_with_uid,
  };
  use crate::supabase::{SupabaseConfiguration, SupabaseServer};
  use dotenv::dotenv;
  use std::sync::Arc;

  #[tokio::test]
  async fn create_user_workspace() {
    dotenv().ok();
    if let Ok(config) = SupabaseConfiguration::from_env() {
      let server = Arc::new(SupabaseServer::new(config));
      let uuid = uuid::Uuid::new_v4();
      let uid = create_user_with_uuid(server.postgres.clone(), uuid.to_string())
        .await
        .unwrap()
        .uid;

      create_workspace_with_uid(server.postgres.clone(), uid, "test")
        .await
        .unwrap();

      let workspaces = get_user_workspace_with_uid(server.postgres.clone(), uid)
        .await
        .unwrap();
      assert_eq!(workspaces.len(), 2);
      assert_eq!(workspaces[0].name, "My workspace");
      assert_eq!(workspaces[1].name, "test");
    }
  }
}
