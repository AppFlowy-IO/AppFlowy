use std::{iter::Iterator, time::Duration};

/// A retry strategy driven by a fixed interval.
#[derive(Debug, Clone)]
pub struct FixedInterval {
    duration: Duration,
}

impl FixedInterval {
    /// Constructs a new fixed interval strategy.
    pub fn new(duration: Duration) -> FixedInterval {
        FixedInterval { duration }
    }

    /// Constructs a new fixed interval strategy,
    /// given a duration in milliseconds.
    pub fn from_millis(millis: u64) -> FixedInterval {
        FixedInterval {
            duration: Duration::from_millis(millis),
        }
    }
}

impl Iterator for FixedInterval {
    type Item = Duration;

    fn next(&mut self) -> Option<Duration> {
        Some(self.duration)
    }
}

#[test]
fn returns_some_fixed() {
    let mut s = FixedInterval::new(Duration::from_millis(123));

    assert_eq!(s.next(), Some(Duration::from_millis(123)));
    assert_eq!(s.next(), Some(Duration::from_millis(123)));
    assert_eq!(s.next(), Some(Duration::from_millis(123)));
}
