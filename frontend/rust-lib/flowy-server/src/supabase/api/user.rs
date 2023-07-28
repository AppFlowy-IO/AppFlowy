use std::str::FromStr;
use std::sync::Arc;

use anyhow::Error;
use uuid::Uuid;

use flowy_user_deps::cloud::*;
use flowy_user_deps::entities::*;
use lib_infra::box_any::BoxAny;
use lib_infra::future::FutureResult;

use crate::supabase::api::util::{ExtendedResponse, InsertParamsBuilder};
use crate::supabase::api::{PostgresWrapper, SupabaseServerService};
use crate::supabase::define::*;
use crate::supabase::entities::GetUserProfileParams;
use crate::supabase::entities::UidResponse;
use crate::supabase::entities::UserProfileResponse;

pub struct RESTfulSupabaseUserAuthServiceImpl<T> {
  server: T,
}

impl<T> RESTfulSupabaseUserAuthServiceImpl<T> {
  pub fn new(server: T) -> Self {
    Self { server }
  }
}

impl<T> UserService for RESTfulSupabaseUserAuthServiceImpl<T>
where
  T: SupabaseServerService,
{
  fn sign_up(&self, params: BoxAny) -> FutureResult<SignUpResponse, Error> {
    let try_get_postgrest = self.server.try_get_postgrest();
    FutureResult::new(async move {
      let postgrest = try_get_postgrest?;
      let params = third_party_params_from_box_any(params)?;
      let is_new_user = postgrest
        .from(USER_TABLE)
        .select("uid")
        .eq("uuid", params.uuid.to_string())
        .execute()
        .await?
        .get_value::<Vec<UidResponse>>()
        .await?
        .is_empty();

      // Insert the user if it's a new user. After the user is inserted, we can query the user profile
      // and workspaces. The profile and workspaces are created by the database trigger.
      if is_new_user {
        let insert_params = InsertParamsBuilder::new()
          .insert(USER_UUID, params.uuid.to_string())
          .insert(USER_EMAIL, params.email)
          .build();
        let resp = postgrest
          .from(USER_TABLE)
          .insert(insert_params)
          .execute()
          .await?
          .success_with_body()
          .await?;
        tracing::debug!("Create user response: {:?}", resp);
      }

      // Query the user profile and workspaces
      tracing::debug!("user uuid: {}", params.uuid);
      let user_profile =
        get_user_profile(postgrest.clone(), GetUserProfileParams::Uuid(params.uuid))
          .await?
          .unwrap();
      let user_workspaces = get_user_workspaces(postgrest.clone(), user_profile.uid).await?;
      let latest_workspace = user_workspaces
        .iter()
        .find(|user_workspace| user_workspace.id == user_profile.latest_workspace_id)
        .cloned();

      Ok(SignUpResponse {
        user_id: user_profile.uid,
        name: user_profile.name,
        latest_workspace: latest_workspace.unwrap(),
        user_workspaces,
        is_new: is_new_user,
        email: Some(user_profile.email),
        token: None,
      })
    })
  }

  fn sign_in(&self, params: BoxAny) -> FutureResult<SignInResponse, Error> {
    let try_get_postgrest = self.server.try_get_postgrest();
    FutureResult::new(async move {
      let postgrest = try_get_postgrest?;
      let params = third_party_params_from_box_any(params)?;
      let uuid = params.uuid;
      let user_profile = get_user_profile(postgrest.clone(), GetUserProfileParams::Uuid(uuid))
        .await?
        .unwrap();
      let user_workspaces = get_user_workspaces(postgrest.clone(), user_profile.uid).await?;
      let latest_workspace = user_workspaces
        .iter()
        .find(|user_workspace| user_workspace.id == user_profile.latest_workspace_id)
        .cloned();
      Ok(SignInResponse {
        user_id: user_profile.uid,
        name: "".to_string(),
        latest_workspace: latest_workspace.unwrap(),
        user_workspaces,
        email: None,
        token: None,
      })
    })
  }

  fn sign_out(&self, _token: Option<String>) -> FutureResult<(), Error> {
    FutureResult::new(async { Ok(()) })
  }

  fn update_user(
    &self,
    _credential: UserCredentials,
    params: UpdateUserProfileParams,
  ) -> FutureResult<(), Error> {
    let try_get_postgrest = self.server.try_get_postgrest();
    FutureResult::new(async move {
      let postgrest = try_get_postgrest?;
      update_user_profile(postgrest, params).await?;
      Ok(())
    })
  }

  fn get_user_profile(
    &self,
    credential: UserCredentials,
  ) -> FutureResult<Option<UserProfile>, Error> {
    let try_get_postgrest = self.server.try_get_postgrest();
    let uid = credential
      .uid
      .ok_or(anyhow::anyhow!("uid is required"))
      .unwrap();
    FutureResult::new(async move {
      let postgrest = try_get_postgrest?;
      let user_profile_resp = get_user_profile(postgrest, GetUserProfileParams::Uid(uid)).await?;
      match user_profile_resp {
        None => Ok(None),
        Some(user_profile_resp) => Ok(Some(UserProfile {
          id: user_profile_resp.uid,
          email: user_profile_resp.email,
          name: user_profile_resp.name,
          token: "".to_string(),
          icon_url: "".to_string(),
          openai_key: "".to_string(),
          workspace_id: user_profile_resp.latest_workspace_id,
          auth_type: AuthType::Supabase,
        })),
      }
    })
  }

  fn get_user_workspaces(&self, uid: i64) -> FutureResult<Vec<UserWorkspace>, Error> {
    let try_get_postgrest = self.server.try_get_postgrest();
    FutureResult::new(async move {
      let postgrest = try_get_postgrest?;
      let user_workspaces = get_user_workspaces(postgrest, uid).await?;
      Ok(user_workspaces)
    })
  }

  fn check_user(&self, credential: UserCredentials) -> FutureResult<(), Error> {
    let try_get_postgrest = self.server.try_get_postgrest();
    let uuid = credential.uuid.and_then(|uuid| Uuid::from_str(&uuid).ok());
    let uid = credential.uid;
    FutureResult::new(async move {
      let postgrest = try_get_postgrest?;
      check_user(postgrest, uid, uuid).await?;
      Ok(())
    })
  }

  fn add_workspace_member(
    &self,
    _user_email: String,
    _workspace_id: String,
  ) -> FutureResult<(), Error> {
    todo!()
  }

  fn remove_workspace_member(
    &self,
    _user_email: String,
    _workspace_id: String,
  ) -> FutureResult<(), Error> {
    todo!()
  }
}

async fn get_user_profile(
  postgrest: Arc<PostgresWrapper>,
  params: GetUserProfileParams,
) -> Result<Option<UserProfileResponse>, Error> {
  let mut builder = postgrest
    .from(USER_PROFILE_VIEW)
    .select("uid, email, name, latest_workspace_id");

  match params {
    GetUserProfileParams::Uid(uid) => builder = builder.eq("uid", uid.to_string()),
    GetUserProfileParams::Uuid(uuid) => builder = builder.eq("uuid", uuid.to_string()),
  }

  let mut profiles = builder
    .execute()
    .await?
    .error_for_status()?
    .get_value::<Vec<UserProfileResponse>>()
    .await?;
  match profiles.len() {
    0 => Ok(None),
    1 => Ok(Some(profiles.swap_remove(0))),
    _ => unreachable!(),
  }
}

async fn get_user_workspaces(
  postgrest: Arc<PostgresWrapper>,
  uid: i64,
) -> Result<Vec<UserWorkspace>, Error> {
  postgrest
    .from(WORKSPACE_TABLE)
    .select("id:workspace_id, name:workspace_name, created_at, database_storage_id")
    .eq("owner_uid", uid.to_string())
    .execute()
    .await?
    .error_for_status()?
    .get_value::<Vec<UserWorkspace>>()
    .await
}

async fn update_user_profile(
  postgrest: Arc<PostgresWrapper>,
  params: UpdateUserProfileParams,
) -> Result<(), Error> {
  if params.is_empty() {
    anyhow::bail!("no params to update");
  }

  // check if user exists
  let exists = !postgrest
    .from(USER_TABLE)
    .select("uid")
    .eq("uid", params.id.to_string())
    .execute()
    .await?
    .error_for_status()?
    .get_value::<Vec<UidResponse>>()
    .await?
    .is_empty();
  if !exists {
    anyhow::bail!("user uid {} does not exist", params.id);
  }

  let mut update_params = serde_json::Map::new();
  if let Some(name) = params.name {
    update_params.insert("name".to_string(), serde_json::json!(name));
  }
  if let Some(email) = params.email {
    update_params.insert("email".to_string(), serde_json::json!(email));
  }
  let update_payload = serde_json::to_string(&update_params).unwrap();

  let resp = postgrest
    .from(USER_TABLE)
    .update(update_payload)
    .eq("uid", params.id.to_string())
    .execute()
    .await?
    .success_with_body()
    .await?;

  tracing::debug!("update user profile resp: {:?}", resp);
  Ok(())
}

async fn check_user(
  postgrest: Arc<PostgresWrapper>,
  uid: Option<i64>,
  uuid: Option<Uuid>,
) -> Result<(), Error> {
  let mut builder = postgrest.from(USER_TABLE);

  if let Some(uid) = uid {
    builder = builder.eq("uid", uid.to_string());
  } else if let Some(uuid) = uuid {
    builder = builder.eq("uuid", uuid.to_string());
  } else {
    anyhow::bail!("uid or uuid is required");
  }

  let exists = !builder
    .execute()
    .await?
    .error_for_status()?
    .get_value::<Vec<UidResponse>>()
    .await?
    .is_empty();
  if !exists {
    anyhow::bail!("user does not exist, uid: {:?}, uuid: {:?}", uid, uuid);
  }
  Ok(())
}
