use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, Default, Debug, Clone, Eq, PartialEq)]
pub struct FolderInfo {
    pub folder_id: String,
    pub text: String,
    pub rev_id: i64,
    pub base_rev_id: i64,
}
