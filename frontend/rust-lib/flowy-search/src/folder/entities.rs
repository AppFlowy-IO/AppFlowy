use serde::{Deserialize, Serialize};

use crate::entities::{IndexTypePB, SearchResultPB};

#[derive(Debug, Serialize, Deserialize)]
pub struct FolderIndexData {
  pub id: String,
  pub title: String,
}

impl From<FolderIndexData> for SearchResultPB {
  fn from(data: FolderIndexData) -> Self {
    Self {
      index_type: IndexTypePB::View,
      view_id: data.id.clone(),
      id: data.id,
      data: data.title,
    }
  }
}
