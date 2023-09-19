use crate::text::TextCompletion;
use anyhow::Error;
use async_openai::config::OpenAIConfig;
use async_openai::types::{CreateCompletionRequest, CreateCompletionResponse};
use async_openai::Client;
use lib_infra::async_trait::async_trait;

pub struct OpenAITextCompletion {
  client: Client<OpenAIConfig>,
}

impl OpenAITextCompletion {
  pub fn new(api_key: &str) -> Self {
    // https://docs.rs/async-openai/latest/async_openai/struct.Completions.html
    let config = OpenAIConfig::new().with_api_key(api_key);
    let client = Client::with_config(config);
    Self { client }
  }
}

#[async_trait]
impl TextCompletion for OpenAITextCompletion {
  type Input = CreateCompletionRequest;
  type Output = CreateCompletionResponse;

  async fn text_completion(&self, params: Self::Input) -> Result<Self::Output, Error> {
    let response = self.client.completions().create(params).await?;
    Ok(response)
  }
}
