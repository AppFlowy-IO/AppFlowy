use std::collections::HashMap;
use std::sync::Arc;

use postgrest::Postgrest;
use serde_json::json;

use flowy_error::{ErrorCode, FlowyError};
use flowy_user::entities::UpdateUserProfileParams;
use lib_infra::box_any::BoxAny;

use crate::supabase::response::{
  InsertResponse, PostgrestError, UserProfile, UserProfileList, UserWorkspace, UserWorkspaceList,
};
use crate::supabase::user::{USER_PROFILE_TABLE, USER_TABLE, USER_WORKSPACE_TABLE};

const USER_ID: &str = "uid";
const USER_UUID: &str = "uuid";

pub(crate) async fn create_user_with_uuid(
  postgrest: Arc<Postgrest>,
  uuid: String,
) -> Result<UserWorkspace, FlowyError> {
  let insert = format!("{{\"{}\": \"{}\"}}", USER_UUID, &uuid);

  // Create a new user with uuid.
  let resp = postgrest
    .from(USER_TABLE)
    .insert(insert)
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

    match get_user_workspace_with_uid(postgrest, record.uid).await {
      Ok(Some(user)) => Ok(user),
      _ => Err(FlowyError::new(
        ErrorCode::Internal,
        "Failed to get user workspace",
      )),
    }
  } else {
    let err = serde_json::from_str::<PostgrestError>(&content)
      .map_err(|e| FlowyError::serde().context(e))?;

    // If there is a unique violation, try to get the user id with uuid. At this point, the user
    // should exist.
    if err.is_unique_violation() {
      match get_user_workspace_with_uuid(postgrest, uuid).await {
        Ok(Some(user)) => Ok(user),
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

#[allow(dead_code)]
pub(crate) async fn get_user_profile(
  postgrest: Arc<Postgrest>,
  uid: i64,
) -> Result<Option<UserProfile>, FlowyError> {
  let resp = postgrest
    .from(USER_PROFILE_TABLE)
    .eq(USER_ID, uid.to_string())
    .select("*")
    .execute()
    .await
    .map_err(|e| FlowyError::new(ErrorCode::HttpError, e))?;

  let content = resp
    .text()
    .await
    .map_err(|e| FlowyError::new(ErrorCode::UnexpectedEmpty, e))?;
  let resp = serde_json::from_str::<UserProfileList>(&content)
    .map_err(|_e| FlowyError::new(ErrorCode::Serde, "Deserialize UserProfileList failed"))?;
  Ok(resp.0.first().cloned())
}

pub(crate) async fn get_user_workspace_with_uuid(
  postgrest: Arc<Postgrest>,
  uuid: String,
) -> Result<Option<UserWorkspace>, FlowyError> {
  let resp = postgrest
    .from(USER_WORKSPACE_TABLE)
    .eq(USER_UUID, uuid)
    .select("*")
    .execute()
    .await
    .map_err(|e| FlowyError::new(ErrorCode::HttpError, e))?;

  let content = resp
    .text()
    .await
    .map_err(|e| FlowyError::new(ErrorCode::UnexpectedEmpty, e))?;
  let resp = serde_json::from_str::<UserWorkspaceList>(&content)
    .map_err(|_e| FlowyError::new(ErrorCode::Serde, "Deserialize UserWorkspaceList failed"))?;
  Ok(resp.0.first().cloned())
}

pub(crate) async fn get_user_workspace_with_uid(
  postgrest: Arc<Postgrest>,
  uid: i64,
) -> Result<Option<UserWorkspace>, FlowyError> {
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
  let resp = serde_json::from_str::<UserWorkspaceList>(&content)
    .map_err(|_e| FlowyError::new(ErrorCode::Serde, "Deserialize UserWorkspaceList failed"))?;
  Ok(resp.0.first().cloned())
}

#[allow(dead_code)]
pub(crate) async fn update_user_profile(
  postgrest: Arc<Postgrest>,
  params: UpdateUserProfileParams,
) -> Result<Option<UserProfile>, FlowyError> {
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

  let resp = serde_json::from_str::<UserProfileList>(&content)
    .map_err(|_e| FlowyError::new(ErrorCode::Serde, "Deserialize UserProfileList failed"))?;
  Ok(resp.0.first().cloned())
}
