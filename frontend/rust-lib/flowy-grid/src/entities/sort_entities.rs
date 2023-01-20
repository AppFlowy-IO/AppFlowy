use crate::entities::parser::NotEmptyStr;
use crate::entities::FieldType;
use crate::services::sort::SortType;
use std::sync::Arc;

use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_error::ErrorCode;
use grid_rev_model::{FieldTypeRevision, SortCondition, SortRevision};

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct SortPB {
    #[pb(index = 1)]
    pub id: String,

    #[pb(index = 2)]
    pub field_id: String,

    #[pb(index = 3)]
    pub field_type: FieldType,

    #[pb(index = 4)]
    pub condition: GridSortConditionPB,
}

impl std::convert::From<&SortRevision> for SortPB {
    fn from(sort_rev: &SortRevision) -> Self {
        Self {
            id: sort_rev.id.clone(),
            field_id: sort_rev.field_id.clone(),
            field_type: sort_rev.field_type.into(),
            condition: sort_rev.condition.clone().into(),
        }
    }
}

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct RepeatedSortPB {
    #[pb(index = 1)]
    pub items: Vec<SortPB>,
}

impl std::convert::From<Vec<Arc<SortRevision>>> for RepeatedSortPB {
    fn from(revs: Vec<Arc<SortRevision>>) -> Self {
        RepeatedSortPB {
            items: revs.into_iter().map(|rev| rev.as_ref().into()).collect(),
        }
    }
}

impl std::convert::From<Vec<SortPB>> for RepeatedSortPB {
    fn from(items: Vec<SortPB>) -> Self {
        Self { items }
    }
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

impl std::convert::From<SortCondition> for GridSortConditionPB {
    fn from(condition: SortCondition) -> Self {
        match condition {
            SortCondition::Ascending => GridSortConditionPB::Ascending,
            SortCondition::Descending => GridSortConditionPB::Descending,
        }
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

    /// Create a new sort if the sort_id is None
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
            Some(sort_id) => Some(NotEmptyStr::parse(sort_id).map_err(|_| ErrorCode::SortIdIsEmpty)?.0),
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

#[derive(Debug, Clone)]
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
    pub insert_sorts: Vec<SortPB>,

    #[pb(index = 3)]
    pub delete_sorts: Vec<SortPB>,

    #[pb(index = 4)]
    pub update_sorts: Vec<SortPB>,
}

impl SortChangesetNotificationPB {
    pub fn new(view_id: String) -> Self {
        Self {
            view_id,
            insert_sorts: vec![],
            delete_sorts: vec![],
            update_sorts: vec![],
        }
    }

    pub fn extend(&mut self, other: SortChangesetNotificationPB) {
        self.insert_sorts.extend(other.insert_sorts);
        self.delete_sorts.extend(other.delete_sorts);
        self.update_sorts.extend(other.update_sorts);
    }

    pub fn is_empty(&self) -> bool {
        self.insert_sorts.is_empty() && self.delete_sorts.is_empty() && self.update_sorts.is_empty()
    }
}

#[derive(Debug, Default, ProtoBuf)]
pub struct ReorderAllRowsPB {
    #[pb(index = 1)]
    pub row_orders: Vec<String>,
}

#[derive(Debug, Default, ProtoBuf)]
pub struct ReorderSingleRowPB {
    #[pb(index = 1)]
    pub row_id: String,

    #[pb(index = 2)]
    pub old_index: i32,

    #[pb(index = 3)]
    pub new_index: i32,
}
