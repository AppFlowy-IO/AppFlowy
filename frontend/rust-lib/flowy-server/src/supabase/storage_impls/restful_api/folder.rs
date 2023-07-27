use crate::supabase::storage_impls::pooler::{
  CREATED_AT, WORKSPACE_ID, WORKSPACE_NAME, WORKSPACE_TABLE,
};
use crate::supabase::storage_impls::restful_api::collab_storage::{
  get_latest_snapshot_from_server, get_updates_from_server, FetchObjectUpdateAction,
};
use crate::supabase::storage_impls::restful_api::util::{ExtendedResponse, InsertParamsBuilder};
use crate::supabase::storage_impls::restful_api::PostgresWrapper;
use crate::supabase::storage_impls::OWNER_USER_UID;
use anyhow::Error;
use chrono::{DateTime, Utc};
use collab::core::origin::CollabOrigin;
use collab_plugins::cloud_storage::CollabType;
use flowy_folder_deps::cloud::{
  gen_workspace_id, Folder, FolderCloudService, FolderData, FolderSnapshot, Workspace,
};
use lib_infra::future::FutureResult;
use serde_json::Value;
use std::str::FromStr;
use std::sync::Arc;
use tokio::sync::oneshot::channel;

pub struct RESTfulSupabaseFolderServiceImpl {
  postgrest: Arc<PostgresWrapper>,
}

impl RESTfulSupabaseFolderServiceImpl {
  pub fn new(postgrest: Arc<PostgresWrapper>) -> Self {
    Self { postgrest }
  }
}

impl FolderCloudService for RESTfulSupabaseFolderServiceImpl {
  fn create_workspace(&self, uid: i64, name: &str) -> FutureResult<Workspace, Error> {
    let postgrest = self.postgrest.clone();
    let name = name.to_string();
    let new_workspace_id = gen_workspace_id().to_string();
    FutureResult::new(async move {
      let insert_params = InsertParamsBuilder::new()
        .insert(OWNER_USER_UID, uid)
        .insert(WORKSPACE_ID, new_workspace_id.clone())
        .insert(WORKSPACE_NAME, name.to_string())
        .build();
      postgrest
        .from(WORKSPACE_TABLE)
        .insert(insert_params)
        .execute()
        .await?
        .success()
        .await?;

      // read the workspace
      let json = postgrest
        .from(WORKSPACE_TABLE)
        .select("*")
        .eq(WORKSPACE_ID, new_workspace_id)
        .execute()
        .await?
        .get_json()
        .await?;

      let workspace = workspace_from_json_value(json)?;
      Ok(workspace)
    })
  }

  fn get_folder_data(&self, workspace_id: &str) -> FutureResult<Option<FolderData>, Error> {
    let postgrest = self.postgrest.clone();
    let workspace_id = workspace_id.to_string();
    FutureResult::new(async move {
      get_updates_from_server(&workspace_id, &CollabType::Folder, postgrest)
        .await
        .map(|updates| {
          let folder =
            Folder::from_collab_raw_data(CollabOrigin::Empty, updates, &workspace_id, vec![])
              .ok()?;
          folder.get_folder_data()
        })
    })
  }

  fn get_folder_latest_snapshot(
    &self,
    workspace_id: &str,
  ) -> FutureResult<Option<FolderSnapshot>, Error> {
    let postgrest = self.postgrest.clone();
    let workspace_id = workspace_id.to_string();
    FutureResult::new(async move {
      let snapshot = get_latest_snapshot_from_server(&workspace_id, postgrest)
        .await?
        .map(|snapshot| FolderSnapshot {
          snapshot_id: snapshot.sid,
          database_id: snapshot.oid,
          data: snapshot.blob,
          created_at: snapshot.created_at,
        });
      Ok(snapshot)
    })
  }

  fn get_folder_updates(&self, workspace_id: &str, _uid: i64) -> FutureResult<Vec<Vec<u8>>, Error> {
    let postgrest = Arc::downgrade(&self.postgrest);
    let workspace_id = workspace_id.to_string();
    let (tx, rx) = channel();
    tokio::spawn(async move {
      tx.send(
        async move {
          let action = FetchObjectUpdateAction::new(workspace_id, CollabType::Folder, postgrest);
          action.run_with_fix_interval(5, 10).await
        }
        .await,
      )
    });
    FutureResult::new(async { rx.await? })
  }

  fn service_name(&self) -> String {
    "Supabase".to_string()
  }
}

fn workspace_from_json_value(value: Value) -> Result<Workspace, Error> {
  let json = value
    .as_array()
    .and_then(|values| values.first())
    .ok_or(anyhow::anyhow!("workspace not found"))?;
  Ok(Workspace {
    id: json
      .get(WORKSPACE_ID)
      .ok_or(anyhow::anyhow!("workspace id not found"))?
      .to_string(),
    name: json
      .get(WORKSPACE_NAME)
      .map(|value| value.to_string())
      .unwrap_or_default(),
    child_views: Default::default(),
    created_at: json
      .get(CREATED_AT)
      .and_then(|value| value.as_str())
      .and_then(|s| DateTime::<Utc>::from_str(s).ok())
      .map(|date| date.timestamp())
      .unwrap_or_default(),
  })
}
