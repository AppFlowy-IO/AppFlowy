use date_time_parser::DateParser;
use flowy_error::FlowyError;
use lib_dispatch::prelude::{data_result_ok, AFPluginData, DataResult};

use crate::entities::*;

#[tracing::instrument(level = "debug", skip_all, err)]
pub(crate) async fn query_date_handler(
  data: AFPluginData<DateQueryPB>,
) -> DataResult<DateResultPB, FlowyError> {
  let query: String = data.into_inner().query;
  let date = DateParser::parse(&query).unwrap();

  data_result_ok(DateResultPB {
    seconds_since_epoch: date.format("%s").to_string(),
  })
}
