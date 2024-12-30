pub use client_api::entity::ai_dto::{TranslateItem, TranslateRowResponse};
use collab::entity::EncodedCollab;
use collab_entity::CollabType;
use flowy_error::FlowyError;
use lib_infra::async_trait::async_trait;
use std::collections::HashMap;

pub type EncodeCollabByOid = HashMap<String, EncodedCollab>;
pub type SummaryRowContent = HashMap<String, String>;
pub type TranslateRowContent = Vec<TranslateItem>;

#[async_trait]
pub trait DatabaseAIService: Send + Sync {
  async fn summary_database_row(
    &self,
    _workspace_id: &str,
    _object_id: &str,
    _summary_row: SummaryRowContent,
  ) -> Result<String, FlowyError> {
    Ok("".to_string())
  }

  async fn translate_database_row(
    &self,
    _workspace_id: &str,
    _translate_row: TranslateRowContent,
    _language: &str,
  ) -> Result<TranslateRowResponse, FlowyError> {
    Ok(TranslateRowResponse::default())
  }
}

/// A trait for database cloud service.
/// Each kind of server should implement this trait. Check out the [AppFlowyServerProvider] of
/// [flowy-server] crate for more information.
///
/// returns the doc state of the object with the given object_id.
/// None if the object is not found.
///
#[async_trait]
pub trait DatabaseCloudService: Send + Sync {
  async fn get_database_encode_collab(
    &self,
    object_id: &str,
    collab_type: CollabType,
    workspace_id: &str,
  ) -> Result<Option<EncodedCollab>, FlowyError>;

  async fn create_database_encode_collab(
    &self,
    object_id: &str,
    collab_type: CollabType,
    workspace_id: &str,
    encoded_collab: EncodedCollab,
  ) -> Result<(), FlowyError>;

  async fn batch_get_database_encode_collab(
    &self,
    object_ids: Vec<String>,
    object_ty: CollabType,
    workspace_id: &str,
  ) -> Result<EncodeCollabByOid, FlowyError>;

  async fn get_database_collab_object_snapshots(
    &self,
    object_id: &str,
    limit: usize,
  ) -> Result<Vec<DatabaseSnapshot>, FlowyError>;
}

pub struct DatabaseSnapshot {
  pub snapshot_id: i64,
  pub database_id: String,
  pub data: Vec<u8>,
  pub created_at: i64,
}
