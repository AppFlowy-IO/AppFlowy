use super::cursor::*;
use crate::core::{Attributes, Delta, Interval, Operation, NEW_LINE};
use std::ops::{Deref, DerefMut};

pub(crate) const MAX_IV_LEN: usize = i32::MAX as usize;

pub struct DeltaIter<'a> {
    cursor: OpCursor<'a>,
}

impl<'a> DeltaIter<'a> {
    pub fn new(delta: &'a Delta) -> Self {
        let interval = Interval::new(0, MAX_IV_LEN);
        Self::from_interval(delta, interval)
    }

    pub fn from_offset(delta: &'a Delta, offset: usize) -> Self {
        let interval = Interval::new(0, MAX_IV_LEN);
        let mut iter = Self::from_interval(delta, interval);
        iter.seek::<CharMetric>(offset);
        iter
    }

    pub fn from_interval(delta: &'a Delta, interval: Interval) -> Self {
        let cursor = OpCursor::new(delta, interval);
        Self { cursor }
    }

    pub fn ops(&mut self) -> Vec<Operation> { self.collect::<Vec<_>>() }

    pub fn next_op_len(&self) -> Option<usize> {
        let interval = self.cursor.next_iv();
        if interval.is_empty() {
            None
        } else {
            Some(interval.size())
        }
    }

    pub fn next_op(&mut self) -> Option<Operation> { self.cursor.next() }

    pub fn next_op_with_len(&mut self, len: usize) -> Option<Operation> { self.cursor.next_with_len(Some(len)) }

    // find next op contains NEW_LINE
    pub fn next_op_with_newline(&mut self) -> Option<(Operation, usize)> {
        let mut offset = 0;
        while self.has_next() {
            if let Some(op) = self.next_op() {
                if OpNewline::parse(&op).is_contain() {
                    return Some((op, offset));
                }
                offset += op.len();
            }
        }

        None
    }

    pub fn seek<M: Metric>(&mut self, index: usize) {
        match M::seek(&mut self.cursor, index) {
            Ok(_) => {},
            Err(e) => log::error!("Seek fail: {:?}", e),
        }
    }

    pub fn has_next(&self) -> bool { self.cursor.has_next() }

    pub fn is_next_insert(&self) -> bool {
        match self.cursor.next_iter_op() {
            None => false,
            Some(op) => op.is_insert(),
        }
    }

    pub fn is_next_retain(&self) -> bool {
        match self.cursor.next_iter_op() {
            None => false,
            Some(op) => op.is_retain(),
        }
    }

    pub fn is_next_delete(&self) -> bool {
        match self.cursor.next_iter_op() {
            None => false,
            Some(op) => op.is_delete(),
        }
    }
}

impl<'a> Iterator for DeltaIter<'a> {
    type Item = Operation;
    fn next(&mut self) -> Option<Self::Item> { self.next_op() }
}

pub fn is_empty_line_at_index(delta: &Delta, index: usize) -> bool {
    let mut iter = DeltaIter::new(delta);
    let (prev, next) = (iter.next_op_with_len(index), iter.next_op());
    if prev.is_none() {
        return true;
    }

    if next.is_none() {
        return false;
    }

    let prev = prev.unwrap();
    let next = next.unwrap();
    OpNewline::parse(&prev).is_end() && OpNewline::parse(&next).is_start()
}

pub struct AttributesIter<'a> {
    delta_iter: DeltaIter<'a>,
}

impl<'a> AttributesIter<'a> {
    pub fn new(delta: &'a Delta) -> Self {
        let interval = Interval::new(0, usize::MAX);
        Self::from_interval(delta, interval)
    }

    pub fn from_interval(delta: &'a Delta, interval: Interval) -> Self {
        let delta_iter = DeltaIter::from_interval(delta, interval);
        Self { delta_iter }
    }

    pub fn next_or_empty(&mut self) -> Attributes {
        match self.next() {
            None => Attributes::default(),
            Some((_, attributes)) => attributes,
        }
    }
}

impl<'a> Deref for AttributesIter<'a> {
    type Target = DeltaIter<'a>;

    fn deref(&self) -> &Self::Target { &self.delta_iter }
}

impl<'a> DerefMut for AttributesIter<'a> {
    fn deref_mut(&mut self) -> &mut Self::Target { &mut self.delta_iter }
}

impl<'a> Iterator for AttributesIter<'a> {
    type Item = (usize, Attributes);
    fn next(&mut self) -> Option<Self::Item> {
        let next_op = self.delta_iter.next_op();
        if next_op.is_none() {
            return None;
        }
        let mut length: usize = 0;
        let mut attributes = Attributes::new();

        match next_op.unwrap() {
            Operation::Delete(_n) => {},
            Operation::Retain(retain) => {
                log::trace!("extend retain attributes with {} ", &retain.attributes);
                attributes.extend(retain.attributes.clone());

                length = retain.n;
            },
            Operation::Insert(insert) => {
                log::trace!("extend insert attributes with {} ", &insert.attributes);
                attributes.extend(insert.attributes.clone());
                length = insert.num_chars();
            },
        }

        Some((length, attributes))
    }
}

#[derive(PartialEq, Eq)]
pub enum OpNewline {
    Start,
    End,
    Contain,
    Equal,
    NotFound,
}

impl OpNewline {
    pub fn parse(op: &Operation) -> OpNewline {
        let s = op.get_data();

        if s == NEW_LINE {
            return OpNewline::Equal;
        }

        if s.starts_with(NEW_LINE) {
            return OpNewline::Start;
        }

        if s.ends_with(NEW_LINE) {
            return OpNewline::End;
        }

        if s.contains(NEW_LINE) {
            return OpNewline::Contain;
        }

        OpNewline::NotFound
    }

    pub fn is_start(&self) -> bool { self == &OpNewline::Start || self.is_equal() }

    pub fn is_end(&self) -> bool { self == &OpNewline::End || self.is_equal() }

    pub fn is_not_found(&self) -> bool { self == &OpNewline::NotFound }

    pub fn is_contain(&self) -> bool { self.is_start() || self.is_end() || self.is_equal() || self == &OpNewline::Contain }

    pub fn is_equal(&self) -> bool { self == &OpNewline::Equal }
}
