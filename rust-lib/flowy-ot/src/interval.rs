use std::{
    cmp::{max, min},
    fmt,
    ops::{Range, RangeInclusive, RangeTo, RangeToInclusive},
};

/// Representing a closed-open range;
/// the interval [5, 7) is the set {5, 6}.
///
/// It is an invariant that `start <= end`. An interval where `end < start` is
/// considered empty.
#[derive(Clone, Copy, PartialEq, Eq)]
pub struct Interval {
    pub start: usize,
    pub end: usize,
}

impl Interval {
    /// Construct a new `Interval` representing the range [start..end).
    /// It is an invariant that `start <= end`.
    pub fn new(start: usize, end: usize) -> Interval {
        debug_assert!(start <= end);
        Interval { start, end }
    }

    pub fn start(&self) -> usize { self.start }

    pub fn end(&self) -> usize { self.end }

    pub fn start_end(&self) -> (usize, usize) { (self.start, self.end) }

    pub fn is_before(&self, val: usize) -> bool { self.end <= val }

    pub fn contains(&self, val: usize) -> bool { self.start <= val && val < self.end }

    pub fn is_after(&self, val: usize) -> bool { self.start > val }

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

    pub fn translate(&self, amount: usize) -> Interval {
        Interval {
            start: self.start + amount,
            end: self.end + amount,
        }
    }

    pub fn translate_neg(&self, amount: usize) -> Interval {
        debug_assert!(self.start >= amount);
        Interval {
            start: self.start - amount,
            end: self.end - amount,
        }
    }

    pub fn union(&self, other: Interval) -> Interval {
        if self.is_empty() {
            return other;
        }
        if other.is_empty() {
            return *self;
        }
        let start = min(self.start, other.start);
        let end = max(self.end, other.end);
        Interval { start, end }
    }

    pub fn size(&self) -> usize { self.end - self.start }
}

impl std::default::Default for Interval {
    fn default() -> Self { Interval::new(0, 0) }
}

impl fmt::Display for Interval {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        write!(f, "[{}, {})", self.start(), self.end())
    }
}

impl fmt::Debug for Interval {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result { fmt::Display::fmt(self, f) }
}

impl From<Range<usize>> for Interval {
    fn from(src: Range<usize>) -> Interval {
        let Range { start, end } = src;
        Interval { start, end }
    }
}

impl From<RangeTo<usize>> for Interval {
    fn from(src: RangeTo<usize>) -> Interval { Interval::new(0, src.end) }
}

impl From<RangeInclusive<usize>> for Interval {
    fn from(src: RangeInclusive<usize>) -> Interval {
        Interval::new(*src.start(), src.end().saturating_add(1))
    }
}

impl From<RangeToInclusive<usize>> for Interval {
    fn from(src: RangeToInclusive<usize>) -> Interval {
        Interval::new(0, src.end.saturating_add(1))
    }
}

#[cfg(test)]
mod tests {
    use crate::interval::Interval;

    #[test]
    fn contains() {
        let i = Interval::new(2, 42);
        assert!(!i.contains(1));
        assert!(i.contains(2));
        assert!(i.contains(3));
        assert!(i.contains(41));
        assert!(!i.contains(42));
        assert!(!i.contains(43));
    }

    #[test]
    fn before() {
        let i = Interval::new(2, 42);
        assert!(!i.is_before(1));
        assert!(!i.is_before(2));
        assert!(!i.is_before(3));
        assert!(!i.is_before(41));
        assert!(i.is_before(42));
        assert!(i.is_before(43));
    }

    #[test]
    fn after() {
        let i = Interval::new(2, 42);
        assert!(i.is_after(1));
        assert!(!i.is_after(2));
        assert!(!i.is_after(3));
        assert!(!i.is_after(41));
        assert!(!i.is_after(42));
        assert!(!i.is_after(43));
    }

    #[test]
    fn translate() {
        let i = Interval::new(2, 42);
        assert_eq!(Interval::new(5, 45), i.translate(3));
        assert_eq!(Interval::new(1, 41), i.translate_neg(1));
    }

    #[test]
    fn empty() {
        assert!(Interval::new(0, 0).is_empty());
        assert!(Interval::new(1, 1).is_empty());
        assert!(!Interval::new(1, 2).is_empty());
    }

    #[test]
    fn intersect() {
        assert_eq!(
            Interval::new(2, 3),
            Interval::new(1, 3).intersect(Interval::new(2, 4))
        );
        assert!(Interval::new(1, 2)
            .intersect(Interval::new(2, 43))
            .is_empty());
    }

    #[test]
    fn prefix() {
        assert_eq!(
            Interval::new(1, 2),
            Interval::new(1, 4).prefix(Interval::new(2, 3))
        );
    }

    #[test]
    fn suffix() {
        assert_eq!(
            Interval::new(3, 4),
            Interval::new(1, 4).suffix(Interval::new(2, 3))
        );
    }

    #[test]
    fn size() {
        assert_eq!(40, Interval::new(2, 42).size());
        assert_eq!(0, Interval::new(1, 1).size());
        assert_eq!(1, Interval::new(1, 2).size());
    }
}
