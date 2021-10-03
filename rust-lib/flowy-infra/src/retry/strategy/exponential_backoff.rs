use std::{iter::Iterator, time::Duration};
/// A retry strategy driven by exponential back-off.
///
/// The power corresponds to the number of past attempts.
#[derive(Debug, Clone)]
pub struct ExponentialBackoff {
    current: u64,
    base: u64,
    factor: u64,
    max_delay: Option<Duration>,
}

impl ExponentialBackoff {
    /// Constructs a new exponential back-off strategy,
    /// given a base duration in milliseconds.
    ///
    /// The resulting duration is calculated by taking the base to the `n`-th
    /// power, where `n` denotes the number of past attempts.
    pub fn from_millis(base: u64) -> ExponentialBackoff {
        ExponentialBackoff {
            current: base,
            base,
            factor: 1u64,
            max_delay: None,
        }
    }

    /// A multiplicative factor that will be applied to the retry delay.
    ///
    /// For example, using a factor of `1000` will make each delay in units of
    /// seconds.
    ///
    /// Default factor is `1`.
    pub fn factor(mut self, factor: u64) -> ExponentialBackoff {
        self.factor = factor;
        self
    }

    /// Apply a maximum delay. No retry delay will be longer than this
    /// `Duration`.
    pub fn max_delay(mut self, duration: Duration) -> ExponentialBackoff {
        self.max_delay = Some(duration);
        self
    }
}

impl Iterator for ExponentialBackoff {
    type Item = Duration;

    fn next(&mut self) -> Option<Duration> {
        // set delay duration by applying factor
        let duration = if let Some(duration) = self.current.checked_mul(self.factor) {
            Duration::from_millis(duration)
        } else {
            Duration::from_millis(u64::MAX)
        };

        // check if we reached max delay
        if let Some(ref max_delay) = self.max_delay {
            if duration > *max_delay {
                return Some(*max_delay);
            }
        }

        if let Some(next) = self.current.checked_mul(self.base) {
            self.current = next;
        } else {
            self.current = u64::MAX;
        }

        Some(duration)
    }
}

#[test]
fn returns_some_exponential_base_10() {
    let mut s = ExponentialBackoff::from_millis(10);

    assert_eq!(s.next(), Some(Duration::from_millis(10)));
    assert_eq!(s.next(), Some(Duration::from_millis(100)));
    assert_eq!(s.next(), Some(Duration::from_millis(1000)));
}

#[test]
fn returns_some_exponential_base_2() {
    let mut s = ExponentialBackoff::from_millis(2);

    assert_eq!(s.next(), Some(Duration::from_millis(2)));
    assert_eq!(s.next(), Some(Duration::from_millis(4)));
    assert_eq!(s.next(), Some(Duration::from_millis(8)));
}

#[test]
fn saturates_at_maximum_value() {
    let mut s = ExponentialBackoff::from_millis(u64::MAX - 1);

    assert_eq!(s.next(), Some(Duration::from_millis(u64::MAX - 1)));
    assert_eq!(s.next(), Some(Duration::from_millis(u64::MAX)));
    assert_eq!(s.next(), Some(Duration::from_millis(u64::MAX)));
}

#[test]
fn can_use_factor_to_get_seconds() {
    let factor = 1000;
    let mut s = ExponentialBackoff::from_millis(2).factor(factor);

    assert_eq!(s.next(), Some(Duration::from_secs(2)));
    assert_eq!(s.next(), Some(Duration::from_secs(4)));
    assert_eq!(s.next(), Some(Duration::from_secs(8)));
}

#[test]
fn stops_increasing_at_max_delay() {
    let mut s = ExponentialBackoff::from_millis(2).max_delay(Duration::from_millis(4));

    assert_eq!(s.next(), Some(Duration::from_millis(2)));
    assert_eq!(s.next(), Some(Duration::from_millis(4)));
    assert_eq!(s.next(), Some(Duration::from_millis(4)));
}

#[test]
fn returns_max_when_max_less_than_base() {
    let mut s = ExponentialBackoff::from_millis(20).max_delay(Duration::from_millis(10));

    assert_eq!(s.next(), Some(Duration::from_millis(10)));
    assert_eq!(s.next(), Some(Duration::from_millis(10)));
}
