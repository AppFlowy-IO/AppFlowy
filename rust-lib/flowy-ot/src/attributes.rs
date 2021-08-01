use std::collections::{hash_map::RandomState, HashMap};

#[derive(Debug, Clone, Default, PartialEq)]
pub struct Attributes {
    inner: HashMap<String, String>,
}

impl Attributes {
    pub fn new() -> Self {
        Attributes {
            inner: HashMap::new(),
        }
    }

    pub fn remove_empty_value(&mut self) { self.inner.retain(|_, v| v.is_empty()); }

    pub fn extend(&mut self, other: Attributes) { self.inner.extend(other.inner); }
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

pub struct AttributesBuilder {
    inner: Attributes,
}

impl AttributesBuilder {
    pub fn new() -> Self {
        Self {
            inner: Attributes::default(),
        }
    }

    pub fn bold(mut self) -> Self {
        self.inner.insert("bold".to_owned(), "true".to_owned());
        self
    }

    pub fn italic(mut self) -> Self {
        self.inner.insert("italic".to_owned(), "true".to_owned());
        self
    }

    pub fn underline(mut self) -> Self {
        self.inner.insert("underline".to_owned(), "true".to_owned());
        self
    }

    pub fn build(self) -> Attributes { self.inner }
}

pub fn compose_attributes(
    a: Option<Attributes>,
    b: Option<Attributes>,
    keep_empty: bool,
) -> Option<Attributes> {
    if a.is_none() {
        return b;
    }

    if b.is_none() {
        return None;
    }

    let mut attrs_a = a.unwrap_or(Attributes::default());
    let attrs_b = b.unwrap_or(Attributes::default());
    attrs_a.extend(attrs_b);

    if !keep_empty {
        attrs_a.remove_empty_value()
    }

    return if attrs_a.is_empty() {
        None
    } else {
        Some(attrs_a)
    };
}

pub fn transform_attributes(
    a: Option<Attributes>,
    b: Option<Attributes>,
    priority: bool,
) -> Option<Attributes> {
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
