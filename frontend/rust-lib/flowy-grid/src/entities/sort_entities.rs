use crate::entities::parser::NotEmptyStr;
use crate::entities::FieldType;
use crate::services::sort::SortType;

use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_error::ErrorCode;
use grid_rev_model::FieldTypeRevision;

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct GridSortPB {
    #[pb(index = 1)]
    pub id: String,

    #[pb(index = 2)]
    pub field_id: String,

    #[pb(index = 3)]
    pub field_type: FieldType,

    #[pb(index = 4)]
    pub condition: GridSortConditionPB,
}

#[derive(Debug, Clone, PartialEq, Eq, ProtoBuf_Enum)]
#[repr(u8)]
pub enum GridSortConditionPB {
    Ascending = 0,
    Descending = 1,
}
impl std::default::Default for GridSortConditionPB {
    fn default() -> Self {
        Self::Ascending
    }
}
#[derive(ProtoBuf, Debug, Default, Clone)]
pub struct AlterSortPayloadPB {
    #[pb(index = 1)]
    pub view_id: String,

    #[pb(index = 2)]
    pub field_id: String,

    #[pb(index = 3)]
    pub field_type: FieldType,

    /// Create a new filter if the filter_id is None
    #[pb(index = 4, one_of)]
    pub sort_id: Option<String>,

    #[pb(index = 5)]
    pub condition: GridSortConditionPB,
}

impl TryInto<AlterSortParams> for AlterSortPayloadPB {
    type Error = ErrorCode;

    fn try_into(self) -> Result<AlterSortParams, Self::Error> {
        let view_id = NotEmptyStr::parse(self.view_id)
            .map_err(|_| ErrorCode::GridViewIdIsEmpty)?
            .0;

        let field_id = NotEmptyStr::parse(self.field_id)
            .map_err(|_| ErrorCode::FieldIdIsEmpty)?
            .0;
        let sort_id = match self.sort_id {
            None => None,
            Some(filter_id) => Some(NotEmptyStr::parse(filter_id).map_err(|_| ErrorCode::FilterIdIsEmpty)?.0),
        };

        Ok(AlterSortParams {
            view_id,
            field_id,
            sort_id,
            field_type: self.field_type.into(),
            condition: self.condition as u8,
        })
    }
}

#[derive(Debug)]
pub struct AlterSortParams {
    pub view_id: String,
    pub field_id: String,
    /// Create a new sort if the sort is None
    pub sort_id: Option<String>,
    pub field_type: FieldTypeRevision,
    pub condition: u8,
}

#[derive(ProtoBuf, Debug, Default, Clone)]
pub struct DeleteSortPayloadPB {
    #[pb(index = 1)]
    pub view_id: String,

    #[pb(index = 2)]
    pub field_id: String,

    #[pb(index = 3)]
    pub field_type: FieldType,

    #[pb(index = 4)]
    pub sort_id: String,
}

impl TryInto<DeleteSortParams> for DeleteSortPayloadPB {
    type Error = ErrorCode;

    fn try_into(self) -> Result<DeleteSortParams, Self::Error> {
        let view_id = NotEmptyStr::parse(self.view_id)
            .map_err(|_| ErrorCode::GridViewIdIsEmpty)?
            .0;
        let field_id = NotEmptyStr::parse(self.field_id)
            .map_err(|_| ErrorCode::FieldIdIsEmpty)?
            .0;

        let sort_id = NotEmptyStr::parse(self.sort_id)
            .map_err(|_| ErrorCode::UnexpectedEmptyString)?
            .0;

        let sort_type = SortType {
            field_id,
            field_type: self.field_type,
        };

        Ok(DeleteSortParams {
            view_id,
            sort_type,
            sort_id,
        })
    }
}

#[derive(Debug)]
pub struct DeleteSortParams {
    pub view_id: String,
    pub sort_type: SortType,
    pub sort_id: String,
}

#[derive(Debug, Default, ProtoBuf)]
pub struct SortChangesetNotificationPB {
    #[pb(index = 1)]
    pub view_id: String,

    #[pb(index = 2)]
    pub insert_sorts: Vec<GridSortPB>,

    #[pb(index = 3)]
    pub delete_sorts: Vec<GridSortPB>,

    #[pb(index = 4)]
    pub update_sorts: Vec<GridSortPB>,
}
