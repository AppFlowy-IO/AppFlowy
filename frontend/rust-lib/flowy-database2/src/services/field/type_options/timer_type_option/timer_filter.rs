use collab_database::fields::Field;
use collab_database::rows::Cell;

use crate::entities::{NumberFilterConditionPB, TimerFilterPB};
use crate::services::cell::insert_text_cell;
use crate::services::filter::PreFillCellsWithFilter;

impl TimerFilterPB {
  pub fn is_visible(&self, cell_minutes: Option<i64>) -> bool {
    if self.content.is_empty() {
      match self.condition {
        NumberFilterConditionPB::NumberIsEmpty => {
          return cell_minutes.is_none();
        },
        NumberFilterConditionPB::NumberIsNotEmpty => {
          return cell_minutes.is_some();
        },
        _ => {},
      }
    }

    if cell_minutes.is_none() {
      return false;
    }

    let minutes = cell_minutes.unwrap();
    let content_minutes = i64::from_str_radix(&self.content, 10).unwrap_or_default();
    match self.condition {
      NumberFilterConditionPB::Equal => minutes == content_minutes,
      NumberFilterConditionPB::NotEqual => minutes != content_minutes,
      NumberFilterConditionPB::GreaterThan => minutes > content_minutes,
      NumberFilterConditionPB::LessThan => minutes < content_minutes,
      NumberFilterConditionPB::GreaterThanOrEqualTo => minutes >= content_minutes,
      NumberFilterConditionPB::LessThanOrEqualTo => minutes <= content_minutes,
      _ => true,
    }
  }
}

impl PreFillCellsWithFilter for TimerFilterPB {
  fn get_compliant_cell(&self, field: &Field) -> (Option<Cell>, bool) {
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

    let open_after_create = matches!(self.condition, NumberFilterConditionPB::NumberIsNotEmpty);

    // use `insert_text_cell` because self.content might not be a parsable i64.
    (text.map(|s| insert_text_cell(s, field)), open_after_create)
  }
}
