use std::cmp::Ordering;

use anyhow::bail;
use collab::preclude::Any;
use collab::util::AnyMapExt;
use collab_database::rows::RowId;
use collab_database::views::{SortMap, SortMapBuilder};

#[derive(Debug, Clone)]
pub struct Sort {
  pub id: String,
  pub field_id: String,
  pub condition: SortCondition,
}

const SORT_ID: &str = "id";
const FIELD_ID: &str = "field_id";
const SORT_CONDITION: &str = "condition";

impl TryFrom<SortMap> for Sort {
  type Error = anyhow::Error;

  fn try_from(value: SortMap) -> Result<Self, Self::Error> {
    match (
      value.get_as::<String>(SORT_ID),
      value.get_as::<String>(FIELD_ID),
    ) {
      (Some(id), Some(field_id)) => {
        let condition = value
          .get_as::<i64>(SORT_CONDITION)
          .map(SortCondition::from)
          .unwrap_or_default();
        Ok(Self {
          id,
          field_id,
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
    SortMapBuilder::from([
      (SORT_ID.into(), data.id.into()),
      (FIELD_ID.into(), data.field_id.into()),
      (SORT_CONDITION.into(), Any::BigInt(data.condition.value())),
    ])
  }
}

#[derive(Copy, Clone, Debug, Default)]
#[repr(u8)]
pub enum SortCondition {
  #[default]
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

impl From<i64> for SortCondition {
  fn from(value: i64) -> Self {
    match value {
      0 => SortCondition::Ascending,
      1 => SortCondition::Descending,
      _ => SortCondition::Ascending,
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

#[derive(Debug, Default)]
pub struct SortChangeset {
  pub(crate) insert_sort: Option<Sort>,
  pub(crate) update_sort: Option<Sort>,
  pub(crate) delete_sort: Option<String>,
  pub(crate) reorder_sort: Option<(String, String)>,
}

impl SortChangeset {
  pub fn from_insert(sort: Sort) -> Self {
    Self {
      insert_sort: Some(sort),
      ..Default::default()
    }
  }

  pub fn from_update(sort: Sort) -> Self {
    Self {
      update_sort: Some(sort),
      ..Default::default()
    }
  }

  pub fn from_delete(sort_id: String) -> Self {
    Self {
      delete_sort: Some(sort_id),
      ..Default::default()
    }
  }

  pub fn from_reorder(from_sort_id: String, to_sort_id: String) -> Self {
    Self {
      reorder_sort: Some((from_sort_id, to_sort_id)),
      ..Default::default()
    }
  }
}
