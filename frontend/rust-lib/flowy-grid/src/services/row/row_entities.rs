use flowy_derive::ProtoBuf;
use flowy_error::ErrorCode;
use flowy_grid_data_model::parser::{NotEmptyStr, NotEmptyUuid};

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
        let grid_id = NotEmptyUuid::parse(self.grid_id).map_err(|_| ErrorCode::GridIdIsEmpty)?;
        let row_id = NotEmptyUuid::parse(self.row_id).map_err(|_| ErrorCode::RowIdIsEmpty)?;

        Ok(RowIdentifier {
            grid_id: grid_id.0,
            row_id: row_id.0,
        })
    }
}
