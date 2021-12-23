mod kv;

use bytes::Bytes;
pub(crate) use kv::*;

use backend_service::errors::ServerError;
use lib_infra::future::FutureResultSend;

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct KeyValue {
    pub key: String,
    pub value: Bytes,
}

pub trait KVStore: Send + Sync {
    fn get(&self, key: &str) -> FutureResultSend<Option<Bytes>, ServerError>;
    fn set(&self, key: &str, value: Bytes) -> FutureResultSend<(), ServerError>;
    fn delete(&self, key: &str) -> FutureResultSend<(), ServerError>;
    fn batch_set(&self, kvs: Vec<KeyValue>) -> FutureResultSend<(), ServerError>;
    fn batch_get(&self, keys: Vec<String>) -> FutureResultSend<Vec<KeyValue>, ServerError>;
    fn batch_get_key_start_with(&self, keyword: &str) -> FutureResultSend<Vec<KeyValue>, ServerError>;

    fn batch_delete(&self, keys: Vec<String>) -> FutureResultSend<(), ServerError>;
    fn batch_delete_key_start_with(&self, keyword: &str) -> FutureResultSend<(), ServerError>;
}
