use appflowy_integrate::config::AWSDynamoDBConfig;

use flowy_error::{FlowyError, FlowyResult};
use flowy_sqlite::kv::KV;
use lib_dispatch::prelude::{data_result_ok, AFPluginData, DataResult};

use crate::entities::{CollabPluginConfigPB, KeyPB, KeyValuePB};

pub(crate) async fn set_key_value_handler(data: AFPluginData<KeyValuePB>) -> FlowyResult<()> {
  let data = data.into_inner();
  match data.value {
    None => KV::remove(&data.key),
    Some(value) => {
      KV::set_str(&data.key, value);
    },
  }
  Ok(())
}

pub(crate) async fn get_key_value_handler(
  data: AFPluginData<KeyPB>,
) -> DataResult<KeyValuePB, FlowyError> {
  let data = data.into_inner();
  let value = KV::get_str(&data.key);
  data_result_ok(KeyValuePB {
    key: data.key,
    value,
  })
}

pub(crate) async fn remove_key_value_handler(data: AFPluginData<KeyPB>) -> FlowyResult<()> {
  let data = data.into_inner();
  KV::remove(&data.key);
  Ok(())
}

pub(crate) async fn set_collab_plugin_config_handler(
  data: AFPluginData<CollabPluginConfigPB>,
) -> FlowyResult<()> {
  let config = data.into_inner();
  if let Some(aws_config_pb) = config.aws_config {
    if let Ok(aws_config) = AWSDynamoDBConfig::try_from(aws_config_pb) {
      aws_config.write_env();
    }
  }
  Ok(())
}
