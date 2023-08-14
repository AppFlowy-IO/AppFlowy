use std::str::FromStr;

use anyhow::Error;
use chrono::{DateTime, Utc};
use collab::core::origin::CollabOrigin;
use collab_plugins::cloud_storage::CollabType;
use serde_json::Value;
use tokio::sync::oneshot::channel;

use flowy_folder_deps::cloud::{
  gen_workspace_id, Folder, FolderCloudService, FolderData, FolderSnapshot, Workspace,
};
use lib_infra::future::FutureResult;

use crate::supabase::api::request::{
  get_latest_snapshot_from_server, get_updates_from_server, FetchObjectUpdateAction,
};
use crate::supabase::api::util::{ExtendedResponse, InsertParamsBuilder};
use crate::supabase::api::SupabaseServerService;
use crate::supabase::define::*;

pub struct SupabaseFolderServiceImpl<T>(T);

impl<T> SupabaseFolderServiceImpl<T> {
  pub fn new(server: T) -> Self {
    Self(server)
  }
}

impl<T> FolderCloudService for SupabaseFolderServiceImpl<T>
where
  T: SupabaseServerService,
{
  fn create_workspace(&self, uid: i64, name: &str) -> FutureResult<Workspace, Error> {
    let try_get_postgrest = self.0.try_get_postgrest();
    let name = name.to_string();
    let new_workspace_id = gen_workspace_id().to_string();
    FutureResult::new(async move {
      let postgrest = try_get_postgrest?;
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
    let try_get_postgrest = self.0.try_get_postgrest();
    let workspace_id = workspace_id.to_string();
    FutureResult::new(async move {
      let postgrest = try_get_postgrest?;
      get_updates_from_server(&workspace_id, &CollabType::Folder, postgrest)
        .await
        .map(|updates| {
          let updates = updates.into_iter().map(|item| item.value).collect();
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
    let try_get_postgrest = self.0.try_get_postgrest();
    let workspace_id = workspace_id.to_string();
    FutureResult::new(async move {
      let postgrest = try_get_postgrest?;
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
    let try_get_postgrest = self.0.try_get_weak_postgrest();
    let workspace_id = workspace_id.to_string();
    let (tx, rx) = channel();
    tokio::spawn(async move {
      tx.send(
        async move {
          let postgrest = try_get_postgrest?;
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
