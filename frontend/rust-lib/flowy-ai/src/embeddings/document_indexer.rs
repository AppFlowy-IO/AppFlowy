use crate::embeddings::embedder::Embedder;
use crate::embeddings::indexer::{EmbeddingModel, Indexer};
use flowy_ai_pub::entities::{EmbeddedChunk, SOURCE, SOURCE_ID, SOURCE_NAME};
use flowy_error::FlowyError;
use lib_infra::async_trait::async_trait;
use ollama_rs::generation::embeddings::request::{EmbeddingsInput, GenerateEmbeddingsRequest};
use serde_json::json;
use text_splitter::{ChunkConfig, TextSplitter};
use tracing::{debug, error, trace, warn};
use twox_hash::xxhash64::Hasher;
use uuid::Uuid;

pub struct DocumentIndexer;

#[async_trait]
impl Indexer for DocumentIndexer {
  fn create_embedded_chunks_from_text(
    &self,
    object_id: Uuid,
    paragraphs: Vec<String>,
    model: EmbeddingModel,
  ) -> Result<Vec<EmbeddedChunk>, FlowyError> {
    if paragraphs.is_empty() {
      warn!(
        "[Embedding] No paragraphs found in document `{}`. Skipping embedding.",
        object_id
      );

      return Ok(vec![]);
    }
    split_text_into_chunks(&object_id.to_string(), paragraphs, model, 1000, 200)
  }

  async fn embed(
    &self,
    embedder: &Embedder,
    mut chunks: Vec<EmbeddedChunk>,
  ) -> Result<Vec<EmbeddedChunk>, FlowyError> {
    let mut valid_indices = Vec::new();
    for (i, chunk) in chunks.iter().enumerate() {
      if let Some(ref content) = chunk.content {
        if !content.is_empty() {
          valid_indices.push(i);
        }
      }
    }

    if valid_indices.is_empty() {
      return Ok(vec![]);
    }

    let mut contents = Vec::with_capacity(valid_indices.len());
    for &i in &valid_indices {
      contents.push(chunks[i].content.as_ref().unwrap().to_owned());
    }

    let request = GenerateEmbeddingsRequest::new(
      embedder.model().name().to_string(),
      EmbeddingsInput::Multiple(contents),
    );
    let resp = embedder.embed(request).await?;
    if resp.embeddings.len() != valid_indices.len() {
      error!(
        "[Embedding] requested {} embeddings, received {} embeddings",
        valid_indices.len(),
        resp.embeddings.len()
      );
      return Err(FlowyError::internal().with_context(format!(
        "Mismatch in number of embeddings requested and received: {} vs {}",
        valid_indices.len(),
        resp.embeddings.len()
      )));
    }

    for (index, embedding) in resp.embeddings.into_iter().enumerate() {
      let chunk_idx = valid_indices[index];
      chunks[chunk_idx].embeddings = Some(embedding);
    }

    Ok(chunks)
  }
}

/// chunk_size:
/// Small Chunks (50–256 tokens): Best for precision-focused tasks (e.g., Q&A, technical docs) where specific details matter.
/// Medium Chunks (256–1,024 tokens): Ideal for balanced tasks like RAG or contextual search, providing enough context without noise.
/// Large Chunks (1,024–2,048 tokens): Suited for analysis or thematic tasks where broad understanding is key.
///
/// overlap:
/// Add 10–20% overlap for larger chunks (e.g., 50–100 tokens for 512-token chunks) to preserve context across boundaries.
pub fn split_text_into_chunks(
  object_id: &str,
  paragraphs: Vec<String>,
  embedding_model: EmbeddingModel,
  chunk_size: usize,
  overlap: usize,
) -> Result<Vec<EmbeddedChunk>, FlowyError> {
  debug_assert!(matches!(embedding_model, EmbeddingModel::NomicEmbedText));

  if paragraphs.is_empty() {
    return Ok(vec![]);
  }
  let split_contents = group_paragraphs_by_max_content_len(paragraphs, chunk_size, overlap);
  let metadata = json!({
      SOURCE_ID: object_id,
      SOURCE: "appflowy",
      SOURCE_NAME: "document",
  });

  let mut seen = std::collections::HashSet::new();
  let mut chunks = Vec::new();

  for (index, content) in split_contents.into_iter().enumerate() {
    let metadata_string = metadata.to_string();
    let combined_data = format!("{}{}", content, metadata_string);
    let consistent_hash = Hasher::oneshot(0, combined_data.as_bytes());
    let fragment_id = format!("{:x}", consistent_hash);
    if seen.insert(fragment_id.clone()) {
      chunks.push(EmbeddedChunk {
        fragment_id,
        object_id: object_id.to_string(),
        content_type: 0,
        content: Some(content),
        embeddings: None,
        metadata: Some(metadata_string),
        fragment_index: index as i32,
        embedder_type: 0,
      });
    } else {
      debug!(
        "[Embedding] Duplicate fragment_id detected: {}. This fragment will not be added.",
        fragment_id
      );
    }
  }

  trace!(
    "[Embedding] Created {} chunks for object_id `{}`, chunk_size: {}, overlap: {}",
    chunks.len(),
    object_id,
    chunk_size,
    overlap
  );
  Ok(chunks)
}

pub fn group_paragraphs_by_max_content_len(
  paragraphs: Vec<String>,
  mut context_size: usize,
  overlap: usize,
) -> Vec<String> {
  if paragraphs.is_empty() {
    return vec![];
  }

  let mut result = Vec::new();
  let mut current = String::with_capacity(context_size.min(4096));

  if overlap > context_size {
    warn!("context_size is smaller than overlap, which may lead to unexpected behavior.");
    context_size = 2 * overlap;
  }

  let chunk_config = ChunkConfig::new(context_size)
    .with_overlap(overlap)
    .unwrap();
  let splitter = TextSplitter::new(chunk_config);

  for paragraph in paragraphs {
    if current.len() + paragraph.len() > context_size {
      if !current.is_empty() {
        result.push(std::mem::take(&mut current));
      }

      if paragraph.len() > context_size {
        let paragraph_chunks = splitter.chunks(&paragraph);
        result.extend(paragraph_chunks.map(String::from));
      } else {
        current.push_str(&paragraph);
      }
    } else {
      // Add paragraph to current chunk
      current.push_str(&paragraph);
    }
  }

  if !current.is_empty() {
    result.push(current);
  }

  result
}
