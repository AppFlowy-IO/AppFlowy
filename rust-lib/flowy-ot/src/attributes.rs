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

    pub fn remove_empty_value(&mut self) { self.inner.retain((|_, v| v.is_empty())); }

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

pub fn compose_attributes(
    mut a: Attributes,
    b: Attributes,
    keep_empty: bool,
) -> Option<Attributes> {
    a.extend(b);
    let mut result = a;
    if !keep_empty {
        result.remove_empty_value()
    }

    return if result.is_empty() {
        None
    } else {
        Some(result)
    };
}

pub fn transform_attributes(a: Attributes, b: Attributes, priority: bool) -> Option<Attributes> {
    if a.is_empty() {
        return Some(b);
    }

    if b.is_empty() {
        return None;
    }

    if !priority {
        return Some(b);
    }

    let result = b.iter().fold(Attributes::new(), |mut attributes, (k, v)| {
        if a.contains_key(k) == false {
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

    let inverted = attr.iter().fold(base_inverted, |mut attributes, (k, v)| {
        if base.get(k) != attr.get(k) && !base.contains_key(k) {
            attributes.insert(k.clone(), "".to_owned());
        }
        attributes
    });

    return inverted;
}
