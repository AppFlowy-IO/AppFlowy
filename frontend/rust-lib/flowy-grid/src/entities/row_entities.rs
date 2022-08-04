use flowy_derive::ProtoBuf;
use flowy_error::ErrorCode;
use flowy_grid_data_model::parser::NotEmptyStr;

#[derive(Debug, Default, Clone, ProtoBuf)]
pub struct GridRowIdPB {
    #[pb(index = 1)]
    pub grid_id: String,

    #[pb(index = 2)]
    pub block_id: String,

    #[pb(index = 3)]
    pub row_id: String,
}

pub struct GridRowIdParams {
    pub grid_id: String,
    pub block_id: String,
    pub row_id: String,
}

impl TryInto<GridRowIdParams> for GridRowIdPB {
    type Error = ErrorCode;

    fn try_into(self) -> Result<GridRowIdParams, Self::Error> {
        let grid_id = NotEmptyStr::parse(self.grid_id).map_err(|_| ErrorCode::GridIdIsEmpty)?;
        let block_id = NotEmptyStr::parse(self.block_id).map_err(|_| ErrorCode::BlockIdIsEmpty)?;
        let row_id = NotEmptyStr::parse(self.row_id).map_err(|_| ErrorCode::RowIdIsEmpty)?;

        Ok(GridRowIdParams {
            grid_id: grid_id.0,
            block_id: block_id.0,
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
pub struct CreateRowPayloadPB {
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

impl TryInto<CreateRowParams> for CreateRowPayloadPB {
    type Error = ErrorCode;

    fn try_into(self) -> Result<CreateRowParams, Self::Error> {
        let grid_id = NotEmptyStr::parse(self.grid_id).map_err(|_| ErrorCode::GridIdIsEmpty)?;
        Ok(CreateRowParams {
            grid_id: grid_id.0,
            start_row_id: self.start_row_id,
        })
    }
}
