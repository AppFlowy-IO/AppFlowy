use crate::cloud::UserUpdate;
use crate::entities::{AuthType, UpdateUserProfileParams, UserProfile};
use flowy_error::{FlowyError, FlowyResult};
use flowy_sqlite::schema::user_table;
use flowy_sqlite::{prelude::*, DBConnection, ExpressionMethods, RunQueryDsl};

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

impl From<UserTable> for UserProfile {
  fn from(table: UserTable) -> Self {
    UserProfile {
      uid: table.id.parse::<i64>().unwrap_or(0),
      email: table.email,
      name: table.name,
      token: table.token,
      icon_url: table.icon_url,
      auth_type: AuthType::from(table.auth_type),
      updated_at: table.updated_at,
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

pub fn select_user_profile(uid: i64, mut conn: DBConnection) -> Result<UserProfile, FlowyError> {
  let user: UserProfile = user_table::dsl::user_table
    .filter(user_table::id.eq(&uid.to_string()))
    .first::<UserTable>(&mut *conn)
    .map_err(|err| {
      FlowyError::record_not_found().with_context(format!(
        "Can't find the user profile for user id: {}, error: {:?}",
        uid, err
      ))
    })?
    .into();

  Ok(user)
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
