use anyhow::Result;
use std::collections::HashMap;

use crate::local_ai::chat::llm::LLMOllama;
use flowy_ai_pub::cloud::ai_dto::{TranslateRowData, TranslateRowResponse};
use flowy_database_pub::cloud::TranslateItem;
use flowy_error::{FlowyError, FlowyResult};
use langchain_rust::language_models::llm::LLM;
use langchain_rust::schemas::Message;
use tracing::{info, warn};

/// The translation prompt templates
const TRANSLATE_SYSTEM_PROMPT: &str = r#"
You are AppFlowy AI who fluent in multiple languages, able to translate texts accurately and efficiently between different languages while maintaining the original context and meaning

<Examples>
-----------------
Translate to Chinese
Input: [{"name": "jack"}, {"age": "twelve"}, {"location": "New York"}]
Output: [{"姓名": "杰克"}, {"年龄": "12"}, {"位置": "纽约"}]

Translate to French
Input: [{"name": "杰克"}, {"age": "12"}, {"地点": "纽约"}]
Output: [{"nom": "Jacques"}, {"âge": "douze"}, {"lieu": "New York"}]

Translate to German
Input: [{"name": "杰克"}, {"age": "12"}, {"地点": "纽约"}]
Output: [{"name": "Jacques"}, {"alter": "fünfundzwanzig"}, {"stadt": "New York"}]
</Examples>

Important Formatting Rules:
- The output must be a JSON array of key–value maps.
- Each key and each string value must be enclosed in quotes (e.g., "name": "Jack").
- Numeric values should not be enclosed in quotes (e.g., "age": 25).
- Do not include any markdown formatting (such as ```json or ```).
- The output must be directly parseable as JSON.
"#;

const TRANSLATE_USER_PROMPT: &str = r#"
Translate following {input} into {language}.
Output:
"#;

/// The main chain for translating database content
pub struct DatabaseTranslateChain {
  llm: LLMOllama,
}

impl DatabaseTranslateChain {
  pub fn new(ollama: LLMOllama) -> Self {
    Self { llm: ollama }
  }

  /// Translates the provided data to the specified language
  pub async fn translate(&self, data: TranslateRowData) -> FlowyResult<TranslateRowResponse> {
    // Format the input text
    let text: Vec<String> = data
      .cells
      .iter()
      .map(|item| format!("{}: {}", item.title, item.content))
      .collect();

    // Create the prompt messages
    let input_json = serde_json::to_string(&text).unwrap_or_else(|_| text.join("\n"));
    let messages = vec![
      Message::new_system_message(TRANSLATE_SYSTEM_PROMPT),
      Message::new_human_message(
        TRANSLATE_USER_PROMPT
          .replace("{input}", &input_json)
          .replace("{language}", &data.language),
      ),
    ];

    self
      .llm
      .generate(&messages)
      .await
      .map_err(|err| {
        FlowyError::internal().with_context(format!("Error generating translation: {}", err))
      })
      .and_then(|result| self.parse_response(&result.generation))
  }

  /// Parses the LLM response into the expected output format
  fn parse_response(&self, response_text: &str) -> FlowyResult<TranslateRowResponse> {
    info!("[Database Translate] Parsing response: {}", response_text);

    // Try different parsing strategies in sequence
    self
      .try_parse_json_array(response_text)
      .or_else(|_| self.try_parse_json_object(response_text))
      .or_else(|_| self.fallback_parse(response_text))
      .map_err(|e| {
        FlowyError::internal().with_context(format!("Failed to parse translation response: {}", e))
      })
  }

  // Try to parse the response as a JSON array
  fn try_parse_json_array(&self, text: &str) -> Result<TranslateRowResponse, anyhow::Error> {
    // Directly attempt JSON parsing and handle any errors
    let text = text.trim();
    if !text.starts_with('[') {
      return Err(anyhow::anyhow!("Not a JSON array"));
    }

    serde_json::from_str::<Vec<serde_json::Value>>(text)
      .map(|parsed| self.convert_values_to_response(parsed))
      .map_err(|e| anyhow::anyhow!("Failed to parse JSON array: {}", e))
  }

  // Try to parse the response as a JSON object
  fn try_parse_json_object(&self, text: &str) -> Result<TranslateRowResponse, anyhow::Error> {
    let text = text.trim();
    if !text.starts_with('{') {
      return Err(anyhow::anyhow!("Not a JSON object"));
    }

    let parsed: serde_json::Value = serde_json::from_str(text)
      .map_err(|e| anyhow::anyhow!("Failed to parse JSON object: {}", e))?;

    // Check if it's an object with an "items" field
    if let Some(serde_json::Value::Array(items)) = parsed.get("items") {
      return Ok(self.convert_values_to_response(items.clone()));
    }

    // Otherwise, treat as a flat key-value object
    if let serde_json::Value::Object(map) = parsed {
      let result = map
        .into_iter()
        .map(|(k, v)| {
          let content = match v {
            serde_json::Value::String(s) => s,
            _ => v.to_string(),
          };
          TranslateItem { title: k, content }
        })
        .collect();

      return Ok(map_translate_items_to_response(result));
    }

    Err(anyhow::anyhow!("JSON value is not an object"))
  }

  // Fallback parsing for non-JSON or malformed responses
  fn fallback_parse(&self, text: &str) -> Result<TranslateRowResponse, anyhow::Error> {
    warn!("[Database Translate] Using fallback parsing for: {}", text);

    // Try to parse line by line
    let items = text
      .lines()
      .filter_map(|line| {
        let line = line.trim();
        if line.is_empty() {
          return None;
        }

        let parts: Vec<&str> = line.splitn(2, ": ").collect();
        (parts.len() == 2).then(|| TranslateItem {
          title: parts[0].trim().to_string(),
          content: parts[1].trim().to_string(),
        })
      })
      .collect();

    Ok(map_translate_items_to_response(items))
  }

  // Convert JSON values to TranslateRowResponse
  fn convert_values_to_response(&self, values: Vec<serde_json::Value>) -> TranslateRowResponse {
    let items = values
      .into_iter()
      .filter_map(|value| match value {
        serde_json::Value::Object(map) => {
          if map.len() == 1 {
            // Handle simple key-value object
            map.into_iter().next().map(|(k, v)| {
              let content = match v {
                serde_json::Value::String(s) => s,
                _ => v.to_string(),
              };
              TranslateItem { title: k, content }
            })
          } else {
            // Try to convert the object directly to a TranslateItem
            serde_json::from_value::<TranslateItem>(serde_json::Value::Object(map)).ok()
          }
        },
        serde_json::Value::String(s) => {
          // Handle string values with "key: value" format
          let parts: Vec<&str> = s.splitn(2, ": ").collect();
          (parts.len() == 2).then(|| TranslateItem {
            title: parts[0].trim().to_string(),
            content: parts[1].trim().to_string(),
          })
        },
        _ => None,
      })
      .collect();

    map_translate_items_to_response(items)
  }
}

fn map_translate_items_to_response(items: Vec<TranslateItem>) -> TranslateRowResponse {
  TranslateRowResponse {
    items: items
      .into_iter()
      .map(|item| {
        let mut map = HashMap::with_capacity(2);
        map.insert("title".to_string(), item.title);
        map.insert("content".to_string(), item.content);
        map
      })
      .collect(),
  }
}
