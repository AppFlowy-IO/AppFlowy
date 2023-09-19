use crate::TextCompletion;
use anyhow::Error;
use lib_infra::async_trait::async_trait;

pub struct OpenAITextCompletion {}

#[async_trait]
impl TextCompletion for OpenAITextCompletion {
  type Input = OpenAITextCompletionParams;
  type Output = ();

  async fn text_completion(&self, params: Self::Input) -> Result<Self::Output, Error> {
    todo!()
  }
}

pub struct OpenAITextCompletionParams {
  pub text: String,
}
