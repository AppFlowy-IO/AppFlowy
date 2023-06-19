use std::collections::HashMap;
use std::sync::Arc;

use postgrest::Postgrest;
use serde_json::json;

use flowy_error::{ErrorCode, FlowyError};
use flowy_folder2::deps::Workspace;
use flowy_user::entities::UpdateUserProfileParams;
use lib_infra::box_any::BoxAny;

use crate::supabase::impls::{
  USER_PROFILE_TABLE, USER_TABLE, USER_WORKSPACE_TABLE, WORKSPACE_NAME_COLUMN, WORKSPACE_TABLE,
};
use crate::supabase::response::{
  InsertResponse, PostgrestError, UserProfileResponse, UserProfileResponseList, UserWorkspaceList,
};

const USER_ID: &str = "uid";
const USER_UUID: &str = "uuid";

pub(crate) async fn create_user_with_uuid(
  postgrest: Arc<Postgrest>,
  uuid: String,
) -> Result<UserProfileResponse, FlowyError> {
  let mut insert = serde_json::Map::new();
  insert.insert(USER_UUID.to_string(), json!(&uuid));
  let insert_query = serde_json::to_string(&insert).unwrap();

  // Create a new user with uuid.
  let resp = postgrest
    .from(USER_TABLE)
    .insert(insert_query)
    .execute()
    .await
    .map_err(|e| FlowyError::new(ErrorCode::HttpError, e))?;

  // Check if the request is successful.
  // If the request is successful, get the user id from the response. Otherwise, try to get the
  // user id with uuid if the error is unique violation,
  let is_success = resp.status().is_success();
  let content = resp
    .text()
    .await
    .map_err(|e| FlowyError::new(ErrorCode::UnexpectedEmpty, e))?;

  if is_success {
    let record = serde_json::from_str::<InsertResponse>(&content)
      .map_err(|e| FlowyError::serde().context(e))?
      .first_or_error()?;

    get_user_profile(postgrest, GetUserProfileParams::Uid(record.uid)).await
  } else {
    let err = serde_json::from_str::<PostgrestError>(&content)
      .map_err(|e| FlowyError::serde().context(e))?;

    // If there is a unique violation, try to get the user id with uuid. At this point, the user
    // should exist.
    if err.is_unique_violation() {
      match get_user_profile(postgrest, GetUserProfileParams::Uuid(uuid)).await {
        Ok(user) => Ok(user),
        _ => Err(FlowyError::new(
          ErrorCode::Internal,
          "Failed to get user workspace",
        )),
      }
    } else {
      Err(FlowyError::new(ErrorCode::Internal, err))
    }
  }
}

#[allow(dead_code)]
pub(crate) async fn get_user_id_with_uuid(
  postgrest: Arc<Postgrest>,
  uuid: String,
) -> Result<Option<i64>, FlowyError> {
  let resp = postgrest
    .from(USER_TABLE)
    .eq(USER_UUID, uuid)
    .select("*")
    .execute()
    .await
    .map_err(|e| FlowyError::new(ErrorCode::HttpError, e))?;

  let is_success = resp.status().is_success();
  if !is_success {
    return Err(FlowyError::new(
      ErrorCode::Internal,
      "Failed to get user id with uuid",
    ));
  }

  let content = resp
    .text()
    .await
    .map_err(|e| FlowyError::new(ErrorCode::UnexpectedEmpty, e))?;
  let resp = serde_json::from_str::<InsertResponse>(&content).unwrap();
  if resp.0.is_empty() {
    Ok(None)
  } else {
    Ok(Some(resp.0[0].uid))
  }
}

pub(crate) fn uuid_from_box_any(any: BoxAny) -> Result<String, FlowyError> {
  let map: HashMap<String, String> = any.unbox_or_error()?;
  let uuid = map
    .get(USER_UUID)
    .ok_or_else(|| FlowyError::new(ErrorCode::MissingAuthField, "Missing uuid field"))?;
  Ok(uuid.to_string())
}

pub enum GetUserProfileParams {
  Uid(i64),
  Uuid(String),
}

pub(crate) async fn get_user_profile(
  postgrest: Arc<Postgrest>,
  params: GetUserProfileParams,
) -> Result<UserProfileResponse, FlowyError> {
  let mut builder = postgrest.from(USER_PROFILE_TABLE);
  match params {
    GetUserProfileParams::Uid(uid) => builder = builder.eq(USER_ID, uid.to_string()),
    GetUserProfileParams::Uuid(uuid) => builder = builder.eq(USER_UUID, uuid),
  }
  let resp = builder
    .select("*")
    .execute()
    .await
    .map_err(|e| FlowyError::new(ErrorCode::HttpError, e))?;

  let content = resp
    .text()
    .await
    .map_err(|e| FlowyError::new(ErrorCode::UnexpectedEmpty, e))?;
  let mut user_profiles =
    serde_json::from_str::<UserProfileResponseList>(&content).map_err(|_e| {
      FlowyError::new(
        ErrorCode::Serde,
        "Deserialize UserProfileResponseList failed",
      )
    })?;
  if user_profiles.0.is_empty() {
    return Err(FlowyError::new(
      ErrorCode::Internal,
      "Failed to get user profile",
    ));
  }
  Ok(user_profiles.0.remove(0))
}

pub(crate) async fn create_workspace_with_uid(
  postgrest: Arc<Postgrest>,
  uid: i64,
  name: &str,
) -> Result<Workspace, FlowyError> {
  let mut insert = serde_json::Map::new();
  insert.insert(USER_ID.to_string(), json!(uid));
  insert.insert(WORKSPACE_NAME_COLUMN.to_string(), json!(name));
  let insert_query = serde_json::to_string(&insert).unwrap();

  let resp = postgrest
    .from(WORKSPACE_TABLE)
    .insert(insert_query)
    .execute()
    .await
    .map_err(|e| FlowyError::new(ErrorCode::HttpError, e))?;

  let content = resp
    .text()
    .await
    .map_err(|e| FlowyError::new(ErrorCode::UnexpectedEmpty, e))?;
  let mut workspace_list = serde_json::from_str::<UserWorkspaceList>(&content)
    .map_err(|_e| FlowyError::new(ErrorCode::Serde, "Deserialize UserWorkspaceList failed"))?
    .into_inner();

  debug_assert!(workspace_list.len() == 1);
  if workspace_list.is_empty() {
    return Err(FlowyError::new(
      ErrorCode::Internal,
      "Failed to create workspace",
    ));
  }
  let user_workspace = workspace_list.remove(0);
  Ok(Workspace {
    id: user_workspace.workspace_id,
    name: user_workspace.workspace_name,
    child_views: Default::default(),
    created_at: user_workspace.created_at.timestamp(),
  })
}

#[allow(dead_code)]
pub(crate) async fn get_user_workspace_with_uid(
  postgrest: Arc<Postgrest>,
  uid: i64,
) -> Result<Vec<Workspace>, FlowyError> {
  let resp = postgrest
    .from(USER_WORKSPACE_TABLE)
    .eq(USER_ID, uid.to_string())
    .select("*")
    .execute()
    .await
    .map_err(|e| FlowyError::new(ErrorCode::HttpError, e))?;

  let content = resp
    .text()
    .await
    .map_err(|e| FlowyError::new(ErrorCode::UnexpectedEmpty, e))?;
  let user_workspaces = serde_json::from_str::<UserWorkspaceList>(&content)
    .map_err(|_e| FlowyError::new(ErrorCode::Serde, "Deserialize UserWorkspaceList failed"))?
    .0;
  Ok(
    user_workspaces
      .into_iter()
      .map(|user_workspace| Workspace {
        id: user_workspace.workspace_id,
        name: user_workspace.workspace_name,
        child_views: Default::default(),
        created_at: user_workspace.created_at.timestamp(),
      })
      .collect(),
  )
}

#[allow(dead_code)]
pub(crate) async fn update_user_profile(
  postgrest: Arc<Postgrest>,
  params: UpdateUserProfileParams,
) -> Result<Option<UserProfileResponse>, FlowyError> {
  if params.is_empty() {
    return Err(FlowyError::new(
      ErrorCode::UnexpectedEmpty,
      "Empty update params",
    ));
  }

  let mut update = serde_json::Map::new();
  if let Some(name) = params.name {
    update.insert("name".to_string(), json!(name));
  }
  let update_str = serde_json::to_string(&update).unwrap();
  let resp = postgrest
    .from(USER_PROFILE_TABLE)
    .eq(USER_ID, params.id.to_string())
    .update(update_str)
    .execute()
    .await
    .map_err(|e| FlowyError::new(ErrorCode::HttpError, e))?;

  let content = resp
    .text()
    .await
    .map_err(|e| FlowyError::new(ErrorCode::UnexpectedEmpty, e))?;

  let resp = serde_json::from_str::<UserProfileResponseList>(&content)
    .map_err(|_e| FlowyError::new(ErrorCode::Serde, "Deserialize UserProfileList failed"))?;
  Ok(resp.0.first().cloned())
}
