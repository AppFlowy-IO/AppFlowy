use crate::entities::{NumberFilterConditionPB, TimerFilterPB};

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
