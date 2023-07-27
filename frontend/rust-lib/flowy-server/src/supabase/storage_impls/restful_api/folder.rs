use crate::supabase::storage_impls::pooler::{
  CREATED_AT, WORKSPACE_ID, WORKSPACE_NAME, WORKSPACE_TABLE,
};
use crate::supabase::storage_impls::restful_api::util::{ExtendedResponse, InsertParamsBuilder};
use crate::supabase::storage_impls::restful_api::PostgresWrapper;
use crate::supabase::storage_impls::OWNER_USER_UID;
use anyhow::Error;
use chrono::{DateTime, Utc};
use flowy_folder_deps::cloud::{
  gen_workspace_id, FolderCloudService, FolderData, FolderSnapshot, Workspace,
};
use lib_infra::future::FutureResult;
use serde_json::Value;
use std::str::FromStr;
use std::sync::Arc;

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

  fn get_folder_data(&self, _workspace_id: &str) -> FutureResult<Option<FolderData>, Error> {
    todo!()
  }

  fn get_folder_latest_snapshot(
    &self,
    _workspace_id: &str,
  ) -> FutureResult<Option<FolderSnapshot>, Error> {
    todo!()
  }

  fn get_folder_updates(
    &self,
    _workspace_id: &str,
    _uid: i64,
  ) -> FutureResult<Vec<Vec<u8>>, Error> {
    todo!()
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
