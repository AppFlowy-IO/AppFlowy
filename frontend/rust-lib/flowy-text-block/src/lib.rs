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
use flowy_sync::entities::text_block::{CreateTextBlockParams, DocumentPB, ResetTextBlockParams, TextBlockIdPB};
use lib_infra::future::FutureResult;

pub trait TextEditorCloudService: Send + Sync {
    fn create_text_block(&self, token: &str, params: CreateTextBlockParams) -> FutureResult<(), FlowyError>;

    fn read_text_block(&self, token: &str, params: TextBlockIdPB) -> FutureResult<Option<DocumentPB>, FlowyError>;

    fn update_text_block(&self, token: &str, params: ResetTextBlockParams) -> FutureResult<(), FlowyError>;
}
