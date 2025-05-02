#[derive(Clone, Debug)]
pub struct PendingIndexedCollab {
  pub object_id: String,
  pub workspace_id: String,
  pub content: String,
  pub collab_type: i16,
}
