use crate::entities::{CellMeta, FieldMeta, RowMeta, RowMetaChangeset};
use crate::parser::NotEmptyStr;
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_error_code::ErrorCode;

use serde_repr::*;
use std::collections::HashMap;
use std::sync::Arc;
use strum_macros::{Display, EnumCount as EnumCountMacro, EnumIter, EnumString};

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
pub struct FieldOrder {
    #[pb(index = 1)]
    pub field_id: String,
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

impl std::convert::From<String> for FieldOrder {
    fn from(s: String) -> Self {
        FieldOrder { field_id: s }
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
        let grid_id = NotEmptyStr::parse(self.grid_id).map_err(|_| ErrorCode::GridIdIsEmpty)?;
        let field_id = NotEmptyStr::parse(self.field_id).map_err(|_| ErrorCode::FieldIdIsEmpty)?;
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

impl std::convert::From<String> for RepeatedFieldOrder {
    fn from(s: String) -> Self {
        RepeatedFieldOrder {
            items: vec![FieldOrder::from(s)],
        }
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

    #[pb(index = 2)]
    pub row_orders: Vec<RowOrder>,
}

impl GridBlockOrder {
    pub fn new(block_id: &str) -> Self {
        GridBlockOrder {
            block_id: block_id.to_owned(),
            row_orders: vec![],
        }
    }
}

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct GridBlockOrderChangeset {
    #[pb(index = 1)]
    pub block_id: String,

    #[pb(index = 2)]
    pub inserted_rows: Vec<IndexRowOrder>,

    #[pb(index = 3)]
    pub deleted_rows: Vec<RowOrder>,

    #[pb(index = 4)]
    pub updated_rows: Vec<RowOrder>,
}

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct IndexRowOrder {
    #[pb(index = 1)]
    pub row_order: RowOrder,

    #[pb(index = 2, one_of)]
    pub index: Option<i32>,
}

impl std::convert::From<RowOrder> for IndexRowOrder {
    fn from(row_order: RowOrder) -> Self {
        Self { row_order, index: None }
    }
}

impl std::convert::From<&RowMeta> for IndexRowOrder {
    fn from(row: &RowMeta) -> Self {
        let row_order = RowOrder::from(row);
        Self::from(row_order)
    }
}

impl GridBlockOrderChangeset {
    pub fn from_insert(block_id: &str, inserted_rows: Vec<IndexRowOrder>) -> Self {
        Self {
            block_id: block_id.to_owned(),
            inserted_rows,
            deleted_rows: vec![],
            updated_rows: vec![],
        }
    }

    pub fn from_delete(block_id: &str, deleted_rows: Vec<RowOrder>) -> Self {
        Self {
            block_id: block_id.to_owned(),
            inserted_rows: vec![],
            deleted_rows,
            updated_rows: vec![],
        }
    }

    pub fn from_update(block_id: &str, updated_rows: Vec<RowOrder>) -> Self {
        Self {
            block_id: block_id.to_owned(),
            inserted_rows: vec![],
            deleted_rows: vec![],
            updated_rows,
        }
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

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct CellNotificationData {
    #[pb(index = 1)]
    pub grid_id: String,

    #[pb(index = 2)]
    pub field_id: String,

    #[pb(index = 3)]
    pub row_id: String,

    #[pb(index = 4, one_of)]
    pub content: Option<String>,
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
        let grid_id = NotEmptyStr::parse(self.grid_id).map_err(|_| ErrorCode::GridIdIsEmpty)?;
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

#[derive(Clone)]
pub struct CreateFieldParams {
    pub grid_id: String,
    pub field: Field,
    pub type_option_data: Vec<u8>,
    pub start_field_id: Option<String>,
}

impl TryInto<CreateFieldParams> for CreateFieldPayload {
    type Error = ErrorCode;

    fn try_into(self) -> Result<CreateFieldParams, Self::Error> {
        let grid_id = NotEmptyStr::parse(self.grid_id).map_err(|_| ErrorCode::GridIdIsEmpty)?;
        let _ = NotEmptyStr::parse(self.field.id.clone()).map_err(|_| ErrorCode::FieldIdIsEmpty)?;

        let start_field_id = match self.start_field_id {
            None => None,
            Some(id) => Some(NotEmptyStr::parse(id).map_err(|_| ErrorCode::FieldIdIsEmpty)?.0),
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

pub struct QueryFieldParams {
    pub grid_id: String,
    pub field_orders: RepeatedFieldOrder,
}

impl TryInto<QueryFieldParams> for QueryFieldPayload {
    type Error = ErrorCode;

    fn try_into(self) -> Result<QueryFieldParams, Self::Error> {
        let grid_id = NotEmptyStr::parse(self.grid_id).map_err(|_| ErrorCode::GridIdIsEmpty)?;
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

pub struct QueryGridBlocksParams {
    pub grid_id: String,
    pub block_orders: Vec<GridBlockOrder>,
}

impl TryInto<QueryGridBlocksParams> for QueryGridBlocksPayload {
    type Error = ErrorCode;

    fn try_into(self) -> Result<QueryGridBlocksParams, Self::Error> {
        let grid_id = NotEmptyStr::parse(self.grid_id).map_err(|_| ErrorCode::GridIdIsEmpty)?;
        Ok(QueryGridBlocksParams {
            grid_id: grid_id.0,
            block_orders: self.block_orders,
        })
    }
}

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct FieldChangesetPayload {
    #[pb(index = 1)]
    pub field_id: String,

    #[pb(index = 2)]
    pub grid_id: String,

    #[pb(index = 3, one_of)]
    pub name: Option<String>,

    #[pb(index = 4, one_of)]
    pub desc: Option<String>,

    #[pb(index = 5, one_of)]
    pub field_type: Option<FieldType>,

    #[pb(index = 6, one_of)]
    pub frozen: Option<bool>,

    #[pb(index = 7, one_of)]
    pub visibility: Option<bool>,

    #[pb(index = 8, one_of)]
    pub width: Option<i32>,

    #[pb(index = 9, one_of)]
    pub type_option_data: Option<Vec<u8>>,
}

#[derive(Debug, Clone, Default)]
pub struct FieldChangesetParams {
    pub field_id: String,

    pub grid_id: String,

    pub name: Option<String>,

    pub desc: Option<String>,

    pub field_type: Option<FieldType>,

    pub frozen: Option<bool>,

    pub visibility: Option<bool>,

    pub width: Option<i32>,

    pub type_option_data: Option<Vec<u8>>,
}

impl TryInto<FieldChangesetParams> for FieldChangesetPayload {
    type Error = ErrorCode;

    fn try_into(self) -> Result<FieldChangesetParams, Self::Error> {
        let grid_id = NotEmptyStr::parse(self.grid_id).map_err(|_| ErrorCode::GridIdIsEmpty)?;
        let field_id = NotEmptyStr::parse(self.field_id).map_err(|_| ErrorCode::FieldIdIsEmpty)?;

        if let Some(type_option_data) = self.type_option_data.as_ref() {
            if type_option_data.is_empty() {
                return Err(ErrorCode::TypeOptionDataIsEmpty);
            }
        }

        Ok(FieldChangesetParams {
            field_id: field_id.0,
            grid_id: grid_id.0,
            name: self.name,
            desc: self.desc,
            field_type: self.field_type,
            frozen: self.frozen,
            visibility: self.visibility,
            width: self.width,
            type_option_data: self.type_option_data,
        })
    }
}

#[derive(
    Debug,
    Clone,
    PartialEq,
    Eq,
    ProtoBuf_Enum,
    EnumCountMacro,
    EnumString,
    EnumIter,
    Display,
    Serialize_repr,
    Deserialize_repr,
)]
#[repr(u8)]
pub enum FieldType {
    RichText = 0,
    Number = 1,
    DateTime = 2,
    SingleSelect = 3,
    MultiSelect = 4,
    Checkbox = 5,
}

impl std::default::Default for FieldType {
    fn default() -> Self {
        FieldType::RichText
    }
}

impl AsRef<FieldType> for FieldType {
    fn as_ref(&self) -> &FieldType {
        self
    }
}

impl From<&FieldType> for FieldType {
    fn from(field_type: &FieldType) -> Self {
        field_type.clone()
    }
}

impl FieldType {
    pub fn type_id(&self) -> String {
        let ty = self.clone();
        format!("{}", ty as u8)
    }

    pub fn default_cell_width(&self) -> i32 {
        match self {
            FieldType::DateTime => 180,
            _ => 150,
        }
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
    pub data: Option<String>,
}

impl std::convert::From<CellChangeset> for RowMetaChangeset {
    fn from(changeset: CellChangeset) -> Self {
        let mut cell_by_field_id = HashMap::with_capacity(1);
        let field_id = changeset.field_id;
        let cell_meta = CellMeta {
            data: changeset.data.unwrap_or_else(|| "".to_owned()),
        };
        cell_by_field_id.insert(field_id, cell_meta);

        RowMetaChangeset {
            row_id: changeset.row_id,
            height: None,
            visibility: None,
            cell_by_field_id,
        }
    }
}
