use std::collections::HashMap;
use std::mem;
use std::ops::Deref;

use anyhow::bail;
use collab::preclude::Any;
use collab::util::AnyMapExt;
use collab_database::database::gen_database_filter_id;
use collab_database::fields::select_type_option::SelectOptionIds;
use collab_database::rows::RowId;
use collab_database::views::{FilterMap, FilterMapBuilder};
use flowy_error::{FlowyError, FlowyResult};
use lib_infra::box_any::BoxAny;
use tracing::error;

use crate::entities::{
  CheckboxFilterPB, ChecklistFilterPB, DateFilterContent, DateFilterPB, FieldType, FilterType,
  InsertedRowPB, MediaFilterPB, NumberFilterPB, RelationFilterPB, SelectOptionFilterPB,
  TextFilterPB, TimeFilterPB,
};

pub trait ParseFilterData {
  fn parse(condition: u8, content: String) -> Self;
}

#[derive(Debug)]
pub struct Filter {
  pub id: String,
  pub inner: FilterInner,
}

impl Filter {
  /// Recursively determine whether there are any data filters in the filter tree. A tree that has
  /// multiple AND/OR filters but no Data filters is considered "empty".
  pub fn is_empty(&self) -> bool {
    match &self.inner {
      FilterInner::And { children } | FilterInner::Or { children } => children
        .iter()
        .map(|filter| filter.is_empty())
        .all(|is_empty| is_empty),
      FilterInner::Data { .. } => false,
    }
  }

  /// Recursively find a filter based on `filter_id`. Returns `None` if the filter cannot be found.
  pub fn find_filter(&mut self, filter_id: &str) -> Option<&mut Self> {
    if self.id == filter_id {
      return Some(self);
    }
    match &mut self.inner {
      FilterInner::And { children } | FilterInner::Or { children } => {
        for child_filter in children.iter_mut() {
          let result = child_filter.find_filter(filter_id);
          if result.is_some() {
            return result;
          }
        }
        None
      },
      FilterInner::Data { .. } => None,
    }
  }

  /// Recursively find the parent of a filter whose id is `filter_id`. Returns `None` if the filter
  /// cannot be found.
  pub fn find_parent_of_filter(&mut self, filter_id: &str) -> Option<&mut Self> {
    if self.id == filter_id {
      return None;
    }
    match &mut self.inner {
      FilterInner::And { children } | FilterInner::Or { children } => {
        for child_filter in children.iter_mut() {
          if child_filter.id == filter_id {
            return Some(child_filter);
          }
          let result = child_filter.find_parent_of_filter(filter_id);
          if result.is_some() {
            return result;
          }
        }
        None
      },
      FilterInner::Data { .. } => None,
    }
  }

  /// Converts a filter from And/Or/Data to And/Or. If the current type of the filter is Data,
  /// return the FilterInner after the conversion.
  pub fn convert_to_and_or_filter_type(
    &mut self,
    filter_type: FilterType,
  ) -> FlowyResult<Option<FilterInner>> {
    match (&mut self.inner, filter_type) {
      (FilterInner::And { children }, FilterType::Or) => {
        self.inner = FilterInner::Or {
          children: mem::take(children),
        };
        Ok(None)
      },
      (FilterInner::Or { children }, FilterType::And) => {
        self.inner = FilterInner::And {
          children: mem::take(children),
        };
        Ok(None)
      },
      (FilterInner::Data { .. }, FilterType::And) => {
        let mut inner = FilterInner::And { children: vec![] };
        mem::swap(&mut self.inner, &mut inner);
        Ok(Some(inner))
      },
      (FilterInner::Data { .. }, FilterType::Or) => {
        let mut inner = FilterInner::Or { children: vec![] };
        mem::swap(&mut self.inner, &mut inner);
        Ok(Some(inner))
      },
      (_, FilterType::Data) => {
        // from And/Or to Data
        Err(FlowyError::internal().with_context(format!(
          "conversion from {:?} to FilterType::Data not supported",
          FilterType::from(&self.inner)
        )))
      },
      _ => {
        tracing::warn!("conversion to the same filter type");
        Ok(None)
      },
    }
  }

  /// Insert a filter into the current filter in the filter tree. If the current filter
  /// is an AND/OR filter, then the filter is appended to its children. Otherwise, the current
  /// filter is converted to an AND filter, after which the current data filter and the new filter
  /// are added to the AND filter's children.
  pub fn insert_filter(&mut self, filter: Filter) -> FlowyResult<()> {
    match &mut self.inner {
      FilterInner::And { children } | FilterInner::Or { children } => {
        children.push(filter);
      },
      FilterInner::Data { .. } => {
        // convert to FilterInner::And by default
        let old_filter = self
          .convert_to_and_or_filter_type(FilterType::And)
          .and_then(|result| {
            result.ok_or_else(|| FlowyError::internal().with_context("failed to convert filter"))
          })?;
        self.insert_filter(Filter {
          id: gen_database_filter_id(),
          inner: old_filter,
        })?;
        self.insert_filter(filter)?;
      },
    }

    Ok(())
  }

  /// Update the criteria of a data filter. Return an error if the current filter is an AND/OR
  /// filter.
  pub fn update_filter_data(&mut self, filter_data: FilterInner) -> FlowyResult<()> {
    match &self.inner {
      FilterInner::And { .. } | FilterInner::Or { .. } => Err(FlowyError::internal().with_context(
        format!("unexpected filter type {:?}", FilterType::from(&self.inner)),
      )),
      _ => {
        self.inner = filter_data;
        Ok(())
      },
    }
  }

  /// Delete a filter based on `filter_id`. The current filter must be the parent of the filter
  /// whose id is `filter_id`. Returns an error if the current filter is a Data filter (which
  /// cannot have children), or the filter to be deleted cannot be found.
  pub fn delete_filter(&mut self, filter_id: &str) -> FlowyResult<()> {
    match &mut self.inner {
      FilterInner::And { children } | FilterInner::Or { children } => children
        .iter()
        .position(|filter| filter.id == filter_id)
        .map(|position| {
          children.remove(position);
        })
        .ok_or_else(|| {
          FlowyError::internal()
            .with_context(format!("filter with filter_id {:?} not found", filter_id))
        }),
      FilterInner::Data { .. } => Err(
        FlowyError::internal().with_context("unexpected parent filter type of FilterInner::Data"),
      ),
    }
  }

  /// Recursively finds any Data filter whose `field_id` is equal to `matching_field_id`. Any found
  /// filters' id is appended to the `ids` vector.
  pub fn find_all_filters_with_field_id(&self, matching_field_id: &str, ids: &mut Vec<String>) {
    match &self.inner {
      FilterInner::And { children } | FilterInner::Or { children } => {
        for child_filter in children.iter() {
          child_filter.find_all_filters_with_field_id(matching_field_id, ids);
        }
      },
      FilterInner::Data { field_id, .. } => {
        if field_id == matching_field_id {
          ids.push(self.id.clone());
        }
      },
    }
  }

  /// Recursively determine the smallest set of filters that loosely represents the filter tree. The
  /// filters are appended to the `min_effective_filters` vector. The following rules are followed
  /// when determining if a filter should get included. If the current filter is:
  ///
  /// 1. a Data filter, then it should be included.
  /// 2. an AND filter, then all of its effective children should be
  /// included.
  /// 3. an OR filter, then only the first child should be included.
  pub fn get_min_effective_filters<'a>(&'a self, min_effective_filters: &mut Vec<&'a FilterInner>) {
    match &self.inner {
      FilterInner::And { children } => {
        for filter in children.iter() {
          filter.get_min_effective_filters(min_effective_filters);
        }
      },
      FilterInner::Or { children } => {
        if let Some(filter) = children.first() {
          filter.get_min_effective_filters(min_effective_filters);
        }
      },
      FilterInner::Data { .. } => min_effective_filters.push(&self.inner),
    }
  }

  /// Recursively get all of the filtering field ids and the associated filter_ids
  pub fn get_all_filtering_field_ids(&self, field_ids: &mut HashMap<String, Vec<String>>) {
    match &self.inner {
      FilterInner::And { children } | FilterInner::Or { children } => {
        for child in children.iter() {
          child.get_all_filtering_field_ids(field_ids);
        }
      },
      FilterInner::Data { field_id, .. } => {
        field_ids
          .entry(field_id.clone())
          .and_modify(|filter_ids| filter_ids.push(self.id.clone()))
          .or_insert_with(|| vec![self.id.clone()]);
      },
    }
  }
}

#[derive(Debug)]
pub enum FilterInner {
  And {
    children: Vec<Filter>,
  },
  Or {
    children: Vec<Filter>,
  },
  Data {
    field_id: String,
    field_type: FieldType,
    condition_and_content: BoxAny,
  },
}

impl FilterInner {
  pub fn new_data(
    field_id: String,
    field_type: FieldType,
    condition: i64,
    content: String,
  ) -> Self {
    let condition_and_content = match field_type {
      FieldType::RichText | FieldType::URL => {
        BoxAny::new(TextFilterPB::parse(condition as u8, content))
      },
      FieldType::Number => BoxAny::new(NumberFilterPB::parse(condition as u8, content)),
      FieldType::DateTime => BoxAny::new(DateFilterPB::parse(condition as u8, content)),
      FieldType::CreatedTime | FieldType::LastEditedTime => {
        let filter = DateFilterPB::parse(condition as u8, content).remove_end_date_conditions();
        BoxAny::new(filter)
      },
      FieldType::SingleSelect => {
        let filter =
          SelectOptionFilterPB::parse(condition as u8, content).to_single_select_filter();
        BoxAny::new(filter)
      },
      FieldType::MultiSelect => {
        let filter = SelectOptionFilterPB::parse(condition as u8, content).to_multi_select_filter();
        BoxAny::new(filter)
      },
      FieldType::Checklist => BoxAny::new(ChecklistFilterPB::parse(condition as u8, content)),
      FieldType::Checkbox => BoxAny::new(CheckboxFilterPB::parse(condition as u8, content)),
      FieldType::Relation => BoxAny::new(RelationFilterPB::parse(condition as u8, content)),
      FieldType::Summary => BoxAny::new(TextFilterPB::parse(condition as u8, content)),
      FieldType::Translate => BoxAny::new(TextFilterPB::parse(condition as u8, content)),
      FieldType::Time => BoxAny::new(TimeFilterPB::parse(condition as u8, content)),
      FieldType::Media => BoxAny::new(MediaFilterPB::parse(condition as u8, content)),
    };

    FilterInner::Data {
      field_id,
      field_type,
      condition_and_content,
    }
  }

  pub fn get_int_repr(&self) -> i64 {
    match self {
      FilterInner::And { .. } => FILTER_AND_INDEX,
      FilterInner::Or { .. } => FILTER_OR_INDEX,
      FilterInner::Data { .. } => FILTER_DATA_INDEX,
    }
  }
}

const FILTER_ID: &str = "id";
const FILTER_TYPE: &str = "filter_type";
const FIELD_ID: &str = "field_id";
const FIELD_TYPE: &str = "ty";
const FILTER_CONDITION: &str = "condition";
const FILTER_CONTENT: &str = "content";
const FILTER_CHILDREN: &str = "children";

const FILTER_AND_INDEX: i64 = 0;
const FILTER_OR_INDEX: i64 = 1;
const FILTER_DATA_INDEX: i64 = 2;

impl<'a> From<&'a Filter> for FilterMap {
  fn from(filter: &'a Filter) -> Self {
    let mut builder = FilterMapBuilder::from([
      (FILTER_ID.into(), filter.id.as_str().into()),
      (FILTER_TYPE.into(), Any::BigInt(filter.inner.get_int_repr())),
    ]);

    builder = match &filter.inner {
      FilterInner::And { children } | FilterInner::Or { children } => {
        let mut vec = Vec::with_capacity(children.len());
        for child in children.iter() {
          let any: Any = FilterMap::from(child).into();
          vec.push(any);
        }
        builder.insert(FILTER_CHILDREN.into(), Any::from(vec));
        builder
      },
      FilterInner::Data {
        field_id,
        field_type,
        condition_and_content,
      } => {
        let get_raw_condition_and_content = || -> Option<(u8, String)> {
          let (condition, content) = match field_type {
            FieldType::RichText | FieldType::URL => {
              let filter = condition_and_content.cloned::<TextFilterPB>()?;
              (filter.condition as u8, filter.content)
            },
            FieldType::Number => {
              let filter = condition_and_content.cloned::<NumberFilterPB>()?;
              (filter.condition as u8, filter.content)
            },
            FieldType::DateTime | FieldType::LastEditedTime | FieldType::CreatedTime => {
              let filter = condition_and_content.cloned::<DateFilterPB>()?;
              let content = DateFilterContent {
                start: filter.start,
                end: filter.end,
                timestamp: filter.timestamp,
              }
              .to_string();
              (filter.condition as u8, content)
            },
            FieldType::SingleSelect | FieldType::MultiSelect => {
              let filter = condition_and_content.cloned::<SelectOptionFilterPB>()?;
              let content = SelectOptionIds::from(filter.option_ids).to_string();
              (filter.condition as u8, content)
            },
            FieldType::Checkbox => {
              let filter = condition_and_content.cloned::<CheckboxFilterPB>()?;
              (filter.condition as u8, "".to_string())
            },
            FieldType::Checklist => {
              let filter = condition_and_content.cloned::<ChecklistFilterPB>()?;
              (filter.condition as u8, "".to_string())
            },
            FieldType::Relation => {
              let filter = condition_and_content.cloned::<RelationFilterPB>()?;
              (filter.condition as u8, "".to_string())
            },
            FieldType::Summary => {
              let filter = condition_and_content.cloned::<TextFilterPB>()?;
              (filter.condition as u8, filter.content)
            },
            FieldType::Time => {
              let filter = condition_and_content.cloned::<TimeFilterPB>()?;
              (filter.condition as u8, filter.content)
            },
            FieldType::Translate => {
              let filter = condition_and_content.cloned::<TextFilterPB>()?;
              (filter.condition as u8, filter.content)
            },
            FieldType::Media => {
              let filter = condition_and_content.cloned::<MediaFilterPB>()?;
              (filter.condition as u8, filter.content)
            },
          };
          Some((condition, content))
        };

        let (condition, content) = get_raw_condition_and_content().unwrap_or_else(|| {
          tracing::error!("cannot deserialize filter condition and content filter properly");
          Default::default()
        });

        builder.insert(FIELD_ID.into(), field_id.as_str().into());
        builder.insert(FIELD_TYPE.into(), Any::BigInt(i64::from(field_type)));
        builder.insert(FILTER_CONDITION.into(), Any::BigInt(condition as i64));
        builder.insert(FILTER_CONTENT.into(), content.into());
        builder
      },
    };

    builder
  }
}

impl TryFrom<FilterMap> for Filter {
  type Error = anyhow::Error;

  fn try_from(filter_map: FilterMap) -> Result<Self, Self::Error> {
    let filter_id: String = filter_map
      .get_as(FILTER_ID)
      .ok_or_else(|| anyhow::anyhow!("invalid filter data"))?;
    let filter_type: i64 = filter_map.get_as(FILTER_TYPE).unwrap_or(FILTER_DATA_INDEX);

    let filter = Filter {
      id: filter_id,
      inner: match filter_type {
        FILTER_AND_INDEX => FilterInner::And {
          children: get_children(filter_map),
        },
        FILTER_OR_INDEX => FilterInner::Or {
          children: get_children(filter_map),
        },
        FILTER_DATA_INDEX => {
          let field_id: String = filter_map
            .get_as(FIELD_ID)
            .ok_or_else(|| anyhow::anyhow!("invalid filter data"))?;
          let field_type = filter_map
            .get_as::<i64>(FIELD_TYPE)
            .map(FieldType::from)
            .unwrap_or_default();
          let condition: i64 = filter_map.get_as(FILTER_CONDITION).unwrap_or_default();
          let content: String = filter_map.get_as(FILTER_CONTENT).unwrap_or_default();

          FilterInner::new_data(field_id, field_type, condition, content)
        },
        _ => bail!("Unsupported filter type"),
      },
    };

    Ok(filter)
  }
}

fn get_children(filter_map: FilterMap) -> Vec<Filter> {
  //TODO: this method wouldn't be necessary if we could make Filters serializable in backward
  // compatible way
  let mut result = Vec::new();
  if let Some(Any::Array(children)) = filter_map.get(FILTER_CHILDREN) {
    for child in children.iter() {
      if let Any::Map(child_map) = child {
        match Filter::try_from(child_map.deref().clone()) {
          Ok(filter) => {
            result.push(filter);
          },
          Err(err) => {
            error!("Failed to deserialize filter: {:?}", err);
          },
        }
      }
    }
  }
  result
}

#[derive(Debug)]
pub enum FilterChangeset {
  Insert {
    parent_filter_id: Option<String>,
    data: FilterInner,
  },
  UpdateType {
    filter_id: String,
    filter_type: FilterType,
  },
  UpdateData {
    filter_id: String,
    data: FilterInner,
  },
  Delete {
    filter_id: String,
  },
  DeleteAllWithFieldId {
    field_id: String,
  },
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
