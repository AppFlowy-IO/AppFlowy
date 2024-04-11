pub(crate) const AF_USER_SESSION_KEY: &str = "af-user-session";

pub(crate) fn user_workspace_key(uid: i64) -> String {
  format!("af-user-workspaces-{}", uid)
}

pub(crate) fn user_profile_key(uid: i64) -> String {
  format!("af-user-profile-{}", uid)
}
