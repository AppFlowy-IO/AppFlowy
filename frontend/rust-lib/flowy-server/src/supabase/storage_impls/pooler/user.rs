use anyhow::Error;
use std::str::FromStr;

use chrono::{DateTime, Utc};
use deadpool_postgres::{GenericClient, Transaction};
use futures::pin_mut;
use futures_util::StreamExt;
use tokio_postgres::error::SqlState;
use uuid::Uuid;

use flowy_error::{ErrorCode, FlowyError};
use flowy_user_deps::cloud::*;
use flowy_user_deps::entities::*;
use lib_infra::box_any::BoxAny;
use lib_infra::future::FutureResult;

use crate::supabase::entities::{GetUserProfileParams, UserProfileResponse};
use crate::supabase::storage_impls::pooler::sql_builder::{SelectSqlBuilder, UpdateSqlBuilder};
use crate::supabase::storage_impls::pooler::util::execute_async;
use crate::supabase::storage_impls::pooler::{
  prepare_cached, PostgresObject, SupabaseServerService,
};
use crate::supabase::PgPoolMode;

pub(crate) const USER_TABLE: &str = "af_user";
pub(crate) const USER_PROFILE_VIEW: &str = "af_user_profile_view";

pub struct SupabaseUserAuthServiceImpl<T> {
  server: T,
}

impl<T> SupabaseUserAuthServiceImpl<T> {
  pub fn new(server: T) -> Self {
    Self { server }
  }
}

impl<T> UserService for SupabaseUserAuthServiceImpl<T>
where
  T: SupabaseServerService,
{
  fn sign_up(&self, params: BoxAny) -> FutureResult<SignUpResponse, Error> {
    execute_async(&self.server, move |mut pg_client, pg_mode| {
      Box::pin(async move {
        let params = third_party_params_from_box_any(params)?;
        let response =
          create_user_with_uuid(&mut pg_client, &pg_mode, params.uuid, params.email).await?;
        Ok(response)
      })
    })
  }

  fn sign_in(&self, params: BoxAny) -> FutureResult<SignInResponse, Error> {
    execute_async(&self.server, move |mut pg_client, pg_mode| {
      Box::pin(async move {
        let uuid = third_party_params_from_box_any(params)?.uuid;
        let txn = pg_client.transaction().await?;
        let user_profile = get_user_profile(&txn, GetUserProfileParams::Uuid(uuid)).await?;
        let user_workspaces = get_user_workspaces(&txn, &pg_mode, user_profile.uid).await?;
        txn.commit().await?;
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
    execute_async(&self.server, move |mut pg_client, pg_mode| {
      Box::pin(async move {
        let txn = pg_client.transaction().await?;
        update_user_profile(&txn, &pg_mode, params).await?;
        txn.commit().await?;
        Ok(())
      })
    })
  }

  fn get_user_profile(
    &self,
    credential: UserCredentials,
  ) -> FutureResult<Option<UserProfile>, Error> {
    execute_async(&self.server, move |mut pg_client, _pg_mode| {
      Box::pin(async move {
        let uid = credential
          .uid
          .ok_or(FlowyError::new(ErrorCode::InvalidParams, "uid is required"))?;
        let txn = pg_client.transaction().await?;
        let user_profile = get_user_profile(&txn, GetUserProfileParams::Uid(uid))
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
        txn.commit().await?;
        Ok(user_profile)
      })
    })
  }

  fn get_user_workspaces(&self, uid: i64) -> FutureResult<Vec<UserWorkspace>, Error> {
    execute_async(&self.server, move |mut pg_client, pg_mode| {
      Box::pin(async move {
        let txn = pg_client.transaction().await?;
        let result = get_user_workspaces(&txn, &pg_mode, uid).await?;
        txn.commit().await?;
        Ok(result)
      })
    })
  }

  fn check_user(&self, credential: UserCredentials) -> FutureResult<(), Error> {
    let uuid = credential.uuid.and_then(|uuid| Uuid::from_str(&uuid).ok());
    execute_async(&self.server, move |mut pg_client, pg_mode| {
      Box::pin(async move {
        let txn = pg_client.transaction().await?;
        check_user(&txn, &pg_mode, credential.uid, uuid).await?;
        txn.commit().await?;
        Ok(())
      })
    })
  }

  fn add_workspace_member(
    &self,
    user_email: String,
    workspace_id: String,
  ) -> FutureResult<(), Error> {
    execute_async(&self.server, move |pg_client, pg_mode| {
      Box::pin(
        async move { add_workspace_member(&pg_client, &pg_mode, user_email, workspace_id).await },
      )
    })
  }

  fn remove_workspace_member(
    &self,
    user_email: String,
    workspace_id: String,
  ) -> FutureResult<(), Error> {
    execute_async(&self.server, move |pg_client, pg_mode| {
      Box::pin(async move {
        remove_workspace_member(&pg_client, &pg_mode, user_email, workspace_id).await
      })
    })
  }
}

async fn create_user_with_uuid(
  client: &mut PostgresObject,
  pg_mode: &PgPoolMode,
  uuid: Uuid,
  email: String,
) -> Result<SignUpResponse, Error> {
  let mut is_new = true;
  let txn = client.transaction().await?;
  let row = txn
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
  } else if let Err(err) = txn
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
  txn.commit().await?;

  let txn = client.transaction().await?;
  let user_profile = get_user_profile(&txn, GetUserProfileParams::Uuid(uuid)).await?;
  let user_workspaces = get_user_workspaces(&txn, pg_mode, user_profile.uid).await?;
  let latest_workspace = user_workspaces
    .iter()
    .find(|user_workspace| user_workspace.id == user_profile.latest_workspace_id)
    .cloned();
  txn.commit().await?;

  Ok(SignUpResponse {
    user_id: user_profile.uid,
    name: user_profile.name,
    latest_workspace: latest_workspace.unwrap(),
    user_workspaces,
    is_new,
    email: Some(user_profile.email),
    token: None,
  })
}

async fn get_user_workspaces<'a>(
  transaction: &'a Transaction<'a>,
  pg_mode: &PgPoolMode,
  uid: i64,
) -> Result<Vec<UserWorkspace>, Error> {
  let sql = r#"
      SELECT af_workspace.*
      FROM af_workspace
      INNER JOIN af_workspace_member
        ON af_workspace.workspace_id = af_workspace_member.workspace_id
      WHERE af_workspace_member.uid = $1"#;
  let stmt = prepare_cached(pg_mode, sql.to_string(), transaction).await?;
  let all_rows = transaction.query(stmt.as_ref(), &[&uid]).await?;
  Ok(
    all_rows
      .into_iter()
      .flat_map(|row| {
        let workspace_id: Uuid = row.try_get("workspace_id").ok()?;
        let database_storage_id: Uuid = row.try_get("database_storage_id").ok()?;
        let created_at: DateTime<Utc> = row.try_get("created_at").ok()?;
        let workspace_name: String = row.try_get("workspace_name").ok()?;
        Some(UserWorkspace {
          id: workspace_id.to_string(),
          name: workspace_name,
          created_at,
          database_storage_id: database_storage_id.to_string(),
        })
      })
      .collect(),
  )
}

/// Returns the user profile of the given user.
/// Can't use `get_user_profile` with sign up in the same transaction because
/// there is a trigger on the user table that creates a user profile.
async fn get_user_profile<'a>(
  transaction: &'a Transaction<'a>,
  params: GetUserProfileParams,
) -> Result<UserProfileResponse, FlowyError> {
  let rows = match params {
    GetUserProfileParams::Uid(uid) => {
      let stmt = format!("SELECT * FROM {} WHERE uid = $1", USER_PROFILE_VIEW);
      transaction
        .query(&stmt, &[&uid])
        .await
        .map_err(|e| FlowyError::new(ErrorCode::PgDatabaseError, e))?
    },
    GetUserProfileParams::Uuid(uuid) => {
      let stmt = format!("SELECT * FROM {} WHERE uuid = $1", USER_PROFILE_VIEW);
      transaction
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

async fn update_user_profile<'a>(
  transaction: &'a Transaction<'a>,
  pg_mode: &PgPoolMode,
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
    let row = transaction
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
  let stmt = prepare_cached(pg_mode, sql, transaction).await?;
  let affect_rows = transaction
    .execute_raw(stmt.as_ref(), pg_params)
    .await
    .map_err(|e| FlowyError::new(ErrorCode::PgDatabaseError, e))?;
  tracing::trace!("Update user profile affect rows: {}", affect_rows);
  Ok(())
}

async fn check_user<'a>(
  transaction: &Transaction<'a>,
  pg_mode: &PgPoolMode,
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
  let stmt = prepare_cached(pg_mode, stmt, transaction)
    .await
    .map_err(|e| FlowyError::new(ErrorCode::PgDatabaseError, e))?;
  let rows = Box::pin(
    transaction
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

async fn add_workspace_member<C: GenericClient>(
  _client: &C,
  _pg_mode: &PgPoolMode,
  _email: String,
  _workspace_id: String,
) -> Result<(), Error> {
  Ok(())
}

async fn remove_workspace_member<C: GenericClient>(
  _client: &C,
  _pg_mode: &PgPoolMode,
  _email: String,
  _workspace_id: String,
) -> Result<(), Error> {
  Ok(())
}
