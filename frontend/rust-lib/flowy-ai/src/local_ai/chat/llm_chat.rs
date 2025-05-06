use crate::local_ai::chat::conversation_chain::{
  AFRetriever, ConversationalRetrieverChain, ConversationalRetrieverChainBuilder, RetrieverOption,
};
use crate::local_ai::chat::format_prompt::DynamicMessageFormatter;
use crate::local_ai::chat::llm::LLMOllama;
use crate::local_ai::chat::OllamaClientRef;
use crate::local_ai::prompt::format_prompt;
use crate::SqliteVectorStore;
use flowy_ai_pub::cloud::{QuestionStreamValue, ResponseFormat, StreamAnswer};
use flowy_ai_pub::entities::{RAG_IDS, SOURCE_ID};
use flowy_error::{FlowyError, FlowyResult};
use flowy_sqlite_vec::entities::SqliteEmbeddedDocument;
use futures::StreamExt;
use langchain_rust::chain::{Chain, ChainError};
use langchain_rust::memory::SimpleMemory;
use langchain_rust::prompt::{
  FormatPrompter, HumanMessagePromptTemplate, MessageFormatter, MessageFormatterStruct,
  MessageOrTemplate, PromptArgs, PromptError,
};
use langchain_rust::schemas::{Document, Message, PromptValue};
use langchain_rust::vectorstore::{VecStoreOptions, VectorStore};
use langchain_rust::{fmt_message, fmt_template, message_formatter, prompt_args, template_jinja2};
use serde_json::json;
use std::collections::HashMap;
use std::sync::Arc;
use std::sync::Mutex;
use tokio::sync::Mutex as TokioMutex;
use tracing::{info, trace};
use uuid::Uuid;

pub struct LLMChat {
  workspace_id: Uuid,
  chat_id: Uuid,
  store: Option<SqliteVectorStore>,
  chain: ConversationalRetrieverChain,
  client: OllamaClientRef,
  rag_ids: Vec<String>,
  format_instruction: Arc<Mutex<Message>>,
  current_format: Arc<Mutex<ResponseFormat>>,
}

impl LLMChat {
  pub async fn new(
    workspace_id: Uuid,
    chat_id: Uuid,
    model: &str,
    client: OllamaClientRef,
    store: Option<SqliteVectorStore>,
    rag_ids: Vec<String>,
  ) -> FlowyResult<Self> {
    let initial_format = ResponseFormat::default();
    let formatter = create_dynamic_prompt_with_format(&initial_format);
    let (format_instruction, current_format) = formatter.get_shared_handles();

    let (chain, _) = create_chain(
      &workspace_id,
      model,
      &client,
      rag_ids.clone(),
      formatter,
      store.clone(),
    )
    .await?;

    Ok(Self {
      workspace_id,
      chat_id,
      store,
      chain,
      client,
      rag_ids,
      format_instruction,
      current_format,
    })
  }

  pub async fn set_chat_model(&mut self, model: &str) -> FlowyResult<()> {
    self.chain.ollama.set_model(model);
    Ok(())
  }

  pub async fn set_rag_ids(&mut self, rag_ids: Vec<String>) {
    info!("[VectorStore]: {} set rag ids: {:?}", self.chat_id, rag_ids);
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

    let options =
      RetrieverOption::new().with_filters(json!({RAG_IDS: ids, "workspace_id": self.workspace_id}));
    let result = store
      .similarity_search(query, limit, &options)
      .await
      .map_err(|err| FlowyError::local_ai().with_context(err))?;
    Ok(result)
  }

  pub async fn get_all_embedded_documents(&self) -> FlowyResult<Vec<SqliteEmbeddedDocument>> {
    let store = self
      .store
      .as_ref()
      .ok_or_else(|| FlowyError::local_ai().with_context("VectorStore is not initialized"))?;

    store
      .select_all_embedded_documents(&self.workspace_id.to_string(), &self.rag_ids)
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
    metadata.insert("workspace_id".to_string(), json!(self.workspace_id));
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
    // Get the current format
    let current_format = {
      let lock = self.current_format.lock().map_err(|_| {
        FlowyError::local_ai().with_context("Failed to acquire lock on current_format")
      })?;
      (*lock).clone()
    };

    // Check if format has changed
    if current_format.output_layout != format.output_layout {
      trace!(
        "[LLMChat] Updating format from {:?} to {:?}",
        current_format.output_layout,
        format.output_layout
      );

      // Update the shared format instruction
      {
        let mut format_lock = self.format_instruction.lock().map_err(|_| {
          FlowyError::local_ai().with_context("Failed to acquire lock on format_instruction")
        })?;
        *format_lock = format_prompt(&format);
      }

      // Update the current format
      {
        let mut format_lock = self.current_format.lock().map_err(|_| {
          FlowyError::local_ai().with_context("Failed to acquire lock on current_format")
        })?;
        *format_lock = format.clone();
      }
    }

    let input_variables = prompt_args! {
        "question" => message,
    };

    let stream_result = self.chain.stream(input_variables).await;
    let stream = stream_result.map_err(map_chain_error)?;
    let transformed_stream = stream.map(|result| {
      result
        .map(|stream_data| {
          if let Some(source) = stream_data.value.as_object().and_then(|v| v.get("source")) {
            trace!("[VectorStore]: reference sources: {:?}", source);
            QuestionStreamValue::Metadata {
              value: source.clone(),
            }
          } else {
            QuestionStreamValue::Answer {
              value: stream_data.content,
            }
          }
        })
        .map_err(map_chain_error)
    });
    Ok(Box::pin(transformed_stream))
  }
}

fn create_dynamic_prompt_with_format(format: &ResponseFormat) -> DynamicMessageFormatter {
  let system_message =
    Message::new_system_message("You are an assistant for question-answering tasks");

  DynamicMessageFormatter::new(system_message, format)
}

fn create_retriever(
  workspace_id: &Uuid,
  rag_ids: Vec<String>,
  store: SqliteVectorStore,
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

async fn create_chain(
  workspace_id: &Uuid,
  model: &str,
  client: &OllamaClientRef,
  rag_ids: Vec<String>,
  formatter: DynamicMessageFormatter,
  store: Option<SqliteVectorStore>,
) -> FlowyResult<(ConversationalRetrieverChain, DynamicMessageFormatter)> {
  let llm = create_llm(client, model).await?;

  let mut builder = ConversationalRetrieverChainBuilder::new()
    .llm(llm)
    .rephrase_question(false)
    .memory(SimpleMemory::new().into());

  if let Some(store) = store {
    let retriever = create_retriever(workspace_id, rag_ids, store);
    builder = builder.retriever(retriever);
  }

  let chain = builder
    .prompt(formatter.clone())
    .build()
    .map_err(|err| FlowyError::local_ai().with_context(err))?;

  Ok((chain, formatter))
}

async fn create_llm(client: &OllamaClientRef, model: &str) -> FlowyResult<LLMOllama> {
  let read_guard = client.read().await;
  let client = read_guard
    .as_ref()
    .ok_or_else(|| FlowyError::local_ai().with_context("Ollama client not initialized"))?
    .upgrade()
    .ok_or_else(|| FlowyError::local_ai().with_context("Ollama client has been dropped"))?
    .clone();
  let ollama = LLMOllama::new(model, client, None, None);
  Ok(ollama)
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
