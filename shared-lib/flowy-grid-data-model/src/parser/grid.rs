use crate::entities::{
    CreateRowPayload, GridBlockOrder, QueryFieldPayload, QueryGridBlocksPayload, QueryRowPayload, RepeatedFieldOrder,
};
use crate::parser::NonEmptyId;
use flowy_error_code::ErrorCode;

#[derive(Default)]
pub struct CreateRowParams {
    pub grid_id: String,
    pub start_row_id: Option<String>,
}

impl TryInto<CreateRowParams> for CreateRowPayload {
    type Error = ErrorCode;

    fn try_into(self) -> Result<CreateRowParams, Self::Error> {
        let grid_id = NonEmptyId::parse(self.grid_id).map_err(|_| ErrorCode::GridIdIsEmpty)?;
        Ok(CreateRowParams {
            grid_id: grid_id.0,
            start_row_id: self.start_row_id,
        })
    }
}

#[derive(Default)]
pub struct QueryFieldParams {
    pub grid_id: String,
    pub field_orders: RepeatedFieldOrder,
}

impl TryInto<QueryFieldParams> for QueryFieldPayload {
    type Error = ErrorCode;

    fn try_into(self) -> Result<QueryFieldParams, Self::Error> {
        let grid_id = NonEmptyId::parse(self.grid_id).map_err(|_| ErrorCode::GridIdIsEmpty)?;
        Ok(QueryFieldParams {
            grid_id: grid_id.0,
            field_orders: self.field_orders,
        })
    }
}

#[derive(Default)]
pub struct QueryGridBlocksParams {
    pub grid_id: String,
    pub block_orders: Vec<GridBlockOrder>,
}

impl TryInto<QueryGridBlocksParams> for QueryGridBlocksPayload {
    type Error = ErrorCode;

    fn try_into(self) -> Result<QueryGridBlocksParams, Self::Error> {
        let grid_id = NonEmptyId::parse(self.grid_id).map_err(|_| ErrorCode::GridIdIsEmpty)?;
        Ok(QueryGridBlocksParams {
            grid_id: grid_id.0,
            block_orders: self.block_orders,
        })
    }
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
        let grid_id = NonEmptyId::parse(self.grid_id).map_err(|_| ErrorCode::GridIdIsEmpty)?;
        let block_id = NonEmptyId::parse(self.block_id).map_err(|_| ErrorCode::BlockIdIsEmpty)?;
        let row_id = NonEmptyId::parse(self.row_id).map_err(|_| ErrorCode::RowIdIsEmpty)?;

        Ok(QueryRowParams {
            grid_id: grid_id.0,
            block_id: block_id.0,
            row_id: row_id.0,
        })
    }
}
