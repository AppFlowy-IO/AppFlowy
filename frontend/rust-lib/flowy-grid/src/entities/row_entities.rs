use flowy_derive::ProtoBuf;
use flowy_error::ErrorCode;
use flowy_grid_data_model::parser::NotEmptyStr;

#[derive(ProtoBuf, Default)]
pub struct RowIdentifierPayload {
    #[pb(index = 1)]
    pub grid_id: String,

    #[pb(index = 3)]
    pub row_id: String,
}

pub struct RowIdentifier {
    pub grid_id: String,
    pub row_id: String,
}

impl TryInto<RowIdentifier> for RowIdentifierPayload {
    type Error = ErrorCode;

    fn try_into(self) -> Result<RowIdentifier, Self::Error> {
        let grid_id = NotEmptyStr::parse(self.grid_id).map_err(|_| ErrorCode::GridIdIsEmpty)?;
        let row_id = NotEmptyStr::parse(self.row_id).map_err(|_| ErrorCode::RowIdIsEmpty)?;

        Ok(RowIdentifier {
            grid_id: grid_id.0,
            row_id: row_id.0,
        })
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
