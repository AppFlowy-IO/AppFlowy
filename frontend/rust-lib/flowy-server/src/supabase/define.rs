use collab_entity::CollabType;

pub const AF_COLLAB_UPDATE_TABLE: &str = "af_collab_update";
pub const AF_COLLAB_KEY_COLUMN: &str = "key";
pub const AF_COLLAB_SNAPSHOT_OID_COLUMN: &str = "oid";
pub const AF_COLLAB_SNAPSHOT_ID_COLUMN: &str = "sid";
pub const AF_COLLAB_SNAPSHOT_BLOB_COLUMN: &str = "blob";
pub const AF_COLLAB_SNAPSHOT_ENCRYPT_COLUMN: &str = "encrypt";
pub const AF_COLLAB_SNAPSHOT_BLOB_SIZE_COLUMN: &str = "blob_size";
pub const AF_COLLAB_SNAPSHOT_CREATED_AT_COLUMN: &str = "created_at";
pub const AF_COLLAB_SNAPSHOT_TABLE: &str = "af_collab_snapshot";

pub const USER_UUID: &str = "uuid";
pub const USER_SIGN_IN_URL: &str = "sign_in_url";
pub const USER_EMAIL: &str = "email";
pub const USER_DEVICE_ID: &str = "device_id";

pub const USER_TABLE: &str = "af_user";
pub const USER_UID: &str = "uid";
pub const OWNER_USER_UID: &str = "owner_uid";
pub const WORKSPACE_TABLE: &str = "af_workspace";
pub const USER_PROFILE_VIEW: &str = "af_user_profile_view";

pub(crate) const WORKSPACE_ID: &str = "workspace_id";
pub(crate) const WORKSPACE_NAME: &str = "workspace_name";
pub(crate) const CREATED_AT: &str = "created_at";

pub fn table_name(ty: &CollabType) -> String {
  match ty {
    CollabType::DatabaseRow => format!("{}_database_row", AF_COLLAB_UPDATE_TABLE),
    CollabType::Document | CollabType::Unknown => format!("{}_document", AF_COLLAB_UPDATE_TABLE),
    CollabType::Database => format!("{}_database", AF_COLLAB_UPDATE_TABLE),
    CollabType::WorkspaceDatabase => format!("{}_w_database", AF_COLLAB_UPDATE_TABLE),
    CollabType::Folder => format!("{}_folder", AF_COLLAB_UPDATE_TABLE),
    CollabType::UserAwareness => format!("{}_user_awareness", AF_COLLAB_UPDATE_TABLE),
  }
}

pub fn partition_key(collab_type: &CollabType) -> i32 {
  match collab_type {
    CollabType::Document => 0,
    CollabType::Database => 1,
    CollabType::WorkspaceDatabase => 2,
    CollabType::Folder => 3,
    CollabType::DatabaseRow => 4,
    CollabType::UserAwareness => 5,
    CollabType::Unknown => 0,
  }
}
