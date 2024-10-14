use crate::entities::{DateFilterConditionPB, DateFilterPB};
use crate::services::cell::insert_date_cell;
use crate::services::field::TimestampCellData;
use crate::services::filter::PreFillCellsWithFilter;

use chrono::{Duration, Local, NaiveDate, TimeZone};
use collab_database::fields::date_type_option::DateCellData;
use collab_database::fields::Field;
use collab_database::rows::Cell;

impl DateFilterPB {
  /// Returns `None` if the DateFilterPB doesn't have the necessary data for
  /// the condition. For example, `start` and `end` timestamps for
  /// `DateFilterConditionPB::DateStartsBetween`.
  pub fn is_visible(&self, cell_data: &DateCellData) -> Option<bool> {
    let strategy = self.get_strategy()?;

    let timestamp = if self.condition.is_filter_on_start_timestamp() {
      cell_data.timestamp
    } else {
      cell_data.end_timestamp.or(cell_data.timestamp)
    };

    Some(strategy.filter(timestamp))
  }

  pub fn is_timestamp_cell_data_visible(&self, cell_data: &TimestampCellData) -> Option<bool> {
    let strategy = self.get_strategy()?;

    Some(strategy.filter(cell_data.timestamp))
  }

  fn get_strategy(&self) -> Option<DateFilterStrategy> {
    let strategy = match self.condition {
      DateFilterConditionPB::DateStartsOn | DateFilterConditionPB::DateEndsOn => {
        DateFilterStrategy::On(self.timestamp?)
      },
      DateFilterConditionPB::DateStartsBefore | DateFilterConditionPB::DateEndsBefore => {
        DateFilterStrategy::Before(self.timestamp?)
      },
      DateFilterConditionPB::DateStartsAfter | DateFilterConditionPB::DateEndsAfter => {
        DateFilterStrategy::After(self.timestamp?)
      },
      DateFilterConditionPB::DateStartsOnOrBefore | DateFilterConditionPB::DateEndsOnOrBefore => {
        DateFilterStrategy::OnOrBefore(self.timestamp?)
      },
      DateFilterConditionPB::DateStartsOnOrAfter | DateFilterConditionPB::DateEndsOnOrAfter => {
        DateFilterStrategy::OnOrAfter(self.timestamp?)
      },
      DateFilterConditionPB::DateStartsBetween | DateFilterConditionPB::DateEndsBetween => {
        DateFilterStrategy::DateBetween {
          start: self.start?,
          end: self.end?,
        }
      },
      DateFilterConditionPB::DateStartIsEmpty | DateFilterConditionPB::DateEndIsEmpty => {
        DateFilterStrategy::Empty
      },
      DateFilterConditionPB::DateStartIsNotEmpty | DateFilterConditionPB::DateEndIsNotEmpty => {
        DateFilterStrategy::NotEmpty
      },
    };

    Some(strategy)
  }
}

#[inline]
fn naive_date_from_timestamp(timestamp: i64) -> Option<NaiveDate> {
  Local
    .timestamp_opt(timestamp, 0)
    .single()
    .map(|date_time| date_time.date_naive())
}

enum DateFilterStrategy {
  On(i64),
  Before(i64),
  After(i64),
  OnOrBefore(i64),
  OnOrAfter(i64),
  DateBetween { start: i64, end: i64 },
  Empty,
  NotEmpty,
}

impl DateFilterStrategy {
  fn filter(self, cell_data: Option<i64>) -> bool {
    match self {
      DateFilterStrategy::On(expected_timestamp) => cell_data.is_some_and(|timestamp| {
        let cell_date = naive_date_from_timestamp(timestamp);
        let expected_date = naive_date_from_timestamp(expected_timestamp);
        cell_date == expected_date
      }),
      DateFilterStrategy::Before(expected_timestamp) => cell_data.is_some_and(|timestamp| {
        let cell_date = naive_date_from_timestamp(timestamp);
        let expected_date = naive_date_from_timestamp(expected_timestamp);
        cell_date < expected_date
      }),
      DateFilterStrategy::After(expected_timestamp) => cell_data.is_some_and(|timestamp| {
        let cell_date = naive_date_from_timestamp(timestamp);
        let expected_date = naive_date_from_timestamp(expected_timestamp);
        cell_date > expected_date
      }),
      DateFilterStrategy::OnOrBefore(expected_timestamp) => cell_data.is_some_and(|timestamp| {
        let cell_date = naive_date_from_timestamp(timestamp);
        let expected_date = naive_date_from_timestamp(expected_timestamp);
        cell_date <= expected_date
      }),
      DateFilterStrategy::OnOrAfter(expected_timestamp) => cell_data.is_some_and(|timestamp| {
        let cell_date = naive_date_from_timestamp(timestamp);
        let expected_date = naive_date_from_timestamp(expected_timestamp);
        cell_date >= expected_date
      }),
      DateFilterStrategy::DateBetween { start, end } => cell_data.is_some_and(|timestamp| {
        let cell_date = naive_date_from_timestamp(timestamp);
        let expected_start_date = naive_date_from_timestamp(start);
        let expected_end_date = naive_date_from_timestamp(end);
        cell_date >= expected_start_date && cell_date <= expected_end_date
      }),
      DateFilterStrategy::Empty => match cell_data {
        None => true,
        Some(timestamp) if naive_date_from_timestamp(timestamp).is_none() => true,
        _ => false,
      },
      DateFilterStrategy::NotEmpty => {
        matches!(cell_data, Some(timestamp) if naive_date_from_timestamp(timestamp).is_some() )
      },
    }
  }
}

impl PreFillCellsWithFilter for DateFilterPB {
  fn get_compliant_cell(&self, field: &Field) -> Option<Cell> {
    let start_timestamp = match self.condition {
      DateFilterConditionPB::DateStartsOn
      | DateFilterConditionPB::DateStartsOnOrBefore
      | DateFilterConditionPB::DateStartsOnOrAfter
      | DateFilterConditionPB::DateEndsOn
      | DateFilterConditionPB::DateEndsOnOrBefore
      | DateFilterConditionPB::DateEndsOnOrAfter => self.timestamp,
      DateFilterConditionPB::DateStartsBefore | DateFilterConditionPB::DateEndsBefore => self
        .timestamp
        .and_then(|timestamp| {
          Local
            .timestamp_opt(timestamp, 0)
            .single()
            .map(|date| date.naive_local())
        })
        .and_then(|date_time| {
          let answer = date_time - Duration::days(1);
          Local
            .from_local_datetime(&answer)
            .single()
            .map(|date_time| date_time.timestamp())
        }),
      DateFilterConditionPB::DateStartsAfter | DateFilterConditionPB::DateEndsAfter => self
        .timestamp
        .and_then(|timestamp| {
          Local
            .timestamp_opt(timestamp, 0)
            .single()
            .map(|date| date.naive_local())
        })
        .and_then(|date_time| {
          let answer = date_time + Duration::days(1);
          Local
            .from_local_datetime(&answer)
            .single()
            .map(|date_time| date_time.timestamp())
        }),
      DateFilterConditionPB::DateStartsBetween | DateFilterConditionPB::DateEndsBetween => {
        self.start
      },
      _ => None,
    };

    start_timestamp.map(|timestamp| insert_date_cell(timestamp, None, None, None, field))
  }
}

#[cfg(test)]
mod tests {
  use crate::entities::{DateFilterConditionPB, DateFilterPB};
  use collab_database::fields::date_type_option::DateCellData;

  fn to_cell_data(timestamp: Option<i64>, end_timestamp: Option<i64>) -> DateCellData {
    DateCellData {
      timestamp,
      end_timestamp,
      ..Default::default()
    }
  }

  #[test]
  fn date_filter_is_test() {
    let filter = DateFilterPB {
      condition: DateFilterConditionPB::DateStartsOn,
      timestamp: Some(1668387885),
      end: None,
      start: None,
    };

    for (start, end, is_visible) in [
      (Some(1668387885), None, true),
      (Some(1647251762), None, false),
      (None, None, false),
    ] {
      assert_eq!(
        filter.is_visible(&to_cell_data(start, end)).unwrap_or(true),
        is_visible
      );
    }

    let filter = DateFilterPB {
      condition: DateFilterConditionPB::DateStartsOn,
      timestamp: None,
      end: None,
      start: None,
    };

    for (start, end, is_visible) in [
      (Some(1668387885), None, true),
      (Some(1647251762), None, true),
      (None, None, true),
    ] {
      assert_eq!(
        filter.is_visible(&to_cell_data(start, end)).unwrap_or(true),
        is_visible
      );
    }
  }

  #[test]
  fn date_filter_before_test() {
    let filter = DateFilterPB {
      condition: DateFilterConditionPB::DateStartsBefore,
      timestamp: Some(1668387885),
      start: None,
      end: None,
    };

    for (start, end, is_visible) in [
      (Some(1668387884), None, false),
      (Some(1647251762), None, true),
    ] {
      assert_eq!(
        filter.is_visible(&to_cell_data(start, end)).unwrap_or(true),
        is_visible,
      );
    }
  }

  #[test]
  fn date_filter_before_or_on_test() {
    let filter = DateFilterPB {
      condition: DateFilterConditionPB::DateStartsOnOrBefore,
      timestamp: Some(1668387885),
      start: None,
      end: None,
    };

    for (start, end, is_visible) in [
      (Some(1668387884), None, true),
      (Some(1668387885), None, true),
    ] {
      assert_eq!(
        filter.is_visible(&to_cell_data(start, end)).unwrap_or(true),
        is_visible
      );
    }
  }
  #[test]
  fn date_filter_after_test() {
    let filter = DateFilterPB {
      condition: DateFilterConditionPB::DateStartsAfter,
      timestamp: Some(1668387885),
      start: None,
      end: None,
    };

    for (start, end, is_visible) in [
      (Some(1668387888), None, false),
      (Some(1668531885), None, true),
      (Some(0), None, false),
    ] {
      assert_eq!(
        filter.is_visible(&to_cell_data(start, end)).unwrap_or(true),
        is_visible
      );
    }
  }

  #[test]
  fn date_filter_within_test() {
    let filter = DateFilterPB {
      condition: DateFilterConditionPB::DateStartsBetween,
      start: Some(1668272685), // 11/13
      end: Some(1668618285),   // 11/17
      timestamp: None,
    };

    for (start, end, is_visible, msg) in [
      (Some(1668272685), None, true, "11/13"),
      (Some(1668359085), None, true, "11/14"),
      (Some(1668704685), None, false, "11/18"),
      (None, None, false, "empty"),
    ] {
      assert_eq!(
        filter.is_visible(&to_cell_data(start, end)).unwrap_or(true),
        is_visible,
        "{msg}"
      );
    }

    let filter = DateFilterPB {
      condition: DateFilterConditionPB::DateStartsBetween,
      start: None,
      end: Some(1668618285), // 11/17
      timestamp: None,
    };

    for (start, end, is_visible, msg) in [
      (Some(1668272685), None, true, "11/13"),
      (Some(1668359085), None, true, "11/14"),
      (Some(1668704685), None, true, "11/18"),
      (None, None, true, "empty"),
    ] {
      assert_eq!(
        filter.is_visible(&to_cell_data(start, end)).unwrap_or(true),
        is_visible,
        "{msg}"
      );
    }
  }

  #[test]
  fn date_filter_is_empty_test() {
    let filter = DateFilterPB {
      condition: DateFilterConditionPB::DateStartIsEmpty,
      start: None,
      end: None,
      timestamp: None,
    };

    for (start, end, is_visible) in [(None, None, true), (Some(123), None, false)] {
      assert_eq!(
        filter.is_visible(&to_cell_data(start, end)).unwrap_or(true),
        is_visible
      );
    }
  }

  #[test]
  fn date_filter_end_test() {
    let filter = DateFilterPB {
      condition: DateFilterConditionPB::DateEndsOnOrBefore,
      timestamp: Some(1668359085), // 11/14
      end: None,
      start: None,
    };

    for (start, end, is_visible, msg) in [
      (Some(1668272685), None, true, "11/13"),
      (Some(1668359085), None, true, "11/14"),
      (Some(1668704685), None, false, "11/18"),
      (None, None, false, "empty"),
      (Some(1668272685), Some(1668272685), true, "11/13"),
      (Some(1668272685), Some(1668359085), true, "11/14"),
      (Some(1668272685), Some(1668704685), false, "11/18"),
    ] {
      assert_eq!(
        filter.is_visible(&to_cell_data(start, end)).unwrap_or(true),
        is_visible,
        "{msg}"
      );
    }

    let filter = DateFilterPB {
      condition: DateFilterConditionPB::DateEndsOnOrBefore,
      timestamp: None,
      start: None,
      end: None,
    };

    for (start, end, is_visible, msg) in [
      (Some(1668272685), Some(1668272685), true, "11/13"),
      (Some(1668272685), Some(1668359085), true, "11/14"),
      (Some(1668272685), Some(1668704685), true, "11/18"),
      (None, None, true, "empty"),
    ] {
      assert_eq!(
        filter.is_visible(&to_cell_data(start, end)).unwrap_or(true),
        is_visible,
        "{msg}"
      );
    }
  }
}
