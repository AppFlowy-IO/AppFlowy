use crate::editor::document::Document;
use lib_ot::core::NodeTree;
use serde::de::{self, MapAccess, Visitor};
use serde::ser::SerializeMap;
use serde::{Deserialize, Deserializer, Serialize, Serializer};
use std::fmt;

impl Serialize for Document {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: Serializer,
    {
        let mut map = serializer.serialize_map(Some(1))?;
        let _ = map.serialize_key("document")?;
        let _ = map.serialize_value(&self.tree)?;
        map.end()
    }
}

const FIELDS: &'static [&str] = &["Document"];

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
                    Some(tree) => Ok(Document { tree }),
                    None => Err(de::Error::missing_field("document")),
                }
            }
        }
        deserializer.deserialize_any(DocumentVisitor())
    }
}

#[cfg(test)]
mod tests {
    use crate::editor::document::Document;

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
