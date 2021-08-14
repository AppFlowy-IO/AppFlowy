use super::cursor::*;
use crate::{
    core::{Attributes, Delta, Interval, Operation},
    errors::OTError,
};
use std::ops::{Deref, DerefMut};

pub(crate) const MAX_IV_LEN: usize = i32::MAX as usize;

pub struct DeltaIter<'a> {
    cursor: Cursor<'a>,
    interval: Interval,
}

impl<'a> DeltaIter<'a> {
    pub fn new(delta: &'a Delta) -> Self {
        let interval = Interval::new(0, MAX_IV_LEN);
        Self::from_interval(delta, interval)
    }

    pub fn from_interval(delta: &'a Delta, interval: Interval) -> Self {
        let cursor = Cursor::new(delta, interval);
        Self { cursor, interval }
    }

    pub fn ops(&mut self) -> Vec<Operation> { self.collect::<Vec<_>>() }

    pub fn next_op(&mut self) -> Option<Operation> { self.cursor.next_op() }

    pub fn next_op_len(&self) -> Option<usize> {
        let interval = self.cursor.next_interval();
        if interval.is_empty() {
            None
        } else {
            Some(interval.size())
        }
    }

    pub fn next_op_with_len(&mut self, length: usize) -> Option<Operation> {
        self.cursor.next_op_with_len(Some(length))
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
        let next_op = self.delta_iter.next();
        if next_op.is_none() {
            return None;
        }
        let mut length: usize = 0;
        let mut attributes = Attributes::new();

        match next_op.unwrap() {
            Operation::Delete(_n) => {},
            Operation::Retain(retain) => {
                log::debug!("extend retain attributes with {} ", &retain.attributes);
                attributes.extend(retain.attributes.clone());

                length = retain.n;
            },
            Operation::Insert(insert) => {
                log::debug!("extend insert attributes with {} ", &insert.attributes);
                attributes.extend(insert.attributes.clone());
                length = insert.num_chars();
            },
        }

        Some((length, attributes))
    }
}
