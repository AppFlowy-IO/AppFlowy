use crate::TextCompletion;
use anyhow::Error;
use lib_infra::async_trait::async_trait;

pub struct StabilityAITextCompletion {}

#[async_trait]
impl TextCompletion for StabilityAITextCompletion {
  type Input = StabilityTextCompletionParams;
  type Output = ();

  async fn text_completion(&self, params: Self::Input) -> Result<Self::Output, Error> {
    todo!()
  }
}

pub struct StabilityTextCompletionParams {}
