use crate::entities::{TextCompletionDataPB, TextCompletionParams, TextCompletionPayloadPB};
use flowy_error::FlowyError;
use lib_dispatch::prelude::{data_result_ok, AFPluginData, DataResult};
use reqwest;
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize)]
struct Message {
  role: String,
  content: String,
}

#[derive(Serialize)]
struct RequestBody {
  model: String,
  messages: Vec<Message>,
}

#[derive(Deserialize)]
struct ResponseChoice {
  index: i32,
  message: Message,
}

#[derive(Deserialize)]
struct ApiResponse {
  choices: Vec<ResponseChoice>,
}

pub(crate) async fn request_text_completion(
  data: AFPluginData<TextCompletionPayloadPB>,
) -> DataResult<TextCompletionDataPB, FlowyError> {
  // Set up the request body
  let body = RequestBody {
    model: "gpt-3.5-turbo".to_string(),
    messages: vec![
      Message {
        role: "system".to_string(),
        content: "You are a helpful assistant.".to_string(),
      },
      Message {
        role: "user".to_string(),
        content: data.prompt.to_string(),
      },
    ],
  };

  // Make the API call
  let client = reqwest::Client::new();
  let response: ApiResponse = client
    .post("https://api.openai.com/v1/chat/completions")
    .header("Content-Type", "application/json")
    .header("Authorization", format!("Bearer {}", data.open_ai_key))
    .json(&body)
    .send()
    .await?
    .json()
    .await?;

  // Extract index and content
  let choice = &response.choices[0];

  let params: TextCompletionParams = data.into_inner().try_into()?;

  return data_result_ok(TextCompletionDataPB {
    request_id: params.request_id,
    model: params.model,
    index: response.choices[0].index,
    content: response.choices[0].message.content.to_string(),
  });
}
