use std::cmp::Ordering;

use anyhow::bail;
use collab::core::any_map::AnyMapExtension;
use collab_database::rows::RowId;
use collab_database::views::{SortMap, SortMapBuilder};

use crate::entities::{DeleteSortParams, FieldType};

#[derive(Debug, Clone)]
pub struct Sort {
  pub id: String,
  pub field_id: String,
  pub field_type: FieldType,
  pub condition: SortCondition,
}

const SORT_ID: &str = "id";
const FIELD_ID: &str = "field_id";
const FIELD_TYPE: &str = "ty";
const SORT_CONDITION: &str = "condition";

impl TryFrom<SortMap> for Sort {
  type Error = anyhow::Error;

  fn try_from(value: SortMap) -> Result<Self, Self::Error> {
    match (
      value.get_str_value(SORT_ID),
      value.get_str_value(FIELD_ID),
      value.get_i64_value(FIELD_TYPE).map(FieldType::from),
    ) {
      (Some(id), Some(field_id), Some(field_type)) => {
        let condition =
          SortCondition::try_from(value.get_i64_value(SORT_CONDITION).unwrap_or_default())
            .unwrap_or_default();
        Ok(Self {
          id,
          field_id,
          field_type,
          condition,
        })
      },
      _ => {
        bail!("Invalid sort data")
      },
    }
  }
}

impl From<Sort> for SortMap {
  fn from(data: Sort) -> Self {
    SortMapBuilder::new()
      .insert_str_value(SORT_ID, data.id)
      .insert_str_value(FIELD_ID, data.field_id)
      .insert_i64_value(FIELD_TYPE, data.field_type.into())
      .insert_i64_value(SORT_CONDITION, data.condition.value())
      .build()
  }
}

#[derive(Copy, Clone, Debug)]
#[repr(u8)]
pub enum SortCondition {
  Ascending = 0,
  Descending = 1,
}

impl SortCondition {
  pub fn value(&self) -> i64 {
    *self as i64
  }

  /// Given an [Ordering] resulting from a comparison,
  /// reverse it if the sort condition is descending rather than
  /// the default ascending
  pub fn evaluate_order(&self, order: Ordering) -> Ordering {
    match self {
      SortCondition::Ascending => order,
      SortCondition::Descending => order.reverse(),
    }
  }
}

impl Default for SortCondition {
  fn default() -> Self {
    Self::Ascending
  }
}

impl From<i64> for SortCondition {
  fn from(value: i64) -> Self {
    match value {
      0 => SortCondition::Ascending,
      1 => SortCondition::Descending,
      _ => SortCondition::Ascending,
    }
  }
}

#[derive(Hash, Eq, PartialEq, Debug, Clone)]
pub struct SortType {
  pub sort_id: String,
  pub field_id: String,
  pub field_type: FieldType,
}

impl From<&Sort> for SortType {
  fn from(data: &Sort) -> Self {
    Self {
      sort_id: data.id.clone(),
      field_id: data.field_id.clone(),
      field_type: data.field_type,
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
    Self {
      view_id,
      row_orders,
    }
  }
}

#[derive(Clone)]
pub struct ReorderSingleRowResult {
  pub view_id: String,
  pub row_id: RowId,
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
