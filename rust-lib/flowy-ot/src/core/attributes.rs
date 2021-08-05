use crate::core::Operation;
use std::{collections::HashMap, fmt};

const REMOVE_FLAG: &'static str = "";
fn should_remove(s: &str) -> bool { s == REMOVE_FLAG }

#[derive(Debug, PartialEq, Clone, serde::Serialize, serde::Deserialize)]
#[serde(untagged)]
pub enum Attributes {
    #[serde(skip)]
    Follow,
    Custom(AttributesData),
    #[serde(skip)]
    Empty,
}

impl Attributes {
    pub fn data(&self) -> Option<AttributesData> {
        match self {
            Attributes::Follow => None,
            Attributes::Custom(data) => Some(data.clone()),
            Attributes::Empty => None,
        }
    }

    pub fn is_empty(&self) -> bool {
        match self {
            Attributes::Follow => true,
            Attributes::Custom(data) => data.is_empty(),
            Attributes::Empty => true,
        }
    }
}

impl std::default::Default for Attributes {
    fn default() -> Self { Attributes::Empty }
}

impl fmt::Display for Attributes {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Attributes::Follow => {
                f.write_str("")?;
            },
            Attributes::Custom(data) => {
                f.write_fmt(format_args!("{:?}", data.inner))?;
            },
            Attributes::Empty => {
                f.write_str("")?;
            },
        }
        Ok(())
    }
}

#[derive(Debug, Clone, Default, PartialEq, serde::Serialize, serde::Deserialize)]
pub struct AttributesData {
    #[serde(skip_serializing_if = "HashMap::is_empty")]
    #[serde(flatten)]
    inner: HashMap<String, String>,
}

impl AttributesData {
    pub fn new() -> Self {
        AttributesData {
            inner: HashMap::new(),
        }
    }
    pub fn is_empty(&self) -> bool {
        self.inner.values().filter(|v| !should_remove(v)).count() == 0
    }

    fn remove_empty(&mut self) { self.inner.retain(|_, v| !should_remove(v)); }

    pub fn extend(&mut self, other: AttributesData) { self.inner.extend(other.inner); }

    pub fn merge(&mut self, other: Option<AttributesData>) {
        if other.is_none() {
            return;
        }

        let mut new_attributes = other.unwrap().inner;
        self.inner.iter().for_each(|(k, v)| {
            if should_remove(v) {
                new_attributes.remove(k);
            } else {
                new_attributes.insert(k.clone(), v.clone());
            }
        });
        self.inner = new_attributes;
    }
}

pub trait AttributesDataRule {
    fn apply_rule(&mut self);

    fn into_attributes(self) -> Attributes;
}
impl AttributesDataRule for AttributesData {
    fn apply_rule(&mut self) { self.remove_empty(); }

    fn into_attributes(mut self) -> Attributes {
        self.apply_rule();

        if self.is_empty() {
            Attributes::Empty
        } else {
            Attributes::Custom(self)
        }
    }
}

pub trait AttributesRule {
    fn apply_rule(self) -> Attributes;
}

impl AttributesRule for Attributes {
    fn apply_rule(self) -> Attributes {
        match self {
            Attributes::Follow => self,
            Attributes::Custom(data) => data.into_attributes(),
            Attributes::Empty => self,
        }
    }
}

impl std::convert::From<HashMap<String, String>> for AttributesData {
    fn from(attributes: HashMap<String, String>) -> Self { AttributesData { inner: attributes } }
}

impl std::ops::Deref for AttributesData {
    type Target = HashMap<String, String>;

    fn deref(&self) -> &Self::Target { &self.inner }
}

impl std::ops::DerefMut for AttributesData {
    fn deref_mut(&mut self) -> &mut Self::Target { &mut self.inner }
}

pub struct AttrsBuilder {
    inner: AttributesData,
}

impl AttrsBuilder {
    pub fn new() -> Self {
        Self {
            inner: AttributesData::default(),
        }
    }

    pub fn bold(mut self, bold: bool) -> Self {
        let val = match bold {
            true => "true",
            false => REMOVE_FLAG,
        };
        self.inner.insert("bold".to_owned(), val.to_owned());
        self
    }

    pub fn italic(mut self, italic: bool) -> Self {
        let val = match italic {
            true => "true",
            false => REMOVE_FLAG,
        };
        self.inner.insert("italic".to_owned(), val.to_owned());
        self
    }

    pub fn underline(mut self) -> Self {
        self.inner.insert("underline".to_owned(), "true".to_owned());
        self
    }

    pub fn build(self) -> Attributes { Attributes::Custom(self.inner) }
}

pub(crate) fn attributes_from(operation: &Option<Operation>) -> Option<Attributes> {
    match operation {
        None => None,
        Some(operation) => Some(operation.get_attributes()),
    }
}

pub fn compose_operation(left: &Option<Operation>, right: &Option<Operation>) -> Attributes {
    if left.is_none() && right.is_none() {
        return Attributes::Empty;
    }
    let attr_l = attributes_from(left);
    let attr_r = attributes_from(right);

    if attr_l.is_none() {
        return attr_r.unwrap();
    }

    if attr_r.is_none() {
        return attr_l.unwrap();
    }

    compose_attributes(attr_l.unwrap(), attr_r.unwrap())
}

pub fn transform_operation(left: &Option<Operation>, right: &Option<Operation>) -> Attributes {
    let attr_l = attributes_from(left);
    let attr_r = attributes_from(right);

    if attr_l.is_none() {
        if attr_r.is_none() {
            return Attributes::Empty;
        }

        return match attr_r.as_ref().unwrap() {
            Attributes::Follow => Attributes::Follow,
            Attributes::Custom(_) => attr_r.unwrap(),
            Attributes::Empty => Attributes::Empty,
        };
    }

    transform_attributes(attr_l.unwrap(), attr_r.unwrap())
}

pub fn invert_attributes(attr: Attributes, base: Attributes) -> Attributes {
    let attr = attr.data();
    let base = base.data();

    if attr.is_none() && base.is_none() {
        return Attributes::Empty;
    }

    let attr = attr.unwrap_or(AttributesData::new());
    let base = base.unwrap_or(AttributesData::new());

    let base_inverted = base
        .iter()
        .fold(AttributesData::new(), |mut attributes, (k, v)| {
            if base.get(k) != attr.get(k) && attr.contains_key(k) {
                attributes.insert(k.clone(), v.clone());
            }
            attributes
        });

    let inverted = attr.iter().fold(base_inverted, |mut attributes, (k, _)| {
        if base.get(k) != attr.get(k) && !base.contains_key(k) {
            // attributes.insert(k.clone(), "".to_owned());
            attributes.remove(k);
        }
        attributes
    });

    return Attributes::Custom(inverted);
}

pub fn merge_attributes(attributes: Attributes, other: Attributes) -> Attributes {
    match (&attributes, &other) {
        (Attributes::Custom(data), Attributes::Custom(o_data)) => {
            let mut data = data.clone();
            data.extend(o_data.clone());
            Attributes::Custom(data)
        },
        (Attributes::Custom(data), _) => Attributes::Custom(data.clone()),
        _ => other,
    }
}

fn compose_attributes(left: Attributes, right: Attributes) -> Attributes {
    log::trace!("compose_attributes: a: {:?}, b: {:?}", left, right);

    let attr = match (&left, &right) {
        (_, Attributes::Empty) => Attributes::Empty,
        (_, Attributes::Custom(_)) => merge_attributes(left, right),
        (Attributes::Custom(_), _) => merge_attributes(left, right),
        _ => Attributes::Follow,
    };

    log::trace!("composed_attributes: a: {:?}", attr);
    attr.apply_rule()
}

fn transform_attributes(left: Attributes, right: Attributes) -> Attributes {
    match (left, right) {
        (Attributes::Custom(data_l), Attributes::Custom(data_r)) => {
            let result = data_r
                .iter()
                .fold(AttributesData::new(), |mut new_attr_data, (k, v)| {
                    if !data_l.contains_key(k) {
                        new_attr_data.insert(k.clone(), v.clone());
                    }
                    new_attr_data
                });

            Attributes::Custom(result)
        },
        _ => Attributes::Empty,
    }
}
