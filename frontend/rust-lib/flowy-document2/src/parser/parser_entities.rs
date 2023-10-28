use crate::parse::NotEmptyStr;
use crate::parser::constant::{
  BG_COLOR, BOLD, BULLETED_LIST, CALLOUT, CHECKED, CODE, DELTA, DIVIDER, FONT_COLOR, FORMULA,
  HEADING, HREF, ICON, IMAGE, ITALIC, LANGUAGE, LEVEL, MATH_EQUATION, NUMBERED_LIST, PAGE,
  PARAGRAPH, QUOTE, STRIKETHROUGH, TODO_LIST, TOGGLE_LIST, UNDERLINE, URL,
};
use crate::parser::utils::{
  convert_insert_delta_from_json, convert_nested_block_children_to_html, delta_to_html,
  delta_to_text,
};
use flowy_derive::ProtoBuf;
use flowy_error::ErrorCode;
use serde::{Deserialize, Serialize};
use serde_json::Value;
use std::collections::HashMap;
use std::sync::Arc;

#[derive(Default, ProtoBuf)]
pub struct SelectionPB {
  #[pb(index = 1)]
  pub block_id: String,

  #[pb(index = 2)]
  pub index: u32,

  #[pb(index = 3)]
  pub length: u32,
}

#[derive(Default, ProtoBuf)]
pub struct RangePB {
  #[pb(index = 1)]
  pub start: SelectionPB,

  #[pb(index = 2)]
  pub end: SelectionPB,
}

/**
* ExportTypePB
 * @field json: bool // export json data
 * @field html: bool // export html data
 * @field text: bool // export text data
 */
#[derive(Default, ProtoBuf, Debug, Clone)]
pub struct ExportTypePB {
  #[pb(index = 1)]
  pub json: bool,

  #[pb(index = 2)]
  pub html: bool,

  #[pb(index = 3)]
  pub text: bool,
}
/**
* ConvertDocumentPayloadPB
 * @field document_id: String
 * @file range: Option<RangePB> - optional // if range is None, copy the whole document
 * @field export_types: [ExportTypePB]
 */
#[derive(Default, ProtoBuf)]
pub struct ConvertDocumentPayloadPB {
  #[pb(index = 1)]
  pub document_id: String,

  #[pb(index = 2, one_of)]
  pub range: Option<RangePB>,

  #[pb(index = 3)]
  pub export_types: ExportTypePB,
}

#[derive(Default, ProtoBuf, Debug)]
pub struct ConvertDocumentResponsePB {
  #[pb(index = 1, one_of)]
  pub json: Option<String>,
  #[pb(index = 2, one_of)]
  pub html: Option<String>,
  #[pb(index = 3, one_of)]
  pub text: Option<String>,
}

pub struct Selection {
  pub block_id: String,
  pub index: u32,
  pub length: u32,
}

pub struct Range {
  pub start: Selection,
  pub end: Selection,
}

pub struct ExportType {
  pub json: bool,
  pub html: bool,
  pub text: bool,
}

pub struct ConvertDocumentParams {
  pub document_id: String,
  pub range: Option<Range>,
  pub export_types: ExportType,
}

impl ExportType {
  pub fn any_enabled(&self) -> bool {
    self.json || self.html || self.text
  }
}

impl From<SelectionPB> for Selection {
  fn from(data: SelectionPB) -> Self {
    Selection {
      block_id: data.block_id,
      index: data.index,
      length: data.length,
    }
  }
}

impl From<RangePB> for Range {
  fn from(data: RangePB) -> Self {
    Range {
      start: data.start.into(),
      end: data.end.into(),
    }
  }
}

impl From<ExportTypePB> for ExportType {
  fn from(data: ExportTypePB) -> Self {
    ExportType {
      json: data.json,
      html: data.html,
      text: data.text,
    }
  }
}
impl TryInto<ConvertDocumentParams> for ConvertDocumentPayloadPB {
  type Error = ErrorCode;
  fn try_into(self) -> Result<ConvertDocumentParams, Self::Error> {
    let document_id =
      NotEmptyStr::parse(self.document_id).map_err(|_| ErrorCode::DocumentIdIsEmpty)?;
    let range = self.range.map(|data| data.into());

    Ok(ConvertDocumentParams {
      document_id: document_id.0,
      range,
      export_types: self.export_types.into(),
    })
  }
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct InsertDelta {
  #[serde(default)]
  pub insert: String,
  #[serde(default)]
  pub attributes: Option<HashMap<String, Value>>,
}

impl InsertDelta {
  pub fn to_text(&self) -> String {
    self.insert.clone()
  }

  pub fn to_html(&self) -> String {
    let mut html = String::new();
    let mut style = String::new();
    // If there are attributes, serialize them as a HashMap.
    if let Some(attrs) = &self.attributes {
      // Serialize the font color attributes.
      if let Some(color) = attrs.get(FONT_COLOR) {
        style.push_str(&format!(
          "color: {};",
          color.to_string().replace("0x", "#").trim_matches('\"')
        ));
      }
      // Serialize the background color attributes.
      if let Some(color) = attrs.get(BG_COLOR) {
        style.push_str(&format!(
          "background-color: {};",
          color.to_string().replace("0x", "#").trim_matches('\"')
        ));
      }
      // Serialize the href attributes.
      if let Some(href) = attrs.get(HREF) {
        html.push_str(&format!("<a href={}>", href));
      }

      // Serialize the code attributes.
      if let Some(code) = attrs.get(CODE) {
        if code.as_bool().unwrap_or(false) {
          html.push_str("<code>");
        }
      }
      // Serialize the italic, underline, strikethrough, bold, formula attributes.
      if let Some(italic) = attrs.get(ITALIC) {
        if italic.as_bool().unwrap_or(false) {
          style.push_str("font-style: italic;");
        }
      }
      if let Some(underline) = attrs.get(UNDERLINE) {
        if underline.as_bool().unwrap_or(false) {
          style.push_str("text-decoration: underline;");
        }
      }
      if let Some(strikethrough) = attrs.get(STRIKETHROUGH) {
        if strikethrough.as_bool().unwrap_or(false) {
          style.push_str("text-decoration: line-through;");
        }
      }
      if let Some(bold) = attrs.get(BOLD) {
        if bold.as_bool().unwrap_or(false) {
          style.push_str("font-weight: bold;");
        }
      }
      if let Some(formula) = attrs.get(FORMULA) {
        if formula.as_bool().unwrap_or(false) {
          style.push_str("font-family: fantasy;");
        }
      }
    }
    // Serialize the attributes to style.
    if !style.is_empty() {
      html.push_str(&format!("<span style=\"{}\">", style));
    }
    // Serialize the insert field.
    html.push_str(&self.insert);

    // Close the style tag.
    if !style.is_empty() {
      html.push_str("</span>");
    }
    // Close the tags: <a>, <code>.
    if let Some(attrs) = &self.attributes {
      if attrs.contains_key(HREF) {
        html.push_str("</a>");
      }
      if attrs.contains_key(CODE) {
        html.push_str("</code>");
      }
    }
    html
  }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct NestedBlock {
  #[serde(default)]
  pub id: String,
  #[serde(rename = "type")]
  pub ty: String,
  #[serde(default)]
  pub data: HashMap<String, Value>,
  #[serde(default)]
  pub children: Vec<NestedBlock>,
}

impl Eq for NestedBlock {}

impl PartialEq for NestedBlock {
  // ignore the id field
  fn eq(&self, other: &Self) -> bool {
    self.ty == other.ty
      && self.data.iter().all(|(k, v)| {
        let other_v = other.data.get(k).unwrap_or(&Value::Null);
        if k == DELTA {
          let v = convert_insert_delta_from_json(v);
          let other_v = convert_insert_delta_from_json(other_v);
          return v == other_v;
        }
        v == other_v
      })
      && self.children == other.children
  }
}

pub struct ConvertBlockToHtmlParams {
  pub prev_block_ty: Option<String>,
  pub next_block_ty: Option<String>,
}

impl NestedBlock {
  pub fn new(
    id: String,
    ty: String,
    data: HashMap<String, Value>,
    children: Vec<NestedBlock>,
  ) -> Self {
    Self {
      id,
      ty,
      data,
      children,
    }
  }

  pub fn add_child(&mut self, child: NestedBlock) {
    self.children.push(child);
  }

  pub fn convert_to_html(&self, params: ConvertBlockToHtmlParams) -> String {
    let mut html = String::new();

    let text_html = self
      .data
      .get("delta")
      .and_then(convert_insert_delta_from_json)
      .map(|delta| delta_to_html(&delta))
      .unwrap_or_default();

    let prev_block_ty = params.prev_block_ty.unwrap_or_default();
    let next_block_ty = params.next_block_ty.unwrap_or_default();

    match self.ty.as_str() {
      HEADING => {
        let level = self.data.get(LEVEL).unwrap_or(&Value::Null);
        if level.as_u64().unwrap_or(0) > 6 {
          html.push_str(&format!("<h6>{}</h6>", text_html));
        } else {
          html.push_str(&format!("<h{}>{}</h{}>", level, text_html, level));
        }
      },
      PARAGRAPH => {
        html.push_str(&format!("<p>{}</p>", text_html));
        html.push_str(&convert_nested_block_children_to_html(Arc::new(
          self.to_owned(),
        )));
      },
      CALLOUT => {
        html.push_str(&format!(
          "<p>{}{}</p>",
          self
            .data
            .get(ICON)
            .unwrap_or(&Value::Null)
            .to_string()
            .trim_matches('\"'),
          text_html
        ));
      },
      IMAGE => {
        html.push_str(&format!(
          "<img src={} alt={} />",
          self.data.get(URL).unwrap(),
          "AppFlowy-Image"
        ));
      },
      DIVIDER => {
        html.push_str("<hr />");
      },
      MATH_EQUATION => {
        let formula = self.data.get(FORMULA).unwrap_or(&Value::Null);
        html.push_str(&format!(
          "<p>{}</p>",
          formula.to_string().trim_matches('\"')
        ));
      },
      CODE => {
        let language = self.data.get(LANGUAGE).unwrap_or(&Value::Null);
        html.push_str(&format!(
          "<pre><code class=\"language-{}\">{}</code></pre>",
          language.to_string().trim_matches('\"'),
          text_html
        ));
      },
      BULLETED_LIST | NUMBERED_LIST | TODO_LIST | TOGGLE_LIST => {
        let list_type = match self.ty.as_str() {
          BULLETED_LIST => "ul",
          NUMBERED_LIST => "ol",
          TODO_LIST => "ul",
          TOGGLE_LIST => "ul",
          _ => "ul", // Default to "ul" for unknown types
        };
        if prev_block_ty != self.ty {
          html.push_str(&format!("<{}>", list_type));
        }
        if self.ty == TODO_LIST {
          let checked_str = if self
            .data
            .get(CHECKED)
            .and_then(|checked| checked.as_bool())
            .unwrap_or(false)
          {
            "x"
          } else {
            " "
          };
          html.push_str(&format!("<li>[{}] {}</li>", checked_str, text_html));
        } else {
          html.push_str(&format!("<li>{}</li>", text_html));
        }

        html.push_str(&convert_nested_block_children_to_html(Arc::new(
          self.to_owned(),
        )));

        if next_block_ty != self.ty {
          html.push_str(&format!("</{}>", list_type));
        }
      },

      QUOTE => {
        if prev_block_ty != self.ty {
          html.push_str("<blockquote>");
        }
        html.push_str(&format!("<p>{}</p>", text_html));
        html.push_str(&convert_nested_block_children_to_html(Arc::new(
          self.to_owned(),
        )));
        if next_block_ty != self.ty {
          html.push_str("</blockquote>");
        }
      },
      PAGE => {
        if !text_html.is_empty() {
          html.push_str(&format!("<p>{}</p>", text_html));
        }
        html.push_str(&convert_nested_block_children_to_html(Arc::new(
          self.to_owned(),
        )));
      },
      _ => {
        html.push_str(&format!("<p>{}</p>", text_html));
        html.push_str(&convert_nested_block_children_to_html(Arc::new(
          self.to_owned(),
        )));
      },
    };

    html
  }

  pub fn convert_to_text(&self) -> String {
    let mut text = String::new();

    let delta_text = self
      .data
      .get("delta")
      .and_then(convert_insert_delta_from_json)
      .map(|delta| delta_to_text(&delta))
      .unwrap_or_default();

    match self.ty.as_str() {
      CALLOUT => {
        text.push_str(&format!(
          "{}{}\n",
          self
            .data
            .get(ICON)
            .unwrap_or(&Value::Null)
            .to_string()
            .trim_matches('\"'),
          delta_text
        ));
      },
      MATH_EQUATION => {
        let formula = self.data.get(FORMULA).unwrap_or(&Value::Null);
        text.push_str(&format!("{}\n", formula.to_string().trim_matches('\"')));
      },
      PAGE => {
        if !delta_text.is_empty() {
          text.push_str(&format!("{}\n", delta_text));
        }
        for child in &self.children {
          text.push_str(&child.convert_to_text());
        }
      },
      _ => {
        text.push_str(&format!("{}\n", delta_text));
        for child in &self.children {
          text.push_str(&child.convert_to_text());
        }
      },
    };
    text
  }
}
