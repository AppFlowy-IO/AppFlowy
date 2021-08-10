use crate::core::{AttributesData, Operation};
use std::{fmt, fmt::Formatter};

pub trait AttributesRule {
    // Remove the empty attribute that its value is empty. e.g. {bold: ""}.
    fn remove_empty(self) -> Attributes;
}

impl AttributesRule for Attributes {
    fn remove_empty(self) -> Attributes {
        match self {
            Attributes::Follow => self,
            Attributes::Custom(mut data) => {
                data.remove_empty_value();
                data.into()
            },
        }
    }
}

#[derive(Debug, PartialEq, Clone, serde::Serialize, serde::Deserialize)]
#[serde(untagged)]
pub enum Attributes {
    #[serde(skip)]
    Follow,
    Custom(AttributesData),
}

impl fmt::Display for Attributes {
    fn fmt(&self, f: &mut Formatter<'_>) -> fmt::Result {
        match self {
            Attributes::Follow => f.write_str("follow"),
            Attributes::Custom(data) => f.write_fmt(format_args!("{}", data)),
        }
    }
}

impl Attributes {
    pub fn data(&self) -> Option<AttributesData> {
        match self {
            Attributes::Follow => None,
            Attributes::Custom(data) => Some(data.clone()),
        }
    }

    pub fn is_empty(&self) -> bool {
        match self {
            Attributes::Follow => false,
            Attributes::Custom(data) => data.is_empty(),
        }
    }
}

impl std::default::Default for Attributes {
    fn default() -> Self { Attributes::Custom(AttributesData::new()) }
}

pub(crate) fn attributes_from(operation: &Option<Operation>) -> Option<Attributes> {
    match operation {
        None => None,
        Some(operation) => Some(operation.get_attributes()),
    }
}

pub fn compose_operation(left: &Option<Operation>, right: &Option<Operation>) -> Attributes {
    if left.is_none() && right.is_none() {
        return Attributes::default();
    }
    let attr_left = attributes_from(left);
    let attr_right = attributes_from(right);

    if attr_left.is_none() {
        return attr_right.unwrap();
    }

    if attr_right.is_none() {
        return attr_left.unwrap();
    }

    let left = attr_left.unwrap();
    let right = attr_right.unwrap();
    log::trace!("compose attributes: a: {:?}, b: {:?}", left, right);
    let attr = match (&left, &right) {
        (_, Attributes::Custom(_)) => merge_attributes(left, right),
        (Attributes::Custom(_), _) => merge_attributes(left, right),
        _ => Attributes::Follow,
    };
    log::trace!("compose attributes result: {:?}", attr);
    attr
}

pub fn transform_operation(left: &Option<Operation>, right: &Option<Operation>) -> Attributes {
    let attr_l = attributes_from(left);
    let attr_r = attributes_from(right);

    if attr_l.is_none() {
        if attr_r.is_none() {
            return Attributes::default();
        }

        return match attr_r.as_ref().unwrap() {
            Attributes::Follow => Attributes::Follow,
            Attributes::Custom(_) => attr_r.unwrap(),
        };
    }

    let left = attr_l.unwrap();
    let right = attr_r.unwrap();
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
        _ => Attributes::default(),
    }
}

pub fn invert_attributes(attr: Attributes, base: Attributes) -> Attributes {
    let attr = attr.data();
    let base = base.data();

    if attr.is_none() && base.is_none() {
        return Attributes::default();
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
            data.extend(Some(o_data.clone()));
            Attributes::Custom(data)
        },
        (Attributes::Custom(data), _) => Attributes::Custom(data.clone()),
        _ => other,
    }
}
