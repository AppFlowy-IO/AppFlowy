use crate::{
    core::{attributes::*, operation::*, DeltaIter, FlowyStr, Interval, OperationTransformable, MAX_IV_LEN},
    errors::{ErrorBuilder, OTError, OTErrorCode},
};
use bytes::Bytes;
use std::{
    cmp::{min, Ordering},
    fmt,
    iter::FromIterator,
    str,
    str::FromStr,
};

// Opti: optimize the memory usage with Arc_mut or Cow
#[derive(Clone, Debug, PartialEq, Eq)]
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

impl std::convert::TryFrom<Vec<u8>> for Delta {
    type Error = OTError;
    fn try_from(bytes: Vec<u8>) -> Result<Self, Self::Error> { Delta::from_bytes(bytes) }
}

impl std::convert::TryFrom<Bytes> for Delta {
    type Error = OTError;

    fn try_from(bytes: Bytes) -> Result<Self, Self::Error> { Delta::from_bytes(&bytes) }
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

    pub fn from_json(json: &str) -> Result<Self, OTError> {
        let delta: Delta = serde_json::from_str(json).map_err(|e| {
            tracing::trace!("Deserialize failed: {:?}", e);
            tracing::trace!("{:?}", json);
            e
        })?;
        Ok(delta)
    }

    pub fn to_json(&self) -> String { serde_json::to_string(self).unwrap_or("".to_owned()) }

    pub fn from_bytes<T: AsRef<[u8]>>(bytes: T) -> Result<Self, OTError> {
        let json = str::from_utf8(bytes.as_ref())?;
        Self::from_json(json)
    }

    pub fn to_bytes(&self) -> Bytes {
        let json = self.to_json();
        Bytes::from(json.into_bytes())
    }

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

    pub fn insert(&mut self, s: &str, attributes: Attributes) {
        let s: FlowyStr = s.into();
        if s.is_empty() {
            return;
        }

        self.target_len += s.count_utf16_code_units();
        let new_last = match self.ops.as_mut_slice() {
            [.., Operation::Insert(insert)] => {
                //
                insert.merge_or_new_op(&s, attributes)
            },
            [.., Operation::Insert(pre_insert), Operation::Delete(_)] => {
                //
                pre_insert.merge_or_new_op(&s, attributes)
            },
            [.., op_last @ Operation::Delete(_)] => {
                let new_last = op_last.clone();
                *op_last = OpBuilder::insert(&s).attributes(attributes).build();
                Some(new_last)
            },
            _ => Some(OpBuilder::insert(&s).attributes(attributes).build()),
        };

        match new_last {
            None => {},
            Some(new_last) => self.ops.push(new_last),
        }
    }

    pub fn retain(&mut self, n: usize, attributes: Attributes) {
        if n == 0 {
            return;
        }
        self.base_len += n as usize;
        self.target_len += n as usize;

        if let Some(Operation::Retain(retain)) = self.ops.last_mut() {
            if let Some(new_op) = retain.merge_or_new(n, attributes) {
                self.ops.push(new_op);
            }
        } else {
            self.ops.push(OpBuilder::retain(n).attributes(attributes).build());
        }
    }

    /// Applies an operation to a string, returning a new string.
    pub fn apply(&self, s: &str) -> Result<String, OTError> {
        let s: FlowyStr = s.into();
        if s.count_utf16_code_units() != self.base_len {
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
                    inverted.delete(insert.count_of_code_units());
                },
                Operation::Delete(delete) => {
                    inverted.insert(&chars.take(*delete as usize).collect::<String>(), op.get_attributes());
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

    pub fn is_empty(&self) -> bool { self.ops.is_empty() }

    pub fn extend(&mut self, other: Self) { other.ops.into_iter().for_each(|op| self.add(op)); }
}

impl OperationTransformable for Delta {
    fn compose(&self, other: &Self) -> Result<Self, OTError>
    where
        Self: Sized,
    {
        let mut new_delta = Delta::default();
        let mut iter = DeltaIter::new(self);
        let mut other_iter = DeltaIter::new(other);

        while iter.has_next() || other_iter.has_next() {
            if other_iter.is_next_insert() {
                new_delta.add(other_iter.next_op().unwrap());
                continue;
            }

            if iter.is_next_delete() {
                new_delta.add(iter.next_op().unwrap());
                continue;
            }

            let length = min(
                iter.next_op_len().unwrap_or(MAX_IV_LEN),
                other_iter.next_op_len().unwrap_or(MAX_IV_LEN),
            );

            let op = iter
                .next_op_with_len(length)
                .unwrap_or(OpBuilder::retain(length).build());
            let other_op = other_iter
                .next_op_with_len(length)
                .unwrap_or(OpBuilder::retain(length).build());

            debug_assert_eq!(op.len(), other_op.len());

            match (&op, &other_op) {
                (Operation::Retain(retain), Operation::Retain(other_retain)) => {
                    let composed_attrs = retain.attributes.compose(&other_retain.attributes)?;

                    new_delta.add(OpBuilder::retain(retain.n).attributes(composed_attrs).build())
                },
                (Operation::Insert(insert), Operation::Retain(other_retain)) => {
                    let mut composed_attrs = insert.attributes.compose(&other_retain.attributes)?;
                    composed_attrs.remove_empty();
                    new_delta.add(OpBuilder::insert(op.get_data()).attributes(composed_attrs).build())
                },
                (Operation::Retain(_), Operation::Delete(_)) => {
                    new_delta.add(other_op);
                },
                (a, b) => {
                    debug_assert_eq!(a.is_insert(), true);
                    debug_assert_eq!(b.is_delete(), true);
                    continue;
                },
            }
        }

        Ok(new_delta)
    }

    fn transform(&self, other: &Self) -> Result<(Self, Self), OTError>
    where
        Self: Sized,
    {
        if self.base_len != other.base_len {
            return Err(ErrorBuilder::new(OTErrorCode::IncompatibleLength)
                .msg(format!(
                    "cur base length: {}, other base length: {}",
                    self.base_len, other.base_len
                ))
                .build());
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
                    b_prime.retain(insert.count_of_code_units(), insert.attributes.clone());
                    next_op1 = ops1.next();
                },
                (_, Some(Operation::Insert(o_insert))) => {
                    let composed_attrs = transform_op_attribute(&next_op1, &next_op2);
                    a_prime.retain(o_insert.count_of_code_units(), composed_attrs.clone());
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
                    let composed_attrs = transform_op_attribute(&next_op1, &next_op2);
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

    fn invert(&self, other: &Self) -> Self {
        let mut inverted = Delta::default();
        if other.is_empty() {
            return inverted;
        }
        tracing::trace!("🌜Calculate invert delta");
        tracing::trace!("current: {}", self);
        tracing::trace!("other: {}", other);
        let mut index = 0;
        for op in &self.ops {
            let len: usize = op.len() as usize;
            match op {
                Operation::Delete(n) => {
                    invert_from_other(&mut inverted, other, op, index, index + *n);
                    index += len;
                },
                Operation::Retain(_) => {
                    match op.has_attribute() {
                        true => invert_from_other(&mut inverted, other, op, index, index + len),
                        false => {
                            tracing::trace!("invert retain: {} by retain {} {}", op, len, op.get_attributes());
                            inverted.retain(len as usize, op.get_attributes())
                        },
                    }
                    index += len;
                },
                Operation::Insert(_) => {
                    tracing::trace!("invert insert: {} by delete {}", op, len);
                    inverted.delete(len as usize);
                },
            }
        }

        tracing::trace!("🌛invert result: {}", inverted);
        inverted
    }
}

fn invert_from_other(base: &mut Delta, other: &Delta, operation: &Operation, start: usize, end: usize) {
    tracing::trace!("invert op: {} [{}:{}]", operation, start, end);
    let other_ops = DeltaIter::from_interval(other, Interval::new(start, end)).ops();
    other_ops.into_iter().for_each(|other_op| match operation {
        Operation::Delete(n) => {
            tracing::trace!("invert delete: {} by add {}", n, other_op);
            base.add(other_op);
        },
        Operation::Retain(_retain) => {
            tracing::trace!(
                "invert attributes: {:?}, {:?}",
                operation.get_attributes(),
                other_op.get_attributes()
            );
            let inverted_attrs = operation.get_attributes().invert(&other_op.get_attributes());
            base.retain(other_op.len(), inverted_attrs);
        },
        Operation::Insert(_) => {
            log::error!("Impossible to here. Insert operation should be treated as delete")
        },
    });
}

fn transform_op_attribute(left: &Option<Operation>, right: &Option<Operation>) -> Attributes {
    if left.is_none() {
        if right.is_none() {
            return Attributes::default();
        }
        return right.as_ref().unwrap().get_attributes();
    }
    let left = left.as_ref().unwrap().get_attributes();
    let right = right.as_ref().unwrap().get_attributes();
    // TODO: It's ok to unwrap?
    left.transform(&right).unwrap().0
}
