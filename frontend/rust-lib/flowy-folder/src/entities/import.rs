use crate::entities::parser::empty_str::NotEmptyStr;
use crate::entities::ViewLayoutPB;
use crate::share::{ImportParams, ImportType, ImportValue};
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
pub struct ImportValuePayloadPB {
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
  pub values: Vec<ImportValuePayloadPB>,
}

impl TryInto<ImportParams> for ImportPayloadPB {
  type Error = FlowyError;

  fn try_into(self) -> Result<ImportParams, Self::Error> {
    let parent_view_id = NotEmptyStr::parse(self.parent_view_id)
      .map_err(|_| FlowyError::invalid_view_id())?
      .0;

    let mut values = Vec::new();

    for value in self.values {
      let name = if value.name.is_empty() {
        "Untitled".to_string()
      } else {
        value.name
      };

      let file_path = match value.file_path {
        None => None,
        Some(file_path) => Some(
          NotEmptyStr::parse(file_path)
            .map_err(|_| FlowyError::invalid_data().with_context("The import file path is empty"))?
            .0,
        ),
      };

      let params = ImportValue {
        name,
        data: value.data,
        file_path,
        view_layout: value.view_layout.into(),
        import_type: value.import_type.into(),
      };

      values.push(params);
    }

    Ok(ImportParams {
      parent_view_id,
      values,
    })
  }
}

#[derive(Clone, Debug, Validate, ProtoBuf, Default)]
pub struct ImportZipPB {
  #[pb(index = 1)]
  #[validate(custom(function = "required_not_empty_str"))]
  pub file_path: String,
}
