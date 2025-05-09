use crate::local_ai::prompt::format_prompt;
use flowy_ai_pub::cloud::ResponseFormat;
use flowy_error::{FlowyError, FlowyResult};
use langchain_rust::prompt::{
  FormatPrompter, HumanMessagePromptTemplate, MessageFormatter, PromptArgs, PromptError,
};
use langchain_rust::schemas::{Message, PromptValue};
use langchain_rust::template_jinja2;
use std::sync::{Arc, RwLock};

const QA_CONTEXT_TEMPLATE: &str = r#"
Only Use the context provided below to formulate your answer. Do not use any other information. If the context doesn't contain sufficient information to answer the question, respond with "I don't know".
Do not reference external knowledge or information outside the context.

##Context##
{{context}}

Question:{{question}}
Answer:
"#;

const QA_TEMPLATE: &str = r#"
Use the context provided below to formulate your response
##Context##
{{context}}

Question:{{question}}
Answer:
"#;

fn template_from_rag_ids(rag_ids: &[String]) -> HumanMessagePromptTemplate {
  if rag_ids.is_empty() {
    HumanMessagePromptTemplate::new(template_jinja2!(QA_TEMPLATE, "question"))
  } else {
    HumanMessagePromptTemplate::new(template_jinja2!(QA_CONTEXT_TEMPLATE, "context", "question"))
  }
}

struct FormatState {
  format_msg: Arc<Message>,
  format: ResponseFormat,
}

pub struct AFContextPrompt {
  rag_ids: Vec<String>,
  system_msg: Arc<Message>,
  state: Arc<RwLock<FormatState>>,
  user_tmpl: Arc<RwLock<HumanMessagePromptTemplate>>,
}

impl AFContextPrompt {
  pub fn new(system_msg: Message, fmt: &ResponseFormat, rag_ids: &[String]) -> Self {
    let user_tmpl = template_from_rag_ids(rag_ids);
    let state = FormatState {
      format_msg: Arc::new(format_prompt(fmt)),
      format: fmt.clone(),
    };

    Self {
      rag_ids: rag_ids.to_vec(),
      system_msg: Arc::new(system_msg),
      state: Arc::new(RwLock::new(state)),
      user_tmpl: Arc::new(RwLock::new(user_tmpl)),
    }
  }

  pub fn set_rag_ids(&mut self, rag_ids: &[String]) {
    if self.rag_ids == rag_ids {
      return;
    }
    self.rag_ids = rag_ids.to_vec();
    let template = template_from_rag_ids(rag_ids);
    if let Ok(mut w) = self.user_tmpl.try_write() {
      *w = template;
    }
  }

  /// Returns true if we actually swapped in a new instruction
  pub fn update_format(&self, new_fmt: &ResponseFormat) -> FlowyResult<()> {
    let mut st = self
      .state
      .write()
      .map_err(|err| FlowyError::internal().with_context(err))?;

    if st.format.output_layout != new_fmt.output_layout {
      st.format = new_fmt.clone();
      st.format_msg = Arc::new(format_prompt(new_fmt));
    }

    Ok(())
  }
}

impl Clone for AFContextPrompt {
  fn clone(&self) -> Self {
    Self {
      rag_ids: self.rag_ids.clone(),
      system_msg: Arc::clone(&self.system_msg),
      state: Arc::clone(&self.state),
      user_tmpl: Arc::clone(&self.user_tmpl),
    }
  }
}

impl MessageFormatter for AFContextPrompt {
  fn format_messages(&self, args: PromptArgs) -> Result<Vec<Message>, PromptError> {
    let mut out = Vec::with_capacity(3);
    out.push((*self.system_msg).clone());

    if let Ok(st) = self.state.try_read() {
      out.push((*st.format_msg).clone());
    }

    if let Ok(user_tmpl) = self.user_tmpl.try_read() {
      out.extend(user_tmpl.format_messages(args)?);
    }

    Ok(out)
  }

  fn input_variables(&self) -> Vec<String> {
    vec!["context".into(), "question".into()]
  }
}

impl FormatPrompter for AFContextPrompt {
  fn format_prompt(&self, input_variables: PromptArgs) -> Result<PromptValue, PromptError> {
    let messages = self.format_messages(input_variables)?;
    Ok(PromptValue::from_messages(messages))
  }

  fn get_input_variables(&self) -> Vec<String> {
    self.input_variables()
  }
}
