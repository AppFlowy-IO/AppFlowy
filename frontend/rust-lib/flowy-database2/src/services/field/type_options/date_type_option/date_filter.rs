use crate::entities::{DateFilterConditionPB, DateFilterPB};

use chrono::{NaiveDate, NaiveDateTime};

use super::DateCellData;

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
  NaiveDateTime::from_timestamp_opt(timestamp, 0).map(|date_time: NaiveDateTime| date_time.date())
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

#[cfg(test)]
mod tests {
  use crate::entities::{DateFilterConditionPB, DateFilterPB};
  use crate::services::field::DateCellData;

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
