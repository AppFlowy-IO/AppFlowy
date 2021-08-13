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
    pub(crate) c_index: usize,
    pub(crate) o_index: usize,
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
            c_index: 0,
            o_index: 0,
            iter: delta.ops.iter().enumerate(),
            next_op: None,
        };
        cursor.descend(0);
        cursor
    }

    fn descend(&mut self, index: usize) {
        self.next_iv.start += index;

        if self.c_index >= self.next_iv.start {
            return;
        }
        while let Some((o_index, op)) = self.iter.next() {
            self.o_index = o_index;
            let start = self.c_index;
            let end = start + op.length();
            let intersect = Interval::new(start, end).intersect(self.next_iv);
            if intersect.is_empty() {
                self.c_index += op.length();
            } else {
                self.next_op = Some(op.clone());
                break;
            }
        }
    }

    pub fn next_interval(&self) -> Interval { self.next_op_interval_with_len(None) }

    fn next_op_interval_with_len(&self, force_len: Option<usize>) -> Interval {
        let op = self
            .next_op
            .as_ref()
            .unwrap_or(&self.delta.ops[self.o_index]);

        let start = self.c_index;
        let end = match force_len {
            None => self.c_index + op.length(),
            Some(force_len) => self.c_index + min(force_len, op.length()),
        };
        let intersect = Interval::new(start, end).intersect(self.next_iv);
        let interval = intersect.translate_neg(start);
        interval
    }

    pub fn next_op_with_len(&mut self, force_len: Option<usize>) -> Option<Operation> {
        let mut find_op = None;
        let next_op = self.next_op.take();
        let mut next_op = next_op.as_ref();

        if next_op.is_none() {
            next_op = find_next_op(self);
        }

        while find_op.is_none() && next_op.is_some() {
            let op = next_op.take().unwrap();
            let interval = self.next_op_interval_with_len(force_len);
            find_op = op.shrink(interval);

            let suffix = Interval::new(0, op.length()).suffix(interval);
            if !suffix.is_empty() {
                self.next_op = op.shrink(suffix);
            }

            self.c_index += interval.end;
            self.next_iv.start = self.c_index;

            if find_op.is_none() {
                next_op = find_next_op(self);
            }
        }

        find_op
    }

    pub fn next_op(&mut self) -> Option<Operation> { self.next_op_with_len(None) }

    pub fn has_next(&self) -> bool { self.c_index < self.next_iv.end }
}

fn find_next_op<'a>(cursor: &mut Cursor<'a>) -> Option<&'a Operation> {
    match cursor.iter.next() {
        None => None,
        Some((o_index, op)) => {
            cursor.o_index = o_index;
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
        let _ = check_bound(cursor.o_index, index)?;
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
        let _ = check_bound(cursor.c_index, index)?;
        let _ = cursor.next_op_with_len(Some(index));
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
