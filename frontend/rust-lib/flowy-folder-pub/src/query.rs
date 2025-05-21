use collab::entity::EncodedCollab;
use collab_entity::CollabType;
use collab_folder::ViewLayout;
use flowy_error::FlowyResult;
use lib_infra::async_trait::async_trait;
use uuid::Uuid;

pub struct QueryCollab {
  pub collab_type: CollabType,
  pub encoded_collab: EncodedCollab,
}

pub trait FolderService: FolderQueryService + FolderViewEdit {}

#[async_trait]
pub trait FolderQueryService: Send + Sync + 'static {
  /// gets the parent view and all of the ids of its children views matching
  /// the provided view layout, given that the parent view is not a space
  async fn get_surrounding_view_ids_with_view_layout(
    &self,
    parent_view_id: &Uuid,
    view_layout: ViewLayout,
  ) -> Vec<Uuid>;

  async fn get_collab(&self, object_id: &Uuid, collab_type: CollabType) -> Option<QueryCollab>;
}

#[async_trait]
pub trait FolderViewEdit: Send + Sync + 'static {
  async fn set_view_title_if_empty(&self, view_id: &Uuid, title: &str) -> FlowyResult<()>;
}
