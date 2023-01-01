use crate::entities::{AlterSortParams, DeleteSortParams, FieldType};
use grid_rev_model::{FieldRevision, FieldTypeRevision};
use std::sync::Arc;

#[derive(Hash, Eq, PartialEq, Debug, Clone)]
pub struct SortType {
    pub field_id: String,
    pub field_type: FieldType,
}

impl From<SortType> for FieldTypeRevision {
    fn from(sort_type: SortType) -> Self {
        sort_type.field_type.into()
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

#[derive(Clone)]
pub struct ReorderAllRowsResult {
    pub view_id: String,
    pub row_orders: Vec<String>,
}

impl ReorderAllRowsResult {
    pub fn new(view_id: String, row_orders: Vec<String>) -> Self {
        Self { view_id, row_orders }
    }
}

#[derive(Clone)]
pub struct ReorderSingleRowResult {
    pub view_id: String,
    pub old_index: usize,
    pub new_index: usize,
}

#[derive(Debug)]
pub struct SortChangeset {
    pub(crate) insert_sort: Option<SortType>,
    pub(crate) update_sort: Option<SortType>,
    pub(crate) delete_sort: Option<DeletedSortType>,
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

    pub fn from_delete(deleted_sort: DeletedSortType) -> Self {
        Self {
            insert_sort: None,
            update_sort: None,
            delete_sort: Some(deleted_sort),
        }
    }
}

#[derive(Debug)]
pub struct DeletedSortType {
    pub sort_type: SortType,
    pub sort_id: String,
}

impl std::convert::From<DeleteSortParams> for DeletedSortType {
    fn from(params: DeleteSortParams) -> Self {
        Self {
            sort_type: params.sort_type,
            sort_id: params.sort_id,
        }
    }
}
