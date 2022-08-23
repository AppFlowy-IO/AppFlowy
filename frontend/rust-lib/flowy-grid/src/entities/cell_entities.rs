use flowy_derive::ProtoBuf;
use flowy_error::ErrorCode;
use flowy_grid_data_model::parser::NotEmptyStr;
use flowy_grid_data_model::revision::{CellRevision, RowChangeset};
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
pub struct GridCellIdPB {
    #[pb(index = 1)]
    pub grid_id: String,

    #[pb(index = 2)]
    pub field_id: String,

    #[pb(index = 3)]
    pub row_id: String,
}

pub struct GridCellIdParams {
    pub grid_id: String,
    pub field_id: String,
    pub row_id: String,
}

impl TryInto<GridCellIdParams> for GridCellIdPB {
    type Error = ErrorCode;

    fn try_into(self) -> Result<GridCellIdParams, Self::Error> {
        let grid_id = NotEmptyStr::parse(self.grid_id).map_err(|_| ErrorCode::GridIdIsEmpty)?;
        let field_id = NotEmptyStr::parse(self.field_id).map_err(|_| ErrorCode::FieldIdIsEmpty)?;
        let row_id = NotEmptyStr::parse(self.row_id).map_err(|_| ErrorCode::RowIdIsEmpty)?;
        Ok(GridCellIdParams {
            grid_id: grid_id.0,
            field_id: field_id.0,
            row_id: row_id.0,
        })
    }
}
#[derive(Debug, Default, ProtoBuf)]
pub struct GridCellPB {
    #[pb(index = 1)]
    pub field_id: String,

    #[pb(index = 2)]
    pub data: Vec<u8>,
}

impl GridCellPB {
    pub fn new(field_id: &str, data: Vec<u8>) -> Self {
        Self {
            field_id: field_id.to_owned(),
            data,
        }
    }

    pub fn empty(field_id: &str) -> Self {
        Self {
            field_id: field_id.to_owned(),
            data: vec![],
        }
    }
}

#[derive(Debug, Default, ProtoBuf)]
pub struct RepeatedCellPB {
    #[pb(index = 1)]
    pub items: Vec<GridCellPB>,
}

impl std::ops::Deref for RepeatedCellPB {
    type Target = Vec<GridCellPB>;
    fn deref(&self) -> &Self::Target {
        &self.items
    }
}

impl std::ops::DerefMut for RepeatedCellPB {
    fn deref_mut(&mut self) -> &mut Self::Target {
        &mut self.items
    }
}

impl std::convert::From<Vec<GridCellPB>> for RepeatedCellPB {
    fn from(items: Vec<GridCellPB>) -> Self {
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
    pub content: String,
}

impl std::convert::From<CellChangesetPB> for RowChangeset {
    fn from(changeset: CellChangesetPB) -> Self {
        let mut cell_by_field_id = HashMap::with_capacity(1);
        let field_id = changeset.field_id;
        let cell_rev = CellRevision {
            data: changeset.content,
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
