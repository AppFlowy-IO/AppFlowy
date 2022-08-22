use crate::entities::{BlockPB, FieldIdPB};
use flowy_derive::ProtoBuf;
use flowy_error::ErrorCode;
use flowy_grid_data_model::parser::NotEmptyStr;

/// [GridPB] describes how many fields and blocks the grid has
#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct GridPB {
    #[pb(index = 1)]
    pub id: String,

    #[pb(index = 2)]
    pub fields: Vec<FieldIdPB>,

    #[pb(index = 3)]
    pub blocks: Vec<BlockPB>,
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

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct MoveFieldPayloadPB {
    #[pb(index = 1)]
    pub grid_id: String,

    #[pb(index = 2)]
    pub field_id: String,

    #[pb(index = 3)]
    pub from_index: i32,

    #[pb(index = 4)]
    pub to_index: i32,
}

#[derive(Clone)]
pub struct MoveFieldParams {
    pub grid_id: String,
    pub field_id: String,
    pub from_index: i32,
    pub to_index: i32,
}

impl TryInto<MoveFieldParams> for MoveFieldPayloadPB {
    type Error = ErrorCode;

    fn try_into(self) -> Result<MoveFieldParams, Self::Error> {
        let grid_id = NotEmptyStr::parse(self.grid_id).map_err(|_| ErrorCode::GridIdIsEmpty)?;
        let item_id = NotEmptyStr::parse(self.field_id).map_err(|_| ErrorCode::InvalidData)?;
        Ok(MoveFieldParams {
            grid_id: grid_id.0,
            field_id: item_id.0,
            from_index: self.from_index,
            to_index: self.to_index,
        })
    }
}

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct MoveRowPayloadPB {
    #[pb(index = 1)]
    pub view_id: String,

    #[pb(index = 2)]
    pub from_row_id: String,

    #[pb(index = 4)]
    pub to_row_id: String,
}

pub struct MoveRowParams {
    pub view_id: String,
    pub from_row_id: String,
    pub to_row_id: String,
}

impl TryInto<MoveRowParams> for MoveRowPayloadPB {
    type Error = ErrorCode;

    fn try_into(self) -> Result<MoveRowParams, Self::Error> {
        let view_id = NotEmptyStr::parse(self.view_id).map_err(|_| ErrorCode::GridViewIdIsEmpty)?;
        let from_row_id = NotEmptyStr::parse(self.from_row_id).map_err(|_| ErrorCode::RowIdIsEmpty)?;
        let to_row_id = NotEmptyStr::parse(self.to_row_id).map_err(|_| ErrorCode::RowIdIsEmpty)?;

        Ok(MoveRowParams {
            view_id: view_id.0,
            from_row_id: from_row_id.0,
            to_row_id: to_row_id.0,
        })
    }
}
