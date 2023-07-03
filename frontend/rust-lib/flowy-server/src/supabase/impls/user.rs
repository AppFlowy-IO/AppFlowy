use std::str::FromStr;
use std::sync::Arc;

use deadpool_postgres::GenericClient;
use futures::pin_mut;
use futures_util::StreamExt;
use tokio::sync::oneshot::channel;
use tokio_postgres::error::SqlState;
use uuid::Uuid;

use flowy_error::{internal_error, ErrorCode, FlowyError};
use flowy_user::entities::{SignInResponse, SignUpResponse, UpdateUserProfileParams, UserProfile};
use flowy_user::event_map::{UserAuthService, UserCredentials};
use lib_infra::box_any::BoxAny;
use lib_infra::future::FutureResult;

use crate::supabase::entities::{GetUserProfileParams, UserProfileResponse};
use crate::supabase::pg_db::PostgresObject;
use crate::supabase::sql_builder::{SelectSqlBuilder, UpdateSqlBuilder};
use crate::supabase::PostgresServer;
use crate::util::uuid_from_box_any;

pub(crate) const USER_TABLE: &str = "af_user";
pub(crate) const USER_PROFILE_TABLE: &str = "af_user_profile";
pub const USER_UUID: &str = "uuid";

pub struct SupabaseUserAuthServiceImpl {
  server: Arc<PostgresServer>,
}

impl SupabaseUserAuthServiceImpl {
  pub fn new(server: Arc<PostgresServer>) -> Self {
    Self { server }
  }
}

impl UserAuthService for SupabaseUserAuthServiceImpl {
  fn sign_up(&self, params: BoxAny) -> FutureResult<SignUpResponse, FlowyError> {
    let server = self.server.clone();
    let (tx, rx) = channel();
    tokio::spawn(async move {
      tx.send(
        async {
          let client = server.get_pg_client().await.recv().await?;
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
          let client = server.get_pg_client().await.recv().await?;
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
    _credential: UserCredentials,
    params: UpdateUserProfileParams,
  ) -> FutureResult<(), FlowyError> {
    let server = self.server.clone();
    let (tx, rx) = channel();
    tokio::spawn(async move {
      tx.send(
        async move {
          let client = server.get_pg_client().await.recv().await?;
          update_user_profile(&client, params).await
        }
        .await,
      )
    });
    FutureResult::new(async { rx.await.map_err(internal_error)? })
  }

  fn get_user_profile(
    &self,
    credential: UserCredentials,
  ) -> FutureResult<Option<UserProfile>, FlowyError> {
    let server = self.server.clone();
    let (tx, rx) = channel();
    tokio::spawn(async move {
      tx.send(
        async move {
          let client = server.get_pg_client().await.recv().await?;
          let uid = credential
            .uid
            .ok_or(FlowyError::new(ErrorCode::InvalidParams, "uid is required"))?;
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

  fn check_user(&self, credential: UserCredentials) -> FutureResult<(), FlowyError> {
    let uuid = credential.uuid.and_then(|uuid| Uuid::from_str(&uuid).ok());
    let server = self.server.clone();
    let (tx, rx) = channel();
    tokio::spawn(async move {
      tx.send(
        async move {
          let client = server.get_pg_client().await.recv().await?;
          check_user(&client, credential.uid, uuid).await
        }
        .await,
      )
    });
    FutureResult::new(async { rx.await.map_err(internal_error)? })
  }
}

async fn create_user_with_uuid(
  client: &PostgresObject,
  uuid: Uuid,
) -> Result<SignUpResponse, FlowyError> {
  let mut is_new = true;
  if let Err(e) = client
    .execute(
      &format!("INSERT INTO {} (uuid) VALUES ($1);", USER_TABLE),
      &[&uuid],
    )
    .await
  {
    if let Some(code) = e.code() {
      if code == &SqlState::UNIQUE_VIOLATION {
        is_new = false;
      } else {
        return Err(FlowyError::new(ErrorCode::PgDatabaseError, e));
      }
    }
  };

  let user_profile = get_user_profile(client, GetUserProfileParams::Uuid(uuid)).await?;
  Ok(SignUpResponse {
    user_id: user_profile.uid,
    name: user_profile.name,
    workspace_id: user_profile.workspace_id,
    is_new,
    email: Some(user_profile.email),
    token: None,
  })
}

async fn get_user_profile(
  client: &PostgresObject,
  params: GetUserProfileParams,
) -> Result<UserProfileResponse, FlowyError> {
  let rows = match params {
    GetUserProfileParams::Uid(uid) => {
      let stmt = client
        .prepare_cached(&format!(
          "SELECT * FROM {} WHERE uid = $1",
          USER_PROFILE_TABLE
        ))
        .await
        .map_err(|e| FlowyError::new(ErrorCode::PgDatabaseError, e))?;

      client
        .query(&stmt, &[&uid])
        .await
        .map_err(|e| FlowyError::new(ErrorCode::PgDatabaseError, e))?
    },
    GetUserProfileParams::Uuid(uuid) => {
      let stmt = client
        .prepare_cached(&format!(
          "SELECT * FROM {} WHERE uuid = $1",
          USER_PROFILE_TABLE
        ))
        .await
        .map_err(|e| FlowyError::new(ErrorCode::PgDatabaseError, e))?;

      client
        .query(&stmt, &[&uuid])
        .await
        .map_err(|e| FlowyError::new(ErrorCode::PgDatabaseError, e))?
    },
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
  client: &PostgresObject,
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

  let stmt = client.prepare_cached(&sql).await.map_err(|e| {
    FlowyError::new(
      ErrorCode::PgDatabaseError,
      format!("Prepare update user profile sql error: {}", e),
    )
  })?;

  let affect_rows = client
    .execute_raw(&stmt, pg_params)
    .await
    .map_err(|e| FlowyError::new(ErrorCode::PgDatabaseError, e))?;
  tracing::trace!("Update user profile affect rows: {}", affect_rows);
  Ok(())
}

async fn check_user(
  client: &PostgresObject,
  uid: Option<i64>,
  uuid: Option<Uuid>,
) -> Result<(), FlowyError> {
  if uid.is_none() && uuid.is_none() {
    return Err(FlowyError::new(
      ErrorCode::InvalidParams,
      "uid and uuid can't be both empty",
    ));
  }

  let (sql, params) = match uid {
    None => SelectSqlBuilder::new(USER_TABLE)
      .where_clause("uuid", uuid.unwrap())
      .build(),
    Some(uid) => SelectSqlBuilder::new(USER_TABLE)
      .where_clause("uid", uid)
      .build(),
  };

  let stmt = client
    .prepare_cached(&sql)
    .await
    .map_err(|e| FlowyError::new(ErrorCode::PgDatabaseError, e))?;
  let rows = Box::pin(
    client
      .query_raw(&stmt, params)
      .await
      .map_err(|e| FlowyError::new(ErrorCode::PgDatabaseError, e))?,
  );
  pin_mut!(rows);

  // TODO(nathan): would it be better to use token.
  if rows.next().await.is_some() {
    Ok(())
  } else {
    Err(FlowyError::new(
      ErrorCode::UserNotExist,
      "Can't find the user in pg database",
    ))
  }
}
