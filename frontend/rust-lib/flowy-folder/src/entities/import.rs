use crate::entities::parser::empty_str::NotEmptyStr;
use crate::entities::ViewLayoutPB;
use crate::share::{ImportData, ImportItem, ImportParams, ImportType};
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_error::FlowyError;
use lib_infra::validator_fn::required_not_empty_str;
use validator::Validate;

#[derive(Clone, Debug, ProtoBuf_Enum)]
pub enum ImportTypePB {
  HistoryDocument = 0,
  HistoryDatabase = 1,
  Markdown = 2,
  AFDatabase = 3,
  CSV = 4,
}

impl From<ImportTypePB> for ImportType {
  fn from(pb: ImportTypePB) -> Self {
    match pb {
      ImportTypePB::HistoryDocument => ImportType::HistoryDocument,
      ImportTypePB::HistoryDatabase => ImportType::HistoryDatabase,
      ImportTypePB::Markdown => ImportType::Markdown,
      ImportTypePB::AFDatabase => ImportType::AFDatabase,
      ImportTypePB::CSV => ImportType::CSV,
    }
  }
}

impl Default for ImportTypePB {
  fn default() -> Self {
    Self::Markdown
  }
}

#[derive(Clone, Debug, ProtoBuf, Default)]
pub struct ImportItemPayloadPB {
  // the name of the import page
  #[pb(index = 1)]
  pub name: String,

  // the data of the import page
  // if the data is empty, the file_path must be provided
  #[pb(index = 2, one_of)]
  pub data: Option<Vec<u8>>,

  // the file path of the import page
  // if the file_path is empty, the data must be provided
  #[pb(index = 3, one_of)]
  pub file_path: Option<String>,

  // the layout of the import page
  #[pb(index = 4)]
  pub view_layout: ViewLayoutPB,

  // the type of the import page
  #[pb(index = 5)]
  pub import_type: ImportTypePB,
}

#[derive(Clone, Debug, Validate, ProtoBuf, Default)]
pub struct ImportPayloadPB {
  #[pb(index = 1)]
  #[validate(custom(function = "required_not_empty_str"))]
  pub parent_view_id: String,

  #[pb(index = 2)]
  pub items: Vec<ImportItemPayloadPB>,
}

impl TryInto<ImportParams> for ImportPayloadPB {
  type Error = FlowyError;

  fn try_into(self) -> Result<ImportParams, Self::Error> {
    let parent_view_id = NotEmptyStr::parse(self.parent_view_id)
      .map_err(|_| FlowyError::invalid_view_id())?
      .0;

    let items = self
      .items
      .into_iter()
      .map(|item| {
        let name = if item.name.is_empty() {
          "Untitled".to_string()
        } else {
          item.name
        };

        let data = match (item.file_path, item.data) {
          (Some(file_path), None) => ImportData::FilePath { file_path },
          (None, Some(bytes)) => ImportData::Bytes { bytes },
          (None, None) => {
            return Err(FlowyError::invalid_data().with_context("The import data is empty"));
          },
          (Some(_), Some(_)) => {
            return Err(FlowyError::invalid_data().with_context("The import data is ambiguous"));
          },
        };

        Ok(ImportItem {
          name,
          data,
          view_layout: item.view_layout.into(),
          import_type: item.import_type.into(),
        })
      })
      .collect::<Result<Vec<_>, _>>()?;

    Ok(ImportParams {
      parent_view_id,
      items,
    })
  }
}

#[derive(Clone, Debug, Validate, ProtoBuf, Default)]
pub struct ImportZipPB {
  #[pb(index = 1)]
  #[validate(custom(function = "required_not_empty_str"))]
  pub file_path: String,
}
