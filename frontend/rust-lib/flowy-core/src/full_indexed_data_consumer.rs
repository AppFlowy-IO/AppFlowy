use crate::full_indexed_data_provider::FullIndexedDataConsumer;
use flowy_ai::embeddings::context::EmbedContext;
use flowy_ai_pub::entities::UnindexedCollab;
use flowy_error::FlowyResult;
use lib_infra::async_trait::async_trait;

pub struct EmbeddingIndexConsumer;

#[async_trait]
impl FullIndexedDataConsumer for EmbeddingIndexConsumer {
  fn consumer_id(&self) -> String {
    "embedding_index_consumer".to_string()
  }

  async fn consume_indexed_data(&self, _uid: i64, data: &UnindexedCollab) -> FlowyResult<()> {
    let scheduler = EmbedContext::shared().get_scheduler()?;
    scheduler.index_collab(data.clone()).await?;
    Ok(())
  }
}
