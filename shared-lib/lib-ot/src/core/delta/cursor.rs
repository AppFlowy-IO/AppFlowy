use crate::{
    core::{Attributes, Delta, Interval, Operation},
    errors::{ErrorBuilder, OTError, OTErrorCode},
};
use std::{cmp::min, iter::Enumerate, slice::Iter};

#[derive(Debug)]
pub struct OpCursor<'a, T: Attributes> {
    pub(crate) delta: &'a Delta<T>,
    pub(crate) origin_iv: Interval,
    pub(crate) consume_iv: Interval,
    pub(crate) consume_count: usize,
    pub(crate) op_index: usize,
    iter: Enumerate<Iter<'a, Operation<T>>>,
    next_op: Option<Operation<T>>,
}

impl<'a, T> OpCursor<'a, T>
where
    T: Attributes,
{
    pub fn new(delta: &'a Delta<T>, interval: Interval) -> OpCursor<'a, T> {
        // debug_assert!(interval.start <= delta.target_len);
        let mut cursor = Self {
            delta,
            origin_iv: interval,
            consume_iv: interval,
            consume_count: 0,
            op_index: 0,
            iter: delta.ops.iter().enumerate(),
            next_op: None,
        };
        cursor.descend(0);
        cursor
    }

    // get the next operation interval
    pub fn next_iv(&self) -> Interval { self.next_iv_with_len(None).unwrap_or_else(|| Interval::new(0, 0)) }

    pub fn next_op(&mut self) -> Option<Operation<T>> { self.next_with_len(None) }

    // get the last operation before the end.
    // checkout the delta_next_op_with_len_cross_op_return_last test for more detail
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

    pub fn has_next(&self) -> bool { self.next_iter_op().is_some() }

    fn descend(&mut self, index: usize) {
        self.consume_iv.start += index;

        if self.consume_count >= self.consume_iv.start {
            return;
        }
        while let Some((o_index, op)) = self.iter.next() {
            self.op_index = o_index;
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
        let op = self.next_iter_op()?;
        let start = self.consume_count;
        let end = match expected_len {
            None => self.consume_count + op.len(),
            Some(expected_len) => self.consume_count + min(expected_len, op.len()),
        };

        let intersect = Interval::new(start, end).intersect(self.consume_iv);
        let interval = intersect.translate_neg(start);
        Some(interval)
    }

    pub fn next_iter_op(&self) -> Option<&Operation<T>> {
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
}

fn find_next<'a, T>(cursor: &mut OpCursor<'a, T>) -> Option<&'a Operation<T>>
where
    T: Attributes,
{
    match cursor.iter.next() {
        None => None,
        Some((o_index, op)) => {
            cursor.op_index = o_index;
            Some(op)
        },
    }
}

type SeekResult = Result<(), OTError>;
pub trait Metric {
    fn seek<T: Attributes>(cursor: &mut OpCursor<T>, offset: usize) -> SeekResult;
}

pub struct OpMetric();

impl Metric for OpMetric {
    fn seek<T: Attributes>(cursor: &mut OpCursor<T>, offset: usize) -> SeekResult {
        let _ = check_bound(cursor.op_index, offset)?;
        let mut seek_cursor = OpCursor::new(cursor.delta, cursor.origin_iv);
        let mut cur_offset = 0;
        while let Some((_, op)) = seek_cursor.iter.next() {
            cur_offset += op.len();
            if cur_offset > offset {
                break;
            }
        }
        cursor.descend(cur_offset);
        Ok(())
    }
}

pub struct Utf16CodeUnitMetric();

impl Metric for Utf16CodeUnitMetric {
    fn seek<T: Attributes>(cursor: &mut OpCursor<T>, offset: usize) -> SeekResult {
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
