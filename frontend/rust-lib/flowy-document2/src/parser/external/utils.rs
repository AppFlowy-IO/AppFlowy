use crate::parser::constant::*;
use crate::parser::parser_entities::{InsertDelta, NestedBlock};
use scraper::node::Attrs;
use scraper::ElementRef;
use serde::{Deserialize, Serialize};
use serde_json::{Map, Value};
use std::collections::HashMap;

const INLINE_TAGS: [&str; 9] = [
  A_TAG_NAME,
  EM_TAG_NAME,
  STRONG_TAG_NAME,
  U_TAG_NAME,
  S_TAG_NAME,
  CODE_TAG_NAME,
  SPAN_TAG_NAME,
  BR_TAG_NAME,
  "",
];

const SRC: &str = "src";
const HREF: &str = "href";
const ROLE: &str = "role";
const CHECKBOX: &str = "checkbox";
const ARIA_CHECKED: &str = "aria-checked";
const CLASS: &str = "class";
const STYLE: &str = "style";

#[derive(Debug, Serialize, Deserialize)]
pub enum JSONResult {
  Block(NestedBlock),
  Delta(InsertDelta),
  BlockArray(Vec<NestedBlock>),
  DeltaArray(Vec<InsertDelta>),
}

/// Flatten element to block
pub fn flatten_element_to_block(node: ElementRef) -> Option<NestedBlock> {
  if let Some(JSONResult::Block(block)) = flatten_element_to_json(node, &None, &None) {
    return Some(block);
  }

  None
}

/// Parse plaintext to nested block
pub fn parse_plaintext_to_nested_block(plaintext: &str) -> Option<NestedBlock> {
  let lines: Vec<&str> = plaintext.lines().collect();
  let mut current_block: NestedBlock = NestedBlock {
    ty: PAGE.to_string(),
    data: HashMap::new(),
    children: Vec::new(),
  };

  for line in lines {
    let trimmed_line = line.trim();
    if !trimmed_line.is_empty() {
      let mut data = HashMap::new();

      // Insert plaintext into delta
      if let Ok(delta) = serde_json::to_value(vec![InsertDelta {
        insert: trimmed_line.to_string(),
        attributes: None,
      }]) {
        data.insert(DELTA.to_string(), delta);
      }

      // Create a new block for each non-empty line
      current_block.children.push(NestedBlock {
        ty: PARAGRAPH.to_string(),
        data,
        children: Vec::new(),
      });
    }
  }

  if current_block.children.is_empty() {
    return None;
  }
  Some(current_block)
}

fn flatten_element_to_json(
  node: ElementRef,
  list_type: &Option<String>,
  attributes: &Option<HashMap<String, Value>>,
) -> Option<JSONResult> {
  let tag_name = get_tag_name(node.to_owned());

  if tag_name == "meta" {
    return None;
  }

  if INLINE_TAGS.contains(&tag_name.as_str()) {
    return process_inline_element(node, attributes);
  }

  match tag_name.as_str() {
    H1_TAG_NAME | H2_TAG_NAME | H3_TAG_NAME | H4_TAG_NAME | H5_TAG_NAME | H6_TAG_NAME => {
      process_heading_element(node)
    },
    UL_TAG_NAME | OL_TAG_NAME | LI_TAG_NAME | BLOCKQUOTE_TAG_NAME => {
      process_list_element(node, list_type.to_owned())
    },
    PRE_TAG_NAME => process_code_element(node),
    IMG_TAG_NAME => process_image_element(node),
    B_TAG_NAME => process_b_container_element(node),
    _ => process_default_element(node),
  }
}

fn process_default_element(node: ElementRef) -> Option<JSONResult> {
  let tag_name = get_tag_name(node.to_owned());
  let mut data = HashMap::new();
  let ty = match tag_name.as_str() {
    HTML_TAG_NAME => PAGE.to_string(),
    P_TAG_NAME => PARAGRAPH.to_string(),
    ASIDE_TAG_NAME => CALLOUT.to_string(),
    HR_TAG_NAME => DIVIDER.to_string(),
    _ => PARAGRAPH.to_string(),
  };

  let (delta, children) = process_node_children(node, &None, &None);

  if !delta.is_empty() {
    data.insert(DELTA.to_string(), serde_json::to_value(delta).unwrap());
  }

  Some(JSONResult::Block(NestedBlock { ty, children, data }))
}

// compatible with google doc, there has a <b> tag, but it's not bold, it's a container.
fn process_b_container_element(node: ElementRef) -> Option<JSONResult> {
  let mut data = HashMap::new();
  let (delta, children) = process_node_children(node, &None, &None);
  if !delta.is_empty() {
    data.insert(DELTA.to_string(), serde_json::to_value(delta).unwrap());
  }
  Some(JSONResult::BlockArray(children))
}

fn process_image_element(node: ElementRef) -> Option<JSONResult> {
  let mut data = HashMap::new();
  if let Some(src) = find_attribute_value(node, SRC) {
    data.insert(URL.to_string(), Value::String(src));
  }
  Some(JSONResult::Block(NestedBlock {
    ty: IMAGE.to_string(),
    children: vec![],
    data,
  }))
}

fn process_code_element(node: ElementRef) -> Option<JSONResult> {
  let mut data = HashMap::new();

  // find code element and get language and delta, then insert into data
  if let Some(code_child) = node
    .children()
    .find(|child| {
      if let Some(child_element) = ElementRef::wrap(child.to_owned()) {
        return child_element.value().name() == CODE_TAG_NAME;
      }
      false
    })
    .and_then(|child| ElementRef::wrap(child.to_owned()))
  {
    // get language
    if let Some(class) = find_attribute_value(code_child.to_owned(), CLASS) {
      let lang = class.split('-').last().unwrap_or_default();
      data.insert(LANGUAGE.to_string(), Value::String(lang.to_string()));
    }
    // get delta
    let text = code_child.text().collect::<String>();
    if let Ok(delta) = serde_json::to_value(vec![InsertDelta {
      insert: text,
      attributes: None,
    }]) {
      data.insert(DELTA.to_string(), delta);
    }
  }

  Some(JSONResult::Block(NestedBlock {
    ty: CODE.to_string(),
    children: vec![],
    data,
  }))
}

// process "ul" | "ol" | "li" | "blockquote"
fn process_list_element(node: ElementRef, list_type: Option<String>) -> Option<JSONResult> {
  let tag_name = get_tag_name(node.to_owned());

  match tag_name.as_str() {
    UL_TAG_NAME | OL_TAG_NAME => {
      let ty = if tag_name == UL_TAG_NAME {
        BULLETED_LIST.to_string()
      } else {
        NUMBERED_LIST.to_string()
      };
      // Expand children of <ul> or <ol> element.
      // Example: <ul><li>1</li><li>2</li></ul> => [{ type: "bulleted_list", data: { delta: [{ insert: "1" }] } }, { type: "bulleted_list", data: { delta: [{ insert: "2" }] } }]
      let (_, children) = process_node_children(node, &Some(ty), &None);
      Some(JSONResult::BlockArray(children))
    },
    LI_TAG_NAME => process_li_element(node, list_type),
    BLOCKQUOTE_TAG_NAME => process_li_element(node, Some(QUOTE.to_string())),
    _ => Some(JSONResult::BlockArray(vec![])),
  }
}

// process <li> element, if it's a checkbox, then return a todo list, otherwise return a normal list.
fn process_li_element(node: ElementRef, list_type: Option<String>) -> Option<JSONResult> {
  let ty = list_type.unwrap_or(BULLETED_LIST.to_string());
  let mut data = HashMap::new();
  if let Some(role) = find_attribute_value(node.to_owned(), ROLE) {
    if role == CHECKBOX {
      if let Some(checked_attr) = find_attribute_value(node.to_owned(), ARIA_CHECKED) {
        let checked = match checked_attr.as_str() {
          "true" => true,
          "false" => false,
          _ => false,
        };
        data.insert(CHECKED.to_string(), serde_json::to_value(checked).unwrap());
      }
      data.insert(CHECKED.to_string(), serde_json::to_value(false).unwrap());
      return process_li_child_element(node, TODO_LIST, &mut data);
    }
  }
  process_li_child_element(node, &ty, &mut data)
}

fn process_li_child_element(
  node: ElementRef,
  ty: &str,
  data: &mut HashMap<String, Value>,
) -> Option<JSONResult> {
  let (delta, children) = process_node_children(node, &Some(ty.to_string()), &None);

  // Compatible with Notion documents because Notion document lists are formatted differently.
  // JSON format: { "type": "numbered_list", delta: [{ "insert": "Hello World!" }] }, children: [{ "type": "paragraph", delta: [{ "insert": "This is a paragraph" }] }]
  // Notion HTML format: <ol><li><p>Hello World!</p><p>This is a paragraph</p></li></ol>
  // AppFlowy HTML format: <ol><li>Hello World!<p>This is a paragraph</p></li></ol>
  if delta.is_empty() {
    if let Some(first_child) = children.first() {
      let mut data = HashMap::new();
      if let Some(first_child_delta) = first_child.data.get(DELTA) {
        data.insert(DELTA.to_string(), first_child_delta.to_owned());
        let rest_children = children.iter().skip(1).cloned().collect();
        return Some(JSONResult::Block(NestedBlock {
          ty: ty.to_string(),
          children: rest_children,
          data,
        }));
      }
    }
  } else {
    data.insert(DELTA.to_string(), serde_json::to_value(delta).unwrap());
  }

  Some(JSONResult::Block(NestedBlock {
    ty: ty.to_string(),
    children,
    data: data.to_owned(),
  }))
}

fn process_heading_element(node: ElementRef) -> Option<JSONResult> {
  let tag_name = get_tag_name(node.to_owned());
  let level = match tag_name.chars().last().unwrap_or_default() {
    '1' => 1,
    '2' => 2,
    // default to h3 even if it's h4, h5, h6
    _ => 3,
  };

  let mut data = HashMap::new();
  data.insert(LEVEL.to_string(), serde_json::to_value(level).unwrap());

  let (delta, children) = process_node_children(node, &None, &None);
  if !delta.is_empty() {
    data.insert(DELTA.to_string(), serde_json::to_value(delta).unwrap());
  }

  Some(JSONResult::Block(NestedBlock {
    ty: HEADING.to_string(),
    children,
    data,
  }))
}

// process <a> <em> <strong> <u> <s> <code> <span> <br>
fn process_inline_element(
  node: ElementRef,
  attributes: &Option<HashMap<String, Value>>,
) -> Option<JSONResult> {
  let tag_name = get_tag_name(node.to_owned());

  let attrs = attrs_to_map(node.value().attrs().to_owned());
  let attributes = get_delta_attributes_for(&tag_name, attrs, attributes);
  let (delta, children) = process_node_children(node, &None, &attributes);
  Some(if !delta.is_empty() {
    JSONResult::DeltaArray(delta)
  } else {
    JSONResult::BlockArray(children)
  })
}

fn process_node_children(
  node: ElementRef,
  list_type: &Option<String>,
  attributes: &Option<HashMap<String, Value>>,
) -> (Vec<InsertDelta>, Vec<NestedBlock>) {
  let tag_name = get_tag_name(node.to_owned());
  let mut delta = Vec::new();
  let mut children = Vec::new();

  for child in node.children() {
    if let Some(child_element) = ElementRef::wrap(child) {
      if let Some(child_json) = flatten_element_to_json(child_element, list_type, attributes) {
        match child_json {
          JSONResult::Delta(op) => delta.push(op),
          JSONResult::Block(block) => children.push(block),
          JSONResult::BlockArray(blocks) => children.extend(blocks),
          JSONResult::DeltaArray(ops) => delta.extend(ops),
        }
      }
    } else {
      // put text into delta while child is a text node
      let text = child
        .value()
        .as_text()
        .map(|text| {
          let text = text.text.to_string();

          if text.trim().is_empty() {
            return text.trim().to_string();
          }

          text
        })
        .unwrap_or_default();
      let attrs = attrs_to_map(node.value().attrs().to_owned());

      if let Some(op) = node_to_delta(&tag_name, text, attrs, attributes) {
        delta.push(op);
      }
    }
  }

  (delta, children)
}

// get attributes from style
// for example: style="font-weight: bold; font-style: italic; text-decoration: underline; text-decoration: line-through;"
fn get_attributes_with_style(style: &str) -> HashMap<String, Value> {
  let mut attributes = HashMap::new();
  if style.contains("font-weight: bold") {
    attributes.insert(BOLD.to_string(), Value::Bool(true));
  }
  if style.contains("font-style: italic") {
    attributes.insert(ITALIC.to_string(), Value::Bool(true));
  }
  if style.contains("text-decoration: underline") {
    attributes.insert(UNDERLINE.to_string(), Value::Bool(true));
  }
  if style.contains("text-decoration: line-through") {
    attributes.insert(STRIKETHROUGH.to_string(), Value::Bool(true));
  }
  attributes
}

// get attributes from tag name
// input <a href="https://www.google.com">Google</a>
// export attributes: { "href": "https://www.google.com" }
// input <em>Italic</em>
// export attributes: { "italic": true }
// input <strong>Bold</strong>
// export attributes: { "bold": true }
// input <u>Underline</u>
// export attributes: { "underline": true }
// input <s>Strikethrough</s>
// export attributes: { "strikethrough": true }
// input <code>Code</code>
// export attributes: { "code": true }
fn get_delta_attributes_for(
  tag_name: &str,
  attributes: Option<Map<String, Value>>,
  parent_attributes: &Option<HashMap<String, Value>>,
) -> Option<HashMap<String, Value>> {
  let style = attributes
    .as_ref()
    .and_then(|attrs| attrs.get(STYLE))
    .map(|v| v.to_string())
    .unwrap_or_default();
  let href = attributes
    .as_ref()
    .and_then(|attrs| attrs.get(HREF))
    .map(|v| v.to_string())
    .unwrap_or_default()
    .trim_matches('"')
    .to_string();
  let mut attributes = get_attributes_with_style(&style);
  if let Some(parent_attributes) = parent_attributes {
    parent_attributes.iter().for_each(|(k, v)| {
      attributes.insert(k.to_string(), v.clone());
    });
  }
  match tag_name {
    A_TAG_NAME => {
      attributes.insert(HREF.to_string(), Value::String(href));
    },
    EM_TAG_NAME => {
      attributes.insert(ITALIC.to_string(), Value::Bool(true));
    },
    STRONG_TAG_NAME => {
      attributes.insert(BOLD.to_string(), Value::Bool(true));
    },
    U_TAG_NAME => {
      attributes.insert(UNDERLINE.to_string(), Value::Bool(true));
    },
    S_TAG_NAME => {
      attributes.insert(STRIKETHROUGH.to_string(), Value::Bool(true));
    },
    CODE_TAG_NAME => {
      attributes.insert(CODE.to_string(), Value::Bool(true));
    },
    _ => (),
  }
  if attributes.is_empty() {
    None
  } else {
    Some(attributes)
  }
}

// transform text_node to delta
// input <a href="https://www.google.com">Google</a>
// export delta: [{ "insert": "Google", "attributes": { "href": "https://www.google.com" } }]
fn node_to_delta(
  tag_name: &str,
  text: String,
  attributes: Option<Map<String, Value>>,
  parent_attributes: &Option<HashMap<String, Value>>,
) -> Option<InsertDelta> {
  let attributes = get_delta_attributes_for(tag_name, attributes, parent_attributes);
  if text.is_empty() {
    return None;
  }
  Some(InsertDelta {
    insert: text,
    attributes,
  })
}

// transform node's attrs to map
fn attrs_to_map(attrs: Attrs) -> Option<Map<String, Value>> {
  let mut map = Map::new();
  for attr in attrs {
    map.insert(attr.0.to_string(), Value::String(attr.1.to_string()));
  }
  if map.is_empty() {
    return None;
  }
  Some(map)
}

// get tag name from node
fn get_tag_name(node: ElementRef) -> String {
  node.value().name().to_string()
}

// find attribute value from node
fn find_attribute_value(node: ElementRef, attr_name: &str) -> Option<String> {
  node
    .value()
    .attrs()
    .find(|(name, _)| *name == attr_name)
    .map(|(_, value)| value.to_string())
}
