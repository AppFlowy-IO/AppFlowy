use reqwest::header::{HeaderMap, AUTHORIZATION, CONTENT_TYPE};
use serde_json::json;
use std::env;

pub async fn send_request(prompt: String) -> Result<String, reqwest::Error> {
  let api_key = env::var("OPENAI_API_KEY").expect("OPENAI_API_KEY not found");

  let mut headers = HeaderMap::new();
  headers.insert(CONTENT_TYPE, "application/json".parse().unwrap());
  headers.insert(
    AUTHORIZATION,
    format!("Bearer {}", api_key).parse().unwrap(),
  );

  let client = reqwest::Client::new();

  let body = json!({
      "model": "gpt-3.5-turbo",
      "messages": [
          {"role": "system", "content": "You are a helpful assistant."},
          {"role": "user", "content": prompt}
      ]
  });

  let res = client
    .post("https://api.openai.com/v1/chat/completions")
    .headers(headers)
    .json(&body)
    .send()
    .await?;

  Ok(res.text().await?)
}
