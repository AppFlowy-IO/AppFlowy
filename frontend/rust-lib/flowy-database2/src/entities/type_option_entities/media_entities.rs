use flowy_derive::{ProtoBuf, ProtoBuf_Enum};

use crate::{
  entities::CellIdPB,
  services::field::{MediaCellData, MediaFile, MediaFileType, MediaUploadType},
};

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct MediaCellDataPB {
  #[pb(index = 1)]
  pub files: Vec<MediaFilePB>,
}

impl From<MediaCellData> for MediaCellDataPB {
  fn from(data: MediaCellData) -> Self {
    Self {
      files: data.files.into_iter().map(Into::into).collect(),
    }
  }
}

impl From<MediaCellDataPB> for MediaCellData {
  fn from(data: MediaCellDataPB) -> Self {
    Self {
      files: data.files.into_iter().map(Into::into).collect(),
    }
  }
}

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct MediaTypeOptionPB {
  #[pb(index = 1)]
  pub files: Vec<MediaFilePB>,
}

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct MediaFilePB {
  #[pb(index = 1)]
  pub id: String,

  #[pb(index = 2)]
  pub name: String,

  #[pb(index = 3)]
  pub url: String,

  #[pb(index = 4)]
  pub upload_type: MediaUploadTypePB,

  #[pb(index = 5)]
  pub file_type: MediaFileTypePB,
}

#[derive(Debug, Clone, Default, PartialEq, Eq, ProtoBuf_Enum)]
#[repr(u8)]
pub enum MediaUploadTypePB {
  #[default]
  LocalMedia = 0,
  NetworkMedia = 1,
  CloudMedia = 2,
}

impl From<MediaUploadType> for MediaUploadTypePB {
  fn from(data: MediaUploadType) -> Self {
    match data {
      MediaUploadType::LocalMedia => MediaUploadTypePB::LocalMedia,
      MediaUploadType::NetworkMedia => MediaUploadTypePB::NetworkMedia,
      MediaUploadType::CloudMedia => MediaUploadTypePB::CloudMedia,
    }
  }
}

impl From<MediaUploadTypePB> for MediaUploadType {
  fn from(data: MediaUploadTypePB) -> Self {
    match data {
      MediaUploadTypePB::LocalMedia => MediaUploadType::LocalMedia,
      MediaUploadTypePB::NetworkMedia => MediaUploadType::NetworkMedia,
      MediaUploadTypePB::CloudMedia => MediaUploadType::CloudMedia,
    }
  }
}

#[derive(Debug, Clone, Default, PartialEq, Eq, ProtoBuf_Enum)]
#[repr(u8)]
pub enum MediaFileTypePB {
  #[default]
  Other = 0,
  Image = 1,
}

impl From<MediaFileType> for MediaFileTypePB {
  fn from(data: MediaFileType) -> Self {
    match data {
      MediaFileType::Other => MediaFileTypePB::Other,
      MediaFileType::Image => MediaFileTypePB::Image,
    }
  }
}

impl From<MediaFileTypePB> for MediaFileType {
  fn from(data: MediaFileTypePB) -> Self {
    match data {
      MediaFileTypePB::Other => MediaFileType::Other,
      MediaFileTypePB::Image => MediaFileType::Image,
    }
  }
}

impl From<MediaFile> for MediaFilePB {
  fn from(data: MediaFile) -> Self {
    Self {
      id: data.id,
      name: data.name,
      url: data.url,
      upload_type: data.upload_type.into(),
      file_type: data.file_type.into(),
    }
  }
}

impl From<MediaFilePB> for MediaFile {
  fn from(data: MediaFilePB) -> Self {
    Self {
      id: data.id,
      name: data.name,
      url: data.url,
      upload_type: data.upload_type.into(),
      file_type: data.file_type.into(),
    }
  }
}

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct MediaCellChangesetPB {
  #[pb(index = 1)]
  pub view_id: String,

  #[pb(index = 2)]
  pub cell_id: CellIdPB,

  #[pb(index = 3)]
  pub inserted_files: Vec<MediaFilePB>,

  #[pb(index = 4)]
  pub removed_ids: Vec<String>,
}

#[derive(Debug, Clone, Default)]
pub struct MediaCellChangeset {
  pub inserted_files: Vec<MediaFile>,
  pub removed_ids: Vec<String>,
}
