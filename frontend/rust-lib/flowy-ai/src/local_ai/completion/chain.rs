use crate::local_ai::chat::llm::LLMOllama;
use crate::local_ai::completion::stream_interpreter::stream_interpreter_for_completion;
use crate::local_ai::completion::writer::{
  AskAiWriter, CompletionWriterContext, ContinueWriteWriter, CustomWriter, ExplainWriter,
  ImproveWritingWriter, MakeLongerWriter, SpellingGrammarWriter, SummaryWriter,
};
use crate::local_ai::prompt::{format_prompt, history_prompt};
use flowy_ai_pub::cloud::{
  CompletionMetadata, CompletionStreamValue, CompletionType, CustomPrompt, ResponseFormat,
};
use flowy_error::FlowyError;
use futures_util::StreamExt;
use langchain_rust::language_models::llm::LLM;
use langchain_rust::schemas::Message;
use std::collections::HashMap;
use tokio::sync::mpsc;
use tokio_stream::wrappers::ReceiverStream;
use tracing::error;

pub trait CompletionWriter: Send + Sync {
  fn system_message(&self) -> String;
  fn reformat_human_input(&self, content: &str) -> String {
    content.to_string()
  }
  fn reasoning_system_message(&self) -> String {
    self.system_message()
  }
  fn support_format(&self) -> bool;
  fn support_reasoning(&self) -> bool {
    false
  }
}

#[derive(Default)]
pub struct WriterConfig {
  pub custom_reasoning_system_prompt: HashMap<CompletionType, String>,
}

pub struct CompletionChain {
  ollama: LLMOllama,
}

impl CompletionChain {
  pub fn new(ollama: LLMOllama) -> Self {
    Self { ollama }
  }

  pub async fn complete(
    &self,
    text: &str,
    ty: CompletionType,
    format: ResponseFormat,
    mut metadata: Option<CompletionMetadata>,
  ) -> Result<ReceiverStream<anyhow::Result<CompletionStreamValue, FlowyError>>, FlowyError> {
    let custom_prompt = metadata.as_ref().and_then(|m| m.custom_prompt.clone());
    let writer = writer_from_type(&ty, &WriterConfig::default(), custom_prompt);

    // Build messages
    let mut messages = vec![];
    let system_msg = if writer.support_reasoning() {
      writer.reasoning_system_message()
    } else {
      writer.system_message()
    };
    messages.push(Message::new_system_message(system_msg));

    messages.push(
      if writer.support_format() {
        format_prompt(&format)
      } else {
        Message::new_system_message(
          "Respond naturally without formal phrases like 'Certainly', 'Absolutely', or 'Sure'. Keep the tone conversational, clear, and professional"
        )
      }
    );

    if let Some(history) = metadata.as_mut().and_then(|m| m.completion_history.take()) {
      messages.extend(history_prompt(Some(history)));
    }
    messages.push(Message::new_human_message(text));
    let raw_stream = self
      .ollama
      .stream(&messages)
      .await
      .map_err(|e| FlowyError::local_ai().with_context(e))?;

    let stream = stream_interpreter_for_completion(raw_stream, ty)
      .map(|res| res.map_err(|e| FlowyError::local_ai().with_context(e)))
      .boxed();

    // Spawn the forwarding task
    let (tx, rx) = mpsc::channel(32);
    spawn_stream(stream, tx);
    Ok(ReceiverStream::new(rx))
  }
}

fn spawn_stream<S>(
  mut stream: S,
  tx: mpsc::Sender<anyhow::Result<CompletionStreamValue, FlowyError>>,
) where
  S: tokio_stream::Stream<Item = anyhow::Result<CompletionStreamValue, FlowyError>>
    + Unpin
    + Send
    + 'static,
{
  tokio::spawn(async move {
    while let Some(item) = stream.next().await {
      if tx.send(item).await.is_err() {
        error!("[AICompletion] channel closed");
        break;
      }
    }
  });
}

/// Construct the appropriate writer based on type
pub fn writer_from_type(
  complete_type: &CompletionType,
  writer_config: &WriterConfig,
  custom_prompt: Option<CustomPrompt>,
) -> Box<dyn CompletionWriter> {
  let context = CompletionWriterContext::new(
    writer_config
      .custom_reasoning_system_prompt
      .get(complete_type)
      .cloned(),
  );

  match complete_type {
    CompletionType::CustomPrompt => match custom_prompt {
      Some(p) => Box::new(CustomWriter::new(p, context)),
      None => Box::new(AskAiWriter::new(context)),
    },
    CompletionType::ImproveWriting => Box::new(ImproveWritingWriter::new(context)),
    CompletionType::SpellingAndGrammar => Box::new(SpellingGrammarWriter::new(context)),
    CompletionType::MakeShorter => Box::new(SummaryWriter::new(context)),
    CompletionType::MakeLonger => Box::new(MakeLongerWriter::new(context)),
    CompletionType::ContinueWriting => Box::new(ContinueWriteWriter::new(context)),
    CompletionType::Explain => Box::new(ExplainWriter::new(context)),
    CompletionType::AskAI => Box::new(AskAiWriter::new(context)),
  }
}
