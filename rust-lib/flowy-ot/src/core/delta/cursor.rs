use crate::{
    core::{Delta, Interval, Operation},
    errors::{ErrorBuilder, OTError, OTErrorCode},
};
use std::{cmp::min, iter::Enumerate, slice::Iter};

#[derive(Debug)]
pub struct Cursor<'a> {
    pub(crate) delta: &'a Delta,
    pub(crate) origin_iv: Interval,
    pub(crate) next_iv: Interval,
    pub(crate) iter_char_count: usize,
    pub(crate) iter_op_index: usize,
    iter: Enumerate<Iter<'a, Operation>>,
    next_op: Option<Operation>,
}

impl<'a> Cursor<'a> {
    pub fn new(delta: &'a Delta, interval: Interval) -> Cursor<'a> {
        // debug_assert!(interval.start <= delta.target_len);
        let mut cursor = Self {
            delta,
            origin_iv: interval,
            next_iv: interval,
            iter_char_count: 0,
            iter_op_index: 0,
            iter: delta.ops.iter().enumerate(),
            next_op: None,
        };
        cursor.descend(0);
        cursor
    }

    pub fn next_iv(&self) -> Interval { self.next_op_iv_before(None) }

    pub fn next_op(&mut self) -> Option<Operation> { self.next_op_before(None) }

    pub fn next_op_before(&mut self, b_index: Option<usize>) -> Option<Operation> {
        let mut find_op = None;
        let next_op = self.next_op.take();
        let mut next_op = next_op.as_ref();

        if next_op.is_none() {
            next_op = find_next_op(self);
        }

        let old_iter_char_count = self.iter_char_count;
        while find_op.is_none() && next_op.is_some() {
            let op = next_op.take().unwrap();
            let interval = self.next_op_iv_before(b_index);
            if interval.is_empty() {
                self.next_op = Some(op.clone());
                break;
            }

            find_op = op.shrink(interval);
            let suffix = Interval::new(0, op.length()).suffix(interval);
            if !suffix.is_empty() {
                self.next_op = op.shrink(suffix);
            }

            self.iter_char_count += interval.end;
            self.next_iv.start = self.iter_char_count;

            if find_op.is_none() {
                next_op = find_next_op(self);
            }
        }

        if find_op.is_some() {
            let last = self.iter_char_count - old_iter_char_count;
            let force_len = b_index.unwrap_or(0);
            if force_len > last {
                let len = force_len - last;
                return self.next_op_before(Some(len));
            }
        }
        return find_op;
    }

    pub fn has_next(&self) -> bool { self.next_iter_op().is_some() }

    fn descend(&mut self, index: usize) {
        self.next_iv.start += index;

        if self.iter_char_count >= self.next_iv.start {
            return;
        }
        while let Some((o_index, op)) = self.iter.next() {
            self.iter_op_index = o_index;
            let start = self.iter_char_count;
            let end = start + op.length();
            let intersect = Interval::new(start, end).intersect(self.next_iv);
            if intersect.is_empty() {
                self.iter_char_count += op.length();
            } else {
                self.next_op = Some(op.clone());
                break;
            }
        }
    }

    pub fn next_iter_op(&self) -> Option<&Operation> {
        let mut next_op = self.next_op.as_ref();
        if next_op.is_none() {
            let mut offset = 0;
            for op in &self.delta.ops {
                offset += op.length();
                if offset > self.iter_char_count {
                    next_op = Some(op);
                    break;
                }
            }
        }
        next_op
    }

    fn next_op_iv_before(&self, b_index: Option<usize>) -> Interval {
        let next_op = self.next_iter_op();
        if next_op.is_none() {
            return Interval::new(0, 0);
        }

        let op = next_op.unwrap();
        let start = self.iter_char_count;
        let end = match b_index {
            None => self.iter_char_count + op.length(),
            Some(b_index) => self.iter_char_count + min(b_index, op.length()),
        };
        let intersect = Interval::new(start, end).intersect(self.next_iv);
        let interval = intersect.translate_neg(start);
        interval
    }
}

fn find_next_op<'a>(cursor: &mut Cursor<'a>) -> Option<&'a Operation> {
    match cursor.iter.next() {
        None => None,
        Some((o_index, op)) => {
            cursor.iter_op_index = o_index;
            Some(op)
        },
    }
}

type SeekResult = Result<(), OTError>;
pub trait Metric {
    fn seek(cursor: &mut Cursor, index: usize) -> SeekResult;
}

pub struct OpMetric {}

impl Metric for OpMetric {
    fn seek(cursor: &mut Cursor, index: usize) -> SeekResult {
        let _ = check_bound(cursor.iter_op_index, index)?;
        let mut temp_cursor = Cursor::new(cursor.delta, cursor.origin_iv);
        let mut offset = 0;
        while let Some((_, op)) = temp_cursor.iter.next() {
            offset += op.length();
            if offset > index {
                break;
            }
        }
        cursor.descend(offset);
        Ok(())
    }
}

pub struct CharMetric {}

impl Metric for CharMetric {
    fn seek(cursor: &mut Cursor, index: usize) -> SeekResult {
        let _ = check_bound(cursor.iter_char_count, index)?;
        let _ = cursor.next_op_before(Some(index));

        Ok(())
    }
}

fn check_bound(current: usize, target: usize) -> Result<(), OTError> {
    if current > target {
        let msg = format!("{} should be greater than current: {}", target, current);
        return Err(ErrorBuilder::new(OTErrorCode::IncompatibleLength)
            .msg(&msg)
            .build());
    }
    Ok(())
}
