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

  #[pb(index = 2)]
  pub hide_file_names: bool,
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
  // Eg. jpg, png, gif, etc.
  Image = 1,
  // Eg. https://appflowy.io
  Link = 2,
  // Eg. pdf, doc, etc.
  Document = 3,
  // Eg. zip, rar, etc.
  Archive = 4,
  // Eg. mp4, avi, etc.
  Video = 5,
  // Eg. mp3, wav, etc.
  Audio = 6,
  // Eg. txt, csv, etc.
  Text = 7,
}

impl From<MediaFileType> for MediaFileTypePB {
  fn from(data: MediaFileType) -> Self {
    match data {
      MediaFileType::Other => MediaFileTypePB::Other,
      MediaFileType::Image => MediaFileTypePB::Image,
      MediaFileType::Link => MediaFileTypePB::Link,
      MediaFileType::Document => MediaFileTypePB::Document,
      MediaFileType::Archive => MediaFileTypePB::Archive,
      MediaFileType::Video => MediaFileTypePB::Video,
      MediaFileType::Audio => MediaFileTypePB::Audio,
      MediaFileType::Text => MediaFileTypePB::Text,
    }
  }
}

impl From<MediaFileTypePB> for MediaFileType {
  fn from(data: MediaFileTypePB) -> Self {
    match data {
      MediaFileTypePB::Other => MediaFileType::Other,
      MediaFileTypePB::Image => MediaFileType::Image,
      MediaFileTypePB::Link => MediaFileType::Link,
      MediaFileTypePB::Document => MediaFileType::Document,
      MediaFileTypePB::Archive => MediaFileType::Archive,
      MediaFileTypePB::Video => MediaFileType::Video,
      MediaFileTypePB::Audio => MediaFileType::Audio,
      MediaFileTypePB::Text => MediaFileType::Text,
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

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct RenameMediaChangesetPB {
  #[pb(index = 1)]
  pub view_id: String,

  #[pb(index = 2)]
  pub cell_id: CellIdPB,

  #[pb(index = 3)]
  pub file_id: String,

  #[pb(index = 4)]
  pub name: String,
}
