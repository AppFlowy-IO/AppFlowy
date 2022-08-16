use crate::entities::{CreateRowParams, GridLayout};
use flowy_derive::ProtoBuf;
use flowy_error::ErrorCode;
use flowy_grid_data_model::parser::NotEmptyStr;

#[derive(ProtoBuf, Debug, Default, Clone)]
pub struct CreateBoardCardPayloadPB {
    #[pb(index = 1)]
    pub grid_id: String,

    #[pb(index = 2)]
    pub group_id: String,
}

impl TryInto<CreateRowParams> for CreateBoardCardPayloadPB {
    type Error = ErrorCode;

    fn try_into(self) -> Result<CreateRowParams, Self::Error> {
        let grid_id = NotEmptyStr::parse(self.grid_id).map_err(|_| ErrorCode::GridIdIsEmpty)?;
        let group_id = NotEmptyStr::parse(self.group_id).map_err(|_| ErrorCode::GroupIdIsEmpty)?;
        Ok(CreateRowParams {
            grid_id: grid_id.0,
            start_row_id: None,
            group_id: Some(group_id.0),
            layout: GridLayout::Board,
        })
    }
}
