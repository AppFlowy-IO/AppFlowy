use collab_folder::ViewLayout;

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

#[derive(Clone, Debug)]
pub struct ImportParams {
  pub parent_view_id: String,
  pub items: Vec<ImportItem>,
}
