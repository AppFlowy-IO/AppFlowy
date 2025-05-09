use crate::local_ai::chat::chains::conversation_chain::{
  AFRetriever, ConversationalRetrieverChain, ConversationalRetrieverChainBuilder, RetrieverOption,
};
use crate::local_ai::chat::chains::related_question_chain::RelatedQuestionChain;
use crate::local_ai::chat::format_prompt::AFContextPrompt;
use crate::local_ai::chat::llm::LLMOllama;
use crate::local_ai::chat::summary_memory::SummaryMemory;
use crate::local_ai::chat::LLMChatInfo;
use crate::SqliteVectorStore;
use flowy_ai_pub::cloud::{QuestionStreamValue, ResponseFormat, StreamAnswer};
use flowy_ai_pub::entities::{RAG_IDS, SOURCE_ID, WORKSPACE_ID};
use flowy_ai_pub::user_service::AIUserService;
use flowy_error::{FlowyError, FlowyResult};
use futures::StreamExt;
use langchain_rust::chain::{Chain, ChainError};
use langchain_rust::memory::SimpleMemory;
use langchain_rust::prompt_args;
use langchain_rust::schemas::{Document, Message};
use langchain_rust::vectorstore::{VecStoreOptions, VectorStore};
use ollama_rs::Ollama;
use serde_json::json;
use std::collections::HashMap;
use std::sync::{Arc, Weak};
use tracing::trace;
use uuid::Uuid;

pub struct LLMChat {
  store: Option<SqliteVectorStore>,
  chain: ConversationalRetrieverChain,
  client: Arc<Ollama>,
  prompt: AFContextPrompt,
  info: LLMChatInfo,
}

impl LLMChat {
  pub fn new(
    info: LLMChatInfo,
    client: Arc<Ollama>,
    store: Option<SqliteVectorStore>,
    user_service: Option<Weak<dyn AIUserService>>,
  ) -> FlowyResult<Self> {
    let response_format = ResponseFormat::default();
    let formatter = create_formatter_prompt_with_format(&response_format, &info.rag_ids);
    let llm = LLMOllama::new(&info.model, client.clone(), None, None);
    let summary_llm = LLMOllama::new(&info.model, client.clone(), None, None);
    let memory = SummaryMemory::new(summary_llm, info.summary.clone(), user_service)
      .map(|v| v.into())
      .unwrap_or(SimpleMemory::new().into());

    let retriever = create_retriever(&info.workspace_id, info.rag_ids.clone(), store.clone());
    let builder =
      ConversationalRetrieverChainBuilder::new(info.workspace_id, llm, retriever, store.clone())
        .rephrase_question(false)
        .memory(memory);

    let chain = builder.prompt(formatter.clone()).build()?;
    Ok(Self {
      store,
      chain,
      client,
      prompt: formatter,
      info,
    })
  }

  pub async fn get_related_question(&self, user_message: String) -> FlowyResult<Vec<String>> {
    let chain = RelatedQuestionChain::new(LLMOllama::new(
      &self.info.model,
      self.client.clone(),
      None,
      None,
    ));
    let questions = chain.related_question(&user_message).await?;
    trace!(
      "related questions: {:?} for message: {}",
      questions,
      user_message
    );
    Ok(questions)
  }

  pub fn set_chat_model(&mut self, model: &str) {
    self.chain.ollama.set_model(model);
  }

  pub fn set_rag_ids(&mut self, rag_ids: Vec<String>) {
    self.prompt.set_rag_ids(&rag_ids);
    self.chain.retriever.set_rag_ids(rag_ids);
  }

  pub async fn search(
    &self,
    query: &str,
    limit: usize,
    ids: Vec<String>,
  ) -> FlowyResult<Vec<Document>> {
    let store = self
      .store
      .as_ref()
      .ok_or_else(|| FlowyError::local_ai().with_context("VectorStore is not initialized"))?;

    let options = RetrieverOption::new()
      .with_filters(json!({RAG_IDS: ids, "workspace_id": self.info.workspace_id}));
    let result = store
      .similarity_search(query, limit, &options)
      .await
      .map_err(|err| FlowyError::local_ai().with_context(err))?;
    Ok(result)
  }

  #[cfg(any(target_os = "windows", target_os = "macos", target_os = "linux"))]
  pub async fn get_all_embedded_documents(
    &self,
  ) -> FlowyResult<Vec<flowy_sqlite_vec::entities::SqliteEmbeddedDocument>> {
    let store = self
      .store
      .as_ref()
      .ok_or_else(|| FlowyError::local_ai().with_context("VectorStore is not initialized"))?;

    store
      .select_all_embedded_documents(&self.info.workspace_id.to_string(), &self.info.rag_ids)
      .await
      .map_err(|err| {
        FlowyError::local_ai().with_context(format!("Failed to select embedded documents: {}", err))
      })
  }

  pub async fn embed_paragraphs(
    &self,
    object_id: &str,
    paragraphs: Vec<String>,
  ) -> FlowyResult<()> {
    let mut metadata = HashMap::new();
    metadata.insert(WORKSPACE_ID.to_string(), json!(self.info.workspace_id));
    metadata.insert(SOURCE_ID.to_string(), json!(object_id));
    let document = Document::new(paragraphs.join("\n\n")).with_metadata(metadata);
    if let Some(store) = &self.store {
      store
        .add_documents(&[document], &VecStoreOptions::default())
        .await
        .map_err(|err| FlowyError::local_ai().with_context(err))?;
    }
    Ok(())
  }

  pub async fn ask_question(&self, question: &str) -> FlowyResult<String> {
    let input_variables = prompt_args! {
        "question" => question,
    };

    let result = self
      .chain
      .invoke(input_variables)
      .await
      .map_err(map_chain_error)?;
    Ok(result)
  }

  /// Send a message to the chat and get a response
  pub async fn stream_question(
    &mut self,
    message: &str,
    format: ResponseFormat,
  ) -> Result<StreamAnswer, FlowyError> {
    trace!("[chat]: {} stream question: {}", self.info.chat_id, message);
    self.prompt.update_format(&format)?;
    let input_variables = prompt_args! {
        "question" => message,
    };

    let stream_result = self.chain.stream(input_variables).await;
    let stream = stream_result.map_err(map_chain_error)?;
    let transformed_stream = stream.map(|result| {
      result
        .map(|stream_data| {
          serde_json::from_value::<QuestionStreamValue>(stream_data.value).unwrap_or_else(|_| {
            QuestionStreamValue::Answer {
              value: String::new(),
            }
          })
        })
        .map_err(map_chain_error)
    });
    Ok(Box::pin(transformed_stream))
  }
}

fn create_formatter_prompt_with_format(
  format: &ResponseFormat,
  rag_ids: &[String],
) -> AFContextPrompt {
  let system_message =
    Message::new_system_message("You are an assistant for question-answering tasks");
  AFContextPrompt::new(system_message, format, rag_ids)
}

fn create_retriever(
  workspace_id: &Uuid,
  rag_ids: Vec<String>,
  store: Option<SqliteVectorStore>,
) -> AFRetriever {
  trace!(
    "[VectorStore]: {} create retriever with rag_ids: {:?}",
    workspace_id,
    rag_ids,
  );
  let options = VecStoreOptions::default()
    .with_score_threshold(0.2)
    .with_filters(json!({RAG_IDS: rag_ids, "workspace_id": workspace_id}));

  AFRetriever::new(store, 5, options)
}

fn map_chain_error(err: ChainError) -> FlowyError {
  match err {
    ChainError::MissingInputVariable(var) => {
      FlowyError::local_ai().with_context(format!("Missing input variable: {}", var))
    },
    ChainError::MissingObject(obj) => {
      FlowyError::local_ai().with_context(format!("Missing object: {}", obj))
    },
    ChainError::RetrieverError(err) => {
      FlowyError::local_ai().with_context(format!("Retriever error: {}", err))
    },
    _ => FlowyError::local_ai().with_context(format!("Chain error: {:?}", err)),
  }
}
