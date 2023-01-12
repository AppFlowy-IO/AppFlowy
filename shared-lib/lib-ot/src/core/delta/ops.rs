use crate::core::delta::operation::{DeltaOperation, EmptyAttributes, OperationAttributes, OperationTransform};
use crate::core::delta::{OperationIterator, MAX_IV_LEN};
use crate::core::interval::Interval;
use crate::core::ot_str::OTString;
use crate::core::DeltaOperationBuilder;
use crate::errors::{ErrorBuilder, OTError, OTErrorCode};
use bytes::Bytes;
use serde::de::DeserializeOwned;
use std::{
    cmp::{min, Ordering},
    fmt,
    iter::FromIterator,
    str,
    str::FromStr,
};

pub type DeltaBuilder = DeltaOperationBuilder<EmptyAttributes>;

/// A [Delta] contains list of operations that consists of 'Retain', 'Delete' and 'Insert' operation.
/// Check out the [Operation] for more details. It describes the document as a sequence of
/// operations.
///
/// You could check [this](https://appflowy.gitbook.io/docs/essential-documentation/contribute-to-appflowy/architecture/backend/delta) out for more information.
///
/// If the [T] supports 'serde', that will enable delta to serialize to JSON or deserialize from
/// a JSON string.
///
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct DeltaOperations<Attribute: OperationAttributes> {
    pub ops: Vec<DeltaOperation<Attribute>>,

    /// 'Delete' and 'Retain' operation will update the [utf16_base_len]
    /// Transforming the other delta, it requires the utf16_base_len must be equal.  
    pub utf16_base_len: usize,

    /// Represents the current len of the delta.
    /// 'Insert' and 'Retain' operation will update the [utf16_target_len]
    pub utf16_target_len: usize,
}

impl<T> Default for DeltaOperations<T>
where
    T: OperationAttributes,
{
    fn default() -> Self {
        Self {
            ops: Vec::new(),
            utf16_base_len: 0,
            utf16_target_len: 0,
        }
    }
}

impl<T> fmt::Display for DeltaOperations<T>
where
    T: OperationAttributes,
{
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

impl<T> FromIterator<DeltaOperation<T>> for DeltaOperations<T>
where
    T: OperationAttributes,
{
    fn from_iter<I: IntoIterator<Item = DeltaOperation<T>>>(ops: I) -> Self {
        let mut operations = DeltaOperations::default();
        for op in ops {
            operations.add(op);
        }
        operations
    }
}

impl<T> DeltaOperations<T>
where
    T: OperationAttributes,
{
    pub fn new() -> Self {
        Self::default()
    }

    #[inline]
    pub fn with_capacity(capacity: usize) -> Self {
        Self {
            ops: Vec::with_capacity(capacity),
            utf16_base_len: 0,
            utf16_target_len: 0,
        }
    }

    /// Adding an operation. It will be added in sequence.
    pub fn add(&mut self, op: DeltaOperation<T>) {
        match op {
            DeltaOperation::Delete(i) => self.delete(i),
            DeltaOperation::Insert(i) => self.insert(&i.s, i.attributes),
            DeltaOperation::Retain(r) => self.retain(r.n, r.attributes),
        }
    }

    /// Creating a [Delete] operation with len [n]
    pub fn delete(&mut self, n: usize) {
        if n == 0 {
            return;
        }
        self.utf16_base_len += n as usize;
        if let Some(DeltaOperation::Delete(n_last)) = self.ops.last_mut() {
            *n_last += n;
        } else {
            self.ops.push(DeltaOperation::delete(n));
        }
    }

    /// Creating a [Insert] operation with string, [s].
    pub fn insert(&mut self, s: &str, attributes: T) {
        let s: OTString = s.into();
        if s.is_empty() {
            return;
        }

        self.utf16_target_len += s.utf16_len();
        let new_last = match self.ops.as_mut_slice() {
            [.., DeltaOperation::<T>::Insert(insert)] => {
                //
                insert.merge_or_new_op(&s, attributes)
            }
            [.., DeltaOperation::<T>::Insert(pre_insert), DeltaOperation::Delete(_)] => {
                //
                pre_insert.merge_or_new_op(&s, attributes)
            }
            [.., op_last @ DeltaOperation::<T>::Delete(_)] => {
                let new_last = op_last.clone();
                *op_last = DeltaOperation::<T>::insert_with_attributes(&s, attributes);
                Some(new_last)
            }
            _ => Some(DeltaOperation::<T>::insert_with_attributes(&s, attributes)),
        };

        match new_last {
            None => {}
            Some(new_last) => self.ops.push(new_last),
        }
    }

    /// Creating a [Retain] operation with len, [n].
    pub fn retain(&mut self, n: usize, attributes: T) {
        if n == 0 {
            return;
        }
        self.utf16_base_len += n as usize;
        self.utf16_target_len += n as usize;

        if let Some(DeltaOperation::<T>::Retain(retain)) = self.ops.last_mut() {
            if let Some(new_op) = retain.merge_or_new(n, attributes) {
                self.ops.push(new_op);
            }
        } else {
            self.ops
                .push(DeltaOperation::<T>::retain_with_attributes(n, attributes));
        }
    }

    /// Return the a new string described by this delta. The new string will contains the input string.
    /// The length of the [applied_str] must be equal to the the [utf16_base_len].
    ///
    /// # Arguments
    ///
    /// * `applied_str`: A string represents the utf16_base_len content. it will be consumed by the [retain]
    /// or [delete] operations.
    ///
    ///
    /// # Examples
    ///
    /// ```
    ///  use lib_ot::core::DeltaBuilder;
    ///  let s = "hello";
    ///  let delta_a = DeltaBuilder::new().insert(s).build();
    ///  let delta_b = DeltaBuilder::new()
    ///         .retain(s.len())
    ///         .insert(", AppFlowy")
    ///         .build();
    ///
    ///  let after_a = delta_a.content().unwrap();
    ///  let after_b = delta_b.apply(&after_a).unwrap();
    ///  assert_eq!("hello, AppFlowy", &after_b);
    /// ```
    pub fn apply(&self, applied_str: &str) -> Result<String, OTError> {
        let applied_str: OTString = applied_str.into();
        if applied_str.utf16_len() != self.utf16_base_len {
            return Err(ErrorBuilder::new(OTErrorCode::IncompatibleLength)
                .msg(format!(
                    "Expected: {}, but received: {}",
                    self.utf16_base_len,
                    applied_str.utf16_len()
                ))
                .build());
        }
        let mut new_s = String::new();
        let code_point_iter = &mut applied_str.utf16_iter();
        for op in &self.ops {
            match &op {
                DeltaOperation::Retain(retain) => {
                    for c in code_point_iter.take(retain.n as usize) {
                        new_s.push_str(str::from_utf8(c.0).unwrap_or(""));
                    }
                }
                DeltaOperation::Delete(delete) => {
                    for _ in 0..*delete {
                        code_point_iter.next();
                    }
                }
                DeltaOperation::Insert(insert) => {
                    new_s += &insert.s;
                }
            }
        }
        Ok(new_s)
    }

    pub fn inverted(&self) -> Self {
        self.invert_str("")
    }

    /// Computes the inverse [Delta]. The inverse of an operation is the
    /// operation that reverts the effects of the operation     
    /// # Arguments
    ///
    /// * `inverted_s`: A string represents the utf16_base_len content. The len of [inverted_s]
    /// must equal to the [utf16_base_len], it will be consumed by the [retain] or [delete] operations.
    ///
    /// If the delta's operations just contain a insert operation. The inverted_s must be empty string.
    ///
    /// # Examples
    ///
    /// ```
    ///  use lib_ot::core::DeltaBuilder;
    ///  let s = "hello world";
    ///  let delta = DeltaBuilder::new().insert(s).build();
    ///  let invert_delta = delta.invert_str(s);
    ///  assert_eq!(delta.utf16_base_len, invert_delta.utf16_target_len);
    ///  assert_eq!(delta.utf16_target_len, invert_delta.utf16_base_len);
    ///
    ///  assert_eq!(invert_delta.apply(s).unwrap(), "")
    ///
    /// ```
    ///
    pub fn invert_str(&self, inverted_s: &str) -> Self {
        let mut inverted = DeltaOperations::default();
        let inverted_s: OTString = inverted_s.into();
        let code_point_iter = &mut inverted_s.utf16_iter();

        for op in &self.ops {
            match &op {
                DeltaOperation::Retain(retain) => {
                    inverted.retain(retain.n, T::default());
                    for _ in 0..retain.n {
                        code_point_iter.next();
                    }
                }
                DeltaOperation::Insert(insert) => {
                    inverted.delete(insert.utf16_size());
                }
                DeltaOperation::Delete(delete) => {
                    let bytes = code_point_iter
                        .take(*delete as usize)
                        .into_iter()
                        .flat_map(|a| str::from_utf8(a.0).ok())
                        .collect::<String>();

                    inverted.insert(&bytes, op.get_attributes());
                }
            }
        }
        inverted
    }

    /// Return true if the delta doesn't contain any [Insert] or [Delete] operations.
    pub fn is_noop(&self) -> bool {
        matches!(self.ops.as_slice(), [] | [DeltaOperation::Retain(_)])
    }

    pub fn is_empty(&self) -> bool {
        self.ops.is_empty()
    }

    pub fn extend(&mut self, other: Self) {
        other.ops.into_iter().for_each(|op| self.add(op));
    }

    /// Get the content that the [Delta] represents.
    pub fn content(&self) -> Result<String, OTError> {
        self.apply("")
    }
}

impl<T> OperationTransform for DeltaOperations<T>
where
    T: OperationAttributes,
{
    fn compose(&self, other: &Self) -> Result<Self, OTError>
    where
        Self: Sized,
    {
        let mut new_delta = DeltaOperations::default();
        let mut iter = OperationIterator::new(self);
        let mut other_iter = OperationIterator::new(other);

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
                .unwrap_or_else(|| DeltaOperation::retain(length));
            let other_op = other_iter
                .next_op_with_len(length)
                .unwrap_or_else(|| DeltaOperation::retain(length));

            // debug_assert_eq!(op.len(), other_op.len(), "Composing delta failed,");

            match (&op, &other_op) {
                (DeltaOperation::Retain(retain), DeltaOperation::Retain(other_retain)) => {
                    let composed_attrs = retain.attributes.compose(&other_retain.attributes)?;

                    new_delta.add(DeltaOperation::retain_with_attributes(retain.n, composed_attrs))
                }
                (DeltaOperation::Insert(insert), DeltaOperation::Retain(other_retain)) => {
                    let mut composed_attrs = insert.attributes.compose(&other_retain.attributes)?;
                    composed_attrs.remove();
                    new_delta.add(DeltaOperation::insert_with_attributes(op.get_data(), composed_attrs))
                }
                (DeltaOperation::Retain(_), DeltaOperation::Delete(_)) => {
                    new_delta.add(other_op);
                }
                (a, b) => {
                    debug_assert!(a.is_insert());
                    debug_assert!(b.is_delete());
                    continue;
                }
            }
        }
        Ok(new_delta)
    }

    fn transform(&self, other: &Self) -> Result<(Self, Self), OTError>
    where
        Self: Sized,
    {
        if self.utf16_base_len != other.utf16_base_len {
            return Err(ErrorBuilder::new(OTErrorCode::IncompatibleLength)
                .msg(format!(
                    "cur base length: {}, other base length: {}",
                    self.utf16_base_len, other.utf16_base_len
                ))
                .build());
        }

        let mut a_prime = DeltaOperations::default();
        let mut b_prime = DeltaOperations::default();

        let mut ops1 = self.ops.iter().cloned();
        let mut ops2 = other.ops.iter().cloned();

        let mut next_op1 = ops1.next();
        let mut next_op2 = ops2.next();
        loop {
            match (&next_op1, &next_op2) {
                (None, None) => break,
                (Some(DeltaOperation::Insert(insert)), _) => {
                    // let composed_attrs = transform_attributes(&next_op1, &next_op2, true);
                    a_prime.insert(&insert.s, insert.attributes.clone());
                    b_prime.retain(insert.utf16_size(), insert.attributes.clone());
                    next_op1 = ops1.next();
                }
                (_, Some(DeltaOperation::Insert(o_insert))) => {
                    let composed_attrs = transform_op_attribute(&next_op1, &next_op2)?;
                    a_prime.retain(o_insert.utf16_size(), composed_attrs.clone());
                    b_prime.insert(&o_insert.s, composed_attrs);
                    next_op2 = ops2.next();
                }
                (None, _) => {
                    return Err(ErrorBuilder::new(OTErrorCode::IncompatibleLength).build());
                }
                (_, None) => {
                    return Err(ErrorBuilder::new(OTErrorCode::IncompatibleLength).build());
                }
                (Some(DeltaOperation::Retain(retain)), Some(DeltaOperation::Retain(o_retain))) => {
                    let composed_attrs = transform_op_attribute(&next_op1, &next_op2)?;
                    match retain.cmp(o_retain) {
                        Ordering::Less => {
                            a_prime.retain(retain.n, composed_attrs.clone());
                            b_prime.retain(retain.n, composed_attrs.clone());
                            next_op2 = Some(DeltaOperation::retain(o_retain.n - retain.n));
                            next_op1 = ops1.next();
                        }
                        Ordering::Equal => {
                            a_prime.retain(retain.n, composed_attrs.clone());
                            b_prime.retain(retain.n, composed_attrs.clone());
                            next_op1 = ops1.next();
                            next_op2 = ops2.next();
                        }
                        Ordering::Greater => {
                            a_prime.retain(o_retain.n, composed_attrs.clone());
                            b_prime.retain(o_retain.n, composed_attrs.clone());
                            next_op1 = Some(DeltaOperation::retain(retain.n - o_retain.n));
                            next_op2 = ops2.next();
                        }
                    };
                }
                (Some(DeltaOperation::Delete(i)), Some(DeltaOperation::Delete(j))) => match i.cmp(j) {
                    Ordering::Less => {
                        next_op2 = Some(DeltaOperation::delete(*j - *i));
                        next_op1 = ops1.next();
                    }
                    Ordering::Equal => {
                        next_op1 = ops1.next();
                        next_op2 = ops2.next();
                    }
                    Ordering::Greater => {
                        next_op1 = Some(DeltaOperation::delete(*i - *j));
                        next_op2 = ops2.next();
                    }
                },
                (Some(DeltaOperation::Delete(i)), Some(DeltaOperation::Retain(o_retain))) => {
                    match i.cmp(o_retain) {
                        Ordering::Less => {
                            a_prime.delete(*i);
                            next_op2 = Some(DeltaOperation::retain(o_retain.n - *i));
                            next_op1 = ops1.next();
                        }
                        Ordering::Equal => {
                            a_prime.delete(*i);
                            next_op1 = ops1.next();
                            next_op2 = ops2.next();
                        }
                        Ordering::Greater => {
                            a_prime.delete(o_retain.n);
                            next_op1 = Some(DeltaOperation::delete(*i - o_retain.n));
                            next_op2 = ops2.next();
                        }
                    };
                }
                (Some(DeltaOperation::Retain(retain)), Some(DeltaOperation::Delete(j))) => {
                    match retain.cmp(j) {
                        Ordering::Less => {
                            b_prime.delete(retain.n);
                            next_op2 = Some(DeltaOperation::delete(*j - retain.n));
                            next_op1 = ops1.next();
                        }
                        Ordering::Equal => {
                            b_prime.delete(retain.n);
                            next_op1 = ops1.next();
                            next_op2 = ops2.next();
                        }
                        Ordering::Greater => {
                            b_prime.delete(*j);
                            next_op1 = Some(DeltaOperation::retain(retain.n - *j));
                            next_op2 = ops2.next();
                        }
                    };
                }
            }
        }
        Ok((a_prime, b_prime))
    }

    fn invert(&self, other: &Self) -> Self {
        let mut inverted = DeltaOperations::default();
        let mut index = 0;
        for op in &self.ops {
            let len: usize = op.len() as usize;
            match op {
                DeltaOperation::Delete(n) => {
                    invert_other(&mut inverted, other, op, index, index + *n);
                    index += len;
                }
                DeltaOperation::Retain(_) => {
                    match op.has_attribute() {
                        true => invert_other(&mut inverted, other, op, index, index + len),
                        false => {
                            // tracing::trace!("invert retain: {} by retain {} {}", op, len,
                            // op.get_attributes());
                            inverted.retain(len as usize, op.get_attributes())
                        }
                    }
                    index += len;
                }
                DeltaOperation::Insert(_) => {
                    // tracing::trace!("invert insert: {} by delete {}", op, len);
                    inverted.delete(len as usize);
                }
            }
        }
        inverted
    }
}

/// Removes trailing retain operation with empty attributes, if present.
pub fn trim<T>(delta: &mut DeltaOperations<T>)
where
    T: OperationAttributes,
{
    if let Some(last) = delta.ops.last() {
        if last.is_retain() && last.is_plain() {
            delta.ops.pop();
        }
    }
}

fn invert_other<T: OperationAttributes>(
    base: &mut DeltaOperations<T>,
    other: &DeltaOperations<T>,
    operation: &DeltaOperation<T>,
    start: usize,
    end: usize,
) {
    tracing::trace!("invert op: {} [{}:{}]", operation, start, end);
    let other_ops = OperationIterator::from_interval(other, Interval::new(start, end)).ops();
    other_ops.into_iter().for_each(|other_op| match operation {
        DeltaOperation::Delete(_n) => {
            // tracing::trace!("invert delete: {} by add {}", n, other_op);
            base.add(other_op);
        }
        DeltaOperation::Retain(_retain) => {
            tracing::trace!(
                "invert attributes: {:?}, {:?}",
                operation.get_attributes(),
                other_op.get_attributes()
            );
            let inverted_attrs = operation.get_attributes().invert(&other_op.get_attributes());
            base.retain(other_op.len(), inverted_attrs);
        }
        DeltaOperation::Insert(_) => {
            log::error!("Impossible to here. Insert operation should be treated as delete")
        }
    });
}

fn transform_op_attribute<T: OperationAttributes>(
    left: &Option<DeltaOperation<T>>,
    right: &Option<DeltaOperation<T>>,
) -> Result<T, OTError> {
    if left.is_none() {
        if right.is_none() {
            return Ok(T::default());
        }
        return Ok(right.as_ref().unwrap().get_attributes());
    }
    let left = left.as_ref().unwrap().get_attributes();
    let right = right.as_ref().unwrap().get_attributes();
    // TODO: replace with anyhow and this error.
    Ok(left.transform(&right)?.0)
}

impl<T> DeltaOperations<T>
where
    T: OperationAttributes + DeserializeOwned,
{
    /// # Examples
    ///
    /// ```
    /// use lib_ot::core::DeltaOperationBuilder;
    /// use lib_ot::text_delta::{DeltaTextOperations};
    /// let json = r#"[
    ///     {"retain":7,"attributes":{"bold":null}}
    ///  ]"#;
    /// let delta = DeltaTextOperations::from_json(json).unwrap();
    /// assert_eq!(delta.json_str(), r#"[{"retain":7,"attributes":{"bold":null}}]"#);
    /// ```
    pub fn from_json(json: &str) -> Result<Self, OTError> {
        let delta = serde_json::from_str(json).map_err(|e| {
            tracing::trace!("Deserialize failed: {:?}", e);
            tracing::trace!("{:?}", json);
            e
        })?;
        Ok(delta)
    }

    /// Deserialize the bytes into [Delta]. It requires the bytes is in utf8 format.
    pub fn from_bytes<B: AsRef<[u8]>>(bytes: B) -> Result<Self, OTError> {
        let json = str::from_utf8(bytes.as_ref())?.to_owned();
        let val = Self::from_json(&json)?;
        Ok(val)
    }
}

impl<T> DeltaOperations<T>
where
    T: OperationAttributes + serde::Serialize,
{
    /// Serialize the [Delta] into a String in JSON format
    pub fn json_str(&self) -> String {
        serde_json::to_string(self).unwrap_or_else(|_| "".to_owned())
    }

    /// Serial the [Delta] into a String in Bytes format
    pub fn json_bytes(&self) -> Bytes {
        let json = self.json_str();
        Bytes::from(json.into_bytes())
    }
}

impl<T> FromStr for DeltaOperations<T>
where
    T: OperationAttributes,
{
    type Err = ();

    fn from_str(s: &str) -> Result<DeltaOperations<T>, Self::Err> {
        let mut delta = DeltaOperations::with_capacity(1);
        delta.add(DeltaOperation::Insert(s.into()));
        Ok(delta)
    }
}

impl<T> std::convert::TryFrom<Vec<u8>> for DeltaOperations<T>
where
    T: OperationAttributes + DeserializeOwned,
{
    type Error = OTError;
    fn try_from(bytes: Vec<u8>) -> Result<Self, Self::Error> {
        DeltaOperations::from_bytes(bytes)
    }
}

impl<T> std::convert::TryFrom<Bytes> for DeltaOperations<T>
where
    T: OperationAttributes + DeserializeOwned,
{
    type Error = OTError;

    fn try_from(bytes: Bytes) -> Result<Self, Self::Error> {
        DeltaOperations::from_bytes(&bytes)
    }
}
