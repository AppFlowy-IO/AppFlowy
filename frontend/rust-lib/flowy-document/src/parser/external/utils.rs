use crate::parser::constant::*;
use crate::parser::parser_entities::{InsertDelta, NestedBlock};
use scraper::node::Attrs;
use scraper::ElementRef;
use serde::{Deserialize, Serialize};
use serde_json::Value;
use std::collections::HashMap;

const INLINE_TAGS: [&str; 18] = [
  A_TAG_NAME,
  EM_TAG_NAME,
  STRONG_TAG_NAME,
  U_TAG_NAME,
  S_TAG_NAME,
  CODE_TAG_NAME,
  SPAN_TAG_NAME,
  ADDRESS_TAG_NAME,
  BASE_TAG_NAME,
  CITE_TAG_NAME,
  DFN_TAG_NAME,
  I_TAG_NAME,
  VAR_TAG_NAME,
  ABBR_TAG_NAME,
  INS_TAG_NAME,
  DEL_TAG_NAME,
  MARK_TAG_NAME,
  "",
];

const LINK_TAGS: [&str; 2] = [A_TAG_NAME, BASE_TAG_NAME];
const ITALIC_TAGS: [&str; 6] = [
  EM_TAG_NAME,
  I_TAG_NAME,
  VAR_TAG_NAME,
  CITE_TAG_NAME,
  DFN_TAG_NAME,
  ADDRESS_TAG_NAME,
];

const BOLD_TAGS: [&str; 2] = [STRONG_TAG_NAME, B_TAG_NAME];

const UNDERLINE_TAGS: [&str; 3] = [U_TAG_NAME, ABBR_TAG_NAME, INS_TAG_NAME];
const STRIKETHROUGH_TAGS: [&str; 2] = [S_TAG_NAME, DEL_TAG_NAME];
const IGNORE_TAGS: [&str; 7] = [
  META_TAG_NAME,
  HEAD_TAG_NAME,
  LINK_TAG_NAME,
  SCRIPT_TAG_NAME,
  STYLE_TAG_NAME,
  NOSCRIPT_TAG_NAME,
  IFRAME_TAG_NAME,
];

const HEADING_TAGS: [&str; 6] = [
  H1_TAG_NAME,
  H2_TAG_NAME,
  H3_TAG_NAME,
  H4_TAG_NAME,
  H5_TAG_NAME,
  H6_TAG_NAME,
];

const SHOULD_EXPAND_TAGS: [&str; 4] = [UL_TAG_NAME, OL_TAG_NAME, DL_TAG_NAME, MENU_TAG_NAME];

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
  let lines: Vec<&str> = plaintext
    .lines()
    .filter(|line| !line.trim().is_empty())
    .collect();
  let mut current_block = NestedBlock {
    ty: PAGE.to_string(),
    ..Default::default()
  };

  for line in lines {
    let mut data = HashMap::new();

    // Insert plaintext into delta
    if let Ok(delta) = serde_json::to_value(vec![InsertDelta {
      insert: line.to_string(),
      attributes: None,
    }]) {
      data.insert(DELTA.to_string(), delta);
    }

    // Create a new block for each non-empty line
    current_block.children.push(NestedBlock {
      ty: PARAGRAPH.to_string(),
      data,
      children: Default::default(),
    });
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

  if IGNORE_TAGS.contains(&tag_name.as_str()) {
    return None;
  }

  if INLINE_TAGS.contains(&tag_name.as_str()) {
    return process_inline_element(node, attributes.to_owned());
  }

  let mut data = HashMap::new();
  // insert dir into attrs when dir is rtl
  // for example: <bdo dir="rtl">Right to left</bdo> -> { "attributes": { "text_direction": "rtl" }, "insert": "Right to left" }
  if let Some(dir) = find_attribute_value(node.to_owned(), DIR_ATTR_NAME) {
    data.insert(TEXT_DIRECTION.to_string(), Value::String(dir));
  }

  if HEADING_TAGS.contains(&tag_name.as_str()) {
    return process_heading_element(node, data);
  }

  if SHOULD_EXPAND_TAGS.contains(&tag_name.as_str()) {
    return process_nested_element(node);
  }

  match tag_name.as_str() {
    LI_TAG_NAME => process_li_element(node, list_type.to_owned(), data),
    BLOCKQUOTE_TAG_NAME | DETAILS_TAG_NAME => {
      process_node_summary_and_details(QUOTE.to_string(), node, data)
    },
    PRE_TAG_NAME => process_code_element(node),
    IMG_TAG_NAME => process_image_element(node),
    B_TAG_NAME => {
      // Compatible with Google Docs, <b id=xxx> is the document top level tag, so we need to process it's children
      let id = find_attribute_value(node.to_owned(), "id");
      if id.is_some() {
        return process_nested_element(node);
      }
      process_inline_element(node, attributes.to_owned())
    },

    _ => process_default_element(node, data),
  }
}

fn process_default_element(
  node: ElementRef,
  mut data: HashMap<String, Value>,
) -> Option<JSONResult> {
  let tag_name = get_tag_name(node.to_owned());

  let ty = match tag_name.as_str() {
    HTML_TAG_NAME => PAGE,
    P_TAG_NAME => PARAGRAPH,
    ASIDE_TAG_NAME | ARTICLE_TAG_NAME => CALLOUT,
    HR_TAG_NAME => DIVIDER,
    _ => PARAGRAPH,
  };

  let (delta, children) = process_node_children(node, &None, None);

  if !delta.is_empty() {
    data.insert(DELTA.to_string(), delta_to_json(&delta));
  }
  Some(JSONResult::Block(NestedBlock {
    ty: ty.to_string(),
    children,
    data,
  }))
}

fn process_image_element(node: ElementRef) -> Option<JSONResult> {
  let mut data = HashMap::new();
  if let Some(src) = find_attribute_value(node, SRC) {
    data.insert(URL.to_string(), Value::String(src));
  }
  Some(JSONResult::Block(NestedBlock {
    ty: IMAGE.to_string(),
    children: Default::default(),
    data,
  }))
}

fn process_code_element(node: ElementRef) -> Option<JSONResult> {
  let mut data = HashMap::new();

  // find code element and get language and delta, then insert into data
  if let Some(code_child) = find_child_node(node.to_owned(), CODE_TAG_NAME.to_string()) {
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
    children: Default::default(),
    data,
  }))
}

// process "ul" | "ol" | "dl" | "menu" element
fn process_nested_element(node: ElementRef) -> Option<JSONResult> {
  let tag_name = get_tag_name(node.to_owned());

  let ty = match tag_name.as_str() {
    UL_TAG_NAME => BULLETED_LIST,
    OL_TAG_NAME => NUMBERED_LIST,
    _ => PARAGRAPH,
  };
  let (_, children) = process_node_children(node, &Some(ty.to_string()), None);
  Some(JSONResult::BlockArray(children))
}

// process <li> element, if it's a checkbox, then return a todo list, otherwise return a normal list.
fn process_li_element(
  node: ElementRef,
  list_type: Option<String>,
  mut data: HashMap<String, Value>,
) -> Option<JSONResult> {
  let mut ty = list_type.unwrap_or(BULLETED_LIST.to_string());
  if let Some(role) = find_attribute_value(node.to_owned(), ROLE) {
    if role == CHECKBOX {
      if let Some(checked_attr) = find_attribute_value(node.to_owned(), ARIA_CHECKED) {
        let checked = match checked_attr.as_str() {
          "true" => true,
          "false" => false,
          _ => false,
        };
        data.insert(
          CHECKED.to_string(),
          serde_json::to_value(checked).unwrap_or_default(),
        );
      }
      data.insert(
        CHECKED.to_string(),
        serde_json::to_value(false).unwrap_or_default(),
      );
      ty = TODO_LIST.to_string();
    }
  }
  process_node_summary_and_details(ty, node, data)
}

// Process children and handle potential nesting
// <li>
//   <p> title </p>
//   <p> content </p>
// </li>
// Or Process children and handle potential consecutive arrangement
// <li>title<p>content</p></li>
// li | blockquote | details
fn process_node_summary_and_details(
  ty: String,
  node: ElementRef,
  mut data: HashMap<String, Value>,
) -> Option<JSONResult> {
  let (delta, children) = process_node_children(node, &Some(ty.to_string()), None);
  if delta.is_empty() {
    if let Some(first_child) = children.first() {
      let mut data = HashMap::new();
      if let Some(first_child_delta) = first_child.data.get(DELTA) {
        data.insert(DELTA.to_string(), first_child_delta.to_owned());
        let rest_children = children.iter().skip(1).cloned().collect();
        return Some(JSONResult::Block(NestedBlock {
          ty,
          children: rest_children,
          data,
        }));
      }
    }
  } else {
    data.insert(DELTA.to_string(), delta_to_json(&delta));
  }
  Some(JSONResult::Block(NestedBlock {
    ty,
    children,
    data: data.to_owned(),
  }))
}

fn process_heading_element(
  node: ElementRef,
  mut data: HashMap<String, Value>,
) -> Option<JSONResult> {
  let tag_name = get_tag_name(node.to_owned());
  let level = match tag_name.chars().last().unwrap_or_default() {
    '1' => 1,
    '2' => 2,
    // default to h3 even if it's h4, h5, h6
    _ => 3,
  };

  data.insert(
    LEVEL.to_string(),
    serde_json::to_value(level).unwrap_or_default(),
  );

  let (delta, children) = process_node_children(node, &None, None);
  if !delta.is_empty() {
    data.insert(
      DELTA.to_string(),
      serde_json::to_value(delta).unwrap_or_default(),
    );
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
  attributes: Option<HashMap<String, Value>>,
) -> Option<JSONResult> {
  let tag_name = get_tag_name(node.to_owned());

  let attributes = get_delta_attributes_for(&tag_name, &get_node_attrs(node), attributes);
  let (delta, children) = process_node_children(node, &None, attributes);
  Some(if !delta.is_empty() {
    JSONResult::DeltaArray(delta)
  } else {
    JSONResult::BlockArray(children)
  })
}

fn process_node_children(
  node: ElementRef,
  list_type: &Option<String>,
  attributes: Option<HashMap<String, Value>>,
) -> (Vec<InsertDelta>, Vec<NestedBlock>) {
  let tag_name = get_tag_name(node.to_owned());
  let mut delta = Vec::new();
  let mut children = Vec::new();

  for child in node.children() {
    if let Some(child_element) = ElementRef::wrap(child) {
      if let Some(child_json) = flatten_element_to_json(child_element, list_type, &attributes) {
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
        .map(|text| text.text.to_string())
        .unwrap_or_default();

      if let Some(op) = node_to_delta(&tag_name, text, &mut get_node_attrs(node), &attributes) {
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

  for property in style.split(';') {
    let parts: Vec<&str> = property.split(':').map(|s| s.trim()).collect::<Vec<&str>>();

    if parts.len() != 2 {
      continue;
    }

    let (key, value) = (parts[0], parts[1]);

    match key {
      FONT_WEIGHT if value.contains(BOLD) => {
        attributes.insert(BOLD.to_string(), Value::Bool(true));
      },
      FONT_STYLE if value.contains(ITALIC) => {
        attributes.insert(ITALIC.to_string(), Value::Bool(true));
      },
      TEXT_DECORATION if value.contains(UNDERLINE) => {
        attributes.insert(UNDERLINE.to_string(), Value::Bool(true));
      },
      TEXT_DECORATION if value.contains(LINE_THROUGH) => {
        attributes.insert(STRIKETHROUGH.to_string(), Value::Bool(true));
      },
      BACKGROUND_COLOR => {
        if value.eq(TRANSPARENT) {
          continue;
        }
        attributes.insert(BG_COLOR.to_string(), Value::String(value.to_string()));
      },
      COLOR => {
        attributes.insert(FONT_COLOR.to_string(), Value::String(value.to_string()));
      },
      _ => {},
    }
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
  attrs: &Attrs,
  parent_attributes: Option<HashMap<String, Value>>,
) -> Option<HashMap<String, Value>> {
  let href = find_attribute_value_from_attrs(attrs, HREF);

  let style = find_attribute_value_from_attrs(attrs, STYLE);

  let mut attributes = get_attributes_with_style(&style);
  if let Some(parent_attributes) = parent_attributes {
    parent_attributes.iter().for_each(|(k, v)| {
      attributes.insert(k.to_string(), v.clone());
    });
  }

  match tag_name {
    CODE_TAG_NAME => {
      attributes.insert(CODE.to_string(), Value::Bool(true));
    },
    MARK_TAG_NAME => {
      attributes.insert(BG_COLOR.to_string(), Value::String("#FFFF00".to_string()));
    },
    _ => {
      if LINK_TAGS.contains(&tag_name) {
        attributes.insert(HREF.to_string(), Value::String(href));
      }
      if ITALIC_TAGS.contains(&tag_name) {
        attributes.insert(ITALIC.to_string(), Value::Bool(true));
      }
      if BOLD_TAGS.contains(&tag_name) {
        attributes.insert(BOLD.to_string(), Value::Bool(true));
      }
      if UNDERLINE_TAGS.contains(&tag_name) {
        attributes.insert(UNDERLINE.to_string(), Value::Bool(true));
      }
      if STRIKETHROUGH_TAGS.contains(&tag_name) {
        attributes.insert(STRIKETHROUGH.to_string(), Value::Bool(true));
      }
    },
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
  attrs: &mut Attrs,
  parent_attributes: &Option<HashMap<String, Value>>,
) -> Option<InsertDelta> {
  let attributes = get_delta_attributes_for(tag_name, attrs, parent_attributes.to_owned());
  if text.trim().is_empty() {
    return None;
  }

  Some(InsertDelta {
    insert: text,
    attributes,
  })
}

// get tag name from node
fn get_tag_name(node: ElementRef) -> String {
  node.value().name().to_string()
}

fn get_node_attrs(node: ElementRef) -> Attrs {
  node.value().attrs()
}
// find attribute value from node
fn find_attribute_value(node: ElementRef, attr_name: &str) -> Option<String> {
  node
    .value()
    .attrs()
    .find(|(name, _)| *name == attr_name)
    .map(|(_, value)| value.to_string())
}

fn find_attribute_value_from_attrs(attrs: &Attrs, attr_name: &str) -> String {
  // The attrs need to be mutable, because the find method will consume the attrs
  // So we clone it and use the clone one
  let mut attrs = attrs.clone();
  attrs
    .find(|(name, _)| *name == attr_name)
    .map(|(_, value)| value.to_string())
    .unwrap_or_default()
}

fn find_child_node(node: ElementRef, child_tag_name: String) -> Option<ElementRef> {
  node
    .children()
    .find(|child| {
      if let Some(child_element) = ElementRef::wrap(child.to_owned()) {
        return get_tag_name(child_element) == child_tag_name;
      }
      false
    })
    .and_then(|child| ElementRef::wrap(child.to_owned()))
}

fn delta_to_json(delta: &Vec<InsertDelta>) -> Value {
  serde_json::to_value(delta).unwrap_or_default()
}
