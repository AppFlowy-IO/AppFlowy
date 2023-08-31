use flowy_derive::ProtoBuf;
use flowy_error::ErrorCode;

/*
 model="text-davinci-003",
 prompt="Write a tagline for an ice cream shop."
*/
#[derive(Default, ProtoBuf)]
pub struct TextCompletionPayloadPB {
  #[pb(index = 1)]
  pub request_id: String,

  // Model: Either text-davinci-003 or gpt-3.5-turbo
  #[pb(index = 2)]
  pub model: String,

  // Prompt to query gpt
  #[pb(index = 3)]
  pub prompt: String,

  // User open_ai_key for authentication
  #[pb(index = 4)]
  pub open_ai_key: String,
}

pub struct TextCompletionParams {
  pub request_id: String,
  pub model: String,
  pub prompt: String,
  pub open_ai_key: String,
}

impl TryInto<TextCompletionParams> for TextCompletionPayloadPB {
  type Error = ErrorCode;
  fn try_into(self) -> Result<TextCompletionParams, Self::Error> {
    // TODO: validate
    return Ok(TextCompletionParams {
      request_id: self.request_id,
      model: self.model,
      prompt: self.prompt,
      open_ai_key: self.open_ai_key,
    });
  }
}

/*
{
  "id": "chatcmpl-123",
  "object": "chat.completion",
  "created": 1677652288,
  "model": "gpt-3.5-turbo-0613",
  "choices": [{
    "index": 0,
    "message": {
      "role": "assistant",
      "content": "\n\nHello there, how may I assist you today?",
    },
    "finish_reason": "stop"
  }],
  "usage": {
    "prompt_tokens": 9,
    "completion_tokens": 12,
    "total_tokens": 21
  }
}

*/
#[derive(Default, ProtoBuf)]
pub struct TextCompletionDataPB {
  #[pb(index = 1)]
  pub request_id: String,

  #[pb(index = 2)]
  pub model: String,

  #[pb(index = 3)]
  pub index: i32,

  #[pb(index = 4)]
  pub content: String,
}
