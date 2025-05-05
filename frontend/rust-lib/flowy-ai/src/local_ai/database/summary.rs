use crate::local_ai::chat::llm::LLMOllama;
use flowy_database_pub::cloud::SummaryRowContent;
use flowy_error::{FlowyError, FlowyResult};
use langchain_rust::language_models::llm::LLM;
use langchain_rust::schemas::Message;

const SUMMARIZE_SYSTEM_PROMPT: &str = r#"
You are AppFlowy AI who are good at distilling complex information into clear and concise summaries. When summarizing, please ensure that the main ideas are communicated effectively and efficiently.
The input text consists of two parts: a category and its corresponding content. Summarize the content based on its category, but do not include the category in the output. Additionally, consider the relationships between categories and summarize the content based on these relationships
{good_format_example}

When summarizing, please follow these constraint
1. If a category's content exceeds 500 characters, shorten it
2. If you can't recognize a category's content, ignore it
3. Do not add any content that is not included in the original sentence 
"#;

const SUMMARIZE_USER_PROMPT: &str = r#"
Summarize following sentence: {input}
Output:
"#;

const SUMMARY_GOOD_FORMAT_EXAMPLE: &str = r#"
Here are examples of correctly formatted outputs

Example
Input: description: Card 1\n content: To do
Output: Card 1 is currently in the "To do" status
"#;

pub struct DatabaseSummaryChain {
  llm: LLMOllama,
}

impl DatabaseSummaryChain {
  pub fn new(llm: LLMOllama) -> Self {
    Self { llm }
  }

  pub async fn summarize(&self, data: SummaryRowContent) -> FlowyResult<String> {
    let input_text = self.format_summary_data(&data);
    self.summarize_text(input_text).await
  }

  fn format_summary_data(&self, data: &SummaryRowContent) -> String {
    let mut formatted_items = Vec::new();
    for (key, value) in data.iter() {
      let value_str = value.to_string().trim().to_string();
      if !value_str.is_empty() {
        formatted_items.push(format!("{}:{}", key, value_str));
      }
    }

    formatted_items.join("\n")
  }

  async fn summarize_text(&self, text: String) -> FlowyResult<String> {
    let system_prompt =
      SUMMARIZE_SYSTEM_PROMPT.replace("{good_format_example}", SUMMARY_GOOD_FORMAT_EXAMPLE);
    let user_prompt = SUMMARIZE_USER_PROMPT.replace("{input}", &text);

    let system_prompt = Message::new_system_message(system_prompt);
    let user_prompt = Message::new_human_message(user_prompt);
    let messages = vec![system_prompt, user_prompt];

    match self.llm.generate(&messages).await {
      Ok(response) => Ok(response.generation),
      Err(err) => {
        Err(FlowyError::internal().with_context(format!("Error generating summary: {}", err)))
      },
    }
  }
}
