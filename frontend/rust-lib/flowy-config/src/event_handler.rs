use flowy_error::{FlowyError, FlowyResult};
use flowy_sqlite::kv::KV;
use lib_dispatch::prelude::{data_result_ok, AFPluginData, DataResult};

use crate::entities::{KeyPB, KeyValuePB};

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
