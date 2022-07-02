use crate::entities::{FieldOrder, GridBlock};
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_error::ErrorCode;
use flowy_grid_data_model::parser::NotEmptyStr;
#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct Grid {
    #[pb(index = 1)]
    pub id: String,

    #[pb(index = 2)]
    pub field_orders: Vec<FieldOrder>,

    #[pb(index = 3)]
    pub blocks: Vec<GridBlock>,
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

#[derive(Debug, Clone, ProtoBuf_Enum)]
pub enum MoveItemType {
    MoveField = 0,
    MoveRow = 1,
}

impl std::default::Default for MoveItemType {
    fn default() -> Self {
        MoveItemType::MoveField
    }
}

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct MoveItemPayload {
    #[pb(index = 1)]
    pub grid_id: String,

    #[pb(index = 2)]
    pub item_id: String,

    #[pb(index = 3)]
    pub from_index: i32,

    #[pb(index = 4)]
    pub to_index: i32,

    #[pb(index = 5)]
    pub ty: MoveItemType,
}

#[derive(Clone)]
pub struct MoveItemParams {
    pub grid_id: String,
    pub item_id: String,
    pub from_index: i32,
    pub to_index: i32,
    pub ty: MoveItemType,
}

impl TryInto<MoveItemParams> for MoveItemPayload {
    type Error = ErrorCode;

    fn try_into(self) -> Result<MoveItemParams, Self::Error> {
        let grid_id = NotEmptyStr::parse(self.grid_id).map_err(|_| ErrorCode::GridIdIsEmpty)?;
        let item_id = NotEmptyStr::parse(self.item_id).map_err(|_| ErrorCode::InvalidData)?;
        Ok(MoveItemParams {
            grid_id: grid_id.0,
            item_id: item_id.0,
            from_index: self.from_index,
            to_index: self.to_index,
            ty: self.ty,
        })
    }
}
