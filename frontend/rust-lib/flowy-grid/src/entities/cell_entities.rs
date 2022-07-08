use crate::entities::{FieldIdentifier, FieldIdentifierPayload};
use flowy_derive::ProtoBuf;
use flowy_error::ErrorCode;
use flowy_grid_data_model::parser::NotEmptyStr;
use flowy_grid_data_model::revision::{CellRevision, RowMetaChangeset};
use std::collections::HashMap;

#[derive(ProtoBuf, Default)]
pub struct CreateSelectOptionPayload {
    #[pb(index = 1)]
    pub field_identifier: FieldIdentifierPayload,

    #[pb(index = 2)]
    pub option_name: String,
}

pub struct CreateSelectOptionParams {
    pub field_identifier: FieldIdentifier,
    pub option_name: String,
}

impl std::ops::Deref for CreateSelectOptionParams {
    type Target = FieldIdentifier;

    fn deref(&self) -> &Self::Target {
        &self.field_identifier
    }
}

impl TryInto<CreateSelectOptionParams> for CreateSelectOptionPayload {
    type Error = ErrorCode;

    fn try_into(self) -> Result<CreateSelectOptionParams, Self::Error> {
        let option_name = NotEmptyStr::parse(self.option_name).map_err(|_| ErrorCode::SelectOptionNameIsEmpty)?;
        let field_identifier = self.field_identifier.try_into()?;
        Ok(CreateSelectOptionParams {
            field_identifier,
            option_name: option_name.0,
        })
    }
}

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct CellIdentifierPayload {
    #[pb(index = 1)]
    pub grid_id: String,

    #[pb(index = 2)]
    pub field_id: String,

    #[pb(index = 3)]
    pub row_id: String,
}

pub struct CellIdentifier {
    pub grid_id: String,
    pub field_id: String,
    pub row_id: String,
}

impl TryInto<CellIdentifier> for CellIdentifierPayload {
    type Error = ErrorCode;

    fn try_into(self) -> Result<CellIdentifier, Self::Error> {
        let grid_id = NotEmptyStr::parse(self.grid_id).map_err(|_| ErrorCode::GridIdIsEmpty)?;
        let field_id = NotEmptyStr::parse(self.field_id).map_err(|_| ErrorCode::FieldIdIsEmpty)?;
        let row_id = NotEmptyStr::parse(self.row_id).map_err(|_| ErrorCode::RowIdIsEmpty)?;
        Ok(CellIdentifier {
            grid_id: grid_id.0,
            field_id: field_id.0,
            row_id: row_id.0,
        })
    }
}
#[derive(Debug, Default, ProtoBuf)]
pub struct Cell {
    #[pb(index = 1)]
    pub field_id: String,

    #[pb(index = 2)]
    pub data: Vec<u8>,
}

impl Cell {
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
pub struct RepeatedCell {
    #[pb(index = 1)]
    pub items: Vec<Cell>,
}

impl std::ops::Deref for RepeatedCell {
    type Target = Vec<Cell>;
    fn deref(&self) -> &Self::Target {
        &self.items
    }
}

impl std::ops::DerefMut for RepeatedCell {
    fn deref_mut(&mut self) -> &mut Self::Target {
        &mut self.items
    }
}

impl std::convert::From<Vec<Cell>> for RepeatedCell {
    fn from(items: Vec<Cell>) -> Self {
        Self { items }
    }
}

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct CellChangeset {
    #[pb(index = 1)]
    pub grid_id: String,

    #[pb(index = 2)]
    pub row_id: String,

    #[pb(index = 3)]
    pub field_id: String,

    #[pb(index = 4, one_of)]
    pub content: Option<String>,
}

impl std::convert::From<CellChangeset> for RowMetaChangeset {
    fn from(changeset: CellChangeset) -> Self {
        let mut cell_by_field_id = HashMap::with_capacity(1);
        let field_id = changeset.field_id;
        let cell_rev = CellRevision {
            data: changeset.content.unwrap_or_else(|| "".to_owned()),
        };
        cell_by_field_id.insert(field_id, cell_rev);

        RowMetaChangeset {
            row_id: changeset.row_id,
            height: None,
            visibility: None,
            cell_by_field_id,
        }
    }
}
