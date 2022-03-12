pub mod editor;
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

pub const TEXT_BLOCK_SYNC_INTERVAL_IN_MILLIS: u64 = 1000;

use crate::errors::FlowyError;
use flowy_collaboration::entities::text_block_info::{
    CreateTextBlockParams, ResetTextBlockParams, TextBlockId, TextBlockInfo,
};
use lib_infra::future::FutureResult;

pub trait BlockCloudService: Send + Sync {
    fn create_block(&self, token: &str, params: CreateTextBlockParams) -> FutureResult<(), FlowyError>;

    fn read_block(&self, token: &str, params: TextBlockId) -> FutureResult<Option<TextBlockInfo>, FlowyError>;

    fn update_block(&self, token: &str, params: ResetTextBlockParams) -> FutureResult<(), FlowyError>;
}
