use flowy_derive::ProtoBuf_Enum;

#[derive(ProtoBuf_Enum, Eq, PartialEq, Debug, Clone)]
pub enum IndexTypePB {
  View = 0,
  DocumentBlock = 1,
  DatabaseRow = 2,
}

impl Default for IndexTypePB {
  fn default() -> Self {
    Self::View
  }
}

impl std::convert::From<IndexTypePB> for i32 {
  fn from(notification: IndexTypePB) -> Self {
    notification as i32
  }
}

impl std::convert::From<i32> for IndexTypePB {
  fn from(notification: i32) -> Self {
    match notification {
      1 => IndexTypePB::View,
      2 => IndexTypePB::DocumentBlock,
      _ => IndexTypePB::DatabaseRow,
    }
  }
}
