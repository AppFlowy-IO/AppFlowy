use crate::local_ai::prompt::format_prompt;
use flowy_ai_pub::cloud::ResponseFormat;
use langchain_rust::prompt::{
  FormatPrompter, HumanMessagePromptTemplate, MessageFormatter, PromptArgs, PromptError,
};
use langchain_rust::schemas::{Message, PromptValue};
use langchain_rust::template_jinja2;
use std::sync::{Arc, Mutex};

const DEFAULT_QA_TEMPLATE: &str = r#"
Only Use the context provided below to formulate your answer. Do not use any other information. If the context doesn't contain sufficient information to answer the question, respond with "I don't know".
Do not reference external knowledge or information outside the context.

##Context##
{{context}}

Question:{{question}}
Answer:
"#;

/// A custom message formatter that allows dynamically updating the format instruction.
pub struct DynamicMessageFormatter {
  // First message is always the system message
  system_message: Message,
  // Second message is the format instruction that we want to update dynamically
  format_instruction: Arc<Mutex<Message>>,
  // The template string for the user question
  template_string: String,
  // Current format for easy access
  current_format: Arc<Mutex<ResponseFormat>>,
}

impl DynamicMessageFormatter {
  pub fn new(system_message: Message, format: &ResponseFormat) -> Self {
    let format_instruction = format_prompt(format);

    Self {
      system_message,
      format_instruction: Arc::new(Mutex::new(format_instruction)),
      template_string: DEFAULT_QA_TEMPLATE.to_string(),
      current_format: Arc::new(Mutex::new(format.clone())),
    }
  }

  /// Get a handle to the shared format instruction and response format
  pub fn get_shared_handles(&self) -> (Arc<Mutex<Message>>, Arc<Mutex<ResponseFormat>>) {
    (self.format_instruction.clone(), self.current_format.clone())
  }

  /// Creates a template for the user question
  fn create_template(&self) -> Box<dyn MessageFormatter> {
    Box::new(HumanMessagePromptTemplate::new(template_jinja2!(
      &self.template_string,
      "context",
      "question"
    )))
  }
}

impl Clone for DynamicMessageFormatter {
  fn clone(&self) -> Self {
    Self {
      system_message: self.system_message.clone(),
      format_instruction: self.format_instruction.clone(),
      template_string: self.template_string.clone(),
      current_format: self.current_format.clone(),
    }
  }
}

impl MessageFormatter for DynamicMessageFormatter {
  fn format_messages(&self, input_variables: PromptArgs) -> Result<Vec<Message>, PromptError> {
    let mut result: Vec<Message> = Vec::new();

    // Add system message
    result.push(self.system_message.clone());

    // Add format instruction - access through the lock
    let format_instruction = self
      .format_instruction
      .lock()
      .map_err(|_| PromptError::OtherError("Failed to lock format_instruction".to_string()))?
      .clone();
    result.push(format_instruction);

    // Create template and add its messages
    let template = self.create_template();
    result.extend(template.format_messages(input_variables)?);

    Ok(result)
  }

  fn input_variables(&self) -> Vec<String> {
    // We need context and question variables from the template
    vec!["context".to_string(), "question".to_string()]
  }
}

impl FormatPrompter for DynamicMessageFormatter {
  fn format_prompt(&self, input_variables: PromptArgs) -> Result<PromptValue, PromptError> {
    let messages = self.format_messages(input_variables)?;
    Ok(PromptValue::from_messages(messages))
  }

  fn get_input_variables(&self) -> Vec<String> {
    self.input_variables()
  }
}
