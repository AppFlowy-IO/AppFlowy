#![allow(clippy::while_let_on_iterator)]
use crate::core::delta::Delta;
use crate::core::interval::Interval;
use crate::core::operation::{Attributes, Operation};
use crate::errors::{ErrorBuilder, OTError, OTErrorCode};
use std::{cmp::min, iter::Enumerate, slice::Iter};

/// A [DeltaCursor] is used to iterate the delta and return the corresponding delta.
#[derive(Debug)]
pub struct DeltaCursor<'a, T: Attributes> {
    pub(crate) delta: &'a Delta<T>,
    pub(crate) origin_iv: Interval,
    pub(crate) consume_iv: Interval,
    pub(crate) consume_count: usize,
    pub(crate) op_offset: usize,
    iter: Enumerate<Iter<'a, Operation<T>>>,
    next_op: Option<Operation<T>>,
}

impl<'a, T> DeltaCursor<'a, T>
where
    T: Attributes,
{
    /// # Arguments
    ///
    /// * `delta`: The delta you want to iterate over.
    /// * `interval`: The range for the cursor movement.
    ///
    /// # Examples
    ///
    /// ```
    /// use lib_ot::core::{DeltaCursor, DeltaIterator, Interval, Operation};
    /// use lib_ot::rich_text::RichTextDelta;
    /// let mut delta = RichTextDelta::default();   
    /// delta.add(Operation::insert("123"));    
    /// delta.add(Operation::insert("4"));
    ///
    /// let mut cursor = DeltaCursor::new(&delta, Interval::new(0, 3));
    /// assert_eq!(cursor.next_iv(), Interval::new(0,3));
    /// assert_eq!(cursor.next_with_len(Some(2)).unwrap(), Operation::insert("12"));
    /// assert_eq!(cursor.get_next_op().unwrap(), Operation::insert("3"));
    /// assert_eq!(cursor.get_next_op(), None);
    /// ```
    pub fn new(delta: &'a Delta<T>, interval: Interval) -> DeltaCursor<'a, T> {
        // debug_assert!(interval.start <= delta.target_len);
        let mut cursor = Self {
            delta,
            origin_iv: interval,
            consume_iv: interval,
            consume_count: 0,
            op_offset: 0,
            iter: delta.ops.iter().enumerate(),
            next_op: None,
        };
        cursor.descend(0);
        cursor
    }

    /// Returns the next operation interval
    pub fn next_iv(&self) -> Interval {
        self.next_iv_with_len(None).unwrap_or_else(|| Interval::new(0, 0))
    }

    /// Returns the next operation
    pub fn get_next_op(&mut self) -> Option<Operation<T>> {
        self.next_with_len(None)
    }

    /// Returns the reference of the next operation
    pub fn next_op(&self) -> Option<&Operation<T>> {
        let mut next_op = self.next_op.as_ref();
        if next_op.is_none() {
            let mut offset = 0;
            for op in &self.delta.ops {
                offset += op.len();
                if offset > self.consume_count {
                    next_op = Some(op);
                    break;
                }
            }
        }
        next_op
    }

    /// # Arguments
    ///
    /// * `expected_len`: Return the next operation with the specified length.
    ///
    ///
    pub fn next_with_len(&mut self, expected_len: Option<usize>) -> Option<Operation<T>> {
        let mut find_op = None;
        let holder = self.next_op.clone();
        let mut next_op = holder.as_ref();

        if next_op.is_none() {
            next_op = find_next(self);
        }

        let mut consume_len = 0;
        while find_op.is_none() && next_op.is_some() {
            let op = next_op.take().unwrap();
            let interval = self
                .next_iv_with_len(expected_len)
                .unwrap_or_else(|| Interval::new(0, 0));

            // cache the op if the interval is empty. e.g. last_op_before(Some(0))
            if interval.is_empty() {
                self.next_op = Some(op.clone());
                break;
            }
            find_op = op.shrink(interval);
            let suffix = Interval::new(0, op.len()).suffix(interval);
            if suffix.is_empty() {
                self.next_op = None;
            } else {
                self.next_op = op.shrink(suffix);
            }

            consume_len += interval.end;
            self.consume_count += interval.end;
            self.consume_iv.start = self.consume_count;

            // continue to find the op in next iteration
            if find_op.is_none() {
                next_op = find_next(self);
            }
        }

        if find_op.is_some() {
            if let Some(end) = expected_len {
                // try to find the next op before the index if consume_len less than index
                if end > consume_len && self.has_next() {
                    return self.next_with_len(Some(end - consume_len));
                }
            }
        }
        find_op
    }

    pub fn has_next(&self) -> bool {
        self.next_op().is_some()
    }

    /// Finds the op within the current offset.
    /// This function sets the start of the consume_iv to the offset, updates the consume_count
    /// and the next_op reference.
    ///
    /// # Arguments
    ///
    /// * `offset`: Represents the offset of the delta string, in Utf16CodeUnit unit.
    fn descend(&mut self, offset: usize) {
        self.consume_iv.start += offset;

        if self.consume_count >= self.consume_iv.start {
            return;
        }
        while let Some((o_index, op)) = self.iter.next() {
            self.op_offset = o_index;
            let start = self.consume_count;
            let end = start + op.len();
            let intersect = Interval::new(start, end).intersect(self.consume_iv);
            if intersect.is_empty() {
                self.consume_count += op.len();
            } else {
                self.next_op = Some(op.clone());
                break;
            }
        }
    }

    fn next_iv_with_len(&self, expected_len: Option<usize>) -> Option<Interval> {
        let op = self.next_op()?;
        let start = self.consume_count;
        let end = match expected_len {
            None => self.consume_count + op.len(),
            Some(expected_len) => self.consume_count + min(expected_len, op.len()),
        };

        let intersect = Interval::new(start, end).intersect(self.consume_iv);
        let interval = intersect.translate_neg(start);
        Some(interval)
    }
}

fn find_next<'a, T>(cursor: &mut DeltaCursor<'a, T>) -> Option<&'a Operation<T>>
where
    T: Attributes,
{
    match cursor.iter.next() {
        None => None,
        Some((o_index, op)) => {
            cursor.op_offset = o_index;
            Some(op)
        }
    }
}

type SeekResult = Result<(), OTError>;
pub trait Metric {
    fn seek<T: Attributes>(cursor: &mut DeltaCursor<T>, offset: usize) -> SeekResult;
}

/// [OpMetric] is used by [DeltaIterator] for seeking operations
/// The unit of the movement is Operation
pub struct OpMetric();

impl Metric for OpMetric {
    fn seek<T: Attributes>(cursor: &mut DeltaCursor<T>, op_offset: usize) -> SeekResult {
        let _ = check_bound(cursor.op_offset, op_offset)?;
        let mut seek_cursor = DeltaCursor::new(cursor.delta, cursor.origin_iv);

        while let Some((_, op)) = seek_cursor.iter.next() {
            cursor.descend(op.len());
            if cursor.op_offset >= op_offset {
                break;
            }
        }
        Ok(())
    }
}

/// [Utf16CodeUnitMetric] is used by [DeltaIterator] for seeking operations.
/// The unit of the movement is Utf16CodeUnit
pub struct Utf16CodeUnitMetric();

impl Metric for Utf16CodeUnitMetric {
    fn seek<T: Attributes>(cursor: &mut DeltaCursor<T>, offset: usize) -> SeekResult {
        if offset > 0 {
            let _ = check_bound(cursor.consume_count, offset)?;
            let _ = cursor.next_with_len(Some(offset));
        }

        Ok(())
    }
}

fn check_bound(current: usize, target: usize) -> Result<(), OTError> {
    debug_assert!(current <= target);
    if current > target {
        let msg = format!("{} should be greater than current: {}", target, current);
        return Err(ErrorBuilder::new(OTErrorCode::IncompatibleLength).msg(&msg).build());
    }
    Ok(())
}
