use collab_database::fields::Field;
use collab_database::rows::Cell;

use crate::entities::{NumberFilterConditionPB, TimeFilterPB};
use crate::services::cell::insert_text_cell;
use crate::services::filter::PreFillCellsWithFilter;

impl TimeFilterPB {
  pub fn is_visible(&self, cell_time: Option<i64>) -> bool {
    if self.content.is_empty() {
      match self.condition {
        NumberFilterConditionPB::NumberIsEmpty => {
          return cell_time.is_none();
        },
        NumberFilterConditionPB::NumberIsNotEmpty => {
          return cell_time.is_some();
        },
        _ => {},
      }
    }

    if cell_time.is_none() {
      return false;
    }

    let time = cell_time.unwrap();
    let content_time = self.content.parse::<i64>().unwrap_or_default();
    match self.condition {
      NumberFilterConditionPB::Equal => time == content_time,
      NumberFilterConditionPB::NotEqual => time != content_time,
      NumberFilterConditionPB::GreaterThan => time > content_time,
      NumberFilterConditionPB::LessThan => time < content_time,
      NumberFilterConditionPB::GreaterThanOrEqualTo => time >= content_time,
      NumberFilterConditionPB::LessThanOrEqualTo => time <= content_time,
      _ => true,
    }
  }
}

impl PreFillCellsWithFilter for TimeFilterPB {
  fn get_compliant_cell(&self, field: &Field) -> Option<Cell> {
    let expected_decimal = || self.content.parse::<i64>().ok();

    let text = match self.condition {
      NumberFilterConditionPB::Equal
      | NumberFilterConditionPB::GreaterThanOrEqualTo
      | NumberFilterConditionPB::LessThanOrEqualTo
        if !self.content.is_empty() =>
      {
        Some(self.content.clone())
      },
      NumberFilterConditionPB::GreaterThan if !self.content.is_empty() => {
        expected_decimal().map(|value| {
          let answer = value + 1;
          answer.to_string()
        })
      },
      NumberFilterConditionPB::LessThan if !self.content.is_empty() => {
        expected_decimal().map(|value| {
          let answer = value - 1;
          answer.to_string()
        })
      },
      _ => None,
    };

    // use `insert_text_cell` because self.content might not be a parsable i64.
    text.map(|s| insert_text_cell(s, field))
  }
}
