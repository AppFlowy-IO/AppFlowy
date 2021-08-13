use crate::{
    core::{attributes::*, operation::*, DeltaIter, Interval},
    errors::{ErrorBuilder, OTError, OTErrorCode},
};
use bytecount::num_chars;
use std::{
    cmp::{min, Ordering},
    fmt,
    iter::FromIterator,
    str::FromStr,
};

#[derive(Clone, Debug, PartialEq)]
pub struct Delta {
    pub ops: Vec<Operation>,
    pub base_len: usize,
    pub target_len: usize,
}

impl Default for Delta {
    fn default() -> Self {
        Self {
            ops: Vec::new(),
            base_len: 0,
            target_len: 0,
        }
    }
}

impl FromStr for Delta {
    type Err = ();

    fn from_str(s: &str) -> Result<Delta, Self::Err> {
        let mut delta = Delta::with_capacity(1);
        delta.add(Operation::Insert(s.into()));
        Ok(delta)
    }
}

impl<T: AsRef<str>> From<T> for Delta {
    fn from(s: T) -> Delta { Delta::from_str(s.as_ref()).unwrap() }
}

impl fmt::Display for Delta {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        // f.write_str(&serde_json::to_string(self).unwrap_or("".to_owned()))?;
        f.write_str("[ ")?;
        for op in &self.ops {
            f.write_fmt(format_args!("{} ", op))?;
        }
        f.write_str("]")?;
        Ok(())
    }
}

impl FromIterator<Operation> for Delta {
    fn from_iter<T: IntoIterator<Item = Operation>>(ops: T) -> Self {
        let mut operations = Delta::default();
        for op in ops {
            operations.add(op);
        }
        operations
    }
}

impl Delta {
    pub fn new() -> Self { Self::default() }

    #[inline]
    pub fn with_capacity(capacity: usize) -> Self {
        Self {
            ops: Vec::with_capacity(capacity),
            base_len: 0,
            target_len: 0,
        }
    }

    pub fn add(&mut self, op: Operation) {
        match op {
            Operation::Delete(i) => self.delete(i),
            Operation::Insert(i) => self.insert(&i.s, i.attributes),
            Operation::Retain(r) => self.retain(r.n, r.attributes),
        }
    }

    pub fn delete(&mut self, n: usize) {
        if n == 0 {
            return;
        }
        self.base_len += n as usize;
        if let Some(Operation::Delete(n_last)) = self.ops.last_mut() {
            *n_last += n;
        } else {
            self.ops.push(OpBuilder::delete(n).build());
        }
    }

    pub fn insert(&mut self, s: &str, attrs: Attributes) {
        if s.is_empty() {
            return;
        }

        self.target_len += num_chars(s.as_bytes());
        let new_last = match self.ops.as_mut_slice() {
            [.., Operation::Insert(insert)] => {
                //
                insert.merge_or_new_op(s, attrs)
            },
            [.., Operation::Insert(pre_insert), Operation::Delete(_)] => {
                //
                pre_insert.merge_or_new_op(s, attrs)
            },
            [.., op_last @ Operation::Delete(_)] => {
                let new_last = op_last.clone();
                *op_last = OpBuilder::insert(s).attributes(attrs).build();
                Some(new_last)
            },
            _ => Some(OpBuilder::insert(s).attributes(attrs).build()),
        };

        match new_last {
            None => {},
            Some(new_last) => self.ops.push(new_last),
        }
    }

    pub fn retain(&mut self, n: usize, attrs: Attributes) {
        if n == 0 {
            return;
        }
        self.base_len += n as usize;
        self.target_len += n as usize;

        if let Some(Operation::Retain(retain)) = self.ops.last_mut() {
            if let Some(new_op) = retain.merge_or_new_op(n, attrs) {
                self.ops.push(new_op);
            }
        } else {
            self.ops
                .push(OpBuilder::retain(n).attributes(attrs).build());
        }
    }

    pub fn compose2(&self, other: &Self) -> Result<Self, OTError> {
        let mut new_delta = Delta::default();
        let mut iter_1 = DeltaIter::new(self);
        let mut iter_2 = DeltaIter::new(other);

        while iter_1.has_next() || iter_2.has_next() {
            if iter_2.is_next_insert() {
                new_delta.add(iter_2.next_op().unwrap());
                continue;
            }

            if iter_1.is_next_Delete() {
                new_delta.add(iter_1.next_op().unwrap());
                continue;
            }

            let length = min(iter_1.next_op_len(), iter_2.next_op_len());
            let op1 = iter_1
                .next_op_with_len(length)
                .unwrap_or(OpBuilder::retain(length).build());
            let op2 = iter_2
                .next_op_with_len(length)
                .unwrap_or(OpBuilder::retain(length).build());

            debug_assert!(op1.length())
        }

        Ok(new_delta)
    }

    /// Merges the operation with `other` into one operation while preserving
    /// the changes of both. Or, in other words, for each input string S and a
    /// pair of consecutive operations A and B.
    ///     `apply(apply(S, A), B) = apply(S, compose(A, B))`
    /// must hold.
    ///
    /// # Error
    ///
    /// Returns an `OTError` if the operations are not composable due to length
    /// conflicts.
    pub fn compose(&self, other: &Self) -> Result<Self, OTError> {
        if self.target_len != other.base_len {
            return Err(ErrorBuilder::new(OTErrorCode::IncompatibleLength).build());
        }

        let mut new_delta = Delta::default();
        let mut ops1 = self.ops.iter().cloned();
        let mut ops2 = other.ops.iter().cloned();

        let mut next_op1 = ops1.next();
        let mut next_op2 = ops2.next();
        loop {
            match (&next_op1, &next_op2) {
                (None, None) => break,
                (Some(Operation::Delete(i)), _) => {
                    new_delta.delete(*i);
                    next_op1 = ops1.next();
                },
                (_, Some(Operation::Insert(o_insert))) => {
                    new_delta.insert(&o_insert.s, o_insert.attributes.clone());
                    next_op2 = ops2.next();
                },
                (None, _) | (_, None) => {
                    return Err(ErrorBuilder::new(OTErrorCode::IncompatibleLength).build());
                },
                (Some(Operation::Retain(retain)), Some(Operation::Retain(o_retain))) => {
                    let composed_attrs = compose_operation(&next_op1, &next_op2);
                    log::debug!(
                        "[retain:{} - retain:{}]: {:?}",
                        retain.n,
                        o_retain.n,
                        composed_attrs
                    );
                    match retain.cmp(&o_retain) {
                        Ordering::Less => {
                            new_delta.retain(retain.n, composed_attrs);
                            next_op2 = Some(
                                OpBuilder::retain(o_retain.n - retain.n)
                                    .attributes(o_retain.attributes.clone())
                                    .build(),
                            );
                            next_op1 = ops1.next();
                        },
                        std::cmp::Ordering::Equal => {
                            new_delta.retain(retain.n, composed_attrs);
                            next_op1 = ops1.next();
                            next_op2 = ops2.next();
                        },
                        std::cmp::Ordering::Greater => {
                            new_delta.retain(o_retain.n, composed_attrs);
                            next_op1 = Some(OpBuilder::retain(retain.n - o_retain.n).build());
                            next_op2 = ops2.next();
                        },
                    }
                },
                (Some(Operation::Insert(insert)), Some(Operation::Delete(o_num))) => {
                    match (num_chars(insert.as_bytes()) as usize).cmp(o_num) {
                        Ordering::Less => {
                            next_op2 = Some(
                                OpBuilder::delete(*o_num - num_chars(insert.as_bytes()) as usize)
                                    .attributes(insert.attributes.clone())
                                    .build(),
                            );
                            next_op1 = ops1.next();
                        },
                        Ordering::Equal => {
                            next_op1 = ops1.next();
                            next_op2 = ops2.next();
                        },
                        Ordering::Greater => {
                            next_op1 = Some(
                                OpBuilder::insert(
                                    &insert.chars().skip(*o_num as usize).collect::<String>(),
                                )
                                .build(),
                            );
                            next_op2 = ops2.next();
                        },
                    }
                },
                (Some(Operation::Insert(insert)), Some(Operation::Retain(o_retain))) => {
                    let mut composed_attrs = compose_operation(&next_op1, &next_op2);
                    composed_attrs = composed_attrs.remove_empty();

                    log::debug!(
                        "compose: [{} - {}], composed_attrs: {}",
                        insert,
                        o_retain,
                        composed_attrs
                    );
                    match (insert.num_chars()).cmp(o_retain) {
                        Ordering::Less => {
                            new_delta.insert(&insert.s, composed_attrs.clone());
                            next_op2 = Some(
                                OpBuilder::retain(o_retain.n - insert.num_chars())
                                    .attributes(o_retain.attributes.clone())
                                    .build(),
                            );
                            next_op1 = ops1.next();
                        },
                        Ordering::Equal => {
                            new_delta.insert(&insert.s, composed_attrs);
                            next_op1 = ops1.next();
                            next_op2 = ops2.next();
                        },
                        Ordering::Greater => {
                            let chars = &mut insert.chars();
                            new_delta.insert(
                                &chars.take(o_retain.n as usize).collect::<String>(),
                                composed_attrs,
                            );
                            next_op1 = Some(OpBuilder::insert(&chars.collect::<String>()).build());
                            next_op2 = ops2.next();
                        },
                    }
                },
                (Some(Operation::Retain(retain)), Some(Operation::Delete(o_num))) => {
                    match retain.cmp(&o_num) {
                        Ordering::Less => {
                            new_delta.delete(retain.n);
                            next_op2 = Some(OpBuilder::delete(*o_num - retain.n).build());
                            next_op1 = ops1.next();
                        },
                        Ordering::Equal => {
                            new_delta.delete(*o_num);
                            next_op2 = ops2.next();
                            next_op1 = ops1.next();
                        },
                        Ordering::Greater => {
                            new_delta.delete(*o_num);
                            next_op1 = Some(OpBuilder::retain(retain.n - *o_num).build());
                            next_op2 = ops2.next();
                        },
                    }
                },
            };
        }
        Ok(new_delta)
    }

    /// Transforms two operations A and B that happened concurrently and
    /// produces two operations A' and B' (in an array) such that
    ///     `apply(apply(S, A), B') = apply(apply(S, B), A')`.
    /// This function is the heart of OT.
    ///
    /// # Error
    ///
    /// Returns an `OTError` if the operations cannot be transformed due to
    /// length conflicts.
    pub fn transform(&self, other: &Self) -> Result<(Self, Self), OTError> {
        if self.base_len != other.base_len {
            return Err(ErrorBuilder::new(OTErrorCode::IncompatibleLength).build());
        }

        let mut a_prime = Delta::default();
        let mut b_prime = Delta::default();

        let mut ops1 = self.ops.iter().cloned();
        let mut ops2 = other.ops.iter().cloned();

        let mut next_op1 = ops1.next();
        let mut next_op2 = ops2.next();
        loop {
            match (&next_op1, &next_op2) {
                (None, None) => break,
                (Some(Operation::Insert(insert)), _) => {
                    // let composed_attrs = transform_attributes(&next_op1, &next_op2, true);
                    a_prime.insert(&insert.s, insert.attributes.clone());
                    b_prime.retain(insert.num_chars(), insert.attributes.clone());
                    next_op1 = ops1.next();
                },
                (_, Some(Operation::Insert(o_insert))) => {
                    let composed_attrs = transform_operation(&next_op1, &next_op2);
                    a_prime.retain(o_insert.num_chars(), composed_attrs.clone());
                    b_prime.insert(&o_insert.s, composed_attrs);
                    next_op2 = ops2.next();
                },
                (None, _) => {
                    return Err(ErrorBuilder::new(OTErrorCode::IncompatibleLength).build());
                },
                (_, None) => {
                    return Err(ErrorBuilder::new(OTErrorCode::IncompatibleLength).build());
                },
                (Some(Operation::Retain(retain)), Some(Operation::Retain(o_retain))) => {
                    let composed_attrs = transform_operation(&next_op1, &next_op2);
                    match retain.cmp(&o_retain) {
                        Ordering::Less => {
                            a_prime.retain(retain.n, composed_attrs.clone());
                            b_prime.retain(retain.n, composed_attrs.clone());
                            next_op2 = Some(OpBuilder::retain(o_retain.n - retain.n).build());
                            next_op1 = ops1.next();
                        },
                        Ordering::Equal => {
                            a_prime.retain(retain.n, composed_attrs.clone());
                            b_prime.retain(retain.n, composed_attrs.clone());
                            next_op1 = ops1.next();
                            next_op2 = ops2.next();
                        },
                        Ordering::Greater => {
                            a_prime.retain(o_retain.n, composed_attrs.clone());
                            b_prime.retain(o_retain.n, composed_attrs.clone());
                            next_op1 = Some(OpBuilder::retain(retain.n - o_retain.n).build());
                            next_op2 = ops2.next();
                        },
                    };
                },
                (Some(Operation::Delete(i)), Some(Operation::Delete(j))) => match i.cmp(&j) {
                    Ordering::Less => {
                        next_op2 = Some(OpBuilder::delete(*j - *i).build());
                        next_op1 = ops1.next();
                    },
                    Ordering::Equal => {
                        next_op1 = ops1.next();
                        next_op2 = ops2.next();
                    },
                    Ordering::Greater => {
                        next_op1 = Some(OpBuilder::delete(*i - *j).build());
                        next_op2 = ops2.next();
                    },
                },
                (Some(Operation::Delete(i)), Some(Operation::Retain(o_retain))) => {
                    match i.cmp(&o_retain) {
                        Ordering::Less => {
                            a_prime.delete(*i);
                            next_op2 = Some(OpBuilder::retain(o_retain.n - *i).build());
                            next_op1 = ops1.next();
                        },
                        Ordering::Equal => {
                            a_prime.delete(*i);
                            next_op1 = ops1.next();
                            next_op2 = ops2.next();
                        },
                        Ordering::Greater => {
                            a_prime.delete(o_retain.n);
                            next_op1 = Some(OpBuilder::delete(*i - o_retain.n).build());
                            next_op2 = ops2.next();
                        },
                    };
                },
                (Some(Operation::Retain(retain)), Some(Operation::Delete(j))) => {
                    match retain.cmp(&j) {
                        Ordering::Less => {
                            b_prime.delete(retain.n);
                            next_op2 = Some(OpBuilder::delete(*j - retain.n).build());
                            next_op1 = ops1.next();
                        },
                        Ordering::Equal => {
                            b_prime.delete(retain.n);
                            next_op1 = ops1.next();
                            next_op2 = ops2.next();
                        },
                        Ordering::Greater => {
                            b_prime.delete(*j);
                            next_op1 = Some(OpBuilder::retain(retain.n - *j).build());
                            next_op2 = ops2.next();
                        },
                    };
                },
            }
        }

        Ok((a_prime, b_prime))
    }

    /// Applies an operation to a string, returning a new string.
    ///
    /// # Error
    ///
    /// Returns an error if the operation cannot be applied due to length
    /// conflicts.
    pub fn apply(&self, s: &str) -> Result<String, OTError> {
        if num_chars(s.as_bytes()) != self.base_len {
            return Err(ErrorBuilder::new(OTErrorCode::IncompatibleLength).build());
        }
        let mut new_s = String::new();
        let chars = &mut s.chars();
        for op in &self.ops {
            match &op {
                Operation::Retain(retain) => {
                    for c in chars.take(retain.n as usize) {
                        new_s.push(c);
                    }
                },
                Operation::Delete(delete) => {
                    for _ in 0..*delete {
                        chars.next();
                    }
                },
                Operation::Insert(insert) => {
                    new_s += &insert.s;
                },
            }
        }
        Ok(new_s)
    }

    /// Computes the inverse of an operation. The inverse of an operation is the
    /// operation that reverts the effects of the operation
    pub fn invert_str(&self, s: &str) -> Self {
        let mut inverted = Delta::default();
        let chars = &mut s.chars();
        for op in &self.ops {
            match &op {
                Operation::Retain(retain) => {
                    inverted.retain(retain.n, Attributes::default());

                    // TODO: use advance_by instead, but it's unstable now
                    // chars.advance_by(retain.num)
                    for _ in 0..retain.n {
                        chars.next();
                    }
                },
                Operation::Insert(insert) => {
                    inverted.delete(insert.num_chars());
                },
                Operation::Delete(delete) => {
                    inverted.insert(
                        &chars.take(*delete as usize).collect::<String>(),
                        op.get_attributes(),
                    );
                },
            }
        }
        inverted
    }

    pub fn invert(&self, other: &Delta) -> Delta {
        let mut inverted = Delta::default();
        if other.is_empty() {
            return inverted;
        }
        log::debug!("🌜Calculate invert delta");
        log::debug!("current: {}", self);
        log::debug!("other: {}", other);
        let mut index = 0;
        for op in &self.ops {
            let len: usize = op.length() as usize;
            match op {
                Operation::Delete(n) => {
                    invert_from_other(&mut inverted, other, op, index, index + *n);
                    index += len;
                },
                Operation::Retain(_) => {
                    match op.has_attribute() {
                        true => invert_from_other(&mut inverted, other, op, index, index + len),
                        false => {
                            log::debug!(
                                "invert retain: {} by retain {} {}",
                                op,
                                len,
                                op.get_attributes()
                            );
                            inverted.retain(len as usize, op.get_attributes())
                        },
                    }
                    index += len;
                },
                Operation::Insert(_) => {
                    log::debug!("invert insert: {} by delete {}", op, len);
                    inverted.delete(len as usize);
                },
            }
        }

        log::debug!("🌛invert result: {}", inverted);
        inverted
    }

    /// Checks if this operation has no effect.
    #[inline]
    pub fn is_noop(&self) -> bool {
        match self.ops.as_slice() {
            [] => true,
            [Operation::Retain(_)] => true,
            _ => false,
        }
    }

    pub fn is_empty(&self) -> bool { self.ops.is_empty() }

    pub fn to_json(&self) -> String { serde_json::to_string(self).unwrap_or("".to_owned()) }
}

fn invert_from_other(
    base: &mut Delta,
    other: &Delta,
    operation: &Operation,
    start: usize,
    end: usize,
) {
    log::debug!("invert op: {} [{}:{}]", operation, start, end);
    let other_ops = DeltaIter::from_interval(other, Interval::new(start, end)).ops();
    other_ops.into_iter().for_each(|other_op| match operation {
        Operation::Delete(n) => {
            log::debug!("invert delete: {} by add {}", n, other_op);
            base.add(other_op);
        },
        Operation::Retain(retain) => {
            log::debug!(
                "invert attributes: {:?}, {:?}",
                operation.get_attributes(),
                other_op.get_attributes()
            );
            let inverted_attrs =
                invert_attributes(operation.get_attributes(), other_op.get_attributes());
            log::debug!("invert result: {:?}", inverted_attrs);
            log::debug!(
                "invert retain: {} by retain len: {}, {}",
                retain,
                other_op.length(),
                inverted_attrs
            );
            base.retain(other_op.length(), inverted_attrs);
        },
        Operation::Insert(_) => {
            log::error!("Impossible to here. Insert operation should be treated as delete")
        },
    });
}
