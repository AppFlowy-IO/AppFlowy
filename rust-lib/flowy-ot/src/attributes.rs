use crate::operation::Operation;
use std::collections::{hash_map::RandomState, HashMap};

#[derive(Debug, Clone, Default, PartialEq, serde::Serialize, serde::Deserialize)]
pub struct Attributes {
    #[serde(skip_serializing_if = "HashMap::is_empty")]
    #[serde(flatten)]
    inner: HashMap<String, String>,
}

impl Attributes {
    pub fn new() -> Self {
        Attributes {
            inner: HashMap::new(),
        }
    }

    pub fn remove_empty(&mut self) { self.inner.retain(|_, v| v.is_empty() == false); }

    pub fn extend(&mut self, other: Attributes) { self.inner.extend(other.inner); }

    pub fn is_empty(&self) -> bool { self.inner.is_empty() }
}

impl std::convert::From<HashMap<String, String>> for Attributes {
    fn from(attributes: HashMap<String, String, RandomState>) -> Self {
        Attributes { inner: attributes }
    }
}

impl std::ops::Deref for Attributes {
    type Target = HashMap<String, String>;

    fn deref(&self) -> &Self::Target { &self.inner }
}

impl std::ops::DerefMut for Attributes {
    fn deref_mut(&mut self) -> &mut Self::Target { &mut self.inner }
}

pub struct AttrsBuilder {
    inner: Attributes,
}

impl AttrsBuilder {
    pub fn new() -> Self {
        Self {
            inner: Attributes::default(),
        }
    }

    pub fn bold(mut self, bold: bool) -> Self {
        let val = match bold {
            true => "true",
            false => "",
        };
        self.inner.insert("bold".to_owned(), val.to_owned());
        self
    }

    pub fn italic(mut self, italic: bool) -> Self {
        let val = match italic {
            true => "true",
            false => "",
        };
        self.inner.insert("italic".to_owned(), val.to_owned());
        self
    }

    pub fn underline(mut self) -> Self {
        self.inner.insert("underline".to_owned(), "true".to_owned());
        self
    }

    pub fn build(self) -> Attributes { self.inner }
}

pub fn attributes_from(operation: &Option<Operation>) -> Option<Attributes> {
    match operation {
        None => None,
        Some(operation) => operation.get_attributes(),
    }
}

pub fn compose_attributes(
    op1: &Option<Operation>,
    op2: &Option<Operation>,
    keep_empty: bool,
) -> Option<Attributes> {
    let a = attributes_from(op1);
    let b = attributes_from(op2);

    if a.is_none() && b.is_none() {
        return None;
    }

    let mut attrs_a = a.unwrap_or(Attributes::default());
    let attrs_b = b.unwrap_or(Attributes::default());

    log::trace!(
        "before compose_attributes: a: {:?}, b: {:?}",
        attrs_a,
        attrs_b
    );
    attrs_a.extend(attrs_b);
    log::trace!("after compose_attributes: a: {:?}", attrs_a);
    if !keep_empty {
        attrs_a.remove_empty()
    }

    Some(attrs_a)
}

pub fn transform_attributes(
    op1: &Option<Operation>,
    op2: &Option<Operation>,
    priority: bool,
) -> Option<Attributes> {
    let a = attributes_from(op1);
    let b = attributes_from(op2);

    if a.is_none() {
        return b;
    }

    if b.is_none() {
        return None;
    }

    if !priority {
        return b;
    }

    let attrs_a = a.unwrap_or(Attributes::default());
    let attrs_b = b.unwrap_or(Attributes::default());

    let result = attrs_b
        .iter()
        .fold(Attributes::new(), |mut attributes, (k, v)| {
            if attrs_a.contains_key(k) == false {
                attributes.insert(k.clone(), v.clone());
            }
            attributes
        });
    Some(result)
}

pub fn invert_attributes(attr: Option<Attributes>, base: Option<Attributes>) -> Attributes {
    let attr = attr.unwrap_or(Attributes::new());
    let base = base.unwrap_or(Attributes::new());

    let base_inverted = base
        .iter()
        .fold(Attributes::new(), |mut attributes, (k, v)| {
            if base.get(k) != attr.get(k) && attr.contains_key(k) {
                attributes.insert(k.clone(), v.clone());
            }
            attributes
        });

    let inverted = attr.iter().fold(base_inverted, |mut attributes, (k, _)| {
        if base.get(k) != attr.get(k) && !base.contains_key(k) {
            attributes.insert(k.clone(), "".to_owned());
        }
        attributes
    });

    return inverted;
}
