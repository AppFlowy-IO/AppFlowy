use crate::entities::{CreateRowParams, RowPB};
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
        })
    }
}

#[derive(Debug, Default, ProtoBuf)]
pub struct BoardCardChangesetPB {
    #[pb(index = 1)]
    pub group_id: String,

    #[pb(index = 2)]
    pub inserted_cards: Vec<RowPB>,

    #[pb(index = 3)]
    pub deleted_cards: Vec<String>,

    #[pb(index = 4)]
    pub updated_cards: Vec<RowPB>,
}
impl BoardCardChangesetPB {
    pub fn insert(group_id: String, inserted_cards: Vec<RowPB>) -> Self {
        Self {
            group_id,
            inserted_cards,
            ..Default::default()
        }
    }

    pub fn delete(group_id: String, deleted_cards: Vec<String>) -> Self {
        Self {
            group_id,
            deleted_cards,
            ..Default::default()
        }
    }

    pub fn update(group_id: String, updated_cards: Vec<RowPB>) -> Self {
        Self {
            group_id,
            updated_cards,
            ..Default::default()
        }
    }
}
