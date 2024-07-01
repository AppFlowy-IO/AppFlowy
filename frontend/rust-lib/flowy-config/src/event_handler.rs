use std::sync::Weak;

use flowy_error::{FlowyError, FlowyResult};
use flowy_sqlite::kv::KVStorePreferences;
use lib_dispatch::prelude::{data_result_ok, AFPluginData, AFPluginState, DataResult};

use crate::entities::{KeyPB, KeyValuePB};

pub(crate) async fn set_key_value_handler(
  store_preferences: AFPluginState<Weak<KVStorePreferences>>,
  data: AFPluginData<KeyValuePB>,
) -> FlowyResult<()> {
  let data = data.into_inner();

  if let Some(store_preferences) = store_preferences.upgrade() {
    match data.value {
      None => store_preferences.remove(&data.key),
      Some(value) => {
        store_preferences.set_str(&data.key, value);
      },
    }
  }

  Ok(())
}

pub(crate) async fn get_key_value_handler(
  store_preferences: AFPluginState<Weak<KVStorePreferences>>,
  data: AFPluginData<KeyPB>,
) -> DataResult<KeyValuePB, FlowyError> {
  match store_preferences.upgrade() {
    None => Err(FlowyError::internal().with_context("The store preferences is already drop"))?,
    Some(store_preferences) => {
      let data = data.into_inner();
      let value = store_preferences.get_str(&data.key);
      data_result_ok(KeyValuePB {
        key: data.key,
        value,
      })
    },
  }
}

pub(crate) async fn remove_key_value_handler(
  store_preferences: AFPluginState<Weak<KVStorePreferences>>,
  data: AFPluginData<KeyPB>,
) -> FlowyResult<()> {
  match store_preferences.upgrade() {
    None => Err(FlowyError::internal().with_context("The store preferences is already drop"))?,
    Some(store_preferences) => {
      let data = data.into_inner();
      store_preferences.remove(&data.key);
      Ok(())
    },
  }
}
