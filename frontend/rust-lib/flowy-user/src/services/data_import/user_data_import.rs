use crate::migrations::session_migration::{get_session_workspace, migrate_session};
use std::collections::{HashMap, HashSet};

use anyhow::anyhow;
use collab_integrate::CollabKVDB;
use flowy_user_pub::entities::AuthType;

use crate::entities::{ImportUserDataPB, UserDataPreviewPB, WorkspaceDataPreviewPB};
use flowy_error::ErrorCode;
use flowy_sqlite::Database;
use flowy_user_pub::sql::{
  select_all_user_workspace, select_user_auth_type, select_user_id, select_user_name,
};
use semver::Version;
use std::path::{Path, PathBuf};
use std::sync::Arc;

pub(crate) struct ImportedUserData {
  pub uid: i64,
  pub user_auth_type: AuthType,
  pub data: ImportUserDataPB,
  pub app_version: Version,
  pub collab_db: Arc<CollabKVDB>,
  pub sqlite_db: Database,
}

pub struct ImportedUserWorkspaceResult {
  workspace_id: String,
  workspace_name: String,
  success: bool,
  error_code: ErrorCode,
}

pub struct ImportedUserDataResult {
  results: Vec<ImportedUserWorkspaceResult>,
}

fn import_user_workspace(
  current_uid: i64,
  current_collab_db: &Arc<CollabKVDB>,
  imported_uid: i64,
  imported_collab_db: &Arc<CollabKVDB>,
  imported_sqlite_db: &Database,
  imported_workspace: &WorkspaceDataPreviewPB,
  import_to_view_id: &str,
) -> ImportedUserWorkspaceResult {
  let mut database_view_ids_by_database_id: HashMap<String, Vec<String>> = HashMap::new();
  let mut row_object_ids = HashSet::new();
  let mut document_object_ids = HashSet::new();
  let mut database_object_ids = HashSet::new();

  todo!()
}

pub fn import_user_data(
  current_uid: i64,
  current_workspace_id: &str,
  current_collab_db: &Arc<CollabKVDB>,
  data: ImportedUserData,
) -> anyhow::Result<ImportedUserDataResult> {
  let imported_uid = data.uid;
  let imported_collab_db = data.collab_db;
  let imported_sqlite_db = data.sqlite_db;
  let imported_user_data = data.data;
  let import_to_view_id = imported_user_data
    .parent_view_id
    .unwrap_or_else(|| current_workspace_id.to_string());

  let mut results = vec![];
  for workspace in imported_user_data.workspaces {
    results.push(import_user_workspace(
      current_uid,
      current_collab_db,
      imported_uid,
      &imported_collab_db,
      &imported_sqlite_db,
      &workspace,
      &import_to_view_id,
    ));
  }

  Ok(ImportedUserDataResult { results })
}

pub(crate) fn user_data_preview(path: &str) -> anyhow::Result<UserDataPreviewPB> {
  if !Path::new(path).exists() {
    return Err(anyhow!("The path: {} is not exist", path));
  }

  let sqlite_db_path = PathBuf::from(path).join("flowy-database.db");
  if !sqlite_db_path.exists() {
    return Err(anyhow!(
      "Can not find flowy-database.db at path: {}",
      sqlite_db_path.display()
    ));
  }

  let collab_db_path = PathBuf::from(path).join("collab_db");
  if !collab_db_path.exists() {
    return Err(anyhow!(
      "Can not find collab_db at path: {}",
      collab_db_path.display()
    ));
  }

  let imported_sqlite_db = flowy_sqlite::init(sqlite_db_path)
    .map_err(|err| anyhow!("[AppflowyData]: open import collab db failed: {:?}", err))?;

  let mut conn = imported_sqlite_db.get_connection()?;
  let uid = select_user_id(&mut conn)?;
  let user_name = select_user_name(uid, &mut conn)?;
  let workspaces = select_all_user_workspace(uid, &mut conn)?
    .into_iter()
    .map(|w| WorkspaceDataPreviewPB {
      name: w.name,
      created_at: w.created_at.timestamp(),
      workspace_id: w.id,
      workspace_database_id: w.workspace_database_id,
    })
    .collect::<Vec<_>>();

  Ok(UserDataPreviewPB {
    user_name,
    workspaces,
  })
}

pub(crate) fn get_import_user_data(
  user_data: ImportUserDataPB,
  app_version: &Version,
) -> anyhow::Result<ImportedUserData> {
  let sqlite_db_path = PathBuf::from(&user_data.path).join("flowy-database.db");
  if !sqlite_db_path.exists() {
    return Err(anyhow!(
      "Can not find flowy-database.db at path: {}",
      sqlite_db_path.display()
    ));
  }

  let collab_db_path = PathBuf::from(&user_data.path).join("collab_db");
  if !collab_db_path.exists() {
    return Err(anyhow!(
      "Can not find collab_db at path: {}",
      collab_db_path.display()
    ));
  }

  let sqlite_db = flowy_sqlite::init(sqlite_db_path)
    .map_err(|err| anyhow!("[AppflowyData]: open import collab db failed: {:?}", err))?;

  let collab_db = Arc::new(
    CollabKVDB::open(collab_db_path)
      .map_err(|err| anyhow!("[AppflowyData]: open import collab db failed: {:?}", err))?,
  );

  let mut conn = sqlite_db.get_connection()?;
  let uid = select_user_id(&mut conn)?;
  let user_auth_type = select_user_auth_type(uid, &mut conn)?;

  Ok(ImportedUserData {
    uid,
    user_auth_type,
    data: user_data,
    app_version: app_version.clone(),
    collab_db,
    sqlite_db,
  })
}
