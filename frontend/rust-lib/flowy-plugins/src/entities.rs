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

  // TODO: add comment
  #[pb(index = 2)]
  pub model: String,

  // TODO: add comment
  #[pb(index = 3)]
  pub prompt: String,
}

pub struct TextCompletionParams {
  pub request_id: String,
  pub model: String,
  pub prompt: String,
}

impl TryInto<TextCompletionParams> for TextCompletionPayloadPB {
  type Error = ErrorCode;
  fn try_into(self) -> Result<TextCompletionParams, Self::Error> {
    // TODO: validate
    return Ok(TextCompletionParams {
      request_id: self.request_id,
      model: self.model,
      prompt: self.prompt,
    });
  }
}

/*
{
  "choices": [
    {
      "finish_reason": "length",
      "index": 0,
      "logprobs": null,
      "text": "\n\n\"Let Your Sweet Tooth Run Wild at Our Creamy Ice Cream Shack"
    }
  ],
  "created": 1683130927,
  "id": "cmpl-7C9Wxi9Du4j1lQjdjhxBlO22M61LD",
  "model": "text-davinci-003",
  "object": "text_completion",
  "usage": {
    "completion_tokens": 16,
    "prompt_tokens": 10,
    "total_tokens": 26
  }
}
*/
#[derive(Default, ProtoBuf)]
pub struct TextCompletionDataPB {
  #[pb(index = 1)]
  pub request_id: String,

  #[pb(index = 2)]
  pub model: String,
  // TODO: implement
  // choices
  // ...
}
