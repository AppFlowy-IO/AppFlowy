use crate::local_ai::chat::conversation_chain::{
  AFRetriever, ConversationalRetrieverChain, ConversationalRetrieverChainBuilder,
};
use crate::local_ai::chat::llm::LLMOllama;
use crate::local_ai::chat::OllamaClientRef;
use crate::local_ai::prompt::format_prompt;
use crate::SqliteVectorStore;
use flowy_ai_pub::cloud::{QuestionStreamValue, ResponseFormat, StreamAnswer};
use flowy_ai_pub::entities::SOURCE_ID;
use flowy_error::{FlowyError, FlowyResult};
use futures::StreamExt;
use langchain_rust::chain::{Chain, ChainError};
use langchain_rust::memory::SimpleMemory;
use langchain_rust::prompt::{HumanMessagePromptTemplate, MessageFormatterStruct};
use langchain_rust::schemas::{Document, Message};
use langchain_rust::vectorstore::{VecStoreOptions, VectorStore};
use langchain_rust::{fmt_message, fmt_template, message_formatter, prompt_args, template_jinja2};
use serde_json::{json, Value};
use std::collections::HashMap;
use uuid::Uuid;

pub struct LLMChat {
  workspace_id: Uuid,
  #[allow(dead_code)]
  chat_id: Uuid,
  store: Option<SqliteVectorStore>,
  chain: ConversationalRetrieverChain,
  client: OllamaClientRef,
  current_format: ResponseFormat,
  rag_ids: Vec<String>,
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
    let current_format = ResponseFormat::default();
    let chain = create_chain(
      &workspace_id,
      model,
      &client,
      rag_ids.clone(),
      &current_format,
      store.clone(),
    )
    .await?;

    Ok(Self {
      workspace_id,
      chat_id,
      store,
      chain,
      client,
      current_format,
      rag_ids,
    })
  }

  pub async fn set_chat_model(&mut self, model: &str) -> FlowyResult<()> {
    self.chain.ollama.set_model(model);
    Ok(())
  }

  pub async fn add_rag_id(&mut self, id: String) -> FlowyResult<()> {
    self.chain.add_rag_ids(vec![id]);
    Ok(())
  }

  pub async fn set_rag_ids(&mut self, rag_ids: Vec<String>) -> FlowyResult<()> {
    self.chain.set_rag_ids(rag_ids);
    Ok(())
  }

  pub fn remove_rag_id(&mut self, id: String) {
    self.chain.remove_rag_ids(vec![id]);
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
    if self.current_format.output_layout != format.output_layout {
      self.current_format = format.clone();
      self.chain = create_chain(
        &self.workspace_id,
        self.chain.ollama.model_name.as_ref(),
        &self.client,
        self.rag_ids.clone(),
        &self.current_format,
        self.store.clone(),
      )
      .await?;
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

fn create_prompt_with_format(format: &ResponseFormat) -> MessageFormatterStruct {
  let format_instruction = format_prompt(format);
  message_formatter![
    fmt_message!(Message::new_system_message(
      "You are a helpful assistant", 
    )),
    fmt_message!(format_instruction),
    fmt_template!(HumanMessagePromptTemplate::new(
      template_jinja2!("
        Use the following pieces of context to answer the question at the end. If you don't know the answer, just say that you don't know, don't try to make up an answer.
        {{context}}

        Question:{{question}}
        Answer:
        ",
        "context",
        "question"
      )
    ))
  ]
}

fn create_retriever(
  workspace_id: &Uuid,
  rag_ids: Vec<String>,
  store: SqliteVectorStore,
) -> AFRetriever<Value> {
  let options = VecStoreOptions::default()
    .with_score_threshold(0.4)
    .with_filters(json!({"rag_ids": rag_ids, "workspace_id": workspace_id}));
  AFRetriever::<Value>::new(store, 5).with_options(options)
}

async fn create_chain(
  workspace_id: &Uuid,
  model: &str,
  client: &OllamaClientRef,
  rag_ids: Vec<String>,
  format: &ResponseFormat,
  store: Option<SqliteVectorStore>,
) -> FlowyResult<ConversationalRetrieverChain> {
  let llm = create_llm(client, model).await?;
  let prompt = create_prompt_with_format(format);

  let mut builder = ConversationalRetrieverChainBuilder::new()
    .llm(llm)
    .rephrase_question(true)
    .memory(SimpleMemory::new().into());

  if let Some(store) = store {
    let retriever = create_retriever(workspace_id, rag_ids, store);
    builder = builder.retriever(retriever);
  }

  let chain = builder
    .prompt(prompt)
    .build()
    .map_err(|err| FlowyError::local_ai().with_context(err))?;

  Ok(chain)
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
