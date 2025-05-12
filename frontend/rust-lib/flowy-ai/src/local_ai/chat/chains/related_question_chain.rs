use crate::local_ai::chat::llm::LLMOllama;
use flowy_error::{FlowyError, FlowyResult};
use langchain_rust::language_models::llm::LLM;
use langchain_rust::schemas::Message;
use ollama_rs::generation::parameters::{FormatType, JsonStructure};
use schemars::JsonSchema;
use serde::Deserialize;

const SYSTEM_PROMPT: &str = r#"
You are the AppFlowy AI assistant. Given the conversation history, generate exactly three medium-length, relevant, and informative questions.
Respond with a single JSON object matching the schema below—and nothing else. If you can’t generate questions, return {}.
"#;

#[derive(Debug, Deserialize, JsonSchema)]
struct QuestionsResponse {
  questions: Vec<String>,
}

pub struct RelatedQuestionChain {
  llm: LLMOllama,
}

impl RelatedQuestionChain {
  pub fn new(ollama: LLMOllama) -> Self {
    let format = FormatType::StructuredJson(JsonStructure::new::<QuestionsResponse>());
    Self {
      llm: ollama.with_format(format),
    }
  }

  pub async fn generate_related_question(&self, question: &str) -> FlowyResult<Vec<String>> {
    let messages = vec![
      Message::new_system_message(SYSTEM_PROMPT),
      Message::new_human_message(question),
    ];

    let result = self.llm.generate(&messages).await.map_err(|err| {
      FlowyError::internal().with_context(format!("Error generating related questions: {}", err))
    })?;

    let parsed_result = serde_json::from_str::<QuestionsResponse>(&result.generation)?;
    Ok(parsed_result.questions)
  }
}
