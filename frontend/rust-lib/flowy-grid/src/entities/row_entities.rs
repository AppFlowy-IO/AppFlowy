use flowy_derive::ProtoBuf;
use flowy_error::ErrorCode;
use flowy_grid_data_model::parser::NotEmptyStr;

#[derive(ProtoBuf, Default)]
pub struct GridRowIdPayload {
    #[pb(index = 1)]
    pub grid_id: String,

    #[pb(index = 2)]
    pub block_id: String,

    #[pb(index = 3)]
    pub row_id: String,
}

#[derive(Debug, Default, Clone, ProtoBuf)]
pub struct GridRowId {
    #[pb(index = 1)]
    pub grid_id: String,

    #[pb(index = 2)]
    pub block_id: String,

    #[pb(index = 3)]
    pub row_id: String,
}

impl TryInto<GridRowId> for GridRowIdPayload {
    type Error = ErrorCode;

    fn try_into(self) -> Result<GridRowId, Self::Error> {
        let grid_id = NotEmptyStr::parse(self.grid_id).map_err(|_| ErrorCode::GridIdIsEmpty)?;
        // let block_id = NotEmptyStr::parse(self.block_id).map_err(|_| ErrorCode::BlockIdIsEmpty)?;
        let row_id = NotEmptyStr::parse(self.row_id).map_err(|_| ErrorCode::RowIdIsEmpty)?;

        Ok(GridRowId {
            grid_id: grid_id.0,
            block_id: self.block_id,
            row_id: row_id.0,
        })
    }
}

#[derive(Debug, Default, Clone, ProtoBuf)]
pub struct BlockRowId {
    #[pb(index = 1)]
    pub block_id: String,

    #[pb(index = 2)]
    pub row_id: String,
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
