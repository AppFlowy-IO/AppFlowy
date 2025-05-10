use crate::local_ai::chat::chains::context_question_chain::RelatedQuestionChain;
use crate::local_ai::chat::llm::LLMOllama;
use crate::local_ai::chat::retriever::AFRetriever;
use crate::SqliteVectorStore;
use async_stream::stream;
use async_trait::async_trait;
use flowy_ai_pub::cloud::{ContextSuggestedQuestion, QuestionStreamValue};
use flowy_ai_pub::entities::SOURCE_ID;
use flowy_error::{FlowyError, FlowyResult};
use futures::Stream;
use futures_util::{pin_mut, StreamExt};
use langchain_rust::chain::{
  Chain, ChainError, CondenseQuestionGeneratorChain, CondenseQuestionPromptBuilder,
  StuffDocumentBuilder, StuffQAPromptBuilder,
};
use langchain_rust::language_models::{GenerateResult, TokenUsage};
use langchain_rust::memory::SimpleMemory;
use langchain_rust::prompt::{FormatPrompter, PromptArgs};
use langchain_rust::schemas::{BaseMemory, Document, Message, StreamData};
use serde::{Deserialize, Serialize};
use serde_json::{json, Value};
use std::{collections::HashMap, pin::Pin, sync::Arc};
use tokio::sync::Mutex;
use tokio_util::either::Either;
use tracing::{error, trace};
use uuid::Uuid;

pub const CAN_NOT_ANSWER_WITH_CONTEXT: &str = "I couldn't find any relevant information in the sources you selected. Please try asking a different question";
pub const ANSWER_WITH_SUGGESTED_QUESTION: &str = "I couldn't find any relevant information in the sources you selected. Please try ask following questions";
pub(crate) const DEFAULT_OUTPUT_KEY: &str = "output";
pub(crate) const DEFAULT_RESULT_KEY: &str = "generate_result";

const CONVERSATIONAL_RETRIEVAL_QA_DEFAULT_SOURCE_DOCUMENT_KEY: &str = "source_documents";
const CONVERSATIONAL_RETRIEVAL_QA_DEFAULT_GENERATED_QUESTION_KEY: &str = "generated_question";
const CONVERSATIONAL_RETRIEVAL_QA_DEFAULT_INPUT_KEY: &str = "question";

pub struct ConversationalRetrieverChain {
  pub(crate) ollama: LLMOllama,
  pub(crate) retriever: Box<dyn AFRetriever>,
  pub memory: Arc<Mutex<dyn BaseMemory>>,
  pub(crate) combine_documents_chain: Box<dyn Chain>,
  pub(crate) condense_question_chain: Box<dyn Chain>,
  pub(crate) context_question_chain: Option<RelatedQuestionChain>,
  pub(crate) rephrase_question: bool,
  pub(crate) return_source_documents: bool,
  pub(crate) input_key: String,
  pub(crate) output_key: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
enum StreamValue {
  Answer {
    value: String,
  },
  ContextSuggested {
    value: String,
    suggested_questions: Vec<ContextSuggestedQuestion>,
  },
}

impl ConversationalRetrieverChain {
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

  async fn get_documents_or_result(
    &self,
    question: &str,
  ) -> Result<Either<Vec<Document>, StreamValue>, ChainError> {
    let rag_ids = self.retriever.get_rag_ids();
    if rag_ids.is_empty() {
      Ok(Either::Left(vec![]))
    } else {
      let documents = self
        .retriever
        .retrieve_documents(question)
        .await
        .map_err(|e| ChainError::RetrieverError(e.to_string()))?;

      if documents.is_empty() {
        trace!(
          "[Embedding] No relevant documents for given RAG IDs:{:?}. try generating suggested questions",
          rag_ids
        );

        let mut suggested_questions = vec![];
        if let Some(c) = self.context_question_chain.as_ref() {
          let rag_ids = rag_ids.iter().map(|v| v.to_string()).collect::<Vec<_>>();
          match c.generate_questions(&rag_ids).await {
            Ok(questions) => {
              trace!("[embedding]: context related questions: {:?}", questions);
              suggested_questions = questions
                .into_iter()
                .map(|q| ContextSuggestedQuestion {
                  content: q.content,
                  object_id: q.object_id,
                })
                .collect::<Vec<_>>();
            },
            Err(err) => {
              error!(
                "[embedding] Error generating context related questions: {}",
                err
              );
            },
          }
        }

        return if suggested_questions.is_empty() {
          Ok(Either::Right(StreamValue::ContextSuggested {
            value: CAN_NOT_ANSWER_WITH_CONTEXT.to_string(),
            suggested_questions,
          }))
        } else {
          Ok(Either::Right(StreamValue::ContextSuggested {
            value: ANSWER_WITH_SUGGESTED_QUESTION.to_string(),
            suggested_questions,
          }))
        };
      }

      Ok(Either::Left(documents))
    }
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
      memory.messages().await
    };

    let (question, token) = self.get_question(&history, &human_message.content).await?;
    if let Some(token) = token {
      token_usage = Some(token);
    }

    let documents = match self.get_documents_or_result(&question).await? {
      Either::Left(docs) => docs,
      Either::Right(result) => {
        let mut memory = self.memory.lock().await;
        memory.add_message(human_message).await;

        let mut output = HashMap::new();
        match &result {
          StreamValue::Answer { value } => {
            memory.add_message(Message::new_ai_message(value)).await;
            output.insert(self.output_key.clone(), json!(value));
          },
          StreamValue::ContextSuggested { value, .. } => {
            memory.add_message(Message::new_ai_message(value)).await;
            output.insert(self.output_key.clone(), json!(value));
          },
        }

        output.insert(DEFAULT_RESULT_KEY.to_string(), json!(result));
        return Ok(output);
      },
    };

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
      memory.add_message(human_message).await;
      memory
        .add_message(Message::new_ai_message(&output.generation))
        .await;
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
      memory.messages().await
    };
    let (question, _) = self.get_question(&history, &human_message.content).await?;
    let documents = match self.get_documents_or_result(&question).await? {
      Either::Left(docs) => docs,
      Either::Right(result) => {
        let mut memory = self.memory.lock().await;
        memory.add_message(human_message).await;

        return match result {
          StreamValue::Answer { value } => {
            memory.add_message(Message::new_ai_message(&value)).await;
            Ok(Box::pin(stream! {
              yield Ok(StreamData::new(
                json!( QuestionStreamValue::Answer { value: value.clone() }),
                None,
                value.clone()
              ));
            }))
          },
          StreamValue::ContextSuggested {
            value,
            suggested_questions,
          } => {
            // Create final value for memory once
            let final_value = if suggested_questions.is_empty() {
              value.clone()
            } else {
              let formatted_questions = suggested_questions
                .iter()
                .enumerate()
                .map(|(i, q)| format!("{}. {}", i + 1, q.content))
                .collect::<Vec<_>>()
                .join("\n");

              format!("{}\n\n{}", value, formatted_questions)
            };

            memory
              .add_message(Message::new_ai_message(&final_value))
              .await;

            Ok(Box::pin(stream! {
              // Yield the initial message
              yield Ok(StreamData::new(
                json!(QuestionStreamValue::Answer { value: value.clone() }),
                None,
                value
              ));

              // If we have questions, add a newline separator before questions
              if !suggested_questions.is_empty() {
                yield Ok(StreamData::new(
                  json!(QuestionStreamValue::Answer { value: "\n\n".to_string() }),
                  None,
                  "\n\n".to_string()
                ));

                yield Ok(StreamData::new(
                  json!(QuestionStreamValue::SuggestedQuestion { context_suggested_questions: suggested_questions.clone() }),
                  None,
                  String::new(),
                ));

                // Yield each question separately with a newline
                // simulate stream effect
                for (i, question) in suggested_questions.iter().enumerate() {
                  tokio::time::sleep(tokio::time::Duration::from_millis(200)).await;
                  let formatted_question = format!("{}. {}\n", i + 1, question.content);
                  yield Ok(StreamData::new(
                    json!(QuestionStreamValue::Answer { value: formatted_question.clone() }),
                    None,
                    formatted_question
                  ));
                  tokio::time::sleep(tokio::time::Duration::from_millis(100)).await;
                }

                yield Ok(StreamData::new(
                  json!(QuestionStreamValue::FollowUp { should_generate_related_question: false }),
                  None,
                  String::new(),
                ));
              }
            }))
          },
        };
      },
    };

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
        while let Some(result) = stream.next().await {
            match result {
                Ok(data) => {
                    let mut ai_message = complete_ai_message_clone.lock().await;
                    ai_message.push_str(&data.content);
                    yield Ok(StreamData::new(
                        json!(QuestionStreamValue::Answer { value: data.content.clone() }),
                        data.tokens,
                        data.content,
                    ));
                },
                Err(e) => {
                    yield Err(e);
                }
            }
        }

        // Stream source metadata after content
        for source in sources {
            yield Ok(StreamData::new(
                json!(source),
                None,
                String::new(),
            ));
        }

        // Update memory with the conversation
        let mut memory = memory.lock().await;
        memory.add_message(human_message).await;
        let complete_message = complete_ai_message.lock().await;
        memory.add_message(Message::new_ai_message(&complete_message)).await;
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
  workspace_id: Uuid,
  llm: LLMOllama,
  retriever: Box<dyn AFRetriever>,
  memory: Option<Arc<Mutex<dyn BaseMemory>>>,
  prompt: Option<Box<dyn FormatPrompter>>,
  rephrase_question: bool,
  return_source_documents: bool,
  input_key: String,
  output_key: String,
  store: Option<SqliteVectorStore>,
}
impl ConversationalRetrieverChainBuilder {
  pub fn new(
    workspace_id: Uuid,
    llm: LLMOllama,
    retriever: Box<dyn AFRetriever>,
    store: Option<SqliteVectorStore>,
  ) -> Self {
    ConversationalRetrieverChainBuilder {
      workspace_id,
      llm,
      retriever,
      memory: None,
      prompt: None,
      rephrase_question: true,
      return_source_documents: true,
      input_key: CONVERSATIONAL_RETRIEVAL_QA_DEFAULT_INPUT_KEY.to_string(),
      output_key: DEFAULT_OUTPUT_KEY.to_string(),
      store,
    }
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

  pub fn rephrase_question(mut self, rephrase_question: bool) -> Self {
    self.rephrase_question = rephrase_question;
    self
  }

  #[allow(dead_code)]
  pub fn return_source_documents(mut self, return_source_documents: bool) -> Self {
    self.return_source_documents = return_source_documents;
    self
  }

  pub fn build(self) -> FlowyResult<ConversationalRetrieverChain> {
    let combine_documents_chain = {
      let mut builder = StuffDocumentBuilder::new().llm(self.llm.clone());
      if let Some(prompt) = self.prompt {
        builder = builder.prompt(prompt);
      }
      builder
        .build()
        .map_err(|err| FlowyError::local_ai().with_context(err))?
    };

    let condense_question_chain = CondenseQuestionGeneratorChain::new(self.llm.clone());
    let memory = self
      .memory
      .unwrap_or_else(|| Arc::new(Mutex::new(SimpleMemory::new())));

    let context_question_chain = self
      .store
      .map(|store| RelatedQuestionChain::new(self.workspace_id, self.llm.clone(), store));

    Ok(ConversationalRetrieverChain {
      ollama: self.llm,
      retriever: self.retriever,
      memory,
      combine_documents_chain: Box::new(combine_documents_chain),
      condense_question_chain: Box::new(condense_question_chain),
      context_question_chain,
      rephrase_question: self.rephrase_question,
      return_source_documents: self.return_source_documents,
      input_key: self.input_key,
      output_key: self.output_key,
    })
  }
}

/// Deduplicates metadata from a list of documents by merging metadata entries with the same keys
fn deduplicate_metadata(documents: &[Document]) -> Vec<QuestionStreamValue> {
  let mut merged_metadata: HashMap<String, QuestionStreamValue> = HashMap::new();
  for document in documents {
    if let Some(object_id) = document.metadata.get(SOURCE_ID).and_then(|s| s.as_str()) {
      merged_metadata.insert(
        object_id.to_string(),
        QuestionStreamValue::Metadata {
          value: json!(document.metadata.clone()),
        },
      );
    }
  }
  merged_metadata.into_values().collect()
}
