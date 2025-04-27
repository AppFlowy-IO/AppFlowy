use crate::embeddings::indexer::EmbeddingModel;
use faiss::index::IndexImpl;
use faiss::{index_factory, Idx, Index, MetricType};
use faiss::{read_index, write_index};
use flowy_error::FlowyResult;
use std::path::PathBuf;

pub struct FaissController {
  index: IndexImpl,
  db_path: PathBuf,
}

impl FaissController {
  pub fn new(
    data_dir: PathBuf,
    workspace_id: String,
    embedding_model: EmbeddingModel,
  ) -> FlowyResult<Self> {
    let db_path = data_dir
      .join(embedding_model.name())
      .join(format!("faiss_{}.index", workspace_id));
    // load the index from the file, if not exist create a new one
    let index = if db_path.exists() {
      // Try to load the existing index
      match read_index(db_path.to_str().unwrap()) {
        Ok(idx) => idx,
        Err(_) => {
          // If loading fails, create a new one
          index_factory(
            embedding_model.dimension() as u32,
            "Flat",
            MetricType::InnerProduct,
          )?
        },
      }
    } else {
      // Create a new index
      index_factory(
        embedding_model.dimension() as u32,
        "Flat",
        MetricType::InnerProduct,
      )?
    };

    Ok(Self { index, db_path })
  }

  // Save the index to the specified path
  pub fn save(&self) -> FlowyResult<()> {
    write_index(&self.index, self.db_path.to_str().unwrap())?;
    Ok(())
  }

  pub fn next_id(&self) -> u64 {
    self.index.ntotal()
  }

  // Add vector to the index
  pub fn add(&mut self, vector: &[f32]) -> FlowyResult<u64> {
    let id = self.index.ntotal();
    self.index.add_with_ids(vector, &[Idx::new(id)])?;
    Ok(id)
  }

  pub fn search(
    &mut self,
    query_vector: &[f32],
    limit: usize,
  ) -> FlowyResult<Vec<FaissSearchResult>> {
    let result = self.index.search(query_vector, limit)?;
    // Search for the k most similar vectors
    let results: Vec<FaissSearchResult> = result
      .labels
      .iter()
      .zip(result.distances.iter())
      .enumerate()
      .map(|(rank, (&faiss_id, &score))| FaissSearchResult {
        faiss_id: faiss_id.to_native(),
        score,
      })
      .collect();

    Ok(results)
  }
}

pub struct FaissSearchResult {
  pub faiss_id: i64,
  pub score: f32,
}
