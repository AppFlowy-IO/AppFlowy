use flowy_error::FlowyError;
use lib_dispatch::prelude::{data_result_ok, AFPluginData, DataResult};

use crate::entities::{TextCompletionDataPB, TextCompletionParams, TextCompletionPayloadPB};

pub(crate) async fn request_text_completion(
  data: AFPluginData<TextCompletionPayloadPB>,
) -> DataResult<TextCompletionDataPB, FlowyError> {
  // TODO: implement
  let params: TextCompletionParams = data.into_inner().try_into()?;
  return data_result_ok(TextCompletionDataPB {
    request_id: params.request_id,
    model: params.model,
  });
}
