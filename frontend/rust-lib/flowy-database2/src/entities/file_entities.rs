use collab_database::entity::FileUploadType;
use collab_database::fields::media_type_option::MediaUploadType;
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

impl From<FileUploadTypePB> for MediaUploadType {
  fn from(file_upload_type: FileUploadTypePB) -> Self {
    match file_upload_type {
      FileUploadTypePB::LocalFile => MediaUploadType::Local,
      FileUploadTypePB::NetworkFile => MediaUploadType::Network,
      FileUploadTypePB::CloudFile => MediaUploadType::Cloud,
    }
  }
}

impl From<MediaUploadType> for FileUploadTypePB {
  fn from(file_upload_type: MediaUploadType) -> Self {
    match file_upload_type {
      MediaUploadType::Local => FileUploadTypePB::LocalFile,
      MediaUploadType::Network => FileUploadTypePB::NetworkFile,
      MediaUploadType::Cloud => FileUploadTypePB::CloudFile,
    }
  }
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
