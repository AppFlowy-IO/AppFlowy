use crate::cloud::UserUpdate;
use crate::entities::{
  AuthType, Role, UpdateUserProfileParams, UserProfile, UserWorkspace, WorkspaceType,
};
use crate::sql::{
  select_user_workspace, upsert_user_workspace, upsert_workspace_member, WorkspaceMemberTable,
};
use flowy_error::{FlowyError, FlowyResult};
use flowy_sqlite::schema::user_table;
use flowy_sqlite::{prelude::*, DBConnection, ExpressionMethods, RunQueryDsl};
use tracing::trace;

/// The order of the fields in the struct must be the same as the order of the fields in the table.
/// Check out the [schema.rs] for table schema.
#[derive(Clone, Default, Queryable, Identifiable, Insertable)]
#[diesel(table_name = user_table)]
pub struct UserTable {
  pub(crate) id: String,
  pub(crate) name: String,
  pub(crate) icon_url: String,
  pub(crate) token: String,
  pub(crate) email: String,
  pub(crate) auth_type: i32,
  pub(crate) updated_at: i64,
}

#[allow(deprecated)]
impl From<(UserProfile, AuthType)> for UserTable {
  fn from(value: (UserProfile, AuthType)) -> Self {
    let (user_profile, auth_type) = value;
    UserTable {
      id: user_profile.uid.to_string(),
      name: user_profile.name,
      #[allow(deprecated)]
      icon_url: user_profile.icon_url,
      token: user_profile.token,
      email: user_profile.email,
      auth_type: auth_type as i32,
      updated_at: user_profile.updated_at,
    }
  }
}

#[derive(AsChangeset, Identifiable, Default, Debug)]
#[diesel(table_name = user_table)]
pub struct UserTableChangeset {
  pub id: String,
  pub name: Option<String>,
  pub email: Option<String>,
  pub icon_url: Option<String>,
  pub token: Option<String>,
}

impl UserTableChangeset {
  pub fn new(params: UpdateUserProfileParams) -> Self {
    UserTableChangeset {
      id: params.uid.to_string(),
      name: params.name,
      email: params.email,
      icon_url: params.icon_url,
      token: params.token,
    }
  }

  pub fn from_user_profile(user_profile: UserProfile) -> Self {
    UserTableChangeset {
      id: user_profile.uid.to_string(),
      name: Some(user_profile.name),
      email: Some(user_profile.email),
      icon_url: Some(user_profile.icon_url),
      token: Some(user_profile.token),
    }
  }
}

impl From<UserUpdate> for UserTableChangeset {
  fn from(value: UserUpdate) -> Self {
    UserTableChangeset {
      id: value.uid.to_string(),
      name: value.name,
      email: value.email,
      ..Default::default()
    }
  }
}

pub fn update_user_profile(
  conn: &mut SqliteConnection,
  changeset: UserTableChangeset,
) -> Result<(), FlowyError> {
  trace!("update user profile: {:?}", changeset);
  let user_id = changeset.id.clone();
  update(user_table::dsl::user_table.filter(user_table::id.eq(&user_id)))
    .set(changeset)
    .execute(conn)?;
  Ok(())
}

pub fn insert_local_workspace(
  uid: i64,
  workspace_id: &str,
  workspace_name: &str,
  conn: &mut SqliteConnection,
) -> FlowyResult<UserWorkspace> {
  let user_workspace = UserWorkspace::new_local(workspace_id.to_string(), workspace_name);
  conn.immediate_transaction(|conn| {
    let row = select_user_table_row(uid, conn)?;
    let row = WorkspaceMemberTable {
      email: row.email,
      role: Role::Owner as i32,
      name: row.name,
      avatar_url: Some(row.icon_url),
      uid,
      workspace_id: workspace_id.to_string(),
      updated_at: chrono::Utc::now().naive_utc(),
      joined_at: None,
    };

    upsert_user_workspace(uid, WorkspaceType::Local, user_workspace.clone(), conn)?;
    upsert_workspace_member(conn, row)?;
    Ok::<_, FlowyError>(())
  })?;

  Ok(user_workspace)
}

fn select_user_table_row(uid: i64, conn: &mut SqliteConnection) -> Result<UserTable, FlowyError> {
  let row = user_table::dsl::user_table
    .filter(user_table::id.eq(&uid.to_string()))
    .first::<UserTable>(conn)
    .map_err(|err| {
      FlowyError::record_not_found().with_context(format!(
        "Can't find the user profile for user id: {}, error: {:?}",
        uid, err
      ))
    })?;
  Ok(row)
}

pub fn select_user_profile(
  uid: i64,
  workspace_id: &str,
  conn: &mut SqliteConnection,
) -> Result<UserProfile, FlowyError> {
  let workspace = select_user_workspace(workspace_id, conn)?;
  let workspace_type = WorkspaceType::from(workspace.workspace_type);
  let row = select_user_table_row(uid, conn)?;

  let user = UserProfile {
    uid: row.id.parse::<i64>().unwrap_or(0),
    email: row.email,
    name: row.name,
    token: row.token,
    icon_url: row.icon_url,
    auth_type: AuthType::from(row.auth_type),
    workspace_type,
    updated_at: row.updated_at,
  };

  Ok(user)
}

pub fn select_user_auth_type(
  uid: i64,
  conn: &mut SqliteConnection,
) -> Result<AuthType, FlowyError> {
  let row = select_user_table_row(uid, conn)?;
  Ok(AuthType::from(row.auth_type))
}

pub fn select_user_token(uid: i64, conn: &mut SqliteConnection) -> Result<String, FlowyError> {
  let row = select_user_table_row(uid, conn)?;
  Ok(row.token)
}

pub fn upsert_user(user: UserTable, mut conn: DBConnection) -> FlowyResult<()> {
  conn.immediate_transaction(|conn| {
    // delete old user if exists
    diesel::delete(user_table::dsl::user_table.filter(user_table::dsl::id.eq(&user.id)))
      .execute(conn)?;

    let _ = diesel::insert_into(user_table::table)
      .values(user)
      .execute(conn)?;
    Ok::<(), FlowyError>(())
  })?;
  Ok(())
}
