use crate::error::PersistenceError;
use anyhow::anyhow;
use indexed_db_futures::idb_object_store::IdbObjectStore;
use indexed_db_futures::idb_transaction::{IdbTransaction, IdbTransactionResult};
use indexed_db_futures::prelude::IdbOpenDbRequestLike;
use indexed_db_futures::{IdbDatabase, IdbQuerySource, IdbVersionChangeEvent};
use js_sys::Uint8Array;
use std::rc::Rc;
use tokio::sync::RwLock;
use wasm_bindgen::JsValue;
use web_sys::IdbTransactionMode;

const APPFLOWY_STORE: &str = "appflowy_store";
pub struct AppFlowyWASMStore {
  db: Rc<RwLock<IdbDatabase>>,
}

impl AppFlowyWASMStore {
  pub async fn new() -> Result<Self, PersistenceError> {
    let mut db_req = IdbDatabase::open_u32("appflowy", 1)?;
    db_req.set_on_upgrade_needed(Some(|evt: &IdbVersionChangeEvent| -> Result<(), JsValue> {
      if evt
        .db()
        .object_store_names()
        .find(|n| n == APPFLOWY_STORE)
        .is_none()
      {
        evt.db().create_object_store(APPFLOWY_STORE)?;
      }
      Ok(())
    }));
    let db = Rc::new(RwLock::new(db_req.await?));
    Ok(Self { db })
  }

  pub async fn get<T: serde::de::DeserializeOwned>(
    &self,
    key: &str,
  ) -> Result<Option<T>, PersistenceError> {
    let db = self.db.read().await;
    let txn = db.transaction_on_one_with_mode(APPFLOWY_STORE, IdbTransactionMode::Readonly)?;
    let store = store_from_transaction(&txn)?;
    let js_key = to_js_value(key);
    match store.get(&js_key)?.await? {
      None => Err(PersistenceError::RecordNotFound(format!(
        "Can't find the value for given key: {} ",
        key
      ))),
      Some(value) => {
        let bytes = Uint8Array::new(&value).to_vec();
        let object = serde_json::from_slice::<T>(&bytes)?;
        Ok(Some(object))
      },
    }
  }

  pub async fn set<T: serde::Serialize>(
    &self,
    key: &str,
    value: &T,
  ) -> Result<(), PersistenceError> {
    let db = self.db.read().await;
    let txn = db.transaction_on_one_with_mode(APPFLOWY_STORE, IdbTransactionMode::Readwrite)?;
    let store = store_from_transaction(&txn)?;
    let js_key = to_js_value(key);
    let js_value = to_js_value(serde_json::to_vec(value)?);
    store.put_key_val(&js_key, &js_value)?.await?;
    transaction_result_to_result(txn.await)?;
    Ok(())
  }

  pub async fn remove(&self, key: &str) -> Result<(), PersistenceError> {
    let db = self.db.read().await;
    let txn = db.transaction_on_one_with_mode(APPFLOWY_STORE, IdbTransactionMode::Readwrite)?;
    let store = store_from_transaction(&txn)?;
    let js_key = to_js_value(key);
    store.delete(&js_key)?.await?;
    transaction_result_to_result(txn.await)?;
    Ok(())
  }
}

fn to_js_value<K: AsRef<[u8]>>(key: K) -> JsValue {
  JsValue::from(Uint8Array::from(key.as_ref()))
}

fn store_from_transaction<'a>(
  txn: &'a IdbTransaction<'a>,
) -> Result<IdbObjectStore<'a>, PersistenceError> {
  txn
    .object_store(APPFLOWY_STORE)
    .map_err(PersistenceError::from)
}

fn transaction_result_to_result(result: IdbTransactionResult) -> Result<(), PersistenceError> {
  match result {
    IdbTransactionResult::Success => Ok(()),
    IdbTransactionResult::Error(err) => Err(PersistenceError::from(err)),
    IdbTransactionResult::Abort => Err(PersistenceError::Internal(anyhow!("Transaction aborted"))),
  }
}
