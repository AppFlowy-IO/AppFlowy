use std::str::FromStr;

use flowy_sqlite::schema::user_table;
use flowy_user_deps::cloud::UserUpdate;
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
  pub(crate) encryption_type: String,
}

impl UserTable {
  pub fn set_workspace(mut self, workspace: String) -> Self {
    self.workspace = workspace;
    self
  }
}

impl From<(UserProfile, AuthType)> for UserTable {
  fn from(value: (UserProfile, AuthType)) -> Self {
    let (user_profile, auth_type) = value;
    let encryption_type = serde_json::to_string(&user_profile.encryption_type).unwrap_or_default();
    UserTable {
      id: user_profile.uid.to_string(),
      name: user_profile.name,
      workspace: user_profile.workspace_id,
      icon_url: user_profile.icon_url,
      openai_key: user_profile.openai_key,
      token: user_profile.token,
      email: user_profile.email,
      auth_type: auth_type as i32,
      encryption_type,
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
      workspace_id: table.workspace,
      auth_type: AuthType::from(table.auth_type),
      encryption_type: EncryptionType::from_str(&table.encryption_type).unwrap_or_default(),
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
  pub encryption_type: Option<String>,
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
    }
  }
}

impl From<UserUpdate> for UserTableChangeset {
  fn from(value: UserUpdate) -> Self {
    UserTableChangeset {
      id: value.uid.to_string(),
      name: Some(value.name),
      email: Some(value.email),
      ..Default::default()
    }
  }
}
