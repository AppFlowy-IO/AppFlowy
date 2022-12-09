use crate::entities::parser::NotEmptyStr;
use crate::entities::GridLayout;
use flowy_derive::ProtoBuf;
use flowy_error::ErrorCode;

#[derive(Debug, Default, Clone, ProtoBuf)]
pub struct RowIdPB {
    #[pb(index = 1)]
    pub grid_id: String,

    #[pb(index = 2)]
    pub row_id: String,
}

pub struct RowIdParams {
    pub grid_id: String,
    pub row_id: String,
}

impl TryInto<RowIdParams> for RowIdPB {
    type Error = ErrorCode;

    fn try_into(self) -> Result<RowIdParams, Self::Error> {
        let grid_id = NotEmptyStr::parse(self.grid_id).map_err(|_| ErrorCode::GridIdIsEmpty)?;
        let row_id = NotEmptyStr::parse(self.row_id).map_err(|_| ErrorCode::RowIdIsEmpty)?;

        Ok(RowIdParams {
            grid_id: grid_id.0,
            row_id: row_id.0,
        })
    }
}

#[derive(Debug, Default, Clone, ProtoBuf)]
pub struct BlockRowIdPB {
    #[pb(index = 1)]
    pub block_id: String,

    #[pb(index = 2)]
    pub row_id: String,
}

#[derive(ProtoBuf, Default)]
pub struct CreateTableRowPayloadPB {
    #[pb(index = 1)]
    pub grid_id: String,

    #[pb(index = 2, one_of)]
    pub start_row_id: Option<String>,
}

#[derive(Default)]
pub struct CreateRowParams {
    pub grid_id: String,
    pub start_row_id: Option<String>,
    pub group_id: Option<String>,
    pub layout: GridLayout,
}

impl TryInto<CreateRowParams> for CreateTableRowPayloadPB {
    type Error = ErrorCode;

    fn try_into(self) -> Result<CreateRowParams, Self::Error> {
        let grid_id = NotEmptyStr::parse(self.grid_id).map_err(|_| ErrorCode::GridIdIsEmpty)?;

        Ok(CreateRowParams {
            grid_id: grid_id.0,
            start_row_id: self.start_row_id,
            group_id: None,
            layout: GridLayout::Table,
        })
    }
}
