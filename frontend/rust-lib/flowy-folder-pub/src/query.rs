use collab_folder::ViewLayout;
use lib_infra::async_trait::async_trait;

#[async_trait]
pub trait FolderQueryService: Send + Sync + 'static {
  async fn get_sibling_ids_with_view_layout(
    &self,
    parent_view_id: &str,
    view_layout: ViewLayout,
  ) -> Vec<String>;
}
