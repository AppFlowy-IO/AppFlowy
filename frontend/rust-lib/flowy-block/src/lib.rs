pub mod block_editor;
mod entities;
mod event_handler;
pub mod event_map;
pub mod manager;
mod queue;
mod web_socket;

pub mod protobuf;
pub use manager::*;
pub mod errors {
    pub use flowy_error::{internal_error, ErrorCode, FlowyError};
}

pub const DOCUMENT_SYNC_INTERVAL_IN_MILLIS: u64 = 1000;

use crate::errors::FlowyError;
use flowy_collaboration::entities::document_info::{BlockId, BlockInfo, CreateBlockParams, ResetBlockParams};
use lib_infra::future::FutureResult;

pub trait BlockCloudService: Send + Sync {
    fn create_block(&self, token: &str, params: CreateBlockParams) -> FutureResult<(), FlowyError>;

    fn read_block(&self, token: &str, params: BlockId) -> FutureResult<Option<BlockInfo>, FlowyError>;

    fn update_block(&self, token: &str, params: ResetBlockParams) -> FutureResult<(), FlowyError>;
}
