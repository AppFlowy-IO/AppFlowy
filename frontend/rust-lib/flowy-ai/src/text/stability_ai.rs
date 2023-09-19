use crate::text::TextCompletion;
use anyhow::Error;
use lib_infra::async_trait::async_trait;

pub struct StabilityAITextCompletion {}

#[async_trait]
impl TextCompletion for StabilityAITextCompletion {
  type Input = ();
  type Output = ();

  async fn text_completion(&self, _params: Self::Input) -> Result<Self::Output, Error> {
    todo!()
  }
}
