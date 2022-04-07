use flowy_derive::ProtoBuf;
use flowy_error::ErrorCode;
use flowy_grid_data_model::parser::NotEmptyUuid;

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct FieldIdentifierPayload {
    #[pb(index = 1)]
    pub field_id: String,

    #[pb(index = 2)]
    pub grid_id: String,
}

pub struct FieldIdentifier {
    pub field_id: String,
    pub grid_id: String,
}

impl TryInto<FieldIdentifier> for FieldIdentifierPayload {
    type Error = ErrorCode;

    fn try_into(self) -> Result<FieldIdentifier, Self::Error> {
        let grid_id = NotEmptyUuid::parse(self.grid_id).map_err(|_| ErrorCode::GridIdIsEmpty)?;
        let field_id = NotEmptyUuid::parse(self.field_id).map_err(|_| ErrorCode::FieldIdIsEmpty)?;
        Ok(FieldIdentifier {
            grid_id: grid_id.0,
            field_id: field_id.0,
        })
    }
}
