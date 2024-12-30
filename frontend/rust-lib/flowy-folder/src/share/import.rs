use collab_folder::ViewLayout;
use std::fmt::{Display, Formatter};

#[derive(Clone, Debug)]
pub enum ImportType {
  HistoryDocument = 0,
  HistoryDatabase = 1,
  Markdown = 2,
  AFDatabase = 3,
  CSV = 4,
}

#[derive(Clone, Debug)]
pub struct ImportItem {
  pub name: String,
  pub data: ImportData,
  pub view_layout: ViewLayout,
  pub import_type: ImportType,
}

#[derive(Clone, Debug)]
pub enum ImportData {
  FilePath { file_path: String },
  Bytes { bytes: Vec<u8> },
}

impl Display for ImportData {
  fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
    match self {
      ImportData::FilePath { file_path } => write!(f, "file: {}", file_path),
      ImportData::Bytes { .. } => write!(f, "binary"),
    }
  }
}

#[derive(Clone, Debug)]
pub struct ImportParams {
  pub parent_view_id: String,
  pub items: Vec<ImportItem>,
}
