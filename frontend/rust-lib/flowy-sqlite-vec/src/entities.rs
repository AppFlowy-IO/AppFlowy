use serde::Serialize;

#[derive(Clone, Debug)]
pub struct PendingIndexedCollab {
  pub object_id: String,
  pub workspace_id: String,
  pub content: String,
  pub collab_type: i16,
}

#[derive(Clone, Debug)]
pub struct SqliteEmbeddedDocument {
  pub workspace_id: String,
  pub object_id: String,
  pub fragments: Vec<SqliteEmbeddedFragment>,
}

#[derive(Clone, Debug)]
pub struct SqliteEmbeddedFragment {
  pub content: String,
  pub embeddings: Vec<f32>,
}

#[derive(Clone, Debug, Serialize)]
pub struct EmbeddedContent {
  pub content: String,
  pub object_id: String,
}
