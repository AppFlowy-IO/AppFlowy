use crate::entities::parser::NotEmptyStr;
use crate::entities::FieldType;
use flowy_derive::ProtoBuf;
use flowy_error::ErrorCode;
use grid_rev_model::{CellRevision, RowChangeset};
use std::collections::HashMap;

#[derive(ProtoBuf, Default)]
pub struct CreateSelectOptionPayloadPB {
    #[pb(index = 1)]
    pub field_id: String,

    #[pb(index = 2)]
    pub grid_id: String,

    #[pb(index = 3)]
    pub option_name: String,
}

pub struct CreateSelectOptionParams {
    pub field_id: String,
    pub grid_id: String,
    pub option_name: String,
}

impl TryInto<CreateSelectOptionParams> for CreateSelectOptionPayloadPB {
    type Error = ErrorCode;

    fn try_into(self) -> Result<CreateSelectOptionParams, Self::Error> {
        let option_name = NotEmptyStr::parse(self.option_name).map_err(|_| ErrorCode::SelectOptionNameIsEmpty)?;
        let grid_id = NotEmptyStr::parse(self.grid_id).map_err(|_| ErrorCode::GridIdIsEmpty)?;
        let field_id = NotEmptyStr::parse(self.field_id).map_err(|_| ErrorCode::FieldIdIsEmpty)?;
        Ok(CreateSelectOptionParams {
            field_id: field_id.0,
            option_name: option_name.0,
            grid_id: grid_id.0,
        })
    }
}

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct CellPathPB {
    #[pb(index = 1)]
    pub view_id: String,

    #[pb(index = 2)]
    pub field_id: String,

    #[pb(index = 3)]
    pub row_id: String,
}

/// Represents as the cell identifier. It's used to locate the cell in corresponding
/// view's row with the field id.
pub struct CellPathParams {
    pub view_id: String,
    pub field_id: String,
    pub row_id: String,
}

impl TryInto<CellPathParams> for CellPathPB {
    type Error = ErrorCode;

    fn try_into(self) -> Result<CellPathParams, Self::Error> {
        let grid_id = NotEmptyStr::parse(self.view_id).map_err(|_| ErrorCode::GridIdIsEmpty)?;
        let field_id = NotEmptyStr::parse(self.field_id).map_err(|_| ErrorCode::FieldIdIsEmpty)?;
        let row_id = NotEmptyStr::parse(self.row_id).map_err(|_| ErrorCode::RowIdIsEmpty)?;
        Ok(CellPathParams {
            view_id: grid_id.0,
            field_id: field_id.0,
            row_id: row_id.0,
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
    pub fn new(field_id: &str, row_id: &str, field_type: FieldType, data: Vec<u8>) -> Self {
        Self {
            field_id: field_id.to_owned(),
            row_id: row_id.to_string(),
            data,
            field_type: Some(field_type),
        }
    }

    pub fn empty(field_id: &str, row_id: &str) -> Self {
        Self {
            field_id: field_id.to_owned(),
            row_id: row_id.to_owned(),
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

///
#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct CellChangesetPB {
    #[pb(index = 1)]
    pub grid_id: String,

    #[pb(index = 2)]
    pub row_id: String,

    #[pb(index = 3)]
    pub field_id: String,

    #[pb(index = 4)]
    pub type_cell_data: String,
}

impl std::convert::From<CellChangesetPB> for RowChangeset {
    fn from(changeset: CellChangesetPB) -> Self {
        let mut cell_by_field_id = HashMap::with_capacity(1);
        let field_id = changeset.field_id;
        let cell_rev = CellRevision {
            type_cell_data: changeset.type_cell_data,
        };
        cell_by_field_id.insert(field_id, cell_rev);

        RowChangeset {
            row_id: changeset.row_id,
            height: None,
            visibility: None,
            cell_by_field_id,
        }
    }
}
