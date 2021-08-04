use crate::core::Operation;
use std::{collections::HashMap, fmt};

const PLAIN: &'static str = "";
fn is_plain(s: &str) -> bool { s == PLAIN }

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
    pub fn extend(&self, other: Option<Attributes>) -> Attributes {
        log::debug!("Attribute extend: {:?} with {:?}", self, other);
        let other = other.unwrap_or(Attributes::Empty);
        let result = match (self, &other) {
            (Attributes::Custom(data), Attributes::Custom(o_data)) => {
                if !data.is_plain() {
                    let mut data = data.clone();
                    data.extend(o_data.clone());
                    Attributes::Custom(data)
                } else {
                    Attributes::Custom(data.clone())
                }
            },
            (Attributes::Custom(data), _) => Attributes::Custom(data.clone()),
            // (Attributes::Empty, _) => Attributes::Empty,
            _ => other,
        };
        log::debug!("result {:?}", result);
        result
    }
    // remove attribute if the value is PLAIN
    // { "k": PLAIN } -> {}
    pub fn remove_plain(&mut self) {
        match self {
            Attributes::Follow => {},
            Attributes::Custom(data) => {
                data.remove_plain();
            },
            Attributes::Empty => {},
        }
    }

    pub fn get_attributes_data(&self) -> Option<AttributesData> {
        match self {
            Attributes::Follow => None,
            Attributes::Custom(data) => Some(data.clone()),
            Attributes::Empty => None,
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

    pub fn remove_plain(&mut self) { self.inner.retain(|_, v| !is_plain(v)); }

    pub fn extend(&mut self, other: AttributesData) { self.inner.extend(other.inner); }

    pub fn is_plain(&self) -> bool { self.inner.values().filter(|v| !is_plain(v)).count() == 0 }
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
            false => PLAIN,
        };
        self.inner.insert("bold".to_owned(), val.to_owned());
        self
    }

    pub fn italic(mut self, italic: bool) -> Self {
        let val = match italic {
            true => "true",
            false => PLAIN,
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

pub fn compose_attributes(left: &Option<Operation>, right: &Option<Operation>) -> Attributes {
    if left.is_none() && right.is_none() {
        return Attributes::Empty;
    }
    let attr_l = attributes_from(left);
    let attr_r = attributes_from(right);
    log::trace!("compose_attributes: a: {:?}, b: {:?}", attr_l, attr_r);

    let mut attr = match (&attr_l, &attr_r) {
        (_, Some(Attributes::Custom(_))) => match attr_l {
            None => attr_r.unwrap(),
            Some(_) => attr_l.unwrap().extend(attr_r.clone()),
            // Some(attr_l) => merge_attributes(attr_l, attr_r),
        },
        (Some(Attributes::Custom(_)), _) => attr_l.unwrap().extend(attr_r),
        // (Some(Attributes::Custom(_)), _) => merge_attributes(attr_l.unwrap(), attr_r),
        (Some(Attributes::Follow), Some(Attributes::Follow)) => Attributes::Follow,
        _ => Attributes::Empty,
    };

    log::trace!("composed_attributes: a: {:?}", attr);

    match &mut attr {
        Attributes::Custom(data) => {
            data.remove_plain();
            match data.is_plain() {
                true => Attributes::Empty,
                false => attr,
            }
        },
        _ => attr,
    }
}

pub fn transform_attributes(
    left: &Option<Operation>,
    right: &Option<Operation>,
    priority: bool,
) -> Attributes {
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

    if !priority {
        return attr_r.unwrap();
    }

    match (attr_l.unwrap(), attr_r.unwrap()) {
        (Attributes::Custom(attr_data_l), Attributes::Custom(attr_data_r)) => {
            let result = transform_attribute_data(attr_data_l, attr_data_r);
            Attributes::Custom(result)
        },
        _ => Attributes::Empty,
    }
}

pub fn invert_attributes(attr: Attributes, base: Attributes) -> Attributes {
    let attr = attr.get_attributes_data();
    let base = base.get_attributes_data();

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

fn transform_attribute_data(left: AttributesData, right: AttributesData) -> AttributesData {
    let result = right
        .iter()
        .fold(AttributesData::new(), |mut new_attr_data, (k, v)| {
            if !left.contains_key(k) {
                new_attr_data.insert(k.clone(), v.clone());
            }
            new_attr_data
        });
    result
}

pub fn merge_attributes(attributes: Attributes, other: Option<Attributes>) -> Attributes {
    let other = other.unwrap_or(Attributes::Empty);
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
