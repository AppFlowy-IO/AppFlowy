use crate::error::PersistenceError;
use anyhow::anyhow;
use futures_util::future::LocalBoxFuture;
use indexed_db_futures::idb_object_store::IdbObjectStore;
use indexed_db_futures::idb_transaction::{IdbTransaction, IdbTransactionResult};
use indexed_db_futures::prelude::IdbOpenDbRequestLike;
use indexed_db_futures::{IdbDatabase, IdbQuerySource, IdbVersionChangeEvent};
use js_sys::Uint8Array;
use serde::de::DeserializeOwned;
use serde::Serialize;
use std::future::Future;
use std::sync::Arc;
use tokio::sync::RwLock;
use wasm_bindgen::JsValue;
use web_sys::IdbTransactionMode;

pub trait IndexddbStore {
  fn get<'a, T>(&'a self, key: &'a str) -> LocalBoxFuture<Result<Option<T>, PersistenceError>>
  where
    T: serde::de::DeserializeOwned + Sync;
  fn set<'a, T>(&'a self, key: &'a str, value: T) -> LocalBoxFuture<Result<(), PersistenceError>>
  where
    T: serde::Serialize + Sync + 'a;
  fn remove<'a>(&'a self, key: &'a str) -> LocalBoxFuture<Result<(), PersistenceError>>;
}

const APPFLOWY_STORE: &str = "appflowy_store";
pub struct AppFlowyWASMStore {
  db: Arc<RwLock<IdbDatabase>>,
}

unsafe impl Send for AppFlowyWASMStore {}
unsafe impl Sync for AppFlowyWASMStore {}

impl AppFlowyWASMStore {
  pub async fn new() -> Result<Self, PersistenceError> {
    let mut db_req = IdbDatabase::open_u32("appflowy", 1)?;
    db_req.set_on_upgrade_needed(Some(|evt: &IdbVersionChangeEvent| -> Result<(), JsValue> {
      if !evt.db().object_store_names().any(|n| &n == APPFLOWY_STORE) {
        evt.db().create_object_store(APPFLOWY_STORE)?;
      }
      Ok(())
    }));
    let db = Arc::new(RwLock::new(db_req.await?));
    Ok(Self { db })
  }

  pub async fn begin_read_transaction<F, Fut>(&self, f: F) -> Result<(), PersistenceError>
  where
    F: FnOnce(&IndexddbStoreImpl<'_>) -> Fut,
    Fut: Future<Output = Result<(), PersistenceError>>,
  {
    let db = self.db.read().await;
    let txn = db.transaction_on_one_with_mode(APPFLOWY_STORE, IdbTransactionMode::Readonly)?;
    let store = store_from_transaction(&txn)?;
    let operation = IndexddbStoreImpl(store);
    f(&operation).await?;
    transaction_result_to_result(txn.await)?;
    Ok(())
  }

  pub async fn begin_write_transaction<F>(&self, f: F) -> Result<(), PersistenceError>
  where
    F: FnOnce(IndexddbStoreImpl<'_>) -> LocalBoxFuture<'_, Result<(), PersistenceError>>,
  {
    let db = self.db.write().await;
    let txn = db.transaction_on_one_with_mode(APPFLOWY_STORE, IdbTransactionMode::Readwrite)?;
    let store = store_from_transaction(&txn)?;
    let operation = IndexddbStoreImpl(store);
    f(operation).await?;
    transaction_result_to_result(txn.await)?;
    Ok(())
  }
}

pub struct IndexddbStoreImpl<'i>(IdbObjectStore<'i>);

impl<'i> IndexddbStore for IndexddbStoreImpl<'i> {
  fn get<'a, T>(&'a self, key: &'a str) -> LocalBoxFuture<Result<Option<T>, PersistenceError>>
  where
    T: DeserializeOwned + Sync,
  {
    let js_key = to_js_value(key);
    Box::pin(async move {
      match self.0.get(&js_key)?.await? {
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
    })
  }

  fn set<'a, T>(&'a self, key: &'a str, value: T) -> LocalBoxFuture<Result<(), PersistenceError>>
  where
    T: Serialize + Sync + 'a,
  {
    let js_key = to_js_value(key);
    Box::pin(async move {
      let js_value = to_js_value(serde_json::to_vec(&value)?);
      self.0.put_key_val(&js_key, &js_value)?.await?;
      Ok(())
    })
  }

  fn remove<'a>(&'a self, key: &'a str) -> LocalBoxFuture<Result<(), PersistenceError>> {
    let js_key = to_js_value(key);
    Box::pin(async move {
      self.0.delete(&js_key)?.await?;
      Ok(())
    })
  }
}

impl IndexddbStore for AppFlowyWASMStore {
  fn get<'a, T>(&'a self, key: &'a str) -> LocalBoxFuture<Result<Option<T>, PersistenceError>>
  where
    T: serde::de::DeserializeOwned + Sync,
  {
    let db = Arc::downgrade(&self.db);
    Box::pin(async move {
      let db = db.upgrade().ok_or_else(|| {
        PersistenceError::Internal(anyhow!("Failed to upgrade the database reference"))
      })?;
      let read_guard = db.read().await;
      let txn =
        read_guard.transaction_on_one_with_mode(APPFLOWY_STORE, IdbTransactionMode::Readonly)?;
      let store = store_from_transaction(&txn)?;
      IndexddbStoreImpl(store).get(key).await
    })
  }

  fn set<'a, T>(&'a self, key: &'a str, value: T) -> LocalBoxFuture<Result<(), PersistenceError>>
  where
    T: serde::Serialize + Sync + 'a,
  {
    let db = Arc::downgrade(&self.db);
    Box::pin(async move {
      let db = db.upgrade().ok_or_else(|| {
        PersistenceError::Internal(anyhow!("Failed to upgrade the database reference"))
      })?;
      let read_guard = db.read().await;
      let txn =
        read_guard.transaction_on_one_with_mode(APPFLOWY_STORE, IdbTransactionMode::Readwrite)?;
      let store = store_from_transaction(&txn)?;
      IndexddbStoreImpl(store).set(key, value).await?;
      transaction_result_to_result(txn.await)?;
      Ok(())
    })
  }

  fn remove<'a>(&'a self, key: &'a str) -> LocalBoxFuture<Result<(), PersistenceError>> {
    let db = Arc::downgrade(&self.db);
    Box::pin(async move {
      let db = db.upgrade().ok_or_else(|| {
        PersistenceError::Internal(anyhow!("Failed to upgrade the database reference"))
      })?;
      let read_guard = db.read().await;
      let txn =
        read_guard.transaction_on_one_with_mode(APPFLOWY_STORE, IdbTransactionMode::Readwrite)?;
      let store = store_from_transaction(&txn)?;
      IndexddbStoreImpl(store).remove(key).await?;
      transaction_result_to_result(txn.await)?;
      Ok(())
    })
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
