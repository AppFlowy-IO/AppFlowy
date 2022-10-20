use crate::editor::document::Document;

use bytes::Bytes;
use flowy_error::FlowyResult;
use lib_ot::core::{
    AttributeHashMap, Body, Changeset, Extension, NodeData, NodeId, NodeOperation, NodeTree, Path, Selection,
    Transaction,
};
use lib_ot::text_delta::TextOperations;
use serde::de::{self, MapAccess, Visitor};
use serde::ser::{SerializeMap, SerializeSeq};
use serde::{Deserialize, Deserializer, Serialize, Serializer};
use std::fmt;

impl Serialize for Document {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: Serializer,
    {
        let mut map = serializer.serialize_map(Some(1))?;
        let _ = map.serialize_key("document")?;
        let _ = map.serialize_value(&DocumentContentSerializer(self))?;
        map.end()
    }
}

const FIELDS: &[&str] = &["Document"];

impl<'de> Deserialize<'de> for Document {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: Deserializer<'de>,
    {
        struct DocumentVisitor();

        impl<'de> Visitor<'de> for DocumentVisitor {
            type Value = Document;

            fn expecting(&self, formatter: &mut fmt::Formatter) -> fmt::Result {
                formatter.write_str("Expect document tree")
            }

            fn visit_map<M>(self, mut map: M) -> Result<Document, M::Error>
            where
                M: MapAccess<'de>,
            {
                let mut node_tree = None;
                while let Some(key) = map.next_key()? {
                    match key {
                        "document" => {
                            if node_tree.is_some() {
                                return Err(de::Error::duplicate_field("document"));
                            }
                            node_tree = Some(map.next_value::<NodeTree>()?)
                        }
                        s => {
                            return Err(de::Error::unknown_field(s, FIELDS));
                        }
                    }
                }

                match node_tree {
                    Some(tree) => Ok(Document::new(tree)),
                    None => Err(de::Error::missing_field("document")),
                }
            }
        }
        deserializer.deserialize_any(DocumentVisitor())
    }
}

#[derive(Debug)]
struct DocumentContentSerializer<'a>(pub &'a Document);

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DocumentTransaction {
    #[serde(default)]
    operations: Vec<DocumentOperation>,

    #[serde(default)]
    before_selection: Selection,

    #[serde(default)]
    after_selection: Selection,
}

impl DocumentTransaction {
    pub fn to_json(&self) -> FlowyResult<String> {
        let json = serde_json::to_string(self)?;
        Ok(json)
    }

    pub fn to_bytes(&self) -> FlowyResult<Bytes> {
        let data = serde_json::to_vec(&self)?;
        Ok(Bytes::from(data))
    }

    pub fn from_bytes(bytes: Bytes) -> FlowyResult<Self> {
        let transaction = serde_json::from_slice(&bytes)?;
        Ok(transaction)
    }
}

impl std::convert::From<Transaction> for DocumentTransaction {
    fn from(transaction: Transaction) -> Self {
        let (before_selection, after_selection) = match transaction.extension {
            Extension::Empty => (Selection::default(), Selection::default()),
            Extension::TextSelection {
                before_selection,
                after_selection,
            } => (before_selection, after_selection),
        };

        DocumentTransaction {
            operations: transaction
                .operations
                .into_inner()
                .into_iter()
                .map(|operation| operation.as_ref().into())
                .collect(),
            before_selection,
            after_selection,
        }
    }
}

impl std::convert::From<DocumentTransaction> for Transaction {
    fn from(transaction: DocumentTransaction) -> Self {
        Transaction {
            operations: transaction
                .operations
                .into_iter()
                .map(|operation| operation.into())
                .collect::<Vec<NodeOperation>>()
                .into(),
            extension: Extension::TextSelection {
                before_selection: transaction.before_selection,
                after_selection: transaction.after_selection,
            },
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "op")]
pub enum DocumentOperation {
    #[serde(rename = "insert")]
    Insert { path: Path, nodes: Vec<DocumentNode> },

    #[serde(rename = "delete")]
    Delete { path: Path, nodes: Vec<DocumentNode> },

    #[serde(rename = "update")]
    Update {
        path: Path,
        attributes: AttributeHashMap,
        #[serde(rename = "oldAttributes")]
        old_attributes: AttributeHashMap,
    },

    #[serde(rename = "update_text")]
    UpdateText {
        path: Path,
        delta: TextOperations,
        inverted: TextOperations,
    },
}

impl std::convert::From<DocumentOperation> for NodeOperation {
    fn from(document_operation: DocumentOperation) -> Self {
        match document_operation {
            DocumentOperation::Insert { path, nodes } => NodeOperation::Insert {
                path,
                nodes: nodes.into_iter().map(|node| node.into()).collect(),
            },
            DocumentOperation::Delete { path, nodes } => NodeOperation::Delete {
                path,

                nodes: nodes.into_iter().map(|node| node.into()).collect(),
            },
            DocumentOperation::Update {
                path,
                attributes,
                old_attributes,
            } => NodeOperation::Update {
                path,
                changeset: Changeset::Attributes {
                    new: attributes,
                    old: old_attributes,
                },
            },
            DocumentOperation::UpdateText { path, delta, inverted } => NodeOperation::Update {
                path,
                changeset: Changeset::Delta { delta, inverted },
            },
        }
    }
}

impl std::convert::From<&NodeOperation> for DocumentOperation {
    fn from(node_operation: &NodeOperation) -> Self {
        let node_operation = node_operation.clone();
        match node_operation {
            NodeOperation::Insert { path, nodes } => DocumentOperation::Insert {
                path,
                nodes: nodes.into_iter().map(|node| node.into()).collect(),
            },
            NodeOperation::Update { path, changeset } => match changeset {
                Changeset::Delta { delta, inverted } => DocumentOperation::UpdateText { path, delta, inverted },
                Changeset::Attributes { new, old } => DocumentOperation::Update {
                    path,
                    attributes: new,
                    old_attributes: old,
                },
            },
            NodeOperation::Delete { path, nodes } => DocumentOperation::Delete {
                path,
                nodes: nodes.into_iter().map(|node| node.into()).collect(),
            },
        }
    }
}

#[derive(Default, Debug, Clone, Serialize, Deserialize, Eq, PartialEq)]
pub struct DocumentNode {
    #[serde(rename = "type")]
    pub node_type: String,

    #[serde(skip_serializing_if = "AttributeHashMap::is_empty")]
    #[serde(default)]
    pub attributes: AttributeHashMap,

    #[serde(skip_serializing_if = "TextOperations::is_empty")]
    pub delta: TextOperations,

    #[serde(skip_serializing_if = "Vec::is_empty")]
    #[serde(default)]
    pub children: Vec<DocumentNode>,
}

impl std::convert::From<NodeData> for DocumentNode {
    fn from(node_data: NodeData) -> Self {
        let delta = if let Body::Delta(operations) = node_data.body {
            operations
        } else {
            TextOperations::default()
        };
        DocumentNode {
            node_type: node_data.node_type,
            attributes: node_data.attributes,
            delta,
            children: node_data.children.into_iter().map(DocumentNode::from).collect(),
        }
    }
}

impl std::convert::From<DocumentNode> for NodeData {
    fn from(document_node: DocumentNode) -> Self {
        NodeData {
            node_type: document_node.node_type,
            attributes: document_node.attributes,
            body: Body::Delta(document_node.delta),
            children: document_node.children.into_iter().map(|child| child.into()).collect(),
        }
    }
}

impl<'a> Serialize for DocumentContentSerializer<'a> {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: Serializer,
    {
        let tree = self.0.get_tree();
        let root_node_id = tree.root_node_id();

        // transform the NodeData to DocumentNodeData
        let get_document_node_data = |node_id: NodeId| tree.get_node_data(node_id).map(DocumentNode::from);

        let mut children = tree.get_children_ids(root_node_id);
        if children.len() == 1 {
            let node_id = children.pop().unwrap();
            match get_document_node_data(node_id) {
                None => serializer.serialize_str(""),
                Some(node_data) => node_data.serialize(serializer),
            }
        } else {
            let mut seq = serializer.serialize_seq(Some(children.len()))?;
            for child in children {
                if let Some(node_data) = get_document_node_data(child) {
                    let _ = seq.serialize_element(&node_data)?;
                }
            }
            seq.end()
        }
    }
}

#[cfg(test)]
mod tests {
    use crate::editor::document::Document;
    use crate::editor::document_serde::DocumentTransaction;

    #[test]
    fn transaction_deserialize_update_text_operation_test() {
        //{"operations":[{"op":"update_text","path":[0,0],"delta":[{"insert":"/"}],"inverted":[{"delete":1}]}],"after_selection":{"start":{"path":[0,0],"offset":1},"end":{"path":[0,0],"offset":1}},"before_selection":{"start":{"path":[0,0],"offset":0},"end":{"path":[0,0],"offset":0}}}
        // {"operations":[{"op":"update_text","path":[0,0],"delta":[{"delete":1}],"inverted":[{"insert":"/"}]}],"after_selection":{"start":{"path":[0,0],"offset":0},"end":{"path":[0,0],"offset":0}},"before_selection":{"start":{"path":[0,0],"offset":1},"end":{"path":[0,0],"offset":1}}}

        // bold
        let json = r#"{"operations":[{"op":"update_text","path":[0],"delta":[{"retain":3,"attributes":{"bold":true}}],"inverted":[{"retain":3,"attributes":{"bold":null}}]}],"after_selection":{"start":{"path":[0],"offset":0},"end":{"path":[0],"offset":3}},"before_selection":{"start":{"path":[0],"offset":0},"end":{"path":[0],"offset":3}}}"#;
        let _ = serde_json::from_str::<DocumentTransaction>(json).unwrap();

        // delete character
        let json = r#"{"operations":[{"op":"update_text","path":[0],"delta":[{"retain":2},{"delete":1}],"inverted":[{"retain":2},{"insert":"C","attributes":{"bold":true}}]}],"after_selection":{"start":{"path":[0],"offset":2},"end":{"path":[0],"offset":2}},"before_selection":{"start":{"path":[0],"offset":3},"end":{"path":[0],"offset":3}}}"#;
        let _ = serde_json::from_str::<DocumentTransaction>(json).unwrap();
    }

    #[test]
    fn transaction_deserialize_insert_operation_test() {
        let json = r#"{"operations":[{"op":"update_text","path":[0],"delta":[{"insert":"a"}],"inverted":[{"delete":1}]}],"after_selection":{"start":{"path":[0],"offset":1},"end":{"path":[0],"offset":1}},"before_selection":{"start":{"path":[0],"offset":0},"end":{"path":[0],"offset":0}}}"#;
        let _ = serde_json::from_str::<DocumentTransaction>(json).unwrap();
    }

    #[test]
    fn transaction_deserialize_delete_operation_test() {
        let json = r#"{"operations": [{"op":"delete","path":[1],"nodes":[{"type":"text","delta":[]}]}],"after_selection":{"start":{"path":[0],"offset":2},"end":{"path":[0],"offset":2}},"before_selection":{"start":{"path":[1],"offset":0},"end":{"path":[1],"offset":0}}}"#;
        let _transaction = serde_json::from_str::<DocumentTransaction>(json).unwrap();
    }

    #[test]
    fn transaction_deserialize_update_attribute_operation_test() {
        // let json = r#"{"operations":[{"op":"update","path":[0],"attributes":{"retain":3,"attributes":{"bold":true}},"oldAttributes":{"retain":3,"attributes":{"bold":null}}}]}"#;
        // let transaction = serde_json::from_str::<DocumentTransaction>(&json).unwrap();

        let json =
            r#"{"operations":[{"op":"update","path":[0],"attributes":{"retain":3},"oldAttributes":{"retain":3}}]}"#;
        let _ = serde_json::from_str::<DocumentTransaction>(json).unwrap();
    }

    #[test]
    fn document_serde_test() {
        let document: Document = serde_json::from_str(EXAMPLE_DOCUMENT).unwrap();
        let _ = serde_json::to_string_pretty(&document).unwrap();
    }

    const EXAMPLE_DOCUMENT: &str = r#"{
  "document": {
    "type": "editor",
    "children": [
      {
        "type": "image",
        "attributes": {
          "image_src": "https://s1.ax1x.com/2022/08/26/v2sSbR.jpg",
          "align": "center"
        }
      },
      {
        "type": "text",
        "attributes": { "subtype": "heading", "heading": "h1" },
        "delta": [
          { "insert": "👋 " },
          { "insert": "Welcome to ", "attributes": { "bold": true } },
          {
            "insert": "AppFlowy Editor",
            "attributes": {
              "href": "appflowy.io",
              "italic": true,
              "bold": true
            }
          }
        ]
      },
      { "type": "text", "delta": [] },
      {
        "type": "text",
        "delta": [
          { "insert": "AppFlowy Editor is a " },
          { "insert": "highly customizable", "attributes": { "bold": true } },
          { "insert": " " },
          { "insert": "rich-text editor", "attributes": { "italic": true } },
          { "insert": " for " },
          { "insert": "Flutter", "attributes": { "underline": true } }
        ]
      },
      {
        "type": "text",
        "attributes": { "checkbox": true, "subtype": "checkbox" },
        "delta": [{ "insert": "Customizable" }]
      },
      {
        "type": "text",
        "attributes": { "checkbox": true, "subtype": "checkbox" },
        "delta": [{ "insert": "Test-covered" }]
      },
      {
        "type": "text",
        "attributes": { "checkbox": false, "subtype": "checkbox" },
        "delta": [{ "insert": "more to come!" }]
      },
      { "type": "text", "delta": [] },
      {
        "type": "text",
        "attributes": { "subtype": "quote" },
        "delta": [{ "insert": "Here is an example you can give a try" }]
      },
      { "type": "text", "delta": [] },
      {
        "type": "text",
        "delta": [
          { "insert": "You can also use " },
          {
            "insert": "AppFlowy Editor",
            "attributes": {
              "italic": true,
              "bold": true,
              "backgroundColor": "0x6000BCF0"
            }
          },
          { "insert": " as a component to build your own app." }
        ]
      },
      { "type": "text", "delta": [] },
      {
        "type": "text",
        "attributes": { "subtype": "bulleted-list" },
        "delta": [{ "insert": "Use / to insert blocks" }]
      },
      {
        "type": "text",
        "attributes": { "subtype": "bulleted-list" },
        "delta": [
          {
            "insert": "Select text to trigger to the toolbar to format your notes."
          }
        ]
      },
      { "type": "text", "delta": [] },
      {
        "type": "text",
        "delta": [
          {
            "insert": "If you have questions or feedback, please submit an issue on Github or join the community along with 1000+ builders!"
          }
        ]
      }
    ]
  }
}
"#;
}
