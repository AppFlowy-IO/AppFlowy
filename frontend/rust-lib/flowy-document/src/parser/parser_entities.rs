use crate::parse::NotEmptyStr;
use crate::parser::constant::*;
use crate::parser::utils::{
  convert_insert_delta_from_json, convert_nested_block_children_to_html, delta_to_html,
  delta_to_text, required_not_empty_str, serialize_color_attribute,
};
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_error::ErrorCode;
use serde::{Deserialize, Serialize};
use serde_json::Value;
use std::collections::HashMap;
use std::sync::Arc;
use validator::Validate;

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
pub struct ParseTypePB {
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
 * @field parse_types: [ParseTypePB]
 */
#[derive(Default, ProtoBuf)]
pub struct ConvertDocumentPayloadPB {
  #[pb(index = 1)]
  pub document_id: String,

  #[pb(index = 2, one_of)]
  pub range: Option<RangePB>,

  #[pb(index = 3)]
  pub parse_types: ParseTypePB,
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

pub struct ParseType {
  pub json: bool,
  pub html: bool,
  pub text: bool,
}

pub struct ConvertDocumentParams {
  pub document_id: String,
  pub range: Option<Range>,
  pub parse_types: ParseType,
}

impl ParseType {
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

impl From<ParseTypePB> for ParseType {
  fn from(data: ParseTypePB) -> Self {
    ParseType {
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
      parse_types: self.parse_types.into(),
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
    let mut html_attributes = String::new();
    // If there are attributes, serialize them as a HashMap.
    if let Some(attrs) = &self.attributes {
      // Serialize the color attributes.
      style.push_str(&serialize_color_attribute(attrs, FONT_COLOR, COLOR));
      // Serialize the background color attributes.
      style.push_str(&serialize_color_attribute(
        attrs,
        BG_COLOR,
        BACKGROUND_COLOR,
      ));
      // Serialize the href attributes.
      if let Some(href) = attrs.get(HREF) {
        html.push_str(&format!("<{} {}={}>", A_TAG_NAME, HREF, href));
      }
      // Serialize the code attributes.
      if let Some(code) = attrs.get(CODE) {
        if code.as_bool().unwrap_or(false) {
          html.push_str(&format!("<{}>", CODE_TAG_NAME));
        }
      }

      // Serialize the italic, underline, strikethrough, bold, formula attributes.
      if let Some(italic) = attrs.get(ITALIC) {
        if italic.as_bool().unwrap_or(false) {
          style.push_str(FONT_STYLE_ITALIC);
        }
      }
      if let Some(underline) = attrs.get(UNDERLINE) {
        if underline.as_bool().unwrap_or(false) {
          style.push_str(TEXT_DECORATION_UNDERLINE);
        }
      }
      if let Some(strikethrough) = attrs.get(STRIKETHROUGH) {
        if strikethrough.as_bool().unwrap_or(false) {
          style.push_str(TEXT_DECORATION_LINE_THROUGH);
        }
      }
      if let Some(bold) = attrs.get(BOLD) {
        if bold.as_bool().unwrap_or(false) {
          style.push_str(FONT_WEIGHT_BOLD);
        }
      }
      if let Some(formula) = attrs.get(FORMULA) {
        if formula.as_bool().unwrap_or(false) {
          style.push_str(FONT_FAMILY_FANTASY);
        }
      }
      if let Some(direction) = attrs.get(TEXT_DIRECTION) {
        html_attributes.push_str(&format!(" {}=\"{}\"", DIR_ATTR_NAME, direction));
      }
    }
    if !style.is_empty() {
      html_attributes.push_str(&format!(" {}=\"{}\"", STYLE, style));
    }

    if !html_attributes.is_empty() {
      html.push_str(&format!("<{}{}>", SPAN_TAG_NAME, html_attributes));
    }
    // Serialize the insert field.
    html.push_str(&self.insert);

    // Close the style tag.
    if !html_attributes.is_empty() {
      html.push_str(&format!("</{}>", SPAN_TAG_NAME));
    }
    // Close the tags: <a>, <code>.
    if let Some(attrs) = &self.attributes {
      if attrs.contains_key(CODE) {
        html.push_str(&format!("</{}>", CODE_TAG_NAME));
      }
      if attrs.contains_key(HREF) {
        html.push_str(&format!("</{}>", A_TAG_NAME));
      }
    }
    html
  }
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct NestedBlock {
  #[serde(default)]
  #[serde(rename = "type")]
  pub ty: String,
  #[serde(default)]
  pub data: HashMap<String, Value>,
  #[serde(default)]
  pub children: Vec<NestedBlock>,
}

impl Eq for NestedBlock {}

impl PartialEq for NestedBlock {
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

impl NestedBlock {
  pub fn new(ty: String, data: HashMap<String, Value>, children: Vec<NestedBlock>) -> Self {
    Self { ty, data, children }
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
      // <h1>Hello</h1>
      HEADING => {
        let level = self.data.get(LEVEL).unwrap_or(&Value::Null);
        if level.as_u64().unwrap_or(0) > 6 {
          html.push_str(&format!("<{}>{}</{}>", H6_TAG_NAME, text_html, H6_TAG_NAME));
        } else {
          html.push_str(&format!("<h{}>{}</h{}>", level, text_html, level));
        }
      },
      // <p>Hello</p>
      PARAGRAPH => {
        html.push_str(&format!("<{}>{}</{}>", P_TAG_NAME, text_html, P_TAG_NAME));
        html.push_str(&convert_nested_block_children_to_html(Arc::new(
          self.to_owned(),
        )));
      },
      // <aside>😁Hello</aside>
      CALLOUT => {
        html.push_str(&format!(
          "<{}>{}{}</{}>",
          ASIDE_TAG_NAME,
          self
            .data
            .get(ICON)
            .unwrap_or(&Value::Null)
            .to_string()
            .trim_matches('\"'),
          text_html,
          ASIDE_TAG_NAME
        ));
      },
      // <img src="https://www.google.com/images/branding/googlelogo/2x/googlelogo_color_272x92dp.png" alt="Google Logo" />
      IMAGE => {
        html.push_str(&format!(
          "<{} src={} alt={} />",
          IMG_TAG_NAME,
          self.data.get(URL).unwrap(),
          "AppFlowy-Image"
        ));
      },
      // <hr />
      DIVIDER => {
        html.push_str(&format!("<{} />", HR_TAG_NAME));
      },
      // <p>$$x = {-b \pm \sqrt{b^2-4ac} \over 2a}.$$</p>
      MATH_EQUATION => {
        let formula = self.data.get(FORMULA).unwrap_or(&Value::Null);
        html.push_str(&format!(
          "<{}>{}</{}>",
          P_TAG_NAME,
          formula.to_string().trim_matches('\"'),
          P_TAG_NAME
        ));
      },
      // <pre><code class="language-js">console.log('Hello World!');</code></pre>
      CODE => {
        let language = self.data.get(LANGUAGE).unwrap_or(&Value::Null);
        html.push_str(&format!(
          "<{}><{} {}=\"{}-{}\">{}</{}></{}>",
          PRE_TAG_NAME,
          CODE_TAG_NAME,
          CLASS,
          LANGUAGE,
          language.to_string().trim_matches('\"'),
          text_html,
          CODE_TAG_NAME,
          PRE_TAG_NAME
        ));
      },
      // <details><summary>Hello</summary><p>World!</p></details>
      TOGGLE_LIST => {
        html.push_str(&format!("<{}>", DETAILS_TAG_NAME));
        html.push_str(&format!(
          "<{}>{}</{}>",
          SUMMARY_TAG_NAME, text_html, SUMMARY_TAG_NAME
        ));
        html.push_str(&convert_nested_block_children_to_html(Arc::new(
          self.to_owned(),
        )));
        html.push_str(&format!("</{}>", DETAILS_TAG_NAME));
      },
      // <ul><li>Hello</li><li>World!</li></ul>
      BULLETED_LIST | NUMBERED_LIST | TODO_LIST => {
        let list_type = if self.ty == NUMBERED_LIST {
          OL_TAG_NAME
        } else {
          UL_TAG_NAME
        };
        if prev_block_ty != self.ty {
          html.push_str(&format!("<{}>", list_type));
        }
        if self.ty == TODO_LIST {
          let checked = self
            .data
            .get(CHECKED)
            .and_then(|v| v.as_bool())
            .unwrap_or_default();
          // <li role="checkbox" aria-checked="true">Hello</li>
          html.push_str(&format!(
            "<{} {}=\"{}\" {}=\"{}\">{}",
            LI_TAG_NAME, ROLE, CHECKBOX, ARIA_CHECKED, checked, text_html
          ));
        } else {
          html.push_str(&format!("<{}>{}", LI_TAG_NAME, text_html));
        }

        html.push_str(&convert_nested_block_children_to_html(Arc::new(
          self.to_owned(),
        )));
        html.push_str(&format!("</{}>", LI_TAG_NAME));

        if next_block_ty != self.ty {
          html.push_str(&format!("</{}>", list_type));
        }
      },

      // <blockquote><p>Hello</p><p>World!</p></blockquote>
      QUOTE => {
        if prev_block_ty != self.ty {
          html.push_str(&format!("<{}>", BLOCKQUOTE_TAG_NAME));
        }
        html.push_str(&format!("<{}>{}</{}>", P_TAG_NAME, text_html, P_TAG_NAME));
        html.push_str(&convert_nested_block_children_to_html(Arc::new(
          self.to_owned(),
        )));
        if next_block_ty != self.ty {
          html.push_str(&format!("</{}>", BLOCKQUOTE_TAG_NAME));
        }
      },
      // <p>Hello</p>
      PAGE => {
        if !text_html.is_empty() {
          html.push_str(&format!("<{}>{}</{}>", P_TAG_NAME, text_html, P_TAG_NAME));
        }
        html.push_str(&convert_nested_block_children_to_html(Arc::new(
          self.to_owned(),
        )));
      },
      // <p>Hello</p>
      _ => {
        html.push_str(&format!("<{}>{}</{}>", P_TAG_NAME, text_html, P_TAG_NAME));
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
      .get(DELTA)
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

pub struct ConvertBlockToHtmlParams {
  pub prev_block_ty: Option<String>,
  pub next_block_ty: Option<String>,
}

#[derive(PartialEq, Eq, Debug, ProtoBuf_Enum, Clone, Default)]
pub enum InputType {
  #[default]
  Html = 0,
  PlainText = 1,
}

#[derive(Default, ProtoBuf, Debug, Validate)]
pub struct ConvertDataToJsonPayloadPB {
  #[pb(index = 1)]
  #[validate(custom = "required_not_empty_str")]
  pub data: String,

  #[pb(index = 2)]
  pub input_type: InputType,
}

pub struct ConvertDataToJsonParams {
  pub data: String,
  pub input_type: InputType,
}

#[derive(Default, ProtoBuf, Debug)]
pub struct ConvertDataToJsonResponsePB {
  #[pb(index = 1)]
  pub json: String,
}

impl TryInto<ConvertDataToJsonParams> for ConvertDataToJsonPayloadPB {
  type Error = ErrorCode;
  fn try_into(self) -> Result<ConvertDataToJsonParams, Self::Error> {
    Ok(ConvertDataToJsonParams {
      data: self.data,
      input_type: self.input_type,
    })
  }
}
