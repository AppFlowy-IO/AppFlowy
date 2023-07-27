use anyhow::Error;
use std::sync::Arc;

use postgrest::Postgrest;

use flowy_error::{internal_error, ErrorCode, FlowyError};
use flowy_user_deps::cloud::*;
use flowy_user_deps::entities::*;
use lib_infra::box_any::BoxAny;
use lib_infra::future::FutureResult;

use crate::supabase::storage_impls::pooler::USER_TABLE;
use crate::supabase::storage_impls::restful_api::util::InsertParamsBuilder;
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
      let response = postgrest
        .from(USER_TABLE)
        .select("*")
        .eq("uuid", &params.uuid.to_string())
        .execute()
        .await
        .map_err(|e| FlowyError::new(ErrorCode::HttpError, e))?;

      if response.status() == 200 {
        // is_new = false;
      } else {
        let insert = InsertParamsBuilder::new()
          .insert(USER_UUID, params.uuid.to_string())
          .build();
        let _response = postgrest
          .from(USER_TABLE)
          .insert(insert)
          .execute()
          .await
          .map_err(internal_error)?;
      }
      todo!()
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
