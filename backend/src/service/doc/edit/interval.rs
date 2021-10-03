use std::cmp::{max, min};

#[derive(Clone, Copy, PartialEq, Eq)]
pub struct Interval {
    pub start: i64,
    pub end: i64,
}

impl Interval {
    /// Construct a new `Interval` representing the range [start..end).
    /// It is an invariant that `start <= end`.
    pub fn new(start: i64, end: i64) -> Interval {
        debug_assert!(start <= end);
        Interval { start, end }
    }

    pub fn start(&self) -> i64 { self.start }

    pub fn end(&self) -> i64 { self.end }

    pub fn is_before(&self, val: i64) -> bool { self.end <= val }

    pub fn contains(&self, val: i64) -> bool { self.start <= val && val < self.end }

    pub fn contains_range(&self, start: i64, end: i64) -> bool { !self.intersect(Interval::new(start, end)).is_empty() }

    pub fn is_after(&self, val: i64) -> bool { self.start > val }

    pub fn is_empty(&self) -> bool { self.end <= self.start }

    pub fn intersect(&self, other: Interval) -> Interval {
        let start = max(self.start, other.start);
        let end = min(self.end, other.end);
        Interval {
            start,
            end: max(start, end),
        }
    }

    // the first half of self - other
    pub fn prefix(&self, other: Interval) -> Interval {
        Interval {
            start: min(self.start, other.start),
            end: min(self.end, other.start),
        }
    }

    // the second half of self - other
    pub fn suffix(&self, other: Interval) -> Interval {
        Interval {
            start: max(self.start, other.end),
            end: max(self.end, other.end),
        }
    }

    pub fn size(&self) -> i64 { self.end - self.start }
}
