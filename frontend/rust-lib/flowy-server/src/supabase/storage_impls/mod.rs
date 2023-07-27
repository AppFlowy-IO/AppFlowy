use crate::supabase::storage_impls::pooler::{
  AF_COLLAB_DATABASE_ROW_UPDATE_TABLE, AF_COLLAB_UPDATE_TABLE,
};
use collab_plugins::cloud_storage::CollabType;

pub mod pooler;
pub mod restful_api;

pub const USER_UUID: &str = "uuid";
pub const USER_UID: &str = "uid";
pub const OWNER_USER_UID: &str = "owner_uid";
pub const USER_EMAIL: &str = "email";
pub const USER_TABLE: &str = "af_user";
pub const WORKSPACE_TABLE: &str = "af_workspace";
pub const USER_PROFILE_VIEW: &str = "af_user_profile_view";

pub fn table_name(ty: &CollabType) -> String {
  match ty {
    CollabType::DatabaseRow => AF_COLLAB_DATABASE_ROW_UPDATE_TABLE.to_string(),
    CollabType::Document => format!("{}_document", AF_COLLAB_UPDATE_TABLE),
    CollabType::Database => format!("{}_database", AF_COLLAB_UPDATE_TABLE),
    CollabType::WorkspaceDatabase => format!("{}_w_database", AF_COLLAB_UPDATE_TABLE),
    CollabType::Folder => format!("{}_folder", AF_COLLAB_UPDATE_TABLE),
  }
}
