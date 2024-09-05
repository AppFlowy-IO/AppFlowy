use std::fmt::{Display, Formatter};

use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, Default, PartialEq, Eq, Serialize, Deserialize)]
pub struct MediaFile {
  pub id: String,
  pub name: String,
  pub url: String,
  pub upload_type: MediaUploadType,
  pub file_type: MediaFileType,
}

impl MediaFile {
  pub fn rename(&self, new_name: String) -> Self {
    Self {
      id: self.id.clone(),
      name: new_name,
      url: self.url.clone(),
      upload_type: self.upload_type.clone(),
      file_type: self.file_type.clone(),
    }
  }
}

impl Display for MediaFile {
  fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
    write!(
      f,
      "MediaFile(id: {}, name: {}, url: {}, upload_type: {:?}, file_type: {:?})",
      self.id, self.name, self.url, self.upload_type, self.file_type
    )
  }
}

#[derive(PartialEq, Eq, Serialize, Deserialize, Debug, Default, Clone)]
#[repr(u8)]
pub enum MediaUploadType {
  #[default]
  LocalMedia = 0,
  NetworkMedia = 1,
  CloudMedia = 2,
}

#[derive(PartialEq, Eq, Serialize, Deserialize, Debug, Default, Clone)]
#[repr(u8)]
pub enum MediaFileType {
  #[default]
  Other = 0,
  Image = 1,
  Link = 2,
  Document = 3,
  Archive = 4,
  Video = 5,
  Audio = 6,
  Text = 7,
}
