use flowy_sqlite::schema::user_table;
use flowy_user_deps::entities::*;

/// The order of the fields in the struct must be the same as the order of the fields in the table.
/// Check out the [schema.rs] for table schema.
#[derive(Clone, Default, Queryable, Identifiable, Insertable)]
#[table_name = "user_table"]
pub struct UserTable {
  pub(crate) id: String,
  pub(crate) name: String,
  pub(crate) workspace: String,
  pub(crate) icon_url: String,
  pub(crate) openai_key: String,
  pub(crate) token: String,
  pub(crate) email: String,
  pub(crate) auth_type: i32,
}

impl UserTable {
  pub fn set_workspace(mut self, workspace: String) -> Self {
    self.workspace = workspace;
    self
  }
}

impl<T> From<(T, AuthType)> for UserTable
where
  T: UserAuthResponse,
{
  fn from(value: (T, AuthType)) -> Self {
    let (resp, auth_type) = value;
    UserTable {
      id: resp.user_id().to_string(),
      name: resp.user_name().to_string(),
      token: resp.user_token().unwrap_or_default(),
      email: resp.user_email().unwrap_or_default(),
      workspace: resp.latest_workspace().id.clone(),
      icon_url: "".to_string(),
      openai_key: "".to_string(),
      auth_type: auth_type as i32,
    }
  }
}

impl From<UserTable> for UserProfile {
  fn from(table: UserTable) -> Self {
    UserProfile {
      id: table.id.parse::<i64>().unwrap_or(0),
      email: table.email,
      name: table.name,
      token: table.token,
      icon_url: table.icon_url,
      openai_key: table.openai_key,
      workspace_id: table.workspace,
      auth_type: AuthType::from(table.auth_type),
    }
  }
}

#[derive(AsChangeset, Identifiable, Default, Debug)]
#[table_name = "user_table"]
pub struct UserTableChangeset {
  pub id: String,
  pub workspace: Option<String>, // deprecated
  pub name: Option<String>,
  pub email: Option<String>,
  pub icon_url: Option<String>,
  pub openai_key: Option<String>,
}

impl UserTableChangeset {
  pub fn new(params: UpdateUserProfileParams) -> Self {
    UserTableChangeset {
      id: params.uid.to_string(),
      workspace: None,
      name: params.name,
      email: params.email,
      icon_url: params.icon_url,
      openai_key: params.openai_key,
    }
  }

  pub fn from_user_profile(user_profile: UserProfile) -> Self {
    UserTableChangeset {
      id: user_profile.id.to_string(),
      workspace: None,
      name: Some(user_profile.name),
      email: Some(user_profile.email),
      icon_url: Some(user_profile.icon_url),
      openai_key: Some(user_profile.openai_key),
    }
  }
}
