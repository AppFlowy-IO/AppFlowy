mod text;

use crate::text::TextCompletion;
use anyhow::Error;
use lib_infra::async_trait::async_trait;
use lib_infra::box_any::BoxAny;

pub struct TextCompletionImpl<T>(T);
#[async_trait]
impl<T> TextCompletion for TextCompletionImpl<T>
where
  T: TextCompletion,
{
  type Input = BoxAny;
  type Output = T::Output;

  async fn text_completion(&self, params: Self::Input) -> Result<Self::Output, Error> {
    let params = params.unbox_or_error::<T::Input>().unwrap();
    self.0.text_completion(params).await
  }
}
