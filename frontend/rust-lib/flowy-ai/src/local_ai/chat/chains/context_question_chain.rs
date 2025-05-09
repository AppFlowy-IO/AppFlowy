use crate::local_ai::chat::llm::LLMOllama;
use crate::SqliteVectorStore;
use flowy_error::{FlowyError, FlowyResult};
use langchain_rust::language_models::llm::LLM;
use langchain_rust::prompt::TemplateFormat;
use langchain_rust::prompt::{PromptFromatter, PromptTemplate};
use langchain_rust::prompt_args;
use langchain_rust::schemas::Message;
use ollama_rs::generation::parameters::{FormatType, JsonStructure};
use schemars::JsonSchema;
use serde::{Deserialize, Serialize};
use serde_json::json;
use tracing::trace;
use uuid::Uuid;

const SYSTEM_PROMPT: &str = r#"
Instruction:
You are a precise question generator working with a context document that has a unique object_id. Generate exactly three questions that:
1. Can be directly answered using ONLY explicit information stated in the document
2. Reference specific facts, details, or statements found verbatim in the text
3. Do not require inference, speculation, or outside knowledge to answer
4. Cover different aspects of the information provided in the document

##Context##
{{context}}

Output format:
Return a valid JSON array of exactly three objects:
[
  {
    "content": "Question that refers to explicitly stated information",
    "object_id": "id_of_context_item"
  },
  {
    "content": "Another question based only on factual content in the document",
    "object_id": "id_of_context_item"
  },
  {
    "content": "A third question referencing specific details from the text",
    "object_id": "id_of_context_item"
  }
]

IMPORTANT RULES:
- Questions MUST be answerable using ONLY information explicitly stated in the document
- Do not create questions about information that must be inferred or guessed
- Do not ask about comparative elements unless the comparison is explicitly made in the text
- Verify that the exact answer to each question appears in the document verbatim
- Ensure questions reference different parts of the document for better coverage
"#;

#[derive(Debug, Deserialize, JsonSchema)]
struct ContextQuestionsResponse {
  questions: Vec<ContextQuestion>,
}

#[derive(Debug, Clone, Serialize, Deserialize, JsonSchema)]
pub struct ContextQuestion {
  pub content: String,
  pub object_id: String,
}

pub struct RelatedQuestionChain {
  workspace_id: Uuid,
  llm: LLMOllama,
  store: SqliteVectorStore,
}

impl RelatedQuestionChain {
  pub fn new(workspace_id: Uuid, ollama: LLMOllama, store: SqliteVectorStore) -> Self {
    let format = FormatType::StructuredJson(JsonStructure::new::<ContextQuestionsResponse>());
    Self {
      workspace_id,
      llm: ollama.with_format(format),
      store,
    }
  }

  pub async fn generate_questions(&self, rag_ids: &[String]) -> FlowyResult<Vec<ContextQuestion>> {
    trace!(
      "[embedding] Generating context related questions for RAG IDs: {:?}",
      rag_ids
    );

    let context = self
      .store
      .select_all_embedded_content(&self.workspace_id.to_string(), rag_ids, 3)
      .await?;

    trace!(
      "[embedding] Generating related questions base on: {:?}",
      context,
    );

    let context_str = json!(context).to_string();
    let input_variables = prompt_args! {
        "context" => context_str,
    };

    let template = PromptTemplate::new(
      SYSTEM_PROMPT.to_string(),
      vec!["context".to_string()],
      TemplateFormat::Jinja2,
    );

    let formatted_prompt = template
      .format(input_variables)
      .map_err(|err| FlowyError::internal().with_context(format!("{}", err)))?;

    let messages = vec![Message::new_system_message(formatted_prompt)];
    let result = self.llm.generate(&messages).await.map_err(|err| {
      FlowyError::internal().with_context(format!("Error generating related questions: {}", err))
    })?;

    let mut parsed_result = serde_json::from_str::<ContextQuestionsResponse>(&result.generation)?;
    // filter out questions that are not in the rag_ids
    parsed_result
      .questions
      .retain(|v| rag_ids.contains(&v.object_id));

    Ok(parsed_result.questions)
  }
}
