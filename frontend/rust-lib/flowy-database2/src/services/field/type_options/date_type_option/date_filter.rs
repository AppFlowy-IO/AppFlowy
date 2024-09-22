use crate::entities::{DateFilterConditionPB, DateFilterPB};
use crate::services::cell::insert_date_cell;
use crate::services::filter::PreFillCellsWithFilter;

use chrono::{Duration, NaiveDate};
use collab_database::fields::date_type_option::DateCellData;
use collab_database::fields::Field;
use collab_database::rows::Cell;

impl DateFilterPB {
  /// Returns `None` if the DateFilterPB doesn't have the necessary data for
  /// the condition. For example, `start` and `end` timestamps for
  /// `DateFilterConditionPB::DateWithin`.
  pub fn is_visible(&self, cell_data: &DateCellData) -> Option<bool> {
    let strategy = match self.condition {
      DateFilterConditionPB::DateIs => DateFilterStrategy::On(self.timestamp?),
      DateFilterConditionPB::DateBefore => DateFilterStrategy::Before(self.timestamp?),
      DateFilterConditionPB::DateAfter => DateFilterStrategy::After(self.timestamp?),
      DateFilterConditionPB::DateOnOrBefore => DateFilterStrategy::OnOrBefore(self.timestamp?),
      DateFilterConditionPB::DateOnOrAfter => DateFilterStrategy::OnOrAfter(self.timestamp?),
      DateFilterConditionPB::DateWithIn => DateFilterStrategy::DateWithin {
        start: self.start?,
        end: self.end?,
      },
      DateFilterConditionPB::DateIsEmpty => DateFilterStrategy::Empty,
      DateFilterConditionPB::DateIsNotEmpty => DateFilterStrategy::NotEmpty,
    };

    Some(strategy.filter(cell_data))
  }
}

#[inline]
fn naive_date_from_timestamp(timestamp: i64) -> Option<NaiveDate> {
  chrono::DateTime::from_timestamp(timestamp, 0).map(|date| date.naive_utc().date())
}

enum DateFilterStrategy {
  On(i64),
  Before(i64),
  After(i64),
  OnOrBefore(i64),
  OnOrAfter(i64),
  DateWithin { start: i64, end: i64 },
  Empty,
  NotEmpty,
}

impl DateFilterStrategy {
  fn filter(self, cell_data: &DateCellData) -> bool {
    match self {
      DateFilterStrategy::On(expected_timestamp) => cell_data.timestamp.is_some_and(|timestamp| {
        let cell_date = naive_date_from_timestamp(timestamp);
        let expected_date = naive_date_from_timestamp(expected_timestamp);
        cell_date == expected_date
      }),
      DateFilterStrategy::Before(expected_timestamp) => {
        cell_data.timestamp.is_some_and(|timestamp| {
          let cell_date = naive_date_from_timestamp(timestamp);
          let expected_date = naive_date_from_timestamp(expected_timestamp);
          cell_date < expected_date
        })
      },
      DateFilterStrategy::After(expected_timestamp) => {
        cell_data.timestamp.is_some_and(|timestamp| {
          let cell_date = naive_date_from_timestamp(timestamp);
          let expected_date = naive_date_from_timestamp(expected_timestamp);
          cell_date > expected_date
        })
      },
      DateFilterStrategy::OnOrBefore(expected_timestamp) => {
        cell_data.timestamp.is_some_and(|timestamp| {
          let cell_date = naive_date_from_timestamp(timestamp);
          let expected_date = naive_date_from_timestamp(expected_timestamp);
          cell_date <= expected_date
        })
      },
      DateFilterStrategy::OnOrAfter(expected_timestamp) => {
        cell_data.timestamp.is_some_and(|timestamp| {
          let cell_date = naive_date_from_timestamp(timestamp);
          let expected_date = naive_date_from_timestamp(expected_timestamp);
          cell_date >= expected_date
        })
      },
      DateFilterStrategy::DateWithin { start, end } => {
        cell_data.timestamp.is_some_and(|timestamp| {
          let cell_date = naive_date_from_timestamp(timestamp);
          let expected_start_date = naive_date_from_timestamp(start);
          let expected_end_date = naive_date_from_timestamp(end);
          cell_date >= expected_start_date && cell_date <= expected_end_date
        })
      },
      DateFilterStrategy::Empty => {
        cell_data.timestamp.is_none() && cell_data.end_timestamp.is_none()
      },
      DateFilterStrategy::NotEmpty => cell_data.timestamp.is_some(),
    }
  }
}

impl PreFillCellsWithFilter for DateFilterPB {
  fn get_compliant_cell(&self, field: &Field) -> (Option<Cell>, bool) {
    let timestamp = match self.condition {
      DateFilterConditionPB::DateIs
      | DateFilterConditionPB::DateOnOrBefore
      | DateFilterConditionPB::DateOnOrAfter => self.timestamp,
      DateFilterConditionPB::DateBefore => self
        .timestamp
        .and_then(|timestamp| {
          chrono::DateTime::from_timestamp(timestamp, 0).map(|date| date.naive_utc())
        })
        .map(|date_time| {
          let answer = date_time - Duration::days(1);
          answer.and_utc().timestamp()
        }),
      DateFilterConditionPB::DateAfter => self
        .timestamp
        .and_then(|timestamp| {
          chrono::DateTime::from_timestamp(timestamp, 0).map(|date| date.naive_utc())
        })
        .map(|date_time| {
          let answer = date_time + Duration::days(1);
          answer.and_utc().timestamp()
        }),
      DateFilterConditionPB::DateWithIn => self.start,
      _ => None,
    };

    let open_after_create = matches!(self.condition, DateFilterConditionPB::DateIsNotEmpty);

    (
      timestamp.map(|timestamp| insert_date_cell(timestamp, None, None, field)),
      open_after_create,
    )
  }
}

#[cfg(test)]
mod tests {
  use crate::entities::{DateFilterConditionPB, DateFilterPB};
  use collab_database::fields::date_type_option::DateCellData;

  fn to_cell_data(timestamp: i32) -> DateCellData {
    DateCellData::new(timestamp as i64, false, false, "".to_string())
  }

  #[test]
  fn date_filter_is_test() {
    let filter = DateFilterPB {
      condition: DateFilterConditionPB::DateIs,
      timestamp: Some(1668387885),
      end: None,
      start: None,
    };

    for (val, visible) in [(1668387885, true), (1647251762, false)] {
      assert_eq!(filter.is_visible(&to_cell_data(val)).unwrap(), visible);
    }
  }

  #[test]
  fn date_filter_before_test() {
    let filter = DateFilterPB {
      condition: DateFilterConditionPB::DateBefore,
      timestamp: Some(1668387885),
      start: None,
      end: None,
    };

    for (val, visible, msg) in [(1668387884, false, "1"), (1647251762, true, "2")] {
      assert_eq!(
        filter.is_visible(&to_cell_data(val)).unwrap(),
        visible,
        "{}",
        msg
      );
    }
  }

  #[test]
  fn date_filter_before_or_on_test() {
    let filter = DateFilterPB {
      condition: DateFilterConditionPB::DateOnOrBefore,
      timestamp: Some(1668387885),
      start: None,
      end: None,
    };

    for (val, visible) in [(1668387884, true), (1668387885, true)] {
      assert_eq!(filter.is_visible(&to_cell_data(val)).unwrap(), visible);
    }
  }
  #[test]
  fn date_filter_after_test() {
    let filter = DateFilterPB {
      condition: DateFilterConditionPB::DateAfter,
      timestamp: Some(1668387885),
      start: None,
      end: None,
    };

    for (val, visible) in [(1668387888, false), (1668531885, true), (0, false)] {
      assert_eq!(filter.is_visible(&to_cell_data(val)).unwrap(), visible);
    }
  }

  #[test]
  fn date_filter_within_test() {
    let filter = DateFilterPB {
      condition: DateFilterConditionPB::DateWithIn,
      start: Some(1668272685), // 11/13
      end: Some(1668618285),   // 11/17
      timestamp: None,
    };

    for (val, visible, _msg) in [
      (1668272685, true, "11/13"),
      (1668359085, true, "11/14"),
      (1668704685, false, "11/18"),
    ] {
      assert_eq!(filter.is_visible(&to_cell_data(val)).unwrap(), visible);
    }
  }

  #[test]
  fn date_filter_is_empty_test() {
    let filter = DateFilterPB {
      condition: DateFilterConditionPB::DateIsEmpty,
      start: None,
      end: None,
      timestamp: None,
    };

    for (val, visible) in [(None, true), (Some(123), false)] {
      assert_eq!(
        filter
          .is_visible(&DateCellData {
            timestamp: val,
            ..Default::default()
          })
          .unwrap(),
        visible
      );
    }
  }
}
