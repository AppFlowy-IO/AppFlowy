use crate::local_ai::chat::llm::LLMOllama;
use async_stream::stream;
use async_trait::async_trait;
use flowy_ai_pub::entities::SOURCE_ID;
use futures::Stream;
use futures_util::{pin_mut, StreamExt};
use langchain_rust::chain::{
  Chain, ChainError, CondenseQuestionGeneratorChain, CondenseQuestionPromptBuilder,
  StuffDocumentBuilder, StuffQAPromptBuilder,
};
use langchain_rust::language_models::{GenerateResult, TokenUsage};
use langchain_rust::memory::SimpleMemory;
use langchain_rust::prompt::{FormatPrompter, PromptArgs};
use langchain_rust::schemas::{BaseMemory, Document, Message, Retriever, StreamData};
use langchain_rust::vectorstore::{VecStoreOptions, VectorStore};
use serde_json::{json, Value};
use std::collections::HashSet;
use std::error::Error;
use std::{collections::HashMap, pin::Pin, sync::Arc};
use tokio::sync::Mutex;

pub(crate) const DEFAULT_OUTPUT_KEY: &str = "output";
pub(crate) const DEFAULT_RESULT_KEY: &str = "generate_result";

const CONVERSATIONAL_RETRIEVAL_QA_DEFAULT_SOURCE_DOCUMENT_KEY: &str = "source_documents";
const CONVERSATIONAL_RETRIEVAL_QA_DEFAULT_GENERATED_QUESTION_KEY: &str = "generated_question";
const CONVERSATIONAL_RETRIEVAL_QA_DEFAULT_INPUT_KEY: &str = "question";

pub struct ConversationalRetrieverChain {
  pub(crate) ollama: LLMOllama,
  pub(crate) retriever: AFRetriever<Value>,
  pub memory: Arc<Mutex<dyn BaseMemory>>,
  pub(crate) combine_documents_chain: Box<dyn Chain>,
  pub(crate) condense_question_chain: Box<dyn Chain>,
  pub(crate) rephrase_question: bool,
  pub(crate) return_source_documents: bool,
  pub(crate) input_key: String,
  pub(crate) output_key: String,
}
impl ConversationalRetrieverChain {
  pub fn set_rag_ids(&mut self, new_rag_ids: Vec<String>) {
    let filters = self
      .retriever
      .options
      .filters
      .get_or_insert_with(|| json!({}));

    filters["rag_ids"] = json!(new_rag_ids);
  }

  pub fn add_rag_ids<I, S>(&mut self, rag_ids: I)
  where
    I: IntoIterator<Item = S>,
    S: AsRef<str>,
  {
    // Ensure a filter object exists
    let filters = self
      .retriever
      .options
      .filters
      .get_or_insert_with(|| json!({}));

    let arr = filters
      .as_object_mut()
      .expect("filters must be a JSON object")
      .entry("rag_ids")
      .or_insert_with(|| json!([]))
      .as_array_mut()
      .expect("`rag_ids` must be an array");

    let mut existing: HashSet<String> = arr
      .iter()
      .filter_map(|v| v.as_str().map(|s| s.to_string()))
      .collect();

    // Insert new IDs if not already present
    for id in rag_ids {
      let id_str = id.as_ref();
      if existing.insert(id_str.to_string()) {
        arr.push(json!(id_str));
      }
    }
  }

  pub fn remove_rag_ids(&mut self, rag_ids: Vec<String>) {
    if let Some(filters) = self.retriever.options.filters.as_mut() {
      if let Some(current_rag_ids) = filters
        .get_mut("rag_ids")
        .and_then(|filter| filter.as_array_mut())
      {
        // Remove specified rag_ids from the array
        current_rag_ids.retain(|id| {
          id.as_str()
            .map_or(true, |id_str| !rag_ids.contains(&id_str.to_string()))
        });
      }
    }
  }

  async fn get_question(
    &self,
    history: &[Message],
    input: &str,
  ) -> Result<(String, Option<TokenUsage>), ChainError> {
    if history.is_empty() {
      return Ok((input.to_string(), None));
    }
    let mut token_usage: Option<TokenUsage> = None;
    let question = match self.rephrase_question {
      true => {
        let result = self
          .condense_question_chain
          .call(
            CondenseQuestionPromptBuilder::new()
              .question(input)
              .chat_history(history)
              .build(),
          )
          .await?;
        if let Some(tokens) = result.tokens {
          token_usage = Some(tokens);
        };
        result.generation
      },
      false => input.to_string(),
    };

    Ok((question, token_usage))
  }
}

#[async_trait]
impl Chain for ConversationalRetrieverChain {
  async fn call(&self, input_variables: PromptArgs) -> Result<GenerateResult, ChainError> {
    let output = self.execute(input_variables).await?;
    let result: GenerateResult = serde_json::from_value(output[DEFAULT_RESULT_KEY].clone())?;
    Ok(result)
  }

  async fn execute(
    &self,
    input_variables: PromptArgs,
  ) -> Result<HashMap<String, Value>, ChainError> {
    let mut token_usage: Option<TokenUsage> = None;
    let input_variable = &input_variables
      .get(&self.input_key)
      .ok_or(ChainError::MissingInputVariable(self.input_key.clone()))?;

    let human_message = Message::new_human_message(input_variable);
    let history = {
      let memory = self.memory.lock().await;
      memory.messages()
    };

    let (question, token) = self.get_question(&history, &human_message.content).await?;
    if let Some(token) = token {
      token_usage = Some(token);
    }

    let documents = self
      .retriever
      .get_relevant_documents(&question)
      .await
      .map_err(|e| ChainError::RetrieverError(e.to_string()))?;

    let mut output = self
      .combine_documents_chain
      .call(
        StuffQAPromptBuilder::new()
          .documents(&documents)
          .question(question.clone())
          .build(),
      )
      .await?;

    if let Some(tokens) = &output.tokens {
      if let Some(mut token_usage) = token_usage {
        token_usage.add(tokens);
        output.tokens = Some(token_usage)
      }
    }

    {
      let mut memory = self.memory.lock().await;
      memory.add_message(human_message);
      memory.add_message(Message::new_ai_message(&output.generation));
    }

    let mut result = HashMap::new();
    result.insert(self.output_key.clone(), json!(output.generation));

    result.insert(DEFAULT_RESULT_KEY.to_string(), json!(output));

    if self.return_source_documents {
      result.insert(
        CONVERSATIONAL_RETRIEVAL_QA_DEFAULT_SOURCE_DOCUMENT_KEY.to_string(),
        json!(documents),
      );
    }

    if self.rephrase_question {
      result.insert(
        CONVERSATIONAL_RETRIEVAL_QA_DEFAULT_GENERATED_QUESTION_KEY.to_string(),
        json!(question),
      );
    }

    Ok(result)
  }

  async fn stream(
    &self,
    input_variables: PromptArgs,
  ) -> Result<Pin<Box<dyn Stream<Item = Result<StreamData, ChainError>> + Send>>, ChainError> {
    let input_variable = &input_variables
      .get(&self.input_key)
      .ok_or(ChainError::MissingInputVariable(self.input_key.clone()))?;

    let human_message = Message::new_human_message(input_variable);
    let history = {
      let memory = self.memory.lock().await;
      memory.messages()
    };

    let (question, _) = self.get_question(&history, &human_message.content).await?;

    let documents = self
      .retriever
      .get_relevant_documents(&question)
      .await
      .map_err(|e| ChainError::RetrieverError(e.to_string()))?;

    let stream = self
      .combine_documents_chain
      .stream(
        StuffQAPromptBuilder::new()
          .documents(&documents)
          .question(question.clone())
          .build(),
      )
      .await?;

    let sources = deduplicate_metadata(&documents);
    let memory = self.memory.clone();
    let complete_ai_message = Arc::new(Mutex::new(String::new()));
    let complete_ai_message_clone = complete_ai_message.clone();
    let output_stream = stream! {
        pin_mut!(stream);

        for source in sources {
          yield Ok(StreamData::new(
              json!({"source": source}),
              None,
              "".to_string(),
          ));
        }


        while let Some(result) = stream.next().await {
            match result {
                Ok(data) => {
                    let mut complete_ai_message_clone =
                        complete_ai_message_clone.lock().await;
                    complete_ai_message_clone.push_str(&data.content);

                    yield Ok(data);
                },
                Err(e) => {
                    yield Err(e);
                }
            }
        }

        let mut memory = memory.lock().await;
        memory.add_message(human_message);
        memory.add_message(Message::new_ai_message(&complete_ai_message.lock().await));
    };

    Ok(Box::pin(output_stream))
  }

  fn get_input_keys(&self) -> Vec<String> {
    vec![self.input_key.clone()]
  }

  fn get_output_keys(&self) -> Vec<String> {
    let mut keys = Vec::new();
    if self.return_source_documents {
      keys.push(CONVERSATIONAL_RETRIEVAL_QA_DEFAULT_SOURCE_DOCUMENT_KEY.to_string());
    }

    if self.rephrase_question {
      keys.push(CONVERSATIONAL_RETRIEVAL_QA_DEFAULT_GENERATED_QUESTION_KEY.to_string());
    }

    keys.push(self.output_key.clone());
    keys.push(DEFAULT_RESULT_KEY.to_string());

    keys
  }
}

pub struct ConversationalRetrieverChainBuilder {
  llm: Option<LLMOllama>,
  retriever: Option<AFRetriever<Value>>,
  memory: Option<Arc<Mutex<dyn BaseMemory>>>,
  combine_documents_chain: Option<Box<dyn Chain>>,
  condense_question_chain: Option<Box<dyn Chain>>,
  prompt: Option<Box<dyn FormatPrompter>>,
  rephrase_question: bool,
  return_source_documents: bool,
  input_key: String,
  output_key: String,
}
impl ConversationalRetrieverChainBuilder {
  pub fn new() -> Self {
    ConversationalRetrieverChainBuilder {
      llm: None,
      retriever: None,
      memory: None,
      combine_documents_chain: None,
      condense_question_chain: None,
      prompt: None,
      rephrase_question: true,
      return_source_documents: true,
      input_key: CONVERSATIONAL_RETRIEVAL_QA_DEFAULT_INPUT_KEY.to_string(),
      output_key: DEFAULT_OUTPUT_KEY.to_string(),
    }
  }

  pub fn retriever(mut self, retriever: AFRetriever<Value>) -> Self {
    self.retriever = Some(retriever);
    self
  }

  ///If you want to add a custom prompt,keep in mind which variables are obligatory.
  pub fn prompt<P: Into<Box<dyn FormatPrompter>>>(mut self, prompt: P) -> Self {
    self.prompt = Some(prompt.into());
    self
  }

  pub fn memory(mut self, memory: Arc<Mutex<dyn BaseMemory>>) -> Self {
    self.memory = Some(memory);
    self
  }

  pub fn llm(mut self, llm: LLMOllama) -> Self {
    self.llm = Some(llm);
    self
  }

  ///Chain designed to take the documents and the question and generate an output
  #[allow(dead_code)]
  pub fn combine_documents_chain<C: Into<Box<dyn Chain>>>(
    mut self,
    combine_documents_chain: C,
  ) -> Self {
    self.combine_documents_chain = Some(combine_documents_chain.into());
    self
  }

  ///Chain designed to reformulate the question based on the cat history
  #[allow(dead_code)]
  pub fn condense_question_chain<C: Into<Box<dyn Chain>>>(
    mut self,
    condense_question_chain: C,
  ) -> Self {
    self.condense_question_chain = Some(condense_question_chain.into());
    self
  }

  pub fn rephrase_question(mut self, rephrase_question: bool) -> Self {
    self.rephrase_question = rephrase_question;
    self
  }

  #[allow(dead_code)]
  pub fn return_source_documents(mut self, return_source_documents: bool) -> Self {
    self.return_source_documents = return_source_documents;
    self
  }

  pub fn build(mut self) -> Result<ConversationalRetrieverChain, ChainError> {
    if let Some(llm) = self.llm.as_ref() {
      let combine_documents_chain = {
        let mut builder = StuffDocumentBuilder::new().llm(llm.clone());
        if let Some(prompt) = self.prompt {
          builder = builder.prompt(prompt);
        }
        builder.build()?
      };
      let condense_question_chain = CondenseQuestionGeneratorChain::new(llm.clone());
      self.combine_documents_chain = Some(Box::new(combine_documents_chain));
      self.condense_question_chain = Some(Box::new(condense_question_chain));
    }

    let retriever = self
      .retriever
      .ok_or_else(|| ChainError::MissingObject("Retriever must be set".into()))?;

    let memory = self
      .memory
      .unwrap_or_else(|| Arc::new(Mutex::new(SimpleMemory::new())));

    let combine_documents_chain = self.combine_documents_chain.ok_or_else(|| {
      ChainError::MissingObject("Combine documents chain must be set or llm must be set".into())
    })?;
    let condense_question_chain = self.condense_question_chain.ok_or_else(|| {
      ChainError::MissingObject("Condense question chain must be set or llm must be set".into())
    })?;

    Ok(ConversationalRetrieverChain {
      ollama: self.llm.unwrap(),
      retriever,
      memory,
      combine_documents_chain,
      condense_question_chain,
      rephrase_question: self.rephrase_question,
      return_source_documents: self.return_source_documents,
      input_key: self.input_key,
      output_key: self.output_key,
    })
  }
}

// Retriever is a retriever for vector stores.
pub struct AFRetriever<F> {
  vstore: Box<dyn VectorStore<Options = VecStoreOptions<F>>>,
  num_docs: usize,
  options: VecStoreOptions<F>,
}
impl<F> AFRetriever<F> {
  pub fn new<V: Into<Box<dyn VectorStore<Options = VecStoreOptions<F>>>>>(
    vstore: V,
    num_docs: usize,
  ) -> Self {
    AFRetriever {
      vstore: vstore.into(),
      num_docs,
      options: VecStoreOptions::<F>::new(),
    }
  }

  pub fn with_options(mut self, options: VecStoreOptions<F>) -> Self {
    self.options = options;
    self
  }
}

#[async_trait]
impl<O: Sync + Send> Retriever for AFRetriever<O> {
  async fn get_relevant_documents(&self, query: &str) -> Result<Vec<Document>, Box<dyn Error>> {
    self
      .vstore
      .similarity_search(query, self.num_docs, &self.options)
      .await
  }
}

/// Deduplicates metadata from a list of documents by merging metadata entries with the same keys
fn deduplicate_metadata(documents: &[Document]) -> Vec<Value> {
  let mut merged_metadata: HashMap<String, Value> = HashMap::new();
  for document in documents {
    if let Some(object_id) = document.metadata.get(SOURCE_ID).and_then(|s| s.as_str()) {
      merged_metadata.insert(object_id.to_string(), json!(document.metadata.clone()));
    }
  }
  merged_metadata.into_values().collect()
}
