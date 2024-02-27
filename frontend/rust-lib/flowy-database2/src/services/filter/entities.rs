use anyhow::bail;
use collab::core::any_map::AnyMapExtension;
use collab_database::rows::RowId;
use collab_database::views::{FilterMap, FilterMapBuilder};

use crate::entities::{FieldType, FilterPB, InsertedRowPB};

#[derive(Debug, Clone)]
pub struct Filter {
  pub id: String,
  pub field_id: String,
  pub field_type: FieldType,
  pub condition: i64,
  pub content: String,
}

const FILTER_ID: &str = "id";
const FIELD_ID: &str = "field_id";
const FIELD_TYPE: &str = "ty";
const FILTER_CONDITION: &str = "condition";
const FILTER_CONTENT: &str = "content";

impl From<Filter> for FilterMap {
  fn from(data: Filter) -> Self {
    FilterMapBuilder::new()
      .insert_str_value(FILTER_ID, data.id)
      .insert_str_value(FIELD_ID, data.field_id)
      .insert_str_value(FILTER_CONTENT, data.content)
      .insert_i64_value(FIELD_TYPE, data.field_type.into())
      .insert_i64_value(FILTER_CONDITION, data.condition)
      .build()
  }
}

impl TryFrom<FilterMap> for Filter {
  type Error = anyhow::Error;

  fn try_from(filter: FilterMap) -> Result<Self, Self::Error> {
    match (
      filter.get_str_value(FILTER_ID),
      filter.get_str_value(FIELD_ID),
    ) {
      (Some(id), Some(field_id)) => {
        let condition = filter.get_i64_value(FILTER_CONDITION).unwrap_or(0);
        let content = filter.get_str_value(FILTER_CONTENT).unwrap_or_default();
        let field_type = filter
          .get_i64_value(FIELD_TYPE)
          .map(FieldType::from)
          .unwrap_or_default();
        Ok(Filter {
          id,
          field_id,
          field_type,
          condition,
          content,
        })
      },
      _ => {
        bail!("Invalid filter data")
      },
    }
  }
}
#[derive(Debug)]
pub struct FilterChangeset {
  pub(crate) insert_filter: Option<Filter>,
  pub(crate) update_filter: Option<UpdatedFilter>,
  pub(crate) delete_filter: Option<FilterContext>,
}

#[derive(Debug)]
pub struct UpdatedFilter {
  pub old: Option<Filter>,
  pub new: Filter,
}

impl UpdatedFilter {
  pub fn new(old: Option<Filter>, new: Filter) -> UpdatedFilter {
    Self { old, new }
  }
}

impl FilterChangeset {
  pub fn from_insert(filter: Filter) -> Self {
    Self {
      insert_filter: Some(filter),
      update_filter: None,
      delete_filter: None,
    }
  }

  pub fn from_update(filter: UpdatedFilter) -> Self {
    Self {
      insert_filter: None,
      update_filter: Some(filter),
      delete_filter: None,
    }
  }
  pub fn from_delete(filter_context: FilterContext) -> Self {
    Self {
      insert_filter: None,
      update_filter: None,
      delete_filter: Some(filter_context),
    }
  }
}

#[derive(Debug, Clone)]
pub struct FilterContext {
  pub filter_id: String,
  pub field_id: String,
  pub field_type: FieldType,
}

impl From<&FilterPB> for FilterContext {
  fn from(filter: &FilterPB) -> Self {
    Self {
      filter_id: filter.id.clone(),
      field_id: filter.field_id.clone(),
      field_type: filter.field_type,
    }
  }
}

#[derive(Clone, Debug)]
pub struct FilterResultNotification {
  pub view_id: String,

  // Indicates there will be some new rows being visible from invisible state.
  pub visible_rows: Vec<InsertedRowPB>,

  // Indicates there will be some new rows being invisible from visible state.
  pub invisible_rows: Vec<RowId>,
}

impl FilterResultNotification {
  pub fn new(view_id: String) -> Self {
    Self {
      view_id,
      visible_rows: vec![],
      invisible_rows: vec![],
    }
  }
}
