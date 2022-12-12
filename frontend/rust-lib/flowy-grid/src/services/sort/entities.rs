use crate::entities::{AlterSortParams, FieldType};
use grid_rev_model::{FieldRevision, FieldTypeRevision};
use std::sync::Arc;

#[derive(Hash, Eq, PartialEq, Debug, Clone)]
pub struct SortType {
    pub field_id: String,
    pub field_type: FieldType,
}

impl Into<FieldTypeRevision> for SortType {
    fn into(self) -> FieldTypeRevision {
        self.field_type.into()
    }
}

impl std::convert::From<&AlterSortParams> for SortType {
    fn from(params: &AlterSortParams) -> Self {
        Self {
            field_id: params.field_id.clone(),
            field_type: params.field_type.into(),
        }
    }
}

impl std::convert::From<&Arc<FieldRevision>> for SortType {
    fn from(rev: &Arc<FieldRevision>) -> Self {
        Self {
            field_id: rev.id.clone(),
            field_type: rev.ty.into(),
        }
    }
}

#[derive(Debug)]
pub struct SortChangeset {
    pub(crate) insert_sort: Option<SortType>,
    pub(crate) update_sort: Option<SortType>,
    pub(crate) delete_sort: Option<SortType>,
}

impl SortChangeset {
    pub fn from_insert(sort: SortType) -> Self {
        Self {
            insert_sort: Some(sort),
            update_sort: None,
            delete_sort: None,
        }
    }

    pub fn from_update(sort: SortType) -> Self {
        Self {
            insert_sort: None,
            update_sort: Some(sort),
            delete_sort: None,
        }
    }

    pub fn from_delete(sort: SortType) -> Self {
        Self {
            insert_sort: None,
            update_sort: None,
            delete_sort: Some(sort),
        }
    }
}
