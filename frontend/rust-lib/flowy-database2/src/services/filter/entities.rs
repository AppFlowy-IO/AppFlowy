use std::mem;

use anyhow::bail;
use collab::core::any_map::AnyMapExtension;
use collab_database::database::gen_database_filter_id;
use collab_database::rows::RowId;
use collab_database::views::{FilterMap, FilterMapBuilder};
use flowy_error::{FlowyError, FlowyResult};
use lib_infra::box_any::BoxAny;

use crate::entities::{
  CheckboxFilterPB, ChecklistFilterPB, DateFilterContentPB, DateFilterPB, FieldType, FilterType,
  InsertedRowPB, NumberFilterPB, RelationFilterPB, SelectOptionFilterPB, TextFilterPB,
};
use crate::services::field::SelectOptionIds;

pub trait ParseFilterData {
  fn parse(condition: u8, content: String) -> Self;
}

#[derive(Debug)]
pub struct Filter {
  pub id: String,
  pub inner: FilterInner,
}

impl Filter {
  /// Recursively determine whether there are any data filters in the filter tree.
  pub fn is_empty(&self) -> bool {
    match &self.inner {
      FilterInner::And { children } | FilterInner::Or { children } => children
        .iter()
        .map(|filter| filter.is_empty())
        .all(|is_empty| is_empty),
      FilterInner::Data { .. } => false,
    }
  }

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

  /// converts a filter from And/Or/Data to And/Or. If the current type of the filter is Data,
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

  pub fn find_all_filters_with_field_id(&mut self, matching_field_id: &str, ids: &mut Vec<String>) {
    match &mut self.inner {
      FilterInner::And { children } | FilterInner::Or { children } => {
        for child_filter in children.iter_mut() {
          child_filter.find_all_filters_with_field_id(matching_field_id, ids);
        }
      },
      FilterInner::Data {
        field_id,
        field_type: _,
        condition_and_content: _,
      } => {
        if field_id == matching_field_id {
          ids.push(self.id.clone());
        }
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
      FieldType::DateTime | FieldType::CreatedTime | FieldType::LastEditedTime => {
        BoxAny::new(DateFilterPB::parse(condition as u8, content))
      },
      FieldType::SingleSelect | FieldType::MultiSelect => {
        BoxAny::new(SelectOptionFilterPB::parse(condition as u8, content))
      },
      FieldType::Checklist => BoxAny::new(ChecklistFilterPB::parse(condition as u8, content)),
      FieldType::Checkbox => BoxAny::new(CheckboxFilterPB::parse(condition as u8, content)),
      FieldType::Relation => BoxAny::new(RelationFilterPB::parse(condition as u8, content)),
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
    let mut builder = FilterMapBuilder::new()
      .insert_str_value(FILTER_ID, &filter.id)
      .insert_i64_value(FILTER_TYPE, filter.inner.get_int_repr());

    builder = match &filter.inner {
      FilterInner::And { children } | FilterInner::Or { children } => {
        builder.insert_maps(FILTER_CHILDREN, children.iter().collect::<Vec<&Filter>>())
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
              let content = DateFilterContentPB {
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
          };
          Some((condition, content))
        };

        let (condition, content) = get_raw_condition_and_content().unwrap_or_else(|| {
          tracing::error!("cannot deserialize filter condition and content filter properly");
          Default::default()
        });

        builder
          .insert_str_value(FIELD_ID, field_id)
          .insert_i64_value(FIELD_TYPE, field_type.into())
          .insert_i64_value(FILTER_CONDITION, condition as i64)
          .insert_str_value(FILTER_CONTENT, content)
      },
    };

    builder.build()
  }
}

impl TryFrom<FilterMap> for Filter {
  type Error = anyhow::Error;

  fn try_from(filter_map: FilterMap) -> Result<Self, Self::Error> {
    let filter_id = filter_map
      .get_str_value(FILTER_ID)
      .ok_or_else(|| anyhow::anyhow!("invalid filter data"))?;
    let filter_type = filter_map
      .get_i64_value(FILTER_TYPE)
      .unwrap_or(FILTER_DATA_INDEX);

    let filter = Filter {
      id: filter_id,
      inner: match filter_type {
        FILTER_AND_INDEX => FilterInner::And {
          children: filter_map.try_get_array(FILTER_CHILDREN),
        },
        FILTER_OR_INDEX => FilterInner::Or {
          children: filter_map.try_get_array(FILTER_CHILDREN),
        },
        FILTER_DATA_INDEX => {
          let field_id = filter_map
            .get_str_value(FIELD_ID)
            .ok_or_else(|| anyhow::anyhow!("invalid filter data"))?;
          let field_type = filter_map
            .get_i64_value(FIELD_TYPE)
            .map(FieldType::from)
            .unwrap_or_default();
          let condition = filter_map.get_i64_value(FILTER_CONDITION).unwrap_or(0);
          let content = filter_map.get_str_value(FILTER_CONTENT).unwrap_or_default();

          FilterInner::new_data(field_id, field_type, condition, content)
        },
        _ => bail!("Unsupported filter type"),
      },
    };

    Ok(filter)
  }
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
    field_id: String,
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
