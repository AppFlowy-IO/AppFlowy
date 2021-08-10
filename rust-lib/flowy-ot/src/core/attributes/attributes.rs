use crate::core::{Attribute, AttributesData, AttributesRule, Operation};
use std::{collections::HashMap, fmt, fmt::Formatter};

#[derive(Debug, PartialEq, Clone, serde::Serialize, serde::Deserialize)]
#[serde(untagged)]
pub enum Attributes {
    #[serde(skip)]
    Follow,
    Custom(AttributesData),
    #[serde(skip)]
    Empty,
}

impl fmt::Display for Attributes {
    fn fmt(&self, f: &mut Formatter<'_>) -> fmt::Result {
        match self {
            Attributes::Follow => f.write_str("follow"),
            Attributes::Custom(data) => f.write_fmt(format_args!("{:?}", data.inner)),
            Attributes::Empty => f.write_str("empty"),
        }
    }
}

impl Attributes {
    pub fn data(&self) -> Option<AttributesData> {
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
            data.extend(Some(o_data.clone()), false);
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
    attr
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
