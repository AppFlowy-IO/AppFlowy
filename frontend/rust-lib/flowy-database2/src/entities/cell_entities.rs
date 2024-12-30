use collab_database::rows::RowId;

use flowy_derive::ProtoBuf;
use flowy_error::ErrorCode;
use lib_infra::validator_fn::required_not_empty_str;
use validator::Validate;

use crate::entities::parser::NotEmptyStr;
use crate::entities::FieldType;

#[derive(ProtoBuf, Default)]
pub struct CreateSelectOptionPayloadPB {
  #[pb(index = 1)]
  pub field_id: String,

  #[pb(index = 2)]
  pub view_id: String,

  #[pb(index = 3)]
  pub option_name: String,
}

pub struct CreateSelectOptionParams {
  pub field_id: String,
  pub view_id: String,
  pub option_name: String,
}

impl TryInto<CreateSelectOptionParams> for CreateSelectOptionPayloadPB {
  type Error = ErrorCode;

  fn try_into(self) -> Result<CreateSelectOptionParams, Self::Error> {
    let option_name =
      NotEmptyStr::parse(self.option_name).map_err(|_| ErrorCode::SelectOptionNameIsEmpty)?;
    let view_id = NotEmptyStr::parse(self.view_id).map_err(|_| ErrorCode::ViewIdIsInvalid)?;
    let field_id = NotEmptyStr::parse(self.field_id).map_err(|_| ErrorCode::FieldIdIsEmpty)?;
    Ok(CreateSelectOptionParams {
      field_id: field_id.0,
      option_name: option_name.0,
      view_id: view_id.0,
    })
  }
}

#[derive(Debug, Clone, Default, ProtoBuf, Validate)]
pub struct CellIdPB {
  #[pb(index = 1)]
  #[validate(custom(function = "required_not_empty_str"))]
  pub view_id: String,

  #[pb(index = 2)]
  #[validate(custom(function = "required_not_empty_str"))]
  pub field_id: String,

  #[pb(index = 3)]
  #[validate(custom(function = "required_not_empty_str"))]
  pub row_id: String,
}

/// Represents as the cell identifier. It's used to locate the cell in corresponding
/// view's row with the field id.
pub struct CellIdParams {
  pub view_id: String,
  pub field_id: String,
  pub row_id: RowId,
}

impl TryInto<CellIdParams> for CellIdPB {
  type Error = ErrorCode;

  fn try_into(self) -> Result<CellIdParams, Self::Error> {
    let view_id = NotEmptyStr::parse(self.view_id).map_err(|_| ErrorCode::DatabaseIdIsEmpty)?;
    let field_id = NotEmptyStr::parse(self.field_id).map_err(|_| ErrorCode::FieldIdIsEmpty)?;
    Ok(CellIdParams {
      view_id: view_id.0,
      field_id: field_id.0,
      row_id: RowId::from(self.row_id),
    })
  }
}

/// Represents as the data of the cell.
#[derive(Debug, Default, ProtoBuf)]
pub struct CellPB {
  #[pb(index = 1)]
  pub field_id: String,

  #[pb(index = 2)]
  pub row_id: String,

  /// Encoded the data using the helper struct `CellProtobufBlob`.
  /// Check out the `CellProtobufBlob` for more information.
  #[pb(index = 3)]
  pub data: Vec<u8>,

  /// the field_type will be None if the field with field_id is not found
  #[pb(index = 4, one_of)]
  pub field_type: Option<FieldType>,
}

impl CellPB {
  pub fn new(field_id: &str, row_id: String, field_type: FieldType, data: Vec<u8>) -> Self {
    Self {
      field_id: field_id.to_owned(),
      row_id,
      data,
      field_type: Some(field_type),
    }
  }

  pub fn empty(field_id: &str, row_id: String) -> Self {
    Self {
      field_id: field_id.to_owned(),
      row_id,
      data: vec![],
      field_type: None,
    }
  }
}

#[derive(Debug, Default, ProtoBuf)]
pub struct RepeatedCellPB {
  #[pb(index = 1)]
  pub items: Vec<CellPB>,
}

impl std::ops::Deref for RepeatedCellPB {
  type Target = Vec<CellPB>;
  fn deref(&self) -> &Self::Target {
    &self.items
  }
}

impl std::ops::DerefMut for RepeatedCellPB {
  fn deref_mut(&mut self) -> &mut Self::Target {
    &mut self.items
  }
}

impl std::convert::From<Vec<CellPB>> for RepeatedCellPB {
  fn from(items: Vec<CellPB>) -> Self {
    Self { items }
  }
}

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct CellChangesetPB {
  #[pb(index = 1)]
  pub view_id: String,

  #[pb(index = 2)]
  pub row_id: String,

  #[pb(index = 3)]
  pub field_id: String,

  #[pb(index = 4)]
  pub cell_changeset: String,
}

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct CellChangesetNotifyPB {
  #[pb(index = 1)]
  pub view_id: String,

  #[pb(index = 2)]
  pub row_id: String,

  #[pb(index = 3)]
  pub field_id: String,
}
