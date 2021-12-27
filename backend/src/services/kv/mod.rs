#![allow(clippy::module_inception)]
mod kv;

use async_trait::async_trait;
use bytes::Bytes;
use futures_core::future::BoxFuture;
pub(crate) use kv::*;

use backend_service::errors::ServerError;
use lib_infra::future::{BoxResultFuture, FutureResultSend};

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct KeyValue {
    pub key: String,
    pub value: Bytes,
}

// https://rust-lang.github.io/async-book/07_workarounds/05_async_in_traits.html
// Note that using these trait methods will result in a heap allocation
// per-function-call. This is not a significant cost for the vast majority of
// applications, but should be considered when deciding whether to use this
// functionality in the public API of a low-level function that is expected to
// be called millions of times a second.
#[async_trait]
pub trait KVStore: KVAction + Send + Sync {}

// pub trait KVTransaction

#[async_trait]
pub trait KVAction: Send + Sync {
    async fn get(&self, key: &str) -> Result<Option<Bytes>, ServerError>;
    async fn set(&self, key: &str, value: Bytes) -> Result<(), ServerError>;
    async fn remove(&self, key: &str) -> Result<(), ServerError>;

    async fn batch_set(&self, kvs: Vec<KeyValue>) -> Result<(), ServerError>;
    async fn batch_get(&self, keys: Vec<String>) -> Result<Vec<KeyValue>, ServerError>;
    async fn batch_delete(&self, keys: Vec<String>) -> Result<(), ServerError>;

    async fn batch_get_start_with(&self, key: &str) -> Result<Vec<KeyValue>, ServerError>;
    async fn batch_delete_key_start_with(&self, keyword: &str) -> Result<(), ServerError>;
}
