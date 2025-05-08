use crate::local_ai::chat::llm::LLMOllama;
use flowy_error::{FlowyError, FlowyResult};
use langchain_rust::language_models::llm::LLM;
use langchain_rust::schemas::Message;
use ollama_rs::generation::parameters::{FormatType, JsonStructure};
use schemars::JsonSchema;
use serde::Deserialize;

const SUMMARIZE_SYSTEM_PROMPT: &str = r#"
As an AppFlowy AI assistant, your task is to generate three medium-length, relevant, and informative questions based on the provided conversation history.
The output should only return a JSON instance that conforms to the JSON schema below.

{
	"questions": [
		"What are the key skills needed to tackle a black diamond slope in snowboarding?",
		"How does the difficulty of black diamond trails compare across different ski resorts?",
		"Can you provide tips for snowboarders preparing to try a black diamond trail for the first time?"
	]
}
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

  pub async fn related_question(&self, question: &str) -> FlowyResult<Vec<String>> {
    let messages = vec![
      Message::new_system_message(SUMMARIZE_SYSTEM_PROMPT),
      Message::new_human_message(question),
    ];

    let result = self.llm.generate(&messages).await.map_err(|err| {
      FlowyError::internal().with_context(format!("Error generating related questions: {}", err))
    })?;

    let parsed_result = serde_json::from_str::<QuestionsResponse>(&result.generation)?;
    Ok(parsed_result.questions)
  }
}
