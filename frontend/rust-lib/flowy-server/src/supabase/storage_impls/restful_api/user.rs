use anyhow::Error;

use anyhow::anyhow;
use flowy_error::internal_error;
use reqwest::Response;
use std::sync::Arc;

use flowy_user_deps::cloud::*;
use flowy_user_deps::entities::*;
use lib_infra::box_any::BoxAny;
use lib_infra::future::FutureResult;

use crate::supabase::entities::GetUserProfileParams;
use crate::supabase::storage_impls::restful_api::util::{ExtendedResponse, InsertParamsBuilder};
use crate::supabase::storage_impls::restful_api::PostgresWrapper;
use crate::supabase::storage_impls::USER_EMAIL;
use crate::supabase::storage_impls::USER_TABLE;
use crate::supabase::storage_impls::USER_UUID;
use crate::supabase::storage_impls::WORKSPACE_TABLE;

pub struct RESTfulSupabaseUserAuthServiceImpl {
  postgrest: Arc<PostgresWrapper>,
}

impl RESTfulSupabaseUserAuthServiceImpl {
  pub fn new(postgrest: Arc<PostgresWrapper>) -> Self {
    Self { postgrest }
  }
}

impl UserService for RESTfulSupabaseUserAuthServiceImpl {
  fn sign_up(&self, params: BoxAny) -> FutureResult<SignUpResponse, Error> {
    let postgrest = self.postgrest.clone();
    FutureResult::new(async move {
      let params = third_party_params_from_box_any(params)?;
      let is_new_user = postgrest
        .from(USER_TABLE)
        .select("uid")
        .eq("uuid", params.uuid.to_string())
        .execute()
        .await?
        .get_value::<Vec<i64>>()
        .await?
        .is_empty();

      // Insert the user if it's a new user. After the user is inserted, we can query the user profile
      // and workspaces. The profile and workspaces are created by the database trigger.
      if is_new_user {
        let insert_params = InsertParamsBuilder::new()
          .insert(USER_UUID, params.uuid.to_string())
          .insert(USER_EMAIL, params.email)
          .build();
        let response = postgrest
          .from(USER_TABLE)
          .insert(insert_params)
          .execute()
          .await?
          .error_for_status()?;
        tracing::debug!("Create user response: {:?}", response.text().await);
      }

      // Query the user profile and workspaces
      tracing::debug!("user uuid: {}", params.uuid);
      let user_profile =
        get_user_profile(postgrest.clone(), GetUserProfileParams::Uuid(params.uuid)).await?;
      let user_workspaces = get_user_workspaces(postgrest.clone(), user_profile.id).await?;
      let latest_workspace = user_workspaces
        .iter()
        .find(|user_workspace| user_workspace.id == user_profile.workspace_id)
        .cloned();

      Ok(SignUpResponse {
        user_id: user_profile.id,
        name: user_profile.name,
        latest_workspace: latest_workspace.unwrap(),
        user_workspaces,
        is_new: is_new_user,
        email: Some(user_profile.email),
        token: None,
      })
    })
  }

  fn sign_in(&self, _params: BoxAny) -> FutureResult<SignInResponse, Error> {
    todo!()
  }

  fn sign_out(&self, _token: Option<String>) -> FutureResult<(), Error> {
    todo!()
  }

  fn update_user(
    &self,
    _credential: UserCredentials,
    _params: UpdateUserProfileParams,
  ) -> FutureResult<(), Error> {
    todo!()
  }

  fn get_user_profile(
    &self,
    _credential: UserCredentials,
  ) -> FutureResult<Option<UserProfile>, Error> {
    todo!()
  }

  fn get_user_workspaces(&self, _uid: i64) -> FutureResult<Vec<UserWorkspace>, Error> {
    todo!()
  }

  fn check_user(&self, _credential: UserCredentials) -> FutureResult<(), Error> {
    todo!()
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
  _postgrest: Arc<PostgresWrapper>,
  _params: GetUserProfileParams,
) -> Result<UserProfile, Error> {
  todo!()
}

async fn get_user_workspaces(
  postgrest: Arc<PostgresWrapper>,
  uid: i64,
) -> Result<Vec<UserWorkspace>, Error> {
  postgrest
    .from(WORKSPACE_TABLE)
    .select("workspace_id, workspace_name, created_at, database_storage_id")
    .eq("owner_uid", uid.to_string())
    .execute()
    .await?
    .error_for_status()?
    .get_value::<Vec<UserWorkspace>>()
    .await
}
