use std::str::FromStr;

use deadpool_postgres::GenericClient;
use futures::pin_mut;
use futures_util::StreamExt;
use tokio::sync::oneshot::channel;
use tokio_postgres::error::SqlState;
use uuid::Uuid;

use flowy_error::{internal_error, ErrorCode, FlowyError, FlowyResult};
use flowy_user::entities::{SignInResponse, SignUpResponse, UpdateUserProfileParams, UserProfile};
use flowy_user::event_map::{UserAuthService, UserCredentials, UserWorkspace};
use flowy_user::services::{third_party_params_from_box_any, AuthType};
use lib_infra::box_any::BoxAny;
use lib_infra::future::FutureResult;

use crate::supabase::entities::{GetUserProfileParams, UserProfileResponse};
use crate::supabase::impls::util::try_upgrade_server;
use crate::supabase::postgres_db::{prepare_cached, PostgresObject};
use crate::supabase::sql_builder::{SelectSqlBuilder, UpdateSqlBuilder};
use crate::supabase::{PgConnectMode, SupabaseServerService};

pub(crate) const USER_TABLE: &str = "af_user";
pub(crate) const USER_PROFILE_VIEW: &str = "af_user_profile_view";
pub const USER_UUID: &str = "uuid";
pub const USER_EMAIL: &str = "email";

pub struct SupabaseUserAuthServiceImpl<T> {
  server: T,
}

impl<T> SupabaseUserAuthServiceImpl<T> {
  pub fn new(server: T) -> Self {
    Self { server }
  }
}

impl<T> UserAuthService for SupabaseUserAuthServiceImpl<T>
where
  T: SupabaseServerService,
{
  fn sign_up(&self, params: BoxAny) -> FutureResult<SignUpResponse, FlowyError> {
    let weak_server = self.server.try_get_pg_server();
    let (tx, rx) = channel();
    tokio::spawn(async move {
      tx.send(
        async move {
          let server = try_upgrade_server(weak_server)?;
          let mut client = server.get_pg_client().await.recv().await?;
          let params = third_party_params_from_box_any(params)?;
          create_user_with_uuid(&mut client, params.uuid, params.email)
            .await
            .map_err(|err| {
              err
                .downcast::<FlowyError>()
                .unwrap_or_else(|err| FlowyError::new(ErrorCode::PgDatabaseError, err))
            })
        }
        .await,
      )
    });
    FutureResult::new(async { rx.await.map_err(internal_error)? })
  }

  fn sign_in(&self, params: BoxAny) -> FutureResult<SignInResponse, FlowyError> {
    let server = self.server.try_get_pg_server();
    let (tx, rx) = channel();
    tokio::spawn(async move {
      tx.send(
        async {
          let server = try_upgrade_server(server)?;
          let client = server.get_pg_client().await.recv().await?;
          let uuid = third_party_params_from_box_any(params)?.uuid;
          let user_profile = get_user_profile(&client, GetUserProfileParams::Uuid(uuid)).await?;
          let user_workspace = get_latest_user_workspace(&client, user_profile.uid).await?;
          Ok(SignInResponse {
            user_id: user_profile.uid,
            name: "".to_string(),
            user_workspace,
            email: None,
            token: None,
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
    let pg_mode = self.server.get_pg_mode();
    let weak_server = self.server.try_get_pg_server();
    let (tx, rx) = channel();
    tokio::spawn(async move {
      tx.send(
        async move {
          if let Some(server) = weak_server?.upgrade() {
            let client = server.get_pg_client().await.recv().await?;
            update_user_profile(&client, &pg_mode, params).await
          } else {
            Ok(())
          }
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
    let weak_server = self.server.try_get_pg_server();
    let (tx, rx) = channel();
    tokio::spawn(async move {
      tx.send(
        async move {
          if let Some(server) = weak_server?.upgrade() {
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
                workspace_id: user_profile.latest_workspace_id,
                auth_type: AuthType::Supabase,
              });
            Ok(user_profile)
          } else {
            Ok(None)
          }
        }
        .await,
      )
    });
    FutureResult::new(async { rx.await.map_err(internal_error)? })
  }

  fn get_latest_user_workspace(&self, uid: i64) -> FutureResult<UserWorkspace, FlowyError> {
    let server = self.server.try_get_pg_server();
    let (tx, rx) = channel();
    tokio::spawn(async move {
      tx.send(
        async {
          let server = try_upgrade_server(server)?;
          let client = server.get_pg_client().await.recv().await?;
          get_latest_user_workspace(&client, uid).await
        }
        .await,
      )
    });
    FutureResult::new(async { rx.await.map_err(internal_error)? })
  }

  fn check_user(&self, credential: UserCredentials) -> FutureResult<(), FlowyError> {
    let uuid = credential.uuid.and_then(|uuid| Uuid::from_str(&uuid).ok());
    let weak_server = self.server.try_get_pg_server();
    let pg_mode = self.server.get_pg_mode();
    let (tx, rx) = channel();
    tokio::spawn(async move {
      tx.send(
        async move {
          let server = try_upgrade_server(weak_server)?;
          let client = server.get_pg_client().await.recv().await?;
          check_user(&client, &pg_mode, credential.uid, uuid).await
        }
        .await,
      )
    });
    FutureResult::new(async { rx.await.map_err(internal_error)? })
  }
}

async fn create_user_with_uuid(
  client: &mut PostgresObject,
  uuid: Uuid,
  email: String,
) -> Result<SignUpResponse, anyhow::Error> {
  let mut is_new = true;
  let row = client
    .query_one(
      &format!(
        "SELECT EXISTS (SELECT 1 FROM {} WHERE uuid = $1)",
        USER_TABLE
      ),
      &[&uuid],
    )
    .await?;
  if row.get::<'_, usize, bool>(0) {
    is_new = false;
  } else if let Err(err) = client
    .execute(
      &format!("INSERT INTO {} (uuid, email) VALUES ($1,$2);", USER_TABLE),
      &[&uuid, &email],
    )
    .await
  {
    if let Some(db_error) = err.as_db_error() {
      if db_error.code() == &SqlState::UNIQUE_VIOLATION {
        let detail = db_error.detail();
        tracing::error!("create user failed:{:?}", detail);
        return Err(FlowyError::email_exist().context(db_error.message()).into());
      }
    }
    return Err(err.into());
  }

  let user_profile = get_user_profile(client, GetUserProfileParams::Uuid(uuid)).await?;
  let user_workspace = get_latest_user_workspace(client, user_profile.uid).await?;
  Ok(SignUpResponse {
    user_id: user_profile.uid,
    name: user_profile.name,
    user_workspace,
    is_new,
    email: Some(user_profile.email),
    token: None,
  })
}

async fn get_latest_user_workspace<C: GenericClient>(
  _client: &C,
  _uid: i64,
) -> FlowyResult<UserWorkspace> {
  todo!()
}

/// Returns the user profile of the given user.
/// Can't use `get_user_profile` with sign up in the same transaction because
/// there is a trigger on the user table that creates a user profile.
async fn get_user_profile<C: GenericClient>(
  client: &C,
  params: GetUserProfileParams,
) -> Result<UserProfileResponse, FlowyError> {
  let rows = match params {
    GetUserProfileParams::Uid(uid) => {
      let stmt = format!("SELECT * FROM {} WHERE uid = $1", USER_PROFILE_VIEW);
      client
        .query(&stmt, &[&uid])
        .await
        .map_err(|e| FlowyError::new(ErrorCode::PgDatabaseError, e))?
    },
    GetUserProfileParams::Uuid(uuid) => {
      let stmt = format!("SELECT * FROM {} WHERE uuid = $1", USER_PROFILE_VIEW);
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
  pg_mode: &PgConnectMode,
  params: UpdateUserProfileParams,
) -> Result<(), FlowyError> {
  if params.is_empty() {
    return Err(FlowyError::new(
      ErrorCode::InvalidParams,
      format!("Update user profile params is empty: {:?}", params),
    ));
  }

  // The email is unique, so we need to check if the email already exists.
  if let Some(email) = params.email.as_ref() {
    let row = client
      .query_one(
        &format!(
          "SELECT EXISTS (SELECT 1 FROM {} WHERE email = $1 and uid != $2)",
          USER_TABLE
        ),
        &[&email, &params.id],
      )
      .await
      .map_err(|e| FlowyError::new(ErrorCode::PgDatabaseError, e))?;
    if row.get::<'_, usize, bool>(0) {
      return Err(FlowyError::new(
        ErrorCode::EmailAlreadyExists,
        format!("Email {} already exists", email),
      ));
    }
  }

  let (sql, pg_params) = UpdateSqlBuilder::new(USER_TABLE)
    .set("name", params.name)
    .set("email", params.email)
    .where_clause("uid", params.id)
    .build();
  let stmt = prepare_cached(pg_mode, sql, client).await.map_err(|e| {
    FlowyError::new(
      ErrorCode::PgDatabaseError,
      format!("Prepare update user profile sql error: {}", e),
    )
  })?;

  let affect_rows = client
    .execute_raw(stmt.as_ref(), pg_params)
    .await
    .map_err(|e| FlowyError::new(ErrorCode::PgDatabaseError, e))?;
  tracing::trace!("Update user profile affect rows: {}", affect_rows);
  Ok(())
}

async fn check_user(
  client: &PostgresObject,
  pg_mode: &PgConnectMode,
  uid: Option<i64>,
  uuid: Option<Uuid>,
) -> Result<(), FlowyError> {
  if uid.is_none() && uuid.is_none() {
    return Err(FlowyError::new(
      ErrorCode::InvalidParams,
      "uid and uuid can't be both empty",
    ));
  }

  let (stmt, params) = match uid {
    None => SelectSqlBuilder::new(USER_TABLE)
      .where_clause("uuid", uuid.unwrap())
      .build(),
    Some(uid) => SelectSqlBuilder::new(USER_TABLE)
      .where_clause("uid", uid)
      .build(),
  };

  let stmt = prepare_cached(pg_mode, stmt, client)
    .await
    .map_err(|e| FlowyError::new(ErrorCode::PgDatabaseError, e))?;
  let rows = Box::pin(
    client
      .query_raw(stmt.as_ref(), params)
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
