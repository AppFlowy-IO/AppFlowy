use std::str::FromStr;

use anyhow::{anyhow, Error};
use chrono::{DateTime, Utc};
use collab::core::collab::DataSource;
use collab::core::origin::CollabOrigin;
use collab_entity::CollabType;
use serde_json::Value;
use tokio::sync::oneshot::channel;
use yrs::merge_updates_v1;

use flowy_folder_pub::cloud::{
  gen_workspace_id, Folder, FolderCloudService, FolderCollabParams, FolderData, FolderSnapshot,
  Workspace, WorkspaceRecord,
};
use flowy_folder_pub::entities::PublishPayload;
use lib_dispatch::prelude::af_spawn;
use lib_infra::future::FutureResult;
use lib_infra::util::timestamp;

use crate::response::ExtendedResponse;
use crate::supabase::api::request::{
  get_snapshots_from_server, get_updates_from_server, FetchObjectUpdateAction,
};
use crate::supabase::api::util::InsertParamsBuilder;
use crate::supabase::api::SupabaseServerService;
use crate::supabase::define::*;

pub struct SupabaseFolderServiceImpl<T> {
  server: T,
}

impl<T> SupabaseFolderServiceImpl<T> {
  pub fn new(server: T) -> Self {
    Self { server }
  }
}

impl<T> FolderCloudService for SupabaseFolderServiceImpl<T>
where
  T: SupabaseServerService,
{
  fn create_workspace(&self, uid: i64, name: &str) -> FutureResult<Workspace, Error> {
    let try_get_postgrest = self.server.try_get_postgrest();
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

  fn open_workspace(&self, _workspace_id: &str) -> FutureResult<(), Error> {
    FutureResult::new(async { Ok(()) })
  }

  fn get_all_workspace(&self) -> FutureResult<Vec<WorkspaceRecord>, Error> {
    FutureResult::new(async { Ok(vec![]) })
  }

  fn get_folder_data(
    &self,
    workspace_id: &str,
    uid: &i64,
  ) -> FutureResult<Option<FolderData>, Error> {
    let uid = *uid;
    let try_get_postgrest = self.server.try_get_postgrest();
    let workspace_id = workspace_id.to_string();
    FutureResult::new(async move {
      let postgrest = try_get_postgrest?;
      let items = get_updates_from_server(&workspace_id, &CollabType::Folder, &postgrest).await?;
      if items.is_empty() {
        return Ok(None);
      }
      let updates = items.into_iter().map(|update| update.value);
      let doc_state = merge_updates_v1(updates)
        .map_err(|err| anyhow::anyhow!("merge updates failed: {:?}", err))?;

      let folder = Folder::from_collab_doc_state(
        uid,
        CollabOrigin::Empty,
        DataSource::DocStateV1(doc_state),
        &workspace_id,
        vec![],
      )?;
      Ok(folder.get_folder_data(&workspace_id))
    })
  }

  fn get_folder_snapshots(
    &self,
    workspace_id: &str,
    limit: usize,
  ) -> FutureResult<Vec<FolderSnapshot>, Error> {
    let try_get_postgrest = self.server.try_get_postgrest();
    let workspace_id = workspace_id.to_string();
    FutureResult::new(async move {
      let postgrest = try_get_postgrest?;
      let snapshots = get_snapshots_from_server(&workspace_id, postgrest, limit)
        .await?
        .into_iter()
        .map(|snapshot| FolderSnapshot {
          snapshot_id: snapshot.sid,
          database_id: snapshot.oid,
          data: snapshot.blob,
          created_at: snapshot.created_at,
        })
        .collect::<Vec<_>>();
      Ok(snapshots)
    })
  }

  fn get_folder_doc_state(
    &self,
    _workspace_id: &str,
    _uid: i64,
    collab_type: CollabType,
    object_id: &str,
  ) -> FutureResult<Vec<u8>, Error> {
    let try_get_postgrest = self.server.try_get_weak_postgrest();
    let object_id = object_id.to_string();
    let (tx, rx) = channel();
    af_spawn(async move {
      tx.send(
        async move {
          let postgrest = try_get_postgrest?;
          let action = FetchObjectUpdateAction::new(object_id, collab_type, postgrest);
          action.run_with_fix_interval(5, 10).await
        }
        .await,
      )
    });
    FutureResult::new(async { rx.await? })
  }

  fn batch_create_folder_collab_objects(
    &self,
    _workspace_id: &str,
    _objects: Vec<FolderCollabParams>,
  ) -> FutureResult<(), Error> {
    FutureResult::new(async {
      Err(anyhow!(
        "supabase server doesn't support batch create collab"
      ))
    })
  }

  fn service_name(&self) -> String {
    "Supabase".to_string()
  }

  fn publish_view(
    &self,
    _workspace_id: &str,
    _payload: Vec<PublishPayload>,
  ) -> FutureResult<(), Error> {
    FutureResult::new(async { Err(anyhow!("supabase server doesn't support publish view")) })
  }

  fn unpublish_views(
    &self,
    _workspace_id: &str,
    _view_ids: Vec<String>,
  ) -> FutureResult<(), Error> {
    FutureResult::new(async { Err(anyhow!("supabase server doesn't support unpublish views")) })
  }

  fn get_publish_info(&self, _view_id: &str) -> FutureResult<PublishInfo, Error> {
    FutureResult::new(async { Err(anyhow!("supabase server doesn't support publish info")) })
  }

  fn set_publish_namespace(
    &self,
    _workspace_id: &str,
    _new_namespace: &str,
  ) -> FutureResult<(), FlowyError> {
    FutureResult::new(async {
      Err(anyhow!(
        "supabase server doesn't support set publish namespace"
      ))
    })
  }

  fn get_publish_namespace(&self, _workspace_id: &str) -> FutureResult<String, Error> {
    FutureResult::new(async {
      Err(anyhow!(
        "supabase server doesn't support get publish namespace"
      ))
    })
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
    created_by: json.get("created_by").and_then(|value| value.as_i64()),
    last_edited_time: json
      .get("last_edited_time")
      .and_then(|value| value.as_i64())
      .unwrap_or(timestamp()),
    last_edited_by: json.get("last_edited_by").and_then(|value| value.as_i64()),
  })
}
