use flowy_ai_pub::cloud::{CompletionStreamValue, CompletionType};
use futures_util::{Stream, StreamExt, stream, stream::BoxStream};
use langchain_rust::language_models::LLMError;
use langchain_rust::schemas::StreamData;
use serde_json::{Value, json};
use std::collections::HashMap;
use std::sync::{Arc, Mutex};
use tracing::{debug, warn};

pub fn stream_interpreter_for_completion(
  input_stream: BoxStream<'static, Result<StreamData, LLMError>>,
  completion_type: CompletionType,
) -> BoxStream<'static, Result<CompletionStreamValue, LLMError>> {
  match completion_type {
    CompletionType::ImproveWriting | CompletionType::SpellingAndGrammar => {
      interpret_completion_stream(input_stream, completion_type)
    },
    _ => input_stream
      .map(|res| res.map(map_response_to_completion_value))
      .boxed(),
  }
}

fn map_response_to_completion_value(data: StreamData) -> CompletionStreamValue {
  if let Some(content) = data.value.get("content") {
    return CompletionStreamValue::Answer {
      value: content.as_str().unwrap_or_default().to_string(),
    };
  }

  if let Some(content) = data.value.get("comment") {
    return CompletionStreamValue::Comment {
      value: content.as_str().unwrap_or_default().to_string(),
    };
  }

  warn!("[AICompletion] unexpected stream data: {:?}", data);
  CompletionStreamValue::Answer {
    value: data.content,
  }
}

/// Creates a mapping for the ImproveWriting completion type
fn create_improve_writing_mapping() -> HashMap<String, String> {
  let mut mapping = HashMap::new();
  // Support multiple variants of the tag names
  mapping.insert("Improved".to_string(), "content".to_string());
  mapping.insert("improved".to_string(), "content".to_string());
  mapping.insert("IMPROVED".to_string(), "content".to_string());
  mapping.insert("Explanation".to_string(), "comment".to_string());
  mapping.insert("explanation".to_string(), "comment".to_string());
  mapping
}

/// Creates a mapping for the SpellingAndGrammar completion type
fn create_spelling_grammar_mapping() -> HashMap<String, String> {
  let mut mapping = HashMap::new();
  // Support multiple variants of the tag names
  mapping.insert("Corrected".to_string(), "content".to_string());
  mapping.insert("corrected".to_string(), "content".to_string());
  mapping.insert("Correct".to_string(), "content".to_string());
  mapping.insert("correct".to_string(), "content".to_string());
  mapping.insert("CORRECTED".to_string(), "content".to_string());
  mapping.insert("Corrected:".to_string(), "content".to_string());
  mapping.insert("Explanation".to_string(), "comment".to_string());
  mapping.insert("explanation".to_string(), "comment".to_string());
  mapping
}

/// Process a stream of completion data with the interpreter
///
/// This function takes an input stream and a completion type, and returns a new stream
/// where each item has been processed by the StreamInterpreter.
///
/// The interpreter extracts content between specific XML-like tags based on the mapping
/// for the given completion type.
pub fn interpret_completion_stream<S>(
  stream: S,
  completion_type: CompletionType,
) -> BoxStream<'static, Result<CompletionStreamValue, LLMError>>
where
  S: Stream<Item = Result<StreamData, LLMError>> + Send + 'static,
{
  let mapping = match completion_type {
    CompletionType::ImproveWriting => create_improve_writing_mapping(),
    CompletionType::SpellingAndGrammar => create_spelling_grammar_mapping(),
    _ => HashMap::new(),
  };

  if mapping.is_empty() {
    // If no mapping exists for this completion type, return the original stream
    return stream
      .map(|res| res.map(map_response_to_completion_value))
      .boxed();
  }

  // Create a shared interpreter that will be used across all stream items
  let interpreter = Arc::new(Mutex::new(StreamInterpreter::new()));
  let section_mapping = Arc::new(mapping);

  // First, process all stream items
  let interpreter_clone = interpreter.clone();
  let section_mapping_clone = section_mapping.clone();
  let processed_stream = stream.filter_map(move |result| {
    let interpreter = interpreter_clone.clone();
    let mapping = section_mapping_clone.clone();
    async move {
      match result {
        Ok(data) => {
          // Lock the interpreter only when needed
          let mut interpreter_guard = interpreter.lock().unwrap();
          interpreter_guard
            .post_process_output(&data.value, &mapping)
            .map(completion_stream_value_from_value)
        },
        Err(err) => Some(Err(err)),
      }
    }
  });

  // Then, handle any remaining data after the stream is done
  let final_stream = stream::once(async move {
    let mut interpreter_guard = interpreter.lock().unwrap();
    interpreter_guard
      .consume_post_process_pending(&section_mapping)
      .map(completion_stream_value_from_value)
  })
  .filter_map(|x| async { x });

  // Combine the processed stream with the final stream
  Box::pin(processed_stream.chain(final_stream))
}

fn completion_stream_value_from_value(value: Value) -> Result<CompletionStreamValue, LLMError> {
  // trace!("[AICompletion] processing stream value: {:?}", value);

  if let Some(content) = value.get("content") {
    return Ok(CompletionStreamValue::Answer {
      value: content.as_str().unwrap_or_default().to_string(),
    });
  }

  if let Some(comment) = value.get("comment") {
    return Ok(CompletionStreamValue::Comment {
      value: comment.as_str().unwrap_or_default().to_string(),
    });
  }

  Err(LLMError::ContentNotFound(format!(
    "Unexpected stream data: {:?}",
    value
  )))
}

struct StreamInterpreter {
  section_buffer: String,
  section: Option<String>,
  section_is_started: HashMap<String, bool>,
  start_tag: Option<String>,
  end_tag: Option<String>,
  end_tag_len: usize,
  check_tag_len: usize,
  // Track tag style for matching appropriate end tags
  tag_style: Option<TagStyle>,
}

// Define supported tag styles
#[derive(Debug, Clone, PartialEq)]
enum TagStyle {
  Xml,      // <Tag>...</Tag>
  Markdown, // **Tag**...**Tag**
  #[allow(dead_code)]
  MixedFormat, // **Tag**...</Tag> or other mixed styles
}

impl StreamInterpreter {
  /// Creates a new TagProcessingMixin.
  pub fn new() -> Self {
    StreamInterpreter {
      section_buffer: String::new(),
      section: None,
      section_is_started: Default::default(),
      start_tag: None,
      end_tag: None,
      end_tag_len: 0,
      check_tag_len: 0,
      tag_style: None,
    }
  }

  /// Creates a Value object from content if it's not empty and the section name exists in the mapping
  fn create_value_from_content(
    &mut self,
    mut content: String,
    section_name: &str,
    section_mapping: &HashMap<String, String>,
  ) -> Option<Value> {
    if self
      .section_is_started
      .get(section_name)
      .cloned()
      .unwrap_or(true)
    {
      content = content.trim_start_matches('\n').to_string();
      self
        .section_is_started
        .insert(section_name.to_string(), true);
    }

    if content.is_empty() {
      return None;
    }
    let output_key = section_mapping.get(section_name)?;
    // trace!(
    //   "[AICompletion] create value from content: {}, key: {}",
    //   content,
    //   output_key
    // );
    Some(json!({output_key: content}))
  }

  /// Finds the earliest start tag in the buffer
  ///
  /// Returns a tuple containing the position, name, tag, style, and length of the earliest tag,
  /// or None if no tags are found.
  fn find_earliest_start_tag(
    &self,
    buffer: &str,
    section_mapping: &HashMap<String, String>,
  ) -> Option<(usize, String, String, TagStyle, usize)> {
    let mut starts: Vec<(usize, String, String, TagStyle, usize)> = Vec::new();
    for section_name in section_mapping.keys() {
      if let Some((idx, tag, style, tag_len)) = self.detect_tag(buffer, section_name) {
        starts.push((idx, section_name.clone(), tag, style, tag_len));
      }
    }

    if starts.is_empty() {
      return None;
    }

    // Pick the earliest start tag
    starts.sort_by_key(|&(idx, _, _, _, _)| idx);
    Some(starts[0].clone())
  }

  /// Detects a tag in multiple formats
  fn detect_tag(&self, text: &str, tag_name: &str) -> Option<(usize, String, TagStyle, usize)> {
    // Check XML style: <Tag>
    let xml_tag = format!("<{}>", tag_name);
    if let Some(pos) = text.find(&xml_tag) {
      let xml_tag_len = xml_tag.len();
      return Some((pos, xml_tag, TagStyle::Xml, xml_tag_len));
    }

    // Check Markdown style: **Tag**
    let md_tag = format!("**{}**", tag_name);
    if let Some(pos) = text.find(&md_tag) {
      let md_tag_len = md_tag.len();
      return Some((pos, md_tag, TagStyle::Markdown, md_tag_len));
    }

    // Check case-insensitive XML style
    let lowercase_text = text.to_lowercase();
    let lowercase_xml_tag = format!("<{}>", tag_name.to_lowercase());
    if let Some(pos) = lowercase_text.find(&lowercase_xml_tag) {
      let xml_tag_len = lowercase_xml_tag.len();
      return Some((pos, xml_tag, TagStyle::Xml, xml_tag_len));
    }

    // Check case-insensitive Markdown style
    let lowercase_md_tag = format!("**{}**", tag_name.to_lowercase());
    if let Some(pos) = lowercase_text.find(&lowercase_md_tag) {
      let md_tag_len = lowercase_md_tag.len();
      // Use the original case for the returned tag
      let original_md_tag = format!("**{}**", tag_name);
      return Some((pos, original_md_tag, TagStyle::Markdown, md_tag_len));
    }

    None
  }

  /// Generates appropriate end tag based on tag style and name
  fn generate_end_tag(&self, tag_name: &str, style: &TagStyle) -> (String, usize) {
    match style {
      TagStyle::Xml => {
        let tag = format!("</{}>", tag_name);
        (tag.clone(), tag.len())
      },
      TagStyle::Markdown => {
        let tag = format!("**{}**", tag_name);
        (tag.to_string(), tag.len())
      },
      TagStyle::MixedFormat => {
        // For mixed format, check both closing styles
        let xml_tag = format!("</{}>", tag_name);
        (xml_tag.clone(), xml_tag.len())
      },
    }
  }

  /// Find end tag in text considering multiple formats
  fn find_end_tag(&self, text: &str, tag_name: &str, style: &TagStyle) -> Option<(usize, usize)> {
    match style {
      TagStyle::Xml => {
        let end_tag = format!("</{}>", tag_name);
        if let Some(pos) = text.find(&end_tag) {
          return Some((pos, end_tag.len()));
        }

        // Try case-insensitive match as fallback
        let lowercase_text = text.to_lowercase();
        let lowercase_end_tag = format!("</{}>", tag_name.to_lowercase());
        if let Some(pos) = lowercase_text.find(&lowercase_end_tag) {
          return Some((pos, end_tag.len()));
        }
      },
      TagStyle::Markdown => {
        let end_tag = format!("**{}**", tag_name);
        if let Some(pos) = text.find(&end_tag) {
          return Some((pos, end_tag.len()));
        }
      },
      TagStyle::MixedFormat => {
        // Check both styles for mixed format
        let xml_end = format!("</{}>", tag_name);
        let md_end = format!("**{}**", tag_name);

        let xml_pos = text.find(&xml_end).map(|p| (p, xml_end.len()));
        let md_pos = text.find(&md_end).map(|p| (p, md_end.len()));

        // Return the first one found
        if let Some(xml_match) = xml_pos {
          if let Some(md_match) = md_pos {
            if xml_match.0 < md_match.0 {
              return Some(xml_match);
            } else {
              return Some(md_match);
            }
          } else {
            return Some(xml_match);
          }
        } else {
          return md_pos;
        }
      },
    }

    None
  }

  /// Processes an input JSON object, extracting content between tags based on a mapping.
  ///
  /// - `input`: JSON object with a key "content" containing the text chunk.
  /// - `section_mapping`: maps section names to output keys.
  ///
  /// Returns an optional JSON object containing the extracted section content.
  pub fn post_process_output(
    &mut self,
    input: &Value,
    section_mapping: &HashMap<String, String>,
  ) -> Option<Value> {
    // Only process JSON objects
    let obj = input.as_object()?;

    // Extract the new text chunk
    let new_text = obj
      .get("message")
      .and_then(|msg| msg.as_object())
      .and_then(|msg_obj| msg_obj.get("content"))
      .and_then(Value::as_str)?;

    // Append to the buffer
    debug!("new_text: {}", new_text);
    self.section_buffer.push_str(new_text);

    // If not currently inside a section, look for a start tag
    if self.section.is_none() {
      let earliest_tag = self.find_earliest_start_tag(&self.section_buffer, section_mapping);
      let (start_pos, selected_name, selected_tag, selected_style, tag_len) = earliest_tag?;

      self.section = Some(selected_name.clone());
      self.start_tag = Some(selected_tag.clone());
      self.tag_style = Some(selected_style.clone());

      let (end_tag, end_tag_len) = self.generate_end_tag(&selected_name, &selected_style);
      self.end_tag = Some(end_tag);
      self.end_tag_len = end_tag_len;
      self.check_tag_len = self.end_tag_len * 2;

      let start = start_pos + tag_len;
      if start < self.section_buffer.len() {
        let after_tag = &self.section_buffer[start..];
        if after_tag.starts_with('\n') && start + 1 < self.section_buffer.len() {
          self.section_buffer = self.section_buffer[(start + 1)..].to_string();
        } else {
          self.section_buffer = self.section_buffer[start..].to_string();
        }
      } else {
        self.section_buffer = String::new();
      }
      return None;
    }

    // We're inside a section: look for the end tag
    let (section_name, tag_style) = match (self.section.clone(), &self.tag_style) {
      (Some(name), Some(style)) => (name, style),
      _ => return None,
    };

    // If the buffer is too short, return None
    if self.section_buffer.len() < self.check_tag_len {
      return None;
    }

    match self.find_end_tag(&self.section_buffer, &section_name, tag_style) {
      None => {
        let earliest_tag = self.find_earliest_start_tag(&self.section_buffer, section_mapping);
        match earliest_tag {
          Some((start_pos, selected_name, selected_tag, selected_style, tag_len)) => {
            if selected_name != section_name {
              // If it's a new section, process the current one
              let content = self.section_buffer[..start_pos].to_string();
              self.section_buffer = self.section_buffer[start_pos + tag_len..].to_string();
              self.section = Some(selected_name.clone());
              self.tag_style = Some(selected_style.clone());
              self.start_tag = Some(selected_tag.clone());
              let (end_tag, end_tag_len) = self.generate_end_tag(&selected_name, &selected_style);
              self.end_tag = Some(end_tag);
              self.end_tag_len = end_tag_len;

              let content = content.trim_end_matches('\n');
              self.create_value_from_content(content.to_string(), &section_name, section_mapping)
            } else {
              let content = std::mem::take(&mut self.section_buffer);
              self.create_value_from_content(content, &section_name, section_mapping)
            }
          },
          None => {
            // do not take all the section buffer, because the current buffer might contain
            // a uncompleted tag
            let content = self.section_buffer[..section_name.len()].to_string();
            self.section_buffer = self.section_buffer[section_name.len()..].to_string();
            self.create_value_from_content(content, &section_name, section_mapping)
          },
        }
      },
      Some((end_pos, end_len)) => {
        let content = self.section_buffer[..end_pos].to_string();
        self.section_buffer = self.section_buffer[end_pos + end_len..].to_string();
        self.section = None;
        self.start_tag = None;

        let content = content.trim_end_matches('\n');
        self.create_value_from_content(content.to_string(), &section_name, section_mapping)
      },
    }
  }

  /// Consume any remaining pending content after processing is complete.
  pub fn consume_post_process_pending(
    &mut self,
    section_mapping: &HashMap<String, String>,
  ) -> Option<Value> {
    if !self.section_buffer.is_empty() {
      let earliest_tag = self.find_earliest_start_tag(&self.section_buffer, section_mapping);
      if let Some((start_pos, selected_name, _, selected_style, tag_len)) = earliest_tag {
        // Set up the new section
        self.section = Some(selected_name.clone());
        self.tag_style = Some(selected_style.clone());

        // Skip past the start tag
        let start = start_pos + tag_len;
        if start < self.section_buffer.len() {
          self.section_buffer = self.section_buffer[start..].to_string();
          return match self.find_end_tag(&self.section_buffer, &selected_name, &selected_style) {
            None => {
              let trimmed_content = self.section_buffer.to_string();
              self.create_value_from_content(trimmed_content, &selected_name, section_mapping)
            },
            Some((end_pos, end_len)) => {
              let content = self.section_buffer[..end_pos].to_string();

              self.section_buffer = self.section_buffer[end_pos + end_len..].to_string();
              self.section = None;
              self.start_tag = None;

              self.create_value_from_content(
                content.trim_end_matches("\n").to_string(),
                &selected_name,
                section_mapping,
              )
            },
          };
        }
      }
    }

    match self.find_end_tag(
      &self.section_buffer,
      self.section.as_ref()?,
      self.tag_style.as_ref()?,
    ) {
      None => {
        let content = std::mem::take(&mut self.section_buffer)
          .trim_end_matches('\n')
          .to_string();
        let section_name = self.section.clone()?;
        self.create_value_from_content(content, &section_name, section_mapping)
      },
      Some((end_pos, _)) => {
        let content = self.section_buffer[..end_pos]
          .trim_end_matches('\n')
          .to_string();
        let section_name = self.section.clone()?;
        self.create_value_from_content(content, &section_name, section_mapping)
      },
    }
  }
}
