use anyhow::Error;
use hyper::http::StatusCode;
use std::sync::Arc;

use postgrest::Postgrest;
use reqwest::Response;

use flowy_error::{internal_error, ErrorCode, FlowyError};
use flowy_user_deps::cloud::*;
use flowy_user_deps::entities::*;
use lib_infra::box_any::BoxAny;
use lib_infra::future::FutureResult;

use crate::supabase::entities::GetUserProfileParams;
use crate::supabase::storage_impls::restful_api::util::InsertParamsBuilder;
use crate::supabase::storage_impls::USER_EMAIL;
use crate::supabase::storage_impls::USER_TABLE;
use crate::supabase::storage_impls::USER_UUID;

pub struct RESTfulSupabaseUserAuthServiceImpl {
  postgrest: Arc<Postgrest>,
}

impl RESTfulSupabaseUserAuthServiceImpl {
  pub fn new(postgrest: Arc<Postgrest>) -> Self {
    Self { postgrest }
  }
}

impl UserService for RESTfulSupabaseUserAuthServiceImpl {
  fn sign_up(&self, params: BoxAny) -> FutureResult<SignUpResponse, Error> {
    let postgrest = self.postgrest.clone();
    FutureResult::new(async move {
      // let mut is_new = true;
      let params = third_party_params_from_box_any(params)?;
      let params_uuid = params.uuid;
      let params_uuid_str = params_uuid.to_string();

      let response = postgrest
        .from(USER_TABLE)
        .select("uid")
        .eq("uuid", params_uuid_str)
        .execute()
        .await
        .map_err(|e| FlowyError::new(ErrorCode::HttpError, e))?;

      let uids: Vec<i64> = from_response(response).await?;
      println!("uids: {:?}", uids);

      if uids.len() > 1 {
        return Err(FlowyError::new(
          ErrorCode::HttpError,
          format!("expected 0 or 1 records, but got {}", uids.len()),
        ));
      }

      if uids.len() == 0 {
        let insert_params = InsertParamsBuilder::new()
          .insert(USER_UUID, params.uuid)
          .insert(USER_EMAIL, params.email)
          .build();
        let response = postgrest
          .from(USER_TABLE)
          .insert(insert_params)
          .execute()
          .await
          .map_err(internal_error)?;
        if response.status() != StatusCode::OK {
          return Err(FlowyError::new(
            ErrorCode::HttpError,
            format!(
              "user creation error. expected status code 200, but got {}, body: {}",
              response.status(),
              response.text().await.unwrap_or_default()
            ),
          ));
        }
      }

      println!("user uuid: {}", params_uuid);

      let user_profile =
        get_user_profile(postgrest.clone(), GetUserProfileParams::Uuid(params_uuid))?;
      let user_workspaces = get_user_workspaces(postgrest, user_profile.id)?;
      let latest_workspace = user_workspaces
        .iter()
        .find(|user_workspace| user_workspace.id == user_profile.workspace_id)
        .cloned();

      Ok(SignUpResponse {
        user_id: user_profile.id,
        name: user_profile.name,
        latest_workspace: latest_workspace.unwrap(),
        user_workspaces,
        is_new: uids.len() == 0,
        email: {
          if user_profile.email.len() == 0 {
            None
          } else {
            Some(user_profile.email)
          }
        },
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

fn get_user_profile(
  postgrest: Arc<Postgrest>,
  params: GetUserProfileParams,
) -> Result<UserProfile, FlowyError> {
  todo!()
}

fn get_user_workspaces(
  postgrest: Arc<Postgrest>,
  uid: i64,
) -> Result<Vec<UserWorkspace>, FlowyError> {
  todo!()
}

async fn from_response<T>(response: Response) -> Result<T, FlowyError>
where
  T: serde::de::DeserializeOwned,
{
  if response.status() != StatusCode::OK {
    return Err(FlowyError::new(
      ErrorCode::HttpError,
      format!(
        "expected status code 200, but got {}, body: {}",
        response.status(),
        response.text().await.unwrap_or_default()
      ),
    ));
  }
  let text = response.text().await.map_err(internal_error)?;

  serde_json::from_str(&text).map_err(|e| FlowyError::new(ErrorCode::HttpError, e))
}
