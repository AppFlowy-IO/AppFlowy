use collab::entity::EncodedCollab;
use collab_entity::CollabType;
use collab_folder::ViewLayout;
use flowy_error::FlowyResult;
use lib_infra::async_trait::async_trait;

pub struct QueryCollab {
  pub collab_type: CollabType,
  pub encoded_collab: EncodedCollab,
}

pub trait FolderService: FolderQueryService + FolderViewEdit {}

#[async_trait]
pub trait FolderQueryService: Send + Sync + 'static {
  async fn get_sibling_ids_with_view_layout(
    &self,
    parent_view_id: &str,
    view_layout: ViewLayout,
  ) -> Vec<String>;

  async fn get_collab(&self, object_id: &str, collab_type: CollabType) -> Option<QueryCollab>;
}

#[async_trait]
pub trait FolderViewEdit: Send + Sync + 'static {
  async fn set_view_title_if_empty(&self, view_id: &str, title: &str) -> FlowyResult<()>;
}
