use crate::entities::{GridBlockPB, GridFieldPB};
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_error::ErrorCode;
use flowy_grid_data_model::parser::NotEmptyStr;
#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct GridPB {
    #[pb(index = 1)]
    pub id: String,

    #[pb(index = 2)]
    pub fields: Vec<GridFieldPB>,

    #[pb(index = 3)]
    pub blocks: Vec<GridBlockPB>,
}

#[derive(ProtoBuf, Default)]
pub struct CreateGridPayloadPB {
    #[pb(index = 1)]
    pub name: String,
}

#[derive(Clone, ProtoBuf, Default, Debug)]
pub struct GridIdPB {
    #[pb(index = 1)]
    pub value: String,
}

impl AsRef<str> for GridIdPB {
    fn as_ref(&self) -> &str {
        &self.value
    }
}

#[derive(Clone, ProtoBuf, Default, Debug)]
pub struct GridBlockIdPB {
    #[pb(index = 1)]
    pub value: String,
}

impl AsRef<str> for GridBlockIdPB {
    fn as_ref(&self) -> &str {
        &self.value
    }
}

impl std::convert::From<&str> for GridBlockIdPB {
    fn from(s: &str) -> Self {
        GridBlockIdPB { value: s.to_owned() }
    }
}

#[derive(Debug, Clone, ProtoBuf_Enum)]
pub enum MoveItemTypePB {
    MoveField = 0,
    MoveRow = 1,
}

impl std::default::Default for MoveItemTypePB {
    fn default() -> Self {
        MoveItemTypePB::MoveField
    }
}

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct MoveItemPayloadPB {
    #[pb(index = 1)]
    pub grid_id: String,

    #[pb(index = 2)]
    pub item_id: String,

    #[pb(index = 3)]
    pub from_index: i32,

    #[pb(index = 4)]
    pub to_index: i32,

    #[pb(index = 5)]
    pub ty: MoveItemTypePB,
}

#[derive(Clone)]
pub struct MoveItemParams {
    pub grid_id: String,
    pub item_id: String,
    pub from_index: i32,
    pub to_index: i32,
    pub ty: MoveItemTypePB,
}

impl TryInto<MoveItemParams> for MoveItemPayloadPB {
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
