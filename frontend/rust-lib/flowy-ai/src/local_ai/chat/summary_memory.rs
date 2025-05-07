use crate::local_ai::chat::llm::LLMOllama;
use async_trait::async_trait;
use flowy_ai_pub::user_service::AIUserService;
use flowy_error::{FlowyError, FlowyResult};
use langchain_rust::chain::{Chain, LLMChain, LLMChainBuilder};
use langchain_rust::schemas::{BaseMemory, Message};
use langchain_rust::{fmt_message, fmt_placeholder, message_formatter, prompt_args};
use std::sync::{Arc, Weak};
use tokio::sync::{Mutex, RwLock};

pub struct SummaryMemory {
  messages: RwLock<Vec<Message>>,
  chain: SummaryMessageChain,
  current_summary: String,
  #[allow(dead_code)]
  user_service: Option<Weak<dyn AIUserService>>,
}

impl SummaryMemory {
  pub async fn new(
    llm: LLMOllama,
    summary: String,
    user_service: Option<Weak<dyn AIUserService>>,
  ) -> FlowyResult<Self> {
    let chain = SummaryMessageChain::new(llm)?;
    Ok(Self {
      chain,
      messages: RwLock::new(Vec::new()),
      current_summary: summary,
      user_service,
    })
  }

  #[allow(dead_code)]
  pub async fn generate_summary(&mut self) -> FlowyResult<String> {
    let summary = self
      .chain
      .generate_summary(self.messages.read().await.as_ref(), &self.current_summary)
      .await?;

    self.current_summary = summary.clone();
    Ok(summary)
  }
}

impl From<SummaryMemory> for Arc<dyn BaseMemory> {
  fn from(memory: SummaryMemory) -> Self {
    Arc::new(memory)
  }
}

impl From<SummaryMemory> for Arc<Mutex<dyn BaseMemory>> {
  fn from(memory: SummaryMemory) -> Self {
    Arc::new(Mutex::new(memory))
  }
}

#[async_trait]
impl BaseMemory for SummaryMemory {
  async fn messages(&self) -> Vec<Message> {
    self.messages.read().await.clone()
  }
  async fn add_message(&mut self, message: Message) {
    self.messages.write().await.push(message);
  }
  async fn clear(&mut self) {
    self.messages.write().await.clear();
  }
}

fn message_to_string_with_role(messages: &[Message]) -> Vec<String> {
  messages
    .iter()
    .map(|msg| format!("{}: {}", msg.message_type.to_string(), msg.content))
    .collect()
}

const SUMMARY_SYSTEM_PROMPT: &str = r#"
You are AppFlowy AI, tasked with progressively summarizing the lines of conversation provided. With each new line, you add to the previous summary and return an updated summary.
Current summary:
{current_summary}

New lines of conversation:
{new_lines}

New summary:
"#;
struct SummaryMessageChain {
  chain: LLMChain,
}

impl SummaryMessageChain {
  pub fn new(llm: LLMOllama) -> FlowyResult<Self> {
    let prompt = message_formatter![
      fmt_message!(Message::new_system_message(SUMMARY_SYSTEM_PROMPT)),
      fmt_placeholder!("current_summary"),
      fmt_placeholder!("new_lines"),
    ];
    let chain = LLMChainBuilder::new()
      .prompt(prompt)
      .llm(llm)
      .build()
      .map_err(|err| FlowyError::internal().with_context(err))?;

    Ok(Self { chain })
  }

  pub async fn generate_summary(
    &self,
    messages: &[Message],
    current_summary: &str,
  ) -> FlowyResult<String> {
    let new_lines = message_to_string_with_role(messages);
    let resp = self
      .chain
      .invoke(prompt_args! {
      "current_summary" => current_summary,
      "new_lines" => new_lines,
      })
      .await
      .map_err(|err| FlowyError::internal().with_context(err))?;
    Ok(resp)
  }
}
