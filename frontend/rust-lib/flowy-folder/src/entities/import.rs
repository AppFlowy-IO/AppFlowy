use crate::entities::parser::empty_str::NotEmptyStr;
use crate::entities::ViewLayoutPB;
use crate::share::{ImportParams, ImportType};
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_error::FlowyError;

#[derive(Clone, Debug, ProtoBuf_Enum)]
pub enum ImportTypePB {
  HistoryDocument = 0,
  HistoryDatabase = 1,
  RawDatabase = 2,
  CSV = 3,
}

impl From<ImportTypePB> for ImportType {
  fn from(pb: ImportTypePB) -> Self {
    match pb {
      ImportTypePB::HistoryDocument => ImportType::HistoryDocument,
      ImportTypePB::HistoryDatabase => ImportType::HistoryDatabase,
      ImportTypePB::RawDatabase => ImportType::RawDatabase,
      ImportTypePB::CSV => ImportType::CSV,
    }
  }
}

impl Default for ImportTypePB {
  fn default() -> Self {
    Self::HistoryDocument
  }
}

#[derive(Clone, Debug, ProtoBuf, Default)]
pub struct ImportPB {
  #[pb(index = 1)]
  pub parent_view_id: String,

  #[pb(index = 2)]
  pub name: String,

  #[pb(index = 3, one_of)]
  pub data: Option<Vec<u8>>,

  #[pb(index = 4, one_of)]
  pub file_path: Option<String>,

  #[pb(index = 5)]
  pub view_layout: ViewLayoutPB,

  #[pb(index = 6)]
  pub import_type: ImportTypePB,
}

impl TryInto<ImportParams> for ImportPB {
  type Error = FlowyError;

  fn try_into(self) -> Result<ImportParams, Self::Error> {
    let parent_view_id = NotEmptyStr::parse(self.parent_view_id)
      .map_err(|_| FlowyError::invalid_view_id())?
      .0;

    let name = if self.name.is_empty() {
      "Untitled".to_string()
    } else {
      self.name
    };

    let file_path = match self.file_path {
      None => None,
      Some(file_path) => Some(
        NotEmptyStr::parse(file_path)
          .map_err(|_| FlowyError::invalid_data().with_context("The import file path is empty"))?
          .0,
      ),
    };

    Ok(ImportParams {
      parent_view_id,
      name,
      data: self.data,
      file_path,
      view_layout: self.view_layout.into(),
      import_type: self.import_type.into(),
    })
  }
}
