use collab_database::entity::FileUploadType;
use flowy_derive::ProtoBuf_Enum;
use serde::{Deserialize, Serialize};

#[derive(Debug, Default, Clone, ProtoBuf_Enum, PartialEq, Eq, Copy, Serialize, Deserialize)]
#[repr(u8)]
pub enum FileUploadTypePB {
  #[default]
  LocalFile = 0,
  NetworkFile = 1,
  CloudFile = 2,
}

impl From<FileUploadType> for FileUploadTypePB {
  fn from(data: FileUploadType) -> Self {
    match data {
      FileUploadType::LocalFile => FileUploadTypePB::LocalFile,
      FileUploadType::NetworkFile => FileUploadTypePB::NetworkFile,
      FileUploadType::CloudFile => FileUploadTypePB::CloudFile,
    }
  }
}

impl From<FileUploadTypePB> for FileUploadType {
  fn from(data: FileUploadTypePB) -> Self {
    match data {
      FileUploadTypePB::LocalFile => FileUploadType::LocalFile,
      FileUploadTypePB::NetworkFile => FileUploadType::NetworkFile,
      FileUploadTypePB::CloudFile => FileUploadType::CloudFile,
    }
  }
}
