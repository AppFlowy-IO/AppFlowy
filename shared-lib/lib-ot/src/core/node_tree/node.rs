use super::node_serde::*;
use crate::core::attributes::{AttributeHashMap, AttributeKey, AttributeValue};
use crate::core::Body::Delta;
use crate::core::OperationTransform;
use crate::errors::OTError;
use crate::text_delta::TextOperations;
use serde::{Deserialize, Serialize};

#[derive(Default, Debug, Clone, Serialize, Deserialize, Eq, PartialEq)]
pub struct NodeData {
    #[serde(rename = "type")]
    pub node_type: String,

    #[serde(skip_serializing_if = "AttributeHashMap::is_empty")]
    #[serde(default)]
    pub attributes: AttributeHashMap,

    #[serde(serialize_with = "serialize_body")]
    #[serde(deserialize_with = "deserialize_body")]
    #[serde(skip_serializing_if = "Body::is_empty")]
    #[serde(default)]
    pub body: Body,

    #[serde(skip_serializing_if = "Vec::is_empty")]
    #[serde(default)]
    pub children: Vec<NodeData>,
}

impl NodeData {
    pub fn new<T: ToString>(node_type: T) -> NodeData {
        NodeData {
            node_type: node_type.to_string(),
            ..Default::default()
        }
    }

    pub fn split(self) -> (Node, Vec<NodeData>) {
        let node = Node {
            node_type: self.node_type,
            body: self.body,
            attributes: self.attributes,
        };

        (node, self.children)
    }
}

/// Builder for [`NodeData`]
pub struct NodeDataBuilder {
    node: NodeData,
}

impl NodeDataBuilder {
    pub fn new<T: ToString>(node_type: T) -> Self {
        Self {
            node: NodeData::new(node_type.to_string()),
        }
    }

    /// Appends a new node to the end of the builder's node children.
    pub fn add_node(mut self, node: NodeData) -> Self {
        self.node.children.push(node);
        self
    }

    /// Inserts attributes to the builder's node.
    ///
    /// The attributes will be replace if they shared the same key
    pub fn insert_attribute(mut self, key: AttributeKey, value: AttributeValue) -> Self {
        self.node.attributes.insert(key, value);
        self
    }

    /// Inserts a body to the builder's node
    pub fn insert_body(mut self, body: Body) -> Self {
        self.node.body = body;
        self
    }

    /// Returns the builder's node
    pub fn build(self) -> NodeData {
        self.node
    }
}

/// NodeBody represents as the node's data.
///
/// For the moment, the NodeBody can be Empty or Delta. We can extend
/// the NodeBody by adding a new enum type.
///
/// The NodeBody implements the [`OperationTransform`] trait which means it can perform
/// compose, transform and invert.
///
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Body {
    Empty,
    Delta(TextOperations),
}

impl std::default::Default for Body {
    fn default() -> Self {
        Body::Empty
    }
}

impl Body {
    fn is_empty(&self) -> bool {
        matches!(self, Body::Empty)
    }
}

impl OperationTransform for Body {
    /// Only the same enum variant can perform the compose operation.
    fn compose(&self, other: &Self) -> Result<Self, OTError>
    where
        Self: Sized,
    {
        match (self, other) {
            (Delta(a), Delta(b)) => a.compose(b).map(Delta),
            (Body::Empty, Body::Empty) => Ok(Body::Empty),
            (l, r) => {
                let msg = format!("{:?} can not compose {:?}", l, r);
                Err(OTError::internal().context(msg))
            }
        }
    }

    /// Only the same enum variant can perform the transform operation.
    fn transform(&self, other: &Self) -> Result<(Self, Self), OTError>
    where
        Self: Sized,
    {
        match (self, other) {
            (Delta(l), Delta(r)) => l.transform(r).map(|(ta, tb)| (Delta(ta), Delta(tb))),
            (Body::Empty, Body::Empty) => Ok((Body::Empty, Body::Empty)),
            (l, r) => {
                let msg = format!("{:?} can not compose {:?}", l, r);
                Err(OTError::internal().context(msg))
            }
        }
    }

    /// Only the same enum variant can perform the invert operation.
    fn invert(&self, other: &Self) -> Self {
        match (self, other) {
            (Delta(l), Delta(r)) => Delta(l.invert(r)),
            (Body::Empty, Body::Empty) => Body::Empty,
            (l, r) => {
                tracing::error!("{:?} can not compose {:?}", l, r);
                l.clone()
            }
        }
    }
}

/// Represents the changeset of the [`NodeBody`]
///
/// Each NodeBody except the Empty should have its corresponding changeset variant.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum Changeset {
    Delta {
        delta: TextOperations,
        inverted: TextOperations,
    },
    Attributes {
        new: AttributeHashMap,
        old: AttributeHashMap,
    },
}

impl Changeset {
    pub fn inverted(&self) -> Changeset {
        match self {
            Changeset::Delta { delta, inverted } => Changeset::Delta {
                delta: inverted.clone(),
                inverted: delta.clone(),
            },
            Changeset::Attributes { new, old } => Changeset::Attributes {
                new: old.clone(),
                old: new.clone(),
            },
        }
    }
}

/// [`Node`] represents as a leaf in the [`NodeTree`].
///
#[derive(Clone, Eq, PartialEq, Debug)]
pub struct Node {
    pub node_type: String,
    pub body: Body,
    pub attributes: AttributeHashMap,
}

impl Node {
    pub fn new(node_type: &str) -> Node {
        Node {
            node_type: node_type.into(),
            attributes: AttributeHashMap::new(),
            body: Body::Empty,
        }
    }

    pub fn apply_changeset(&mut self, changeset: Changeset) -> Result<(), OTError> {
        match changeset {
            Changeset::Delta { delta, inverted: _ } => {
                let new_body = self.body.compose(&Delta(delta))?;
                self.body = new_body;
                Ok(())
            }
            Changeset::Attributes { new, old: _ } => {
                let new_attributes = AttributeHashMap::compose(&self.attributes, &new)?;
                self.attributes = new_attributes;
                Ok(())
            }
        }
    }
}

impl std::convert::From<NodeData> for Node {
    fn from(node: NodeData) -> Self {
        Self {
            node_type: node.node_type,
            attributes: node.attributes,
            body: node.body,
        }
    }
}

impl std::convert::From<&NodeData> for Node {
    fn from(node: &NodeData) -> Self {
        Self {
            node_type: node.node_type.clone(),
            attributes: node.attributes.clone(),
            body: node.body.clone(),
        }
    }
}
