use crate::{attributes::*, errors::OTError, operation::*};
use bytecount::num_chars;
use std::{cmp::Ordering, error::Error, fmt, iter::FromIterator, str::FromStr};

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
    #[inline]
    pub fn with_capacity(capacity: usize) -> Self {
        Self {
            ops: Vec::with_capacity(capacity),
            base_len: 0,
            target_len: 0,
        }
    }

    fn add(&mut self, op: Operation) {
        match op {
            Operation::Delete(i) => self.delete(i),
            Operation::Insert(i) => self.insert(&i.s, i.attrs),
            Operation::Retain(r) => self.retain(r.n, r.attrs),
        }
    }

    pub fn delete(&mut self, n: u64) {
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

    pub fn insert(&mut self, s: &str, attrs: Option<Attributes>) {
        if s.is_empty() {
            return;
        }
        self.target_len += num_chars(s.as_bytes());

        let new_last = match self.ops.as_mut_slice() {
            [.., Operation::Insert(s_last)] => {
                s_last.s += &s;
                return;
            },
            [.., Operation::Insert(s_pre_last), Operation::Delete(_)] => {
                s_pre_last.s += s;
                return;
            },
            [.., op_last @ Operation::Delete(_)] => {
                let new_last = op_last.clone();
                *op_last = Operation::Insert(s.into());
                new_last
            },
            _ => Operation::Insert(s.into()),
        };
        self.ops
            .push(OpBuilder::new(new_last).with_attrs(attrs).build());
    }

    pub fn retain(&mut self, n: u64, attrs: Option<Attributes>) {
        if n == 0 {
            return;
        }
        self.base_len += n as usize;
        self.target_len += n as usize;

        if let Some(Operation::Retain(i_last)) = self.ops.last_mut() {
            i_last.n += n;
            i_last.attrs = attrs;
        } else {
            self.ops
                .push(OpBuilder::retain(n).with_attrs(attrs).build());
        }
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
            return Err(OTError);
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
                (_, Some(Operation::Insert(insert))) => {
                    new_delta.insert(&insert.s, get_attrs(&next_op2));
                    next_op2 = ops2.next();
                },
                (None, _) | (_, None) => {
                    return Err(OTError);
                },
                (Some(Operation::Retain(i)), Some(Operation::Retain(j))) => {
                    let new_attrs =
                        compose_attributes(get_attrs(&next_op1), get_attrs(&next_op2), true);
                    match i.cmp(&j) {
                        Ordering::Less => {
                            new_delta.retain(i.n, new_attrs);
                            next_op2 = Some(OpBuilder::retain(j.n - i.n).build());
                            next_op1 = ops1.next();
                        },
                        std::cmp::Ordering::Equal => {
                            new_delta.retain(i.n, new_attrs);
                            next_op1 = ops1.next();
                            next_op2 = ops2.next();
                        },
                        std::cmp::Ordering::Greater => {
                            new_delta.retain(j.n, new_attrs);
                            next_op1 = Some(OpBuilder::retain(i.n - j.n).build());
                            next_op2 = ops2.next();
                        },
                    }
                },
                (Some(Operation::Insert(insert)), Some(Operation::Delete(j))) => {
                    match (num_chars(insert.as_bytes()) as u64).cmp(j) {
                        Ordering::Less => {
                            next_op2 = Some(
                                OpBuilder::delete(*j - num_chars(insert.as_bytes()) as u64).build(),
                            );
                            next_op1 = ops1.next();
                        },
                        Ordering::Equal => {
                            next_op1 = ops1.next();
                            next_op2 = ops2.next();
                        },
                        Ordering::Greater => {
                            next_op1 = Some(
                                OpBuilder::insert(insert.chars().skip(*j as usize).collect())
                                    .build(),
                            );
                            next_op2 = ops2.next();
                        },
                    }
                },
                (Some(Operation::Insert(insert)), Some(Operation::Retain(j))) => {
                    let new_attrs =
                        compose_attributes(get_attrs(&next_op1), get_attrs(&next_op2), false);
                    match (insert.num_chars()).cmp(j) {
                        Ordering::Less => {
                            new_delta.insert(&insert.s, new_attrs);
                            next_op2 = Some(OpBuilder::retain(j.n - insert.num_chars()).build());
                            next_op1 = ops1.next();
                        },
                        Ordering::Equal => {
                            new_delta.insert(&insert.s, new_attrs);
                            next_op1 = ops1.next();
                            next_op2 = ops2.next();
                        },
                        Ordering::Greater => {
                            let chars = &mut insert.chars();
                            new_delta
                                .insert(&chars.take(j.n as usize).collect::<String>(), new_attrs);
                            next_op1 = Some(OpBuilder::insert(chars.collect()).build());
                            next_op2 = ops2.next();
                        },
                    }
                },
                (Some(Operation::Retain(i)), Some(Operation::Delete(j))) => match i.cmp(&j) {
                    Ordering::Less => {
                        new_delta.delete(i.n);
                        next_op2 = Some(OpBuilder::delete(*j - i.n).build());
                        next_op1 = ops1.next();
                    },
                    Ordering::Equal => {
                        new_delta.delete(*j);
                        next_op2 = ops2.next();
                        next_op1 = ops1.next();
                    },
                    Ordering::Greater => {
                        new_delta.delete(*j);
                        next_op1 = Some(OpBuilder::retain(i.n - *j).build());
                        next_op2 = ops2.next();
                    },
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
            return Err(OTError);
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
                    let new_attrs =
                        compose_attributes(get_attrs(&next_op1), get_attrs(&next_op2), true);
                    a_prime.insert(&insert.s, new_attrs.clone());
                    b_prime.retain(insert.num_chars(), new_attrs.clone());
                    next_op1 = ops1.next();
                },
                (_, Some(Operation::Insert(insert))) => {
                    let new_attrs =
                        compose_attributes(get_attrs(&next_op1), get_attrs(&next_op2), true);
                    a_prime.retain(insert.num_chars(), new_attrs.clone());
                    b_prime.insert(&insert.s, new_attrs.clone());
                    next_op2 = ops2.next();
                },
                (None, _) => {
                    return Err(OTError);
                },
                (_, None) => {
                    return Err(OTError);
                },
                (Some(Operation::Retain(i)), Some(Operation::Retain(j))) => {
                    let new_attrs =
                        compose_attributes(get_attrs(&next_op1), get_attrs(&next_op2), true);
                    match i.cmp(&j) {
                        Ordering::Less => {
                            a_prime.retain(i.n, new_attrs.clone());
                            b_prime.retain(i.n, new_attrs.clone());
                            next_op2 = Some(OpBuilder::retain(j.n - i.n).build());
                            next_op1 = ops1.next();
                        },
                        Ordering::Equal => {
                            a_prime.retain(i.n, new_attrs.clone());
                            b_prime.retain(i.n, new_attrs.clone());
                            next_op1 = ops1.next();
                            next_op2 = ops2.next();
                        },
                        Ordering::Greater => {
                            a_prime.retain(j.n, new_attrs.clone());
                            b_prime.retain(j.n, new_attrs.clone());
                            next_op1 = Some(OpBuilder::retain(i.n - j.n).build());
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
                (Some(Operation::Delete(i)), Some(Operation::Retain(j))) => {
                    match i.cmp(&j) {
                        Ordering::Less => {
                            a_prime.delete(*i);
                            next_op2 = Some(OpBuilder::retain(j.n - *i).build());
                            next_op1 = ops1.next();
                        },
                        Ordering::Equal => {
                            a_prime.delete(*i);
                            next_op1 = ops1.next();
                            next_op2 = ops2.next();
                        },
                        Ordering::Greater => {
                            a_prime.delete(j.n);
                            next_op1 = Some(OpBuilder::delete(*i - j.n).build());
                            next_op2 = ops2.next();
                        },
                    };
                },
                (Some(Operation::Retain(i)), Some(Operation::Delete(j))) => {
                    match i.cmp(&j) {
                        Ordering::Less => {
                            b_prime.delete(i.n);
                            next_op2 = Some(OpBuilder::delete(*j - i.n).build());
                            next_op1 = ops1.next();
                        },
                        Ordering::Equal => {
                            b_prime.delete(i.n);
                            next_op1 = ops1.next();
                            next_op2 = ops2.next();
                        },
                        Ordering::Greater => {
                            b_prime.delete(*j);
                            next_op1 = Some(OpBuilder::retain(i.n - *j).build());
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
            return Err(OTError);
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
    pub fn invert(&self, s: &str) -> Self {
        let mut inverted = Delta::default();
        let chars = &mut s.chars();
        for op in &self.ops {
            match &op {
                Operation::Retain(retain) => {
                    inverted.retain(retain.n, None);
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
                        op.attrs(),
                    );
                },
            }
        }
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

    /// Returns the length of a string these operations can be applied to
    #[inline]
    pub fn base_len(&self) -> usize { self.base_len }

    /// Returns the length of the resulting string after the operations have
    /// been applied.
    #[inline]
    pub fn target_len(&self) -> usize { self.target_len }

    /// Returns the wrapped sequence of operations.
    #[inline]
    pub fn ops(&self) -> &[Operation] { &self.ops }

    pub fn is_empty(&self) -> bool { self.ops.is_empty() }
}

pub fn get_attrs(operation: &Option<Operation>) -> Option<Attributes> {
    match operation {
        None => None,
        Some(operation) => operation.attrs(),
    }
}
