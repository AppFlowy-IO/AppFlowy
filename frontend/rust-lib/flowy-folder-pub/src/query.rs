use lib_infra::async_trait::async_trait;

#[async_trait]
pub trait FolderQueryService: Send + Sync + 'static {
  async fn get_sibling_ids(&self, parent_view_id: &str) -> Vec<String>;
}
