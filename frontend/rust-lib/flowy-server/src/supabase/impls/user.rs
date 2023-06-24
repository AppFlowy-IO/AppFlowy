use std::sync::Arc;

use tokio::sync::oneshot::channel;
use tokio_postgres::error::SqlState;
use uuid::Uuid;

use flowy_error::{internal_error, ErrorCode, FlowyError};
use flowy_user::entities::{SignInResponse, SignUpResponse, UpdateUserProfileParams, UserProfile};
use flowy_user::event_map::UserAuthService;
use lib_infra::box_any::BoxAny;
use lib_infra::future::FutureResult;

use crate::supabase::entities::{GetUserProfileParams, UserProfileResponse};
use crate::supabase::pg_db::{PostgresClient, UpdateSqlBuilder};
use crate::supabase::PostgresServer;
use crate::util::uuid_from_box_any;

pub(crate) const USER_TABLE: &str = "af_user";
pub(crate) const USER_PROFILE_TABLE: &str = "af_user_profile";

#[allow(dead_code)]
const USER_UUID: &str = "uuid";

pub(crate) struct PostgrestUserAuthServiceImpl {
  server: Arc<PostgresServer>,
}

impl PostgrestUserAuthServiceImpl {
  pub(crate) fn new(server: Arc<PostgresServer>) -> Self {
    Self { server }
  }
}

impl UserAuthService for PostgrestUserAuthServiceImpl {
  fn sign_up(&self, params: BoxAny) -> FutureResult<SignUpResponse, FlowyError> {
    let server = self.server.clone();
    let (tx, rx) = channel();
    tokio::spawn(async move {
      tx.send(
        async {
          let client = server.pg_client().await?;
          let uuid = uuid_from_box_any(params)?;
          create_user_with_uuid(&client, uuid).await
        }
        .await,
      )
    });
    FutureResult::new(async { rx.await.map_err(internal_error)? })
  }

  fn sign_in(&self, params: BoxAny) -> FutureResult<SignInResponse, FlowyError> {
    let server = self.server.clone();
    let (tx, rx) = channel();
    tokio::spawn(async move {
      tx.send(
        async {
          let client = server.pg_client().await?;
          let uuid = uuid_from_box_any(params)?;
          let user_profile = get_user_profile(&client, GetUserProfileParams::Uuid(uuid)).await?;
          Ok(SignInResponse {
            user_id: user_profile.uid,
            workspace_id: user_profile.workspace_id,
            ..Default::default()
          })
        }
        .await,
      )
    });
    FutureResult::new(async { rx.await.map_err(internal_error)? })
  }

  fn sign_out(&self, _token: Option<String>) -> FutureResult<(), FlowyError> {
    FutureResult::new(async { Ok(()) })
  }

  fn update_user(
    &self,
    _token: &Option<String>,
    params: UpdateUserProfileParams,
  ) -> FutureResult<(), FlowyError> {
    let server = self.server.clone();
    let (tx, rx) = channel();
    tokio::spawn(async move {
      tx.send(
        async move {
          let client = server.pg_client().await?;
          update_user_profile(&client, params).await
        }
        .await,
      )
    });
    FutureResult::new(async { rx.await.map_err(internal_error)? })
  }

  fn get_user_profile(
    &self,
    _token: Option<String>,
    uid: i64,
  ) -> FutureResult<Option<UserProfile>, FlowyError> {
    let server = self.server.clone();
    let (tx, rx) = channel();
    tokio::spawn(async move {
      tx.send(
        async move {
          let client = server.pg_client().await?;
          let user_profile = get_user_profile(&client, GetUserProfileParams::Uid(uid))
            .await
            .ok()
            .map(|user_profile| UserProfile {
              id: user_profile.uid,
              email: user_profile.email,
              name: user_profile.name,
              token: "".to_string(),
              icon_url: "".to_string(),
              openai_key: "".to_string(),
              workspace_id: user_profile.workspace_id,
            });
          Ok(user_profile)
        }
        .await,
      )
    });
    FutureResult::new(async { rx.await.map_err(internal_error)? })
  }
}

async fn create_user_with_uuid(
  client: &Arc<PostgresClient>,
  uuid: Uuid,
) -> Result<SignUpResponse, FlowyError> {
  if let Err(e) = client
    .execute(
      &format!("INSERT INTO {} (uuid) VALUES ($1);", USER_TABLE),
      &[&uuid],
    )
    .await
  {
    if let Some(code) = e.code() {
      if code != &SqlState::UNIQUE_VIOLATION {
        return Err(FlowyError::new(ErrorCode::PgDatabaseError, e));
      }
    }
  };

  let user_profile = get_user_profile(client, GetUserProfileParams::Uuid(uuid)).await?;
  Ok(SignUpResponse {
    user_id: user_profile.uid,
    workspace_id: user_profile.workspace_id,
    email: Some(user_profile.email),
    ..Default::default()
  })
}

async fn get_user_profile(
  client: &Arc<PostgresClient>,
  params: GetUserProfileParams,
) -> Result<UserProfileResponse, FlowyError> {
  let rows = match params {
    GetUserProfileParams::Uid(uid) => client
      .query(
        &format!("SELECT * FROM {} WHERE uid = $1", USER_PROFILE_TABLE),
        &[&uid],
      )
      .await
      .map_err(|e| FlowyError::new(ErrorCode::PgDatabaseError, e))?,
    GetUserProfileParams::Uuid(uuid) => client
      .query(
        &format!("SELECT * FROM {} WHERE uuid = $1", USER_PROFILE_TABLE),
        &[&uuid],
      )
      .await
      .map_err(|e| FlowyError::new(ErrorCode::PgDatabaseError, e))?,
  };

  let mut user_profiles = rows
    .into_iter()
    .map(UserProfileResponse::from)
    .collect::<Vec<_>>();
  if user_profiles.is_empty() {
    Err(FlowyError::record_not_found())
  } else {
    Ok(user_profiles.remove(0))
  }
}

async fn update_user_profile(
  client: &Arc<PostgresClient>,
  params: UpdateUserProfileParams,
) -> Result<(), FlowyError> {
  if params.is_empty() {
    return Err(FlowyError::new(
      ErrorCode::InvalidParams,
      format!("Update user profile params is empty: {:?}", params),
    ));
  }
  let (sql, pg_params) = UpdateSqlBuilder::new(USER_PROFILE_TABLE)
    .set("name", params.name)
    .set("email", params.email)
    .where_clause("uid", params.id)
    .build();

  let affect_rows = client
    .execute_raw(&sql, pg_params)
    .await
    .map_err(|e| FlowyError::new(ErrorCode::PgDatabaseError, e))?;
  tracing::trace!("Update user profile affect rows: {}", affect_rows);
  Ok(())
}

#[cfg(test)]
mod tests {
  use std::collections::HashMap;
  use std::sync::Arc;

  use uuid::Uuid;

  use flowy_user::entities::{SignUpResponse, UpdateUserProfileParams};
  use flowy_user::event_map::UserAuthService;
  use lib_infra::box_any::BoxAny;

  use crate::supabase::impls::user::USER_UUID;
  use crate::supabase::impls::PostgrestUserAuthServiceImpl;
  use crate::supabase::PostgresServer;

  // ‼️‼️‼️ Warning: this test will create a table in the database
  #[tokio::test]
  async fn user_sign_up_test() {
    if dotenv::from_filename("./.env.user.test").is_err() {
      return;
    }
    let server = Arc::new(PostgresServer::new());
    let user_service = PostgrestUserAuthServiceImpl::new(server);

    let mut params = HashMap::new();
    params.insert(USER_UUID.to_string(), Uuid::new_v4().to_string());
    let user: SignUpResponse = user_service.sign_up(BoxAny::new(params)).await.unwrap();
    assert!(!user.workspace_id.is_empty());
  }

  #[tokio::test]
  async fn user_sign_up_with_existing_uuid_test() {
    if dotenv::from_filename("./.env.user.test").is_err() {
      return;
    }
    let server = Arc::new(PostgresServer::new());
    let user_service = PostgrestUserAuthServiceImpl::new(server);
    let uuid = Uuid::new_v4();

    let mut params = HashMap::new();
    params.insert(USER_UUID.to_string(), uuid.to_string());
    let _user: SignUpResponse = user_service
      .sign_up(BoxAny::new(params.clone()))
      .await
      .unwrap();
    let user: SignUpResponse = user_service.sign_up(BoxAny::new(params)).await.unwrap();
    assert!(!user.workspace_id.is_empty());
  }

  #[tokio::test]
  async fn update_user_profile_test() {
    if dotenv::from_filename("./.env.user.test").is_err() {
      return;
    }
    let server = Arc::new(PostgresServer::new());
    let user_service = PostgrestUserAuthServiceImpl::new(server);
    let uuid = Uuid::new_v4();

    let mut params = HashMap::new();
    params.insert(USER_UUID.to_string(), uuid.to_string());
    let user: SignUpResponse = user_service
      .sign_up(BoxAny::new(params.clone()))
      .await
      .unwrap();

    user_service
      .update_user(
        &None,
        UpdateUserProfileParams {
          id: user.user_id,
          auth_type: Default::default(),
          name: Some("123".to_string()),
          email: Some("123@appflowy.io".to_string()),
          password: None,
          icon_url: None,
          openai_key: None,
        },
      )
      .await
      .unwrap();

    let user_profile = user_service
      .get_user_profile(None, user.user_id)
      .await
      .unwrap()
      .unwrap();

    assert_eq!(user_profile.name, "123");
  }
}
