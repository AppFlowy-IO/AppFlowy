use diesel::{sql_query, RunQueryDsl};
use flowy_error::{internal_error, FlowyError};
use std::str::FromStr;

use flowy_user_pub::cloud::UserUpdate;
use flowy_user_pub::entities::*;

use flowy_sqlite::schema::user_table;

use flowy_sqlite::{query_dsl::*, DBConnection, ExpressionMethods};
/// The order of the fields in the struct must be the same as the order of the fields in the table.
/// Check out the [schema.rs] for table schema.
#[derive(Clone, Default, Queryable, Identifiable, Insertable)]
#[diesel(table_name = user_table)]
pub struct UserTable {
  pub(crate) id: String,
  pub(crate) name: String,
  #[deprecated(
    note = "The workspace_id is deprecated, please use the [Session::UserWorkspace] instead"
  )]
  pub(crate) workspace: String,
  pub(crate) icon_url: String,
  pub(crate) openai_key: String,
  pub(crate) token: String,
  pub(crate) email: String,
  pub(crate) auth_type: i32,
  pub(crate) encryption_type: String,
  pub(crate) stability_ai_key: String,
  pub(crate) updated_at: i64,
  pub(crate) ai_model: String,
}

#[allow(deprecated)]
impl From<(UserProfile, Authenticator)> for UserTable {
  fn from(value: (UserProfile, Authenticator)) -> Self {
    let (user_profile, auth_type) = value;
    let encryption_type = serde_json::to_string(&user_profile.encryption_type).unwrap_or_default();
    UserTable {
      id: user_profile.uid.to_string(),
      name: user_profile.name,
      #[allow(deprecated)]
      workspace: "".to_string(),
      icon_url: user_profile.icon_url,
      openai_key: user_profile.openai_key,
      token: user_profile.token,
      email: user_profile.email,
      auth_type: auth_type as i32,
      encryption_type,
      stability_ai_key: user_profile.stability_ai_key,
      updated_at: user_profile.updated_at,
      ai_model: user_profile.ai_model,
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
      openai_key: table.openai_key,
      authenticator: Authenticator::from(table.auth_type),
      encryption_type: EncryptionType::from_str(&table.encryption_type).unwrap_or_default(),
      stability_ai_key: table.stability_ai_key,
      updated_at: table.updated_at,
      ai_model: table.ai_model,
    }
  }
}

#[derive(AsChangeset, Identifiable, Default, Debug)]
#[diesel(table_name = user_table)]
pub struct UserTableChangeset {
  pub id: String,
  pub workspace: Option<String>, // deprecated
  pub name: Option<String>,
  pub email: Option<String>,
  pub icon_url: Option<String>,
  pub openai_key: Option<String>,
  pub encryption_type: Option<String>,
  pub token: Option<String>,
  pub stability_ai_key: Option<String>,
  pub ai_model: Option<String>,
}

impl UserTableChangeset {
  pub fn new(params: UpdateUserProfileParams) -> Self {
    let encryption_type = params.encryption_sign.map(|sign| {
      let ty = EncryptionType::from_sign(&sign);
      serde_json::to_string(&ty).unwrap_or_default()
    });
    UserTableChangeset {
      id: params.uid.to_string(),
      workspace: None,
      name: params.name,
      email: params.email,
      icon_url: params.icon_url,
      openai_key: params.openai_key,
      encryption_type,
      token: params.token,
      stability_ai_key: params.stability_ai_key,
      ai_model: params.ai_model,
    }
  }

  pub fn from_user_profile(user_profile: UserProfile) -> Self {
    let encryption_type = serde_json::to_string(&user_profile.encryption_type).unwrap_or_default();
    UserTableChangeset {
      id: user_profile.uid.to_string(),
      workspace: None,
      name: Some(user_profile.name),
      email: Some(user_profile.email),
      icon_url: Some(user_profile.icon_url),
      openai_key: Some(user_profile.openai_key),
      encryption_type: Some(encryption_type),
      token: Some(user_profile.token),
      stability_ai_key: Some(user_profile.stability_ai_key),
      ai_model: Some(user_profile.ai_model),
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

pub(crate) fn vacuum_database(mut conn: DBConnection) -> Result<(), FlowyError> {
  sql_query("VACUUM")
    .execute(&mut *conn)
    .map_err(internal_error)?;
  Ok(())
}
