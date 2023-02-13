use crate::entities::{DateFilterConditionPB, DateFilterPB};
use chrono::NaiveDateTime;

impl DateFilterPB {
  pub fn is_visible<T: Into<Option<i64>>>(&self, cell_timestamp: T) -> bool {
    match cell_timestamp.into() {
      None => DateFilterConditionPB::DateIsEmpty == self.condition,
      Some(timestamp) => {
        match self.condition {
          DateFilterConditionPB::DateIsNotEmpty => {
            return true;
          },
          DateFilterConditionPB::DateIsEmpty => {
            return false;
          },
          _ => {},
        }

        let cell_time = NaiveDateTime::from_timestamp_opt(timestamp, 0);
        let cell_date = cell_time.map(|time| time.date());
        match self.timestamp {
          None => {
            if self.start.is_none() {
              return true;
            }

            if self.end.is_none() {
              return true;
            }

            let start_time = NaiveDateTime::from_timestamp_opt(*self.start.as_ref().unwrap(), 0);
            let start_date = start_time.map(|time| time.date());

            let end_time = NaiveDateTime::from_timestamp_opt(*self.end.as_ref().unwrap(), 0);
            let end_date = end_time.map(|time| time.date());

            cell_date >= start_date && cell_date <= end_date
          },
          Some(timestamp) => {
            let expected_timestamp = NaiveDateTime::from_timestamp_opt(timestamp, 0);
            let expected_date = expected_timestamp.map(|time| time.date());

            // We assume that the cell_timestamp doesn't contain hours, just day.
            match self.condition {
              DateFilterConditionPB::DateIs => cell_date == expected_date,
              DateFilterConditionPB::DateBefore => cell_date < expected_date,
              DateFilterConditionPB::DateAfter => cell_date > expected_date,
              DateFilterConditionPB::DateOnOrBefore => cell_date <= expected_date,
              DateFilterConditionPB::DateOnOrAfter => cell_date >= expected_date,
              _ => true,
            }
          },
        }
      },
    }
  }
}

#[cfg(test)]
mod tests {
  #![allow(clippy::all)]
  use crate::entities::{DateFilterConditionPB, DateFilterPB};

  #[test]
  fn date_filter_is_test() {
    let filter = DateFilterPB {
      condition: DateFilterConditionPB::DateIs,
      timestamp: Some(1668387885),
      end: None,
      start: None,
    };

    for (val, visible) in vec![(1668387885, true), (1647251762, false)] {
      assert_eq!(filter.is_visible(val as i64), visible);
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

    for (val, visible, msg) in vec![(1668387884, false, "1"), (1647251762, true, "2")] {
      assert_eq!(filter.is_visible(val as i64), visible, "{}", msg);
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

    for (val, visible) in vec![(1668387884, true), (1668387885, true)] {
      assert_eq!(filter.is_visible(val as i64), visible);
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

    for (val, visible) in vec![(1668387888, false), (1668531885, true), (0, false)] {
      assert_eq!(filter.is_visible(val as i64), visible);
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

    for (val, visible, _msg) in vec![
      (1668272685, true, "11/13"),
      (1668359085, true, "11/14"),
      (1668704685, false, "11/18"),
    ] {
      assert_eq!(filter.is_visible(val as i64), visible);
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

    for (val, visible) in vec![(None, true), (Some(123), false)] {
      assert_eq!(filter.is_visible(val), visible);
    }
  }
}
