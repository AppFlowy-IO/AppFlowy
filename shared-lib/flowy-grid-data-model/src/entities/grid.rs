use crate::entities::{FieldMeta, FieldType, RowMeta};
use crate::parser::{NotEmptyStr, NotEmptyUuid};
use flowy_derive::ProtoBuf;
use flowy_error_code::ErrorCode;
use std::collections::HashMap;
use std::sync::Arc;

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct Grid {
    #[pb(index = 1)]
    pub id: String,

    #[pb(index = 2)]
    pub field_orders: Vec<FieldOrder>,

    #[pb(index = 3)]
    pub block_orders: Vec<GridBlockOrder>,
}

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct Field {
    #[pb(index = 1)]
    pub id: String,

    #[pb(index = 2)]
    pub name: String,

    #[pb(index = 3)]
    pub desc: String,

    #[pb(index = 4)]
    pub field_type: FieldType,

    #[pb(index = 5)]
    pub frozen: bool,

    #[pb(index = 6)]
    pub visibility: bool,

    #[pb(index = 7)]
    pub width: i32,
}

impl std::convert::From<FieldMeta> for Field {
    fn from(field_meta: FieldMeta) -> Self {
        Self {
            id: field_meta.id,
            name: field_meta.name,
            desc: field_meta.desc,
            field_type: field_meta.field_type,
            frozen: field_meta.frozen,
            visibility: field_meta.visibility,
            width: field_meta.width,
        }
    }
}

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct FieldIdentifierPayload {
    #[pb(index = 1)]
    pub field_id: String,

    #[pb(index = 2)]
    pub grid_id: String,
}

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct FieldIdentifierParams {
    #[pb(index = 1)]
    pub field_id: String,

    #[pb(index = 2)]
    pub grid_id: String,
}

impl TryInto<FieldIdentifierParams> for FieldIdentifierPayload {
    type Error = ErrorCode;

    fn try_into(self) -> Result<FieldIdentifierParams, Self::Error> {
        let grid_id = NotEmptyUuid::parse(self.grid_id).map_err(|_| ErrorCode::GridIdIsEmpty)?;
        let field_id = NotEmptyUuid::parse(self.field_id).map_err(|_| ErrorCode::FieldIdIsEmpty)?;
        Ok(FieldIdentifierParams {
            grid_id: grid_id.0,
            field_id: field_id.0,
        })
    }
}

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct FieldOrder {
    #[pb(index = 1)]
    pub field_id: String,
}

impl std::convert::Into<Vec<FieldOrder>> for FieldOrder {
    fn into(self) -> Vec<FieldOrder> {
        vec![self]
    }
}

impl std::convert::From<&FieldMeta> for FieldOrder {
    fn from(field_meta: &FieldMeta) -> Self {
        Self {
            field_id: field_meta.id.clone(),
        }
    }
}

impl std::convert::From<&str> for FieldOrder {
    fn from(s: &str) -> Self {
        FieldOrder { field_id: s.to_owned() }
    }
}

#[derive(Debug, Default, ProtoBuf)]
pub struct GetEditFieldContextPayload {
    #[pb(index = 1)]
    pub grid_id: String,

    #[pb(index = 2, one_of)]
    pub field_id: Option<String>,

    #[pb(index = 3)]
    pub field_type: FieldType,
}

#[derive(Debug, Default, ProtoBuf)]
pub struct EditFieldPayload {
    #[pb(index = 1)]
    pub grid_id: String,

    #[pb(index = 2)]
    pub field_id: String,

    #[pb(index = 3)]
    pub field_type: FieldType,
}

pub struct EditFieldParams {
    pub grid_id: String,
    pub field_id: String,
    pub field_type: FieldType,
}

impl TryInto<EditFieldParams> for EditFieldPayload {
    type Error = ErrorCode;

    fn try_into(self) -> Result<EditFieldParams, Self::Error> {
        let grid_id = NotEmptyUuid::parse(self.grid_id).map_err(|_| ErrorCode::GridIdIsEmpty)?;
        let field_id = NotEmptyUuid::parse(self.field_id).map_err(|_| ErrorCode::FieldIdIsEmpty)?;
        Ok(EditFieldParams {
            grid_id: grid_id.0,
            field_id: field_id.0,
            field_type: self.field_type,
        })
    }
}

#[derive(Debug, Default, ProtoBuf)]
pub struct EditFieldContext {
    #[pb(index = 1)]
    pub grid_id: String,

    #[pb(index = 2)]
    pub grid_field: Field,

    #[pb(index = 3)]
    pub type_option_data: Vec<u8>,
}

#[derive(Debug, Default, ProtoBuf)]
pub struct RepeatedField {
    #[pb(index = 1)]
    pub items: Vec<Field>,
}
impl std::ops::Deref for RepeatedField {
    type Target = Vec<Field>;
    fn deref(&self) -> &Self::Target {
        &self.items
    }
}

impl std::ops::DerefMut for RepeatedField {
    fn deref_mut(&mut self) -> &mut Self::Target {
        &mut self.items
    }
}

impl std::convert::From<Vec<Field>> for RepeatedField {
    fn from(items: Vec<Field>) -> Self {
        Self { items }
    }
}

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct RepeatedFieldOrder {
    #[pb(index = 1)]
    pub items: Vec<FieldOrder>,
}

impl std::ops::Deref for RepeatedFieldOrder {
    type Target = Vec<FieldOrder>;
    fn deref(&self) -> &Self::Target {
        &self.items
    }
}

impl std::convert::From<Vec<FieldOrder>> for RepeatedFieldOrder {
    fn from(field_orders: Vec<FieldOrder>) -> Self {
        RepeatedFieldOrder { items: field_orders }
    }
}

#[derive(Debug, Default, Clone, ProtoBuf)]
pub struct RowOrder {
    #[pb(index = 1)]
    pub row_id: String,

    #[pb(index = 2)]
    pub block_id: String,

    #[pb(index = 3)]
    pub height: i32,
}

impl std::convert::From<&RowMeta> for RowOrder {
    fn from(row: &RowMeta) -> Self {
        Self {
            row_id: row.id.clone(),
            block_id: row.block_id.clone(),
            height: row.height,
        }
    }
}

impl std::convert::From<&Arc<RowMeta>> for RowOrder {
    fn from(row: &Arc<RowMeta>) -> Self {
        Self {
            row_id: row.id.clone(),
            block_id: row.block_id.clone(),
            height: row.height,
        }
    }
}

#[derive(Debug, Default, ProtoBuf)]
pub struct Row {
    #[pb(index = 1)]
    pub id: String,

    #[pb(index = 2)]
    pub cell_by_field_id: HashMap<String, Cell>,

    #[pb(index = 3)]
    pub height: i32,
}

#[derive(Debug, Default, ProtoBuf)]
pub struct RepeatedRow {
    #[pb(index = 1)]
    pub items: Vec<Row>,
}

impl std::convert::From<Vec<Row>> for RepeatedRow {
    fn from(items: Vec<Row>) -> Self {
        Self { items }
    }
}

#[derive(Debug, Default, ProtoBuf)]
pub struct RepeatedGridBlock {
    #[pb(index = 1)]
    pub items: Vec<GridBlock>,
}

impl std::convert::From<Vec<GridBlock>> for RepeatedGridBlock {
    fn from(items: Vec<GridBlock>) -> Self {
        Self { items }
    }
}

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct GridBlockOrder {
    #[pb(index = 1)]
    pub block_id: String,
}

impl std::convert::From<&str> for GridBlockOrder {
    fn from(s: &str) -> Self {
        GridBlockOrder { block_id: s.to_owned() }
    }
}

#[derive(Debug, Default, ProtoBuf)]
pub struct GridBlock {
    #[pb(index = 1)]
    pub id: String,

    #[pb(index = 2)]
    pub row_orders: Vec<RowOrder>,
}

impl GridBlock {
    pub fn new(block_id: &str, row_orders: Vec<RowOrder>) -> Self {
        Self {
            id: block_id.to_owned(),
            row_orders,
        }
    }
}

#[derive(Debug, Default, ProtoBuf)]
pub struct Cell {
    #[pb(index = 1)]
    pub field_id: String,

    #[pb(index = 2)]
    pub content: String,
}

impl Cell {
    pub fn new(field_id: &str, content: String) -> Self {
        Self {
            field_id: field_id.to_owned(),
            content,
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

#[derive(ProtoBuf, Default)]
pub struct CreateGridPayload {
    #[pb(index = 1)]
    pub name: String,
}

#[derive(Clone, ProtoBuf, Default, Debug)]
pub struct GridId {
    #[pb(index = 1)]
    pub value: String,
}

impl AsRef<str> for GridId {
    fn as_ref(&self) -> &str {
        &self.value
    }
}

#[derive(Clone, ProtoBuf, Default, Debug)]
pub struct GridBlockId {
    #[pb(index = 1)]
    pub value: String,
}

impl AsRef<str> for GridBlockId {
    fn as_ref(&self) -> &str {
        &self.value
    }
}

impl std::convert::From<&str> for GridBlockId {
    fn from(s: &str) -> Self {
        GridBlockId { value: s.to_owned() }
    }
}

#[derive(ProtoBuf, Default)]
pub struct CreateRowPayload {
    #[pb(index = 1)]
    pub grid_id: String,

    #[pb(index = 2, one_of)]
    pub start_row_id: Option<String>,
}

#[derive(Default)]
pub struct CreateRowParams {
    pub grid_id: String,
    pub start_row_id: Option<String>,
}

impl TryInto<CreateRowParams> for CreateRowPayload {
    type Error = ErrorCode;

    fn try_into(self) -> Result<CreateRowParams, Self::Error> {
        let grid_id = NotEmptyUuid::parse(self.grid_id).map_err(|_| ErrorCode::GridIdIsEmpty)?;
        Ok(CreateRowParams {
            grid_id: grid_id.0,
            start_row_id: self.start_row_id,
        })
    }
}

#[derive(ProtoBuf, Default)]
pub struct CreateFieldPayload {
    #[pb(index = 1)]
    pub grid_id: String,

    #[pb(index = 2)]
    pub field: Field,

    #[pb(index = 3)]
    pub type_option_data: Vec<u8>,

    #[pb(index = 4, one_of)]
    pub start_field_id: Option<String>,
}

#[derive(Default, Clone)]
pub struct CreateFieldParams {
    pub grid_id: String,
    pub field: Field,
    pub type_option_data: Vec<u8>,
    pub start_field_id: Option<String>,
}

impl TryInto<CreateFieldParams> for CreateFieldPayload {
    type Error = ErrorCode;

    fn try_into(self) -> Result<CreateFieldParams, Self::Error> {
        let grid_id = NotEmptyUuid::parse(self.grid_id).map_err(|_| ErrorCode::GridIdIsEmpty)?;
        let _ = NotEmptyUuid::parse(self.field.id.clone()).map_err(|_| ErrorCode::FieldIdIsEmpty)?;

        let start_field_id = match self.start_field_id {
            None => None,
            Some(id) => Some(NotEmptyUuid::parse(id).map_err(|_| ErrorCode::FieldIdIsEmpty)?.0),
        };

        Ok(CreateFieldParams {
            grid_id: grid_id.0,
            field: self.field,
            type_option_data: self.type_option_data,
            start_field_id,
        })
    }
}

#[derive(ProtoBuf, Default)]
pub struct QueryFieldPayload {
    #[pb(index = 1)]
    pub grid_id: String,

    #[pb(index = 2)]
    pub field_orders: RepeatedFieldOrder,
}

#[derive(Default)]
pub struct QueryFieldParams {
    pub grid_id: String,
    pub field_orders: RepeatedFieldOrder,
}

impl TryInto<QueryFieldParams> for QueryFieldPayload {
    type Error = ErrorCode;

    fn try_into(self) -> Result<QueryFieldParams, Self::Error> {
        let grid_id = NotEmptyUuid::parse(self.grid_id).map_err(|_| ErrorCode::GridIdIsEmpty)?;
        Ok(QueryFieldParams {
            grid_id: grid_id.0,
            field_orders: self.field_orders,
        })
    }
}

#[derive(ProtoBuf, Default)]
pub struct QueryGridBlocksPayload {
    #[pb(index = 1)]
    pub grid_id: String,

    #[pb(index = 2)]
    pub block_orders: Vec<GridBlockOrder>,
}

#[derive(Default)]
pub struct QueryGridBlocksParams {
    pub grid_id: String,
    pub block_orders: Vec<GridBlockOrder>,
}

impl TryInto<QueryGridBlocksParams> for QueryGridBlocksPayload {
    type Error = ErrorCode;

    fn try_into(self) -> Result<QueryGridBlocksParams, Self::Error> {
        let grid_id = NotEmptyUuid::parse(self.grid_id).map_err(|_| ErrorCode::GridIdIsEmpty)?;
        Ok(QueryGridBlocksParams {
            grid_id: grid_id.0,
            block_orders: self.block_orders,
        })
    }
}

#[derive(ProtoBuf, Default)]
pub struct QueryRowPayload {
    #[pb(index = 1)]
    pub grid_id: String,

    #[pb(index = 2)]
    pub block_id: String,

    #[pb(index = 3)]
    pub row_id: String,
}

#[derive(Default)]
pub struct QueryRowParams {
    pub grid_id: String,
    pub block_id: String,
    pub row_id: String,
}

impl TryInto<QueryRowParams> for QueryRowPayload {
    type Error = ErrorCode;

    fn try_into(self) -> Result<QueryRowParams, Self::Error> {
        let grid_id = NotEmptyUuid::parse(self.grid_id).map_err(|_| ErrorCode::GridIdIsEmpty)?;
        let block_id = NotEmptyUuid::parse(self.block_id).map_err(|_| ErrorCode::BlockIdIsEmpty)?;
        let row_id = NotEmptyUuid::parse(self.row_id).map_err(|_| ErrorCode::RowIdIsEmpty)?;

        Ok(QueryRowParams {
            grid_id: grid_id.0,
            block_id: block_id.0,
            row_id: row_id.0,
        })
    }
}

#[derive(ProtoBuf, Default)]
pub struct CreateSelectOptionPayload {
    #[pb(index = 1)]
    pub option_name: String,
}

pub struct CreateSelectOptionParams {
    pub option_name: String,
}

impl TryInto<CreateSelectOptionParams> for CreateSelectOptionPayload {
    type Error = ErrorCode;

    fn try_into(self) -> Result<CreateSelectOptionParams, Self::Error> {
        let option_name = NotEmptyStr::parse(self.option_name).map_err(|_| ErrorCode::SelectOptionNameIsEmpty)?;
        Ok(CreateSelectOptionParams {
            option_name: option_name.0,
        })
    }
}
