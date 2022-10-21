use crate::editor::{DocumentNode, DocumentOperation};
use flowy_error::FlowyResult;
use flowy_sync::entities::revision::Revision;
use lib_ot::core::{AttributeHashMap, DeltaOperation, Insert, Transaction};
use lib_ot::text_delta::{DeltaTextOperation, DeltaTextOperations};

pub struct DeltaRevisionMigration(pub Vec<Revision>);

impl DeltaRevisionMigration {
    #[allow(dead_code)]
    pub fn run(delta: DeltaTextOperations) -> FlowyResult<Transaction> {
        let migrate_background_attribute = |insert: &mut Insert<AttributeHashMap>| {
            if let Some(Some(color)) = insert.attributes.get("background").map(|value| value.str_value()) {
                insert.attributes.remove_key("background");
                insert.attributes.insert("backgroundColor", color);
            }
        };
        let migrate_strike_attribute = |insert: &mut Insert<AttributeHashMap>| {
            if let Some(Some(_)) = insert.attributes.get("strike").map(|value| value.str_value()) {
                insert.attributes.remove_key("strike");
                insert.attributes.insert("strikethrough", true);
            }
        };

        let migrate_link_attribute = |insert: &mut Insert<AttributeHashMap>| {
            if let Some(Some(link)) = insert.attributes.get("link").map(|value| value.str_value()) {
                insert.attributes.remove_key("link");
                insert.attributes.insert("href", link);
            }
        };

        let migrate_list_attribute =
            |attribute_node: &mut DocumentNode, value: &str, number_list_number: &mut usize| {
                if value == "unchecked" {
                    *number_list_number = 0;
                    attribute_node.attributes.insert("subtype", "checkbox");
                    attribute_node.attributes.insert("checkbox", false);
                }
                if value == "checked" {
                    *number_list_number = 0;
                    attribute_node.attributes.insert("subtype", "checkbox");
                    attribute_node.attributes.insert("checkbox", true);
                }

                if value == "bullet" {
                    *number_list_number = 0;
                    attribute_node.attributes.insert("subtype", "bulleted-list");
                }

                if value == "ordered" {
                    *number_list_number += 1;
                    attribute_node.attributes.insert("subtype", "number-list");
                    attribute_node.attributes.insert("number", *number_list_number);
                }
            };

        let generate_new_op_with_double_new_lines = |insert: &mut Insert<AttributeHashMap>| {
            let pattern = "\n\n";
            let mut new_ops = vec![];
            if insert.s.as_str().contains(pattern) {
                let insert_str = insert.s.clone();
                let insert_strings = insert_str.split(pattern).map(|s| s.to_owned());
                for (index, new_s) in insert_strings.enumerate() {
                    if index == 0 {
                        insert.s = new_s.into();
                    } else {
                        new_ops.push(DeltaOperation::Insert(Insert {
                            s: new_s.into(),
                            attributes: AttributeHashMap::default(),
                        }));
                    }
                }
            }
            new_ops
        };

        let create_text_node = |ops: Vec<DeltaTextOperation>| {
            let mut document_node = DocumentNode::new();
            document_node.node_type = "text".to_owned();
            ops.into_iter().for_each(|op| document_node.delta.add(op));
            document_node
        };

        let transform_op = |mut insert: Insert<AttributeHashMap>| {
            // Rename the attribute name from background to backgroundColor
            migrate_background_attribute(&mut insert);
            migrate_strike_attribute(&mut insert);
            migrate_link_attribute(&mut insert);

            let new_ops = generate_new_op_with_double_new_lines(&mut insert);
            (DeltaOperation::Insert(insert), new_ops)
        };
        let mut index: usize = 0;
        let mut number_list_number = 0;
        let mut editor_node = DocumentNode::new();
        editor_node.node_type = "editor".to_owned();

        let mut transaction = Transaction::new();
        transaction.push_operation(DocumentOperation::Insert {
            path: 0.into(),
            nodes: vec![editor_node],
        });

        let mut iter = delta.ops.into_iter().enumerate();
        while let Some((_, op)) = iter.next() {
            let mut document_node = create_text_node(vec![]);
            let mut split_document_nodes = vec![];
            match op {
                DeltaOperation::Delete(_) => tracing::warn!("Should not contain delete operation"),
                DeltaOperation::Retain(_) => tracing::warn!("Should not contain retain operation"),
                DeltaOperation::Insert(insert) => {
                    if insert.s.as_str() != "\n" {
                        let (op, new_ops) = transform_op(insert);
                        document_node.delta.add(op);
                        if !new_ops.is_empty() {
                            split_document_nodes.push(create_text_node(new_ops));
                        }
                    }

                    while let Some((_, DeltaOperation::Insert(insert))) = iter.next() {
                        if insert.s.as_str() != "\n" {
                            let (op, new_ops) = transform_op(insert);
                            document_node.delta.add(op);

                            if !new_ops.is_empty() {
                                split_document_nodes.push(create_text_node(new_ops));
                            }
                        } else {
                            let attribute_node = match split_document_nodes.last_mut() {
                                None => &mut document_node,
                                Some(split_document_node) => split_document_node,
                            };

                            if let Some(value) = insert.attributes.get("header") {
                                attribute_node.attributes.insert("subtype", "heading");
                                if let Some(v) = value.int_value() {
                                    number_list_number = 0;
                                    attribute_node.attributes.insert("heading", format!("h{}", v));
                                }
                            }

                            if insert.attributes.get("blockquote").is_some() {
                                attribute_node.attributes.insert("subtype", "quote");
                            }

                            if let Some(value) = insert.attributes.get("list") {
                                if let Some(s) = value.str_value() {
                                    migrate_list_attribute(attribute_node, &s, &mut number_list_number);
                                }
                            }
                            break;
                        }
                    }
                }
            }
            let mut operations = vec![document_node];
            operations.extend(split_document_nodes);
            operations.into_iter().for_each(|node| {
                // println!("{}", serde_json::to_string(&node).unwrap());
                let operation = DocumentOperation::Insert {
                    path: vec![0, index].into(),
                    nodes: vec![node],
                };
                transaction.push_operation(operation);
                index += 1;
            });
        }
        Ok(transaction)
    }
}

#[cfg(test)]
mod tests {
    use crate::editor::migration::delta_migration::DeltaRevisionMigration;
    use crate::editor::Document;
    use lib_ot::text_delta::DeltaTextOperations;

    #[test]
    fn transform_delta_to_transaction_test() {
        let delta = DeltaTextOperations::from_json(DELTA_STR).unwrap();
        let transaction = DeltaRevisionMigration::run(delta).unwrap();
        let document = Document::from_transaction(transaction).unwrap();
        let s = document.get_content(true).unwrap();
        assert!(!s.is_empty());
    }

    const DELTA_STR: &str = r#"[
    {
        "insert": "\n👋 Welcome to AppFlowy!"
    },
    {
        "insert": "\n",
        "attributes": {
            "header": 1
        }
    },
    {
        "insert": "\nHere are the basics"
    },
    {
        "insert": "\n",
        "attributes": {
            "header": 2
        }
    },
    {
        "insert": "Click anywhere and just start typing"
    },
    {
        "insert": "\n",
        "attributes": {
            "list": "unchecked"
        }
    },
    {
        "insert": "Highlight",
        "attributes": {
            "background": "$fff2cd"
        }
    },
    {
        "insert": " any text, and use the menu at the bottom to "
    },
    {
        "insert": "style",
        "attributes": {
            "italic": true
        }
    },
    {
        "insert": " "
    },
    {
        "insert": "your",
        "attributes": {
            "bold": true
        }
    },
    {
        "insert": " "
    },
    {
        "insert": "writing",
        "attributes": {
            "underline": true
        }
    },
    {
        "insert": " "
    },
    {
        "insert": "however",
        "attributes": {
            "code": true
        }
    },
    {
        "insert": " "
    },
    {
        "insert": "you",
        "attributes": {
            "strike": true
        }
    },
    {
        "insert": " "
    },
    {
        "insert": "like",
        "attributes": {
            "background": "$e8e0ff"
        }
    },
    {
        "insert": "\n",
        "attributes": {
            "list": "unchecked"
        }
    },
    {
        "insert": "Click "
    },
    {
        "insert": "+ New Page",
        "attributes": {
            "background": "$defff1",
            "bold": true
        }
    },
    {
        "insert": " button at the bottom of your sidebar to add a new page"
    },
    {
        "insert": "\n",
        "attributes": {
            "list": "unchecked"
        }
    },
    {
        "insert": "Click the "
    },
    {
        "insert": "'",
        "attributes": {
            "background": "$defff1"
        }
    },
    {
        "insert": "+",
        "attributes": {
            "background": "$defff1",
            "bold": true
        }
    },
    {
        "insert": "'",
        "attributes": {
            "background": "$defff1"
        }
    },
    {
        "insert": "  next to any page title in the sidebar to quickly add a new subpage"
    },
    {
        "insert": "\n",
        "attributes": {
            "list": "unchecked"
        }
    },
    {
        "insert": "\nHave a question? "
    },
    {
        "insert": "\n",
        "attributes": {
            "header": 2
        }
    },
    {
        "insert": "Click the "
    },
    {
        "insert": "'?'",
        "attributes": {
            "background": "$defff1",
            "bold": true
        }
    },
    {
        "insert": " at the bottom right for help and support.\n\nLike AppFlowy? Follow us:"
    },
    {
        "insert": "\n",
        "attributes": {
            "header": 2
        }
    },
    {
        "insert": "GitHub: https://github.com/AppFlowy-IO/appflowy"
    },
    {
        "insert": "\n",
        "attributes": {
            "blockquote": true
        }
    },
    {
        "insert": "Twitter: https://twitter.com/appflowy"
    },
    {
        "insert": "\n",
        "attributes": {
            "blockquote": true
        }
    },
    {
        "insert": "Newsletter: https://www.appflowy.io/blog"
    },
    {
        "insert": "\n",
        "attributes": {
            "blockquote": true
        }
    },
    {
        "insert": "item 1"
    },
    {
        "insert": "\n",
        "attributes": {
            "list": "ordered"
        }
    },
    {
        "insert": "item 2"
    },
    {
        "insert": "\n",
        "attributes": {
            "list": "ordered"
        }
    },
    {
        "insert": "item3"
    },
    {
        "insert": "\n",
        "attributes": {
            "list": "ordered"
        }
    },
    {
        "insert": "appflowy",
        "attributes": {
            "link": "https://www.appflowy.io/"
        }
    }
]"#;
}
