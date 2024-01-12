use crate::migrations::MigrationUser;
use crate::services::data_import::importer::import_data;
use crate::services::data_import::{
  import_appflowy_data_folder, upload_imported_data, ImportContext,
};
use collab_integrate::CollabKVDB;
use flowy_error::{internal_error, ErrorCode, FlowyError, FlowyResult};
use flowy_user_deps::cloud::UserCloudService;
use std::sync::Arc;

#[allow(dead_code)]
pub async fn migration_anon_user_on_appflowy_cloud_sign_up(
  old_user: &MigrationUser,
  old_collab_db: &Arc<CollabKVDB>,
  new_user: &MigrationUser,
  new_collab_db: &Arc<CollabKVDB>,
  user_cloud_service: Arc<dyn UserCloudService>,
) -> FlowyResult<()> {
  let import_context = ImportContext {
    imported_session: old_user.session.clone(),
    imported_collab_db: old_collab_db.clone(),
    container_name: None,
  };

  let cloned_new_collab_db = new_collab_db.clone();
  let import_data = tokio::task::spawn_blocking(move || {
    import_appflowy_data_folder(
      &new_user.session,
      &new_user.session.user_workspace.id,
      &cloned_new_collab_db,
      import_context,
    )
  })
  .await
  .map_err(internal_error)??;

  upload_imported_data(
    new_user.session.user_id,
    new_collab_db.clone(),
    &new_user.session.user_workspace.id,
    &new_user.user_profile.authenticator,
    &import_data,
    user_cloud_service,
  )
  .await?;
  Ok(())
}
