use flowy_error::FlowyError;
use ollama_rs::generation::chat::request::ChatMessageRequest;
use ollama_rs::generation::chat::{ChatMessage, MessageRole};
use ollama_rs::generation::parameters::{FormatType, JsonStructure};
use ollama_rs::Ollama;
use schemars::JsonSchema;
use serde::{Deserialize, Serialize};
use serde_json::json;
use tracing::error;
use uuid::Uuid;

#[derive(Debug)]
pub struct SearchSummary {
  pub content: String,
  pub highlights: String,
  pub sources: Vec<Uuid>,
}

#[derive(Debug)]
pub struct SummarySearchResponse {
  pub summaries: Vec<SearchSummary>,
}

#[derive(Debug, Serialize, Deserialize, JsonSchema)]
#[serde(deny_unknown_fields)]
struct SummarySearchSchema {
  pub answer: String,
  pub highlights: String,
  pub sources: Vec<String>,
}

const SYSTEM_PROMPT: &str = r#"
You are a strict, context-bound question answering assistant. Answer solely based on the context provided below. If the context lacks sufficient information for a confident response, reply with an empty answer.

Output must include:
- `answer`: a detailed, on-point answer to the user’s question.
- `highlights`:A markdown bullet list that highlights key themes and important details (e.g., date, time, location, etc.).
- `sources`: array of source IDs used for the answer.
"#;

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct LLMDocument {
  pub content: String,
  pub object_id: Uuid,
}

impl LLMDocument {
  #[allow(dead_code)]
  pub fn new(content: String, object_id: Uuid) -> Self {
    Self { content, object_id }
  }
}

fn convert_documents_to_text(documents: Vec<LLMDocument>) -> String {
  documents
    .into_iter()
    .map(|doc| json!(doc).to_string())
    .collect::<Vec<String>>()
    .join("\n")
}

pub async fn summarize_documents(
  client: &Ollama,
  question: &str,
  model_name: &str,
  documents: Vec<LLMDocument>,
) -> Result<SummarySearchResponse, FlowyError> {
  let documents_text = convert_documents_to_text(documents);
  let context = format!("{}\n\n##Context##\n{}", SYSTEM_PROMPT, documents_text);
  let messages = vec![
    ChatMessage::new(MessageRole::System, context),
    ChatMessage::new(MessageRole::User, question.to_string()),
  ];

  let format = FormatType::StructuredJson(JsonStructure::new::<SummarySearchSchema>());
  let request = ChatMessageRequest::new(model_name.to_string(), messages).format(format);
  match client.send_chat_messages(request).await {
    Ok(resp) => {
      if resp.final_data.is_some() {
        let resp: SummarySearchSchema = serde_json::from_str(&resp.message.content)?;
        let resp = SummarySearchResponse {
          summaries: vec![SearchSummary {
            content: resp.answer,
            highlights: resp.highlights,
            sources: resp
              .sources
              .into_iter()
              .flat_map(|s| Uuid::parse_str(&s).ok())
              .collect(),
          }],
        };
        Ok(resp)
      } else {
        Ok(SummarySearchResponse { summaries: vec![] })
      }
    },
    Err(err) => {
      error!("Error generating summary: {}", err);
      Ok(SummarySearchResponse { summaries: vec![] })
    },
  }
}

#[cfg(test)]
mod tests {
  use crate::search::summary::{summarize_documents, LLMDocument};
  use ollama_rs::Ollama;

  #[tokio::test]
  async fn summarize_documents_test() {
    let ollama = Ollama::try_new("http://localhost:11434").unwrap();
    let docs = vec![
      ("Rust is a multiplayer survival game developed by Facepunch Studios, first released in early access in December 2013 and fully launched in February 2018. It has since become one of the most popular games in the survival genre, known for its harsh environment, intricate crafting system, and player-driven dynamics. The game is available on Windows, macOS, and PlayStation, with a community-driven approach to updates and content additions.", uuid::Uuid::new_v4()),
      ("Rust is a modern, system-level programming language designed with a focus on performance, safety, and concurrency. It was created by Mozilla and first released in 2010, with its 1.0 version launched in 2015. Rust is known for providing the control and performance of languages like C and C++, but with built-in safety features that prevent common programming errors, such as memory leaks, data races, and buffer overflows.", uuid::Uuid::new_v4()),
      ("Rust as a Natural Process (Oxidation) refers to the chemical reaction that occurs when metals, primarily iron, come into contact with oxygen and moisture (water) over time, leading to the formation of iron oxide, commonly known as rust. This process is a form of oxidation, where a substance reacts with oxygen in the air or water, resulting in the degradation of the metal.", uuid::Uuid::new_v4()),
    ].into_iter().map(|(content, object_id)| LLMDocument::new(content.to_string(), object_id)).collect::<Vec<_>>();
    let result = summarize_documents(&ollama, "multiplayer game", "llama3.1", docs.clone())
      .await
      .unwrap();
    dbg!(result);
  }
}
