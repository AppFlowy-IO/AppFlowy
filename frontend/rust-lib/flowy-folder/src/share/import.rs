use collab_folder::ViewLayout;

#[derive(Clone, Debug)]
pub enum ImportType {
  Markdown = 0,
  AFDatabase = 1,
  CSV = 2,
  NotionZip = 3,
}

#[derive(Clone, Debug)]
pub struct ImportValue {
  pub name: String,
  pub data: Option<Vec<u8>>,
  pub file_path: Option<String>,
  pub view_layout: ViewLayout,
  pub import_type: ImportType,
}

#[derive(Clone, Debug)]
pub struct ImportParams {
  pub parent_view_id: String,
  pub values: Vec<ImportValue>,
}
