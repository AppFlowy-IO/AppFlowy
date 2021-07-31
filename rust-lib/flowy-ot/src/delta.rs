use crate::{attributes::*, errors::OTError, operation::*};
use bytecount::num_chars;
use std::{cmp::Ordering, error::Error, fmt, iter::FromIterator};

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

// impl FromIterator<OpType> for Delta {
//     fn from_iter<T: IntoIterator<Item = OpType>>(ops: T) -> Self {
//         let mut operations = Delta::default();
//         for op in ops {
//             operations.add(op);
//         }
//         operations
//     }
// }

impl Delta {
    #[inline]
    pub fn with_capacity(capacity: usize) -> Self {
        Self {
            ops: Vec::with_capacity(capacity),
            base_len: 0,
            target_len: 0,
        }
    }

    // fn add(&mut self, op: OpType) {
    //     match op {
    //         OpType::Delete(i) => self.delete(i),
    //         OpType::Insert(s) => self.insert(&s),
    //         OpType::Retain(i) => self.retain(i),
    //     }
    // }

    pub fn delete(&mut self, n: u64) {
        if n == 0 {
            return;
        }
        self.base_len += n as usize;

        if let Some(operation) = self.ops.last_mut() {
            if operation.ty.is_delete() {
                operation.delete(n);
                return;
            }
        }

        self.ops.push(OperationBuilder::delete(n).build());
    }

    pub fn insert(&mut self, s: &str, attrs: Option<Attributes>) {
        if s.is_empty() {
            return;
        }
        self.target_len += num_chars(s.as_bytes());
        let new_last = match self
            .ops
            .iter_mut()
            .map(|op| &mut op.ty)
            .collect::<Vec<&mut OpType>>()
            .as_mut_slice()
        {
            [.., OpType::Insert(s_last)] => {
                *s_last += &s;
                return;
            },
            [.., OpType::Insert(s_pre_last), OpType::Delete(_)] => {
                *s_pre_last += s;
                return;
            },
            [.., op_last @ OpType::Delete(_)] => {
                let new_last = op_last.clone();
                *(*op_last) = OpType::Insert(s.to_owned());
                new_last
            },
            _ => OpType::Insert(s.to_owned()),
        };
        self.ops
            .push(OperationBuilder::new(new_last).with_attrs(attrs).build());
    }

    pub fn retain(&mut self, n: u64, attrs: Option<Attributes>) {
        if n == 0 {
            return;
        }
        self.base_len += n as usize;
        self.target_len += n as usize;

        if let Some(operation) = self.ops.last_mut() {
            if operation.ty.is_retain() {
                operation.retain(n);
                operation.set_attrs(attrs);
                return;
            }
        }

        self.ops
            .push(OperationBuilder::retain(n).with_attrs(attrs).build());
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

        let mut maybe_op1 = ops1.next();
        let mut maybe_op2 = ops2.next();
        loop {
            match (
                &maybe_op1.as_ref().map(|o| &o.ty),
                &maybe_op2.as_ref().map(|o| &o.ty),
            ) {
                (None, None) => break,
                (Some(OpType::Delete(i)), _) => {
                    new_delta.delete(*i);
                    maybe_op1 = ops1.next();
                },
                (_, Some(OpType::Insert(s))) => {
                    new_delta.insert(s, operation_attrs(&maybe_op2));
                    maybe_op2 = ops2.next();
                },
                (None, _) | (_, None) => {
                    return Err(OTError);
                },
                (Some(OpType::Retain(i)), Some(OpType::Retain(j))) => {
                    let new_attrs = compose_attributes(
                        operation_attrs(&maybe_op1),
                        operation_attrs(&maybe_op2),
                        true,
                    );
                    match i.cmp(&j) {
                        Ordering::Less => {
                            new_delta.retain(*i, new_attrs);
                            maybe_op2 = Some(OperationBuilder::retain(*j - *i).build());
                            maybe_op1 = ops1.next();
                        },
                        std::cmp::Ordering::Equal => {
                            new_delta.retain(*i, new_attrs);
                            maybe_op1 = ops1.next();
                            maybe_op2 = ops2.next();
                        },
                        std::cmp::Ordering::Greater => {
                            new_delta.retain(*j, new_attrs);
                            maybe_op1 = Some(OperationBuilder::retain(*i - *j).build());
                            maybe_op2 = ops2.next();
                        },
                    }
                },
                (Some(OpType::Insert(s)), Some(OpType::Delete(j))) => {
                    match (num_chars(s.as_bytes()) as u64).cmp(j) {
                        Ordering::Less => {
                            maybe_op2 = Some(
                                OperationBuilder::delete(*j - num_chars(s.as_bytes()) as u64)
                                    .build(),
                            );
                            maybe_op1 = ops1.next();
                        },
                        Ordering::Equal => {
                            maybe_op1 = ops1.next();
                            maybe_op2 = ops2.next();
                        },
                        Ordering::Greater => {
                            maybe_op1 = Some(
                                OperationBuilder::insert(s.chars().skip(*j as usize).collect())
                                    .build(),
                            );
                            maybe_op2 = ops2.next();
                        },
                    }
                },
                (Some(OpType::Insert(s)), Some(OpType::Retain(j))) => {
                    let new_attrs = compose_attributes(
                        operation_attrs(&maybe_op1),
                        operation_attrs(&maybe_op2),
                        false,
                    );
                    match (num_chars(s.as_bytes()) as u64).cmp(j) {
                        Ordering::Less => {
                            new_delta.insert(s, new_attrs);
                            maybe_op2 = Some(
                                OperationBuilder::retain(*j - num_chars(s.as_bytes()) as u64)
                                    .build(),
                            );
                            maybe_op1 = ops1.next();
                        },
                        Ordering::Equal => {
                            new_delta.insert(s, new_attrs);
                            maybe_op1 = ops1.next();
                            maybe_op2 = ops2.next();
                        },
                        Ordering::Greater => {
                            let chars = &mut s.chars();
                            new_delta
                                .insert(&chars.take(*j as usize).collect::<String>(), new_attrs);
                            maybe_op1 = Some(OperationBuilder::insert(chars.collect()).build());
                            maybe_op2 = ops2.next();
                        },
                    }
                },
                (Some(OpType::Retain(i)), Some(OpType::Delete(j))) => match i.cmp(&j) {
                    Ordering::Less => {
                        new_delta.delete(*i);
                        maybe_op2 = Some(OperationBuilder::delete(*j - *i).build());
                        maybe_op1 = ops1.next();
                    },
                    Ordering::Equal => {
                        new_delta.delete(*j);
                        maybe_op2 = ops2.next();
                        maybe_op1 = ops1.next();
                    },
                    Ordering::Greater => {
                        new_delta.delete(*j);
                        maybe_op1 = Some(OperationBuilder::retain(*i - *j).build());
                        maybe_op2 = ops2.next();
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

        let mut maybe_op1 = ops1.next();
        let mut maybe_op2 = ops2.next();
        loop {
            match (
                &maybe_op1.as_ref().map(|o| &o.ty),
                &maybe_op2.as_ref().map(|o| &o.ty),
            ) {
                (None, None) => break,
                (Some(OpType::Insert(s)), _) => {
                    let new_attrs = compose_attributes(
                        operation_attrs(&maybe_op1),
                        operation_attrs(&maybe_op2),
                        true,
                    );
                    a_prime.insert(s, new_attrs.clone());
                    b_prime.retain(num_chars(s.as_bytes()) as _, new_attrs.clone());
                    maybe_op1 = ops1.next();
                },
                (_, Some(OpType::Insert(s))) => {
                    let new_attrs = compose_attributes(
                        operation_attrs(&maybe_op1),
                        operation_attrs(&maybe_op2),
                        true,
                    );
                    a_prime.retain(num_chars(s.as_bytes()) as _, new_attrs.clone());
                    b_prime.insert(s, new_attrs.clone());
                    maybe_op2 = ops2.next();
                },
                (None, _) => {
                    return Err(OTError);
                },
                (_, None) => {
                    return Err(OTError);
                },
                (Some(OpType::Retain(i)), Some(OpType::Retain(j))) => {
                    let new_attrs = compose_attributes(
                        operation_attrs(&maybe_op1),
                        operation_attrs(&maybe_op2),
                        true,
                    );
                    match i.cmp(&j) {
                        Ordering::Less => {
                            a_prime.retain(*i, new_attrs.clone());
                            b_prime.retain(*i, new_attrs.clone());
                            maybe_op2 = Some(OperationBuilder::retain(*j - *i).build());
                            maybe_op1 = ops1.next();
                        },
                        Ordering::Equal => {
                            a_prime.retain(*i, new_attrs.clone());
                            b_prime.retain(*i, new_attrs.clone());
                            maybe_op1 = ops1.next();
                            maybe_op2 = ops2.next();
                        },
                        Ordering::Greater => {
                            a_prime.retain(*j, new_attrs.clone());
                            b_prime.retain(*j, new_attrs.clone());
                            maybe_op1 = Some(OperationBuilder::retain(*i - *j).build());
                            maybe_op2 = ops2.next();
                        },
                    };
                },
                (Some(OpType::Delete(i)), Some(OpType::Delete(j))) => match i.cmp(&j) {
                    Ordering::Less => {
                        maybe_op2 = Some(OperationBuilder::delete(*j - *i).build());
                        maybe_op1 = ops1.next();
                    },
                    Ordering::Equal => {
                        maybe_op1 = ops1.next();
                        maybe_op2 = ops2.next();
                    },
                    Ordering::Greater => {
                        maybe_op1 = Some(OperationBuilder::delete(*i - *j).build());
                        maybe_op2 = ops2.next();
                    },
                },
                (Some(OpType::Delete(i)), Some(OpType::Retain(j))) => {
                    match i.cmp(&j) {
                        Ordering::Less => {
                            a_prime.delete(*i);
                            maybe_op2 = Some(OperationBuilder::retain(*j - *i).build());
                            maybe_op1 = ops1.next();
                        },
                        Ordering::Equal => {
                            a_prime.delete(*i);
                            maybe_op1 = ops1.next();
                            maybe_op2 = ops2.next();
                        },
                        Ordering::Greater => {
                            a_prime.delete(*j);
                            maybe_op1 = Some(OperationBuilder::delete(*i - *j).build());
                            maybe_op2 = ops2.next();
                        },
                    };
                },
                (Some(OpType::Retain(i)), Some(OpType::Delete(j))) => {
                    match i.cmp(&j) {
                        Ordering::Less => {
                            b_prime.delete(*i);
                            maybe_op2 = Some(OperationBuilder::delete(*j - *i).build());
                            maybe_op1 = ops1.next();
                        },
                        Ordering::Equal => {
                            b_prime.delete(*i);
                            maybe_op1 = ops1.next();
                            maybe_op2 = ops2.next();
                        },
                        Ordering::Greater => {
                            b_prime.delete(*j);
                            maybe_op1 = Some(OperationBuilder::retain(*i - *j).build());
                            maybe_op2 = ops2.next();
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
            match &op.ty {
                OpType::Retain(retain) => {
                    for c in chars.take(*retain as usize) {
                        new_s.push(c);
                    }
                },
                OpType::Delete(delete) => {
                    for _ in 0..*delete {
                        chars.next();
                    }
                },
                OpType::Insert(insert) => {
                    new_s += insert;
                },
            }
        }
        Ok(new_s)
    }

    /// Computes the inverse of an operation. The inverse of an operation is the
    /// operation that reverts the effects of the operation
    pub fn invert(&self, s: &str) -> Self {
        let mut inverse = Delta::default();
        let chars = &mut s.chars();
        for op in &self.ops {
            match &op.ty {
                OpType::Retain(retain) => {
                    inverse.retain(*retain, op.attrs.clone());
                    for _ in 0..*retain {
                        chars.next();
                    }
                },
                OpType::Insert(insert) => {
                    inverse.delete(num_chars(insert.as_bytes()) as u64);
                },
                OpType::Delete(delete) => {
                    inverse.insert(
                        &chars.take(*delete as usize).collect::<String>(),
                        op.attrs.clone(),
                    );
                },
            }
        }
        inverse
    }

    /// Checks if this operation has no effect.
    #[inline]
    pub fn is_noop(&self) -> bool {
        match self
            .ops
            .iter()
            .map(|op| &op.ty)
            .collect::<Vec<&OpType>>()
            .as_slice()
        {
            [] => true,
            [OpType::Retain(_)] => true,
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
}

pub fn operation_attrs(operation: &Option<Operation>) -> Option<Attributes> {
    match operation {
        None => None,
        Some(operation) => operation.attrs.clone(),
    }
}
