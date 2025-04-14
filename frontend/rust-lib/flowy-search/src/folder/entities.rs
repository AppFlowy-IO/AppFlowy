use serde::{Deserialize, Serialize};

use crate::entities::{IndexTypePB, ResultIconPB, SearchResponseItemPB};

#[derive(Debug, Serialize, Deserialize)]
pub struct FolderIndexData {
  pub id: String,
  pub title: String,
  pub icon: String,
  pub icon_ty: i64,
  pub workspace_id: String,
}

impl From<FolderIndexData> for SearchResponseItemPB {
  fn from(data: FolderIndexData) -> Self {
    let icon = if data.icon.is_empty() {
      None
    } else {
      Some(ResultIconPB {
        ty: data.icon_ty.into(),
        value: data.icon,
      })
    };

    Self {
      index_type: IndexTypePB::View,
      id: data.id,
      display_name: data.title,
      score: 0.0,
      icon,
      workspace_id: data.workspace_id,
      preview: None,
      content: "".to_string(),
    }
  }
}
