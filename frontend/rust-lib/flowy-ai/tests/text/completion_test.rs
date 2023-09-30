use crate::util::get_openai_config;
use async_openai::types::CreateCompletionRequestArgs;
use flowy_ai::text::open_ai::OpenAITextCompletion;
use flowy_ai::text::TextCompletion;

#[tokio::test]
async fn text_completion_test() {
  if let Some(config) = get_openai_config() {
    let client = OpenAITextCompletion::new(&config.openai_api_key);
    let params = CreateCompletionRequestArgs::default()
      .model("text-davinci-003")
      .prompt("Write a rust function to calculate the sum of two numbers")
      .build()
      .unwrap();
    let resp = client.text_completion(params).await.unwrap();
    dbg!("{:?}", resp);
  }
}
