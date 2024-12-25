use anyhow::anyhow;
use bytes::Bytes;
use std::fmt::Display;
use std::path::Path;
use tokio::fs::File;
use tokio::io::AsyncReadExt;
use tokio::io::SeekFrom;
use tokio::io::{self, AsyncSeekExt};

/// In Amazon S3, the minimum chunk size for multipart uploads is 5 MB,except for the last part,
/// which can be smaller.(https://docs.aws.amazon.com/AmazonS3/latest/userguide/qfacts.html)
pub const MIN_CHUNK_SIZE: usize = 5 * 1024 * 1024; // Minimum Chunk Size 5 MB
#[derive(Debug)]
pub struct ChunkedBytes {
  file: File,
  chunk_size: usize,
  file_size: u64,
  current_offset: u64,
}

impl ChunkedBytes {
  /// Create a `ChunkedBytes` instance from a file.
  pub async fn from_file<P: AsRef<Path>>(
    file_path: P,
    chunk_size: usize,
  ) -> Result<Self, anyhow::Error> {
    if chunk_size < MIN_CHUNK_SIZE {
      return Err(anyhow!(
        "Chunk size should be greater than or equal to {} bytes",
        MIN_CHUNK_SIZE
      ));
    }

    let file = File::open(file_path).await?;
    let file_size = file.metadata().await?.len();

    Ok(ChunkedBytes {
      file,
      chunk_size,
      file_size,
      current_offset: 0,
    })
  }

  /// Read the next chunk from the file.
  pub async fn next_chunk(&mut self) -> Option<Result<Bytes, io::Error>> {
    if self.current_offset >= self.file_size {
      return None; // End of file
    }

    let mut buffer = vec![0u8; self.chunk_size];
    let mut total_bytes_read = 0;

    // Loop to ensure the buffer is filled or EOF is reached
    while total_bytes_read < self.chunk_size {
      let read_result = self.file.read(&mut buffer[total_bytes_read..]).await;
      match read_result {
        Ok(0) => break, // EOF
        Ok(n) => total_bytes_read += n,
        Err(e) => return Some(Err(e)),
      }
    }

    if total_bytes_read == 0 {
      return None; // EOF
    }

    self.current_offset += total_bytes_read as u64;
    Some(Ok(Bytes::from(buffer[..total_bytes_read].to_vec())))
  }

  /// Set the offset for the next chunk to be read.
  pub async fn set_offset(&mut self, offset: u64) -> Result<(), io::Error> {
    if offset > self.file_size {
      return Err(io::Error::new(
        io::ErrorKind::InvalidInput,
        "Offset out of range",
      ));
    }
    self.current_offset = offset;
    self.file.seek(SeekFrom::Start(offset)).await?;
    Ok(())
  }

  /// Get the total number of chunks in the file.
  pub fn total_chunks(&self) -> usize {
    ((self.file_size + self.chunk_size as u64 - 1) / self.chunk_size as u64) as usize
  }

  /// Get the current offset in the file.
  pub fn current_offset(&self) -> u64 {
    self.current_offset
  }
}

impl Display for ChunkedBytes {
  fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
    write!(
      f,
      "file_size: {}, chunk_size: {}, total_chunks: {}, current_offset: {}",
      self.file_size,
      self.chunk_size,
      self.total_chunks(),
      self.current_offset
    )
  }
}

// Function to split input bytes into several chunks and return offsets
pub fn split_into_chunks(data: &Bytes, chunk_size: usize) -> Vec<(usize, usize)> {
  calculate_offsets(data.len(), chunk_size)
}

pub fn calculate_offsets(data_len: usize, chunk_size: usize) -> Vec<(usize, usize)> {
  let mut offsets = Vec::new();
  let mut start = 0;

  while start < data_len {
    let end = std::cmp::min(start + chunk_size, data_len);
    offsets.push((start, end));
    start = end;
  }

  offsets
}

#[cfg(test)]
mod tests {
  use super::*;
  use std::env::temp_dir;
  use tokio::io::AsyncWriteExt;

  #[tokio::test]
  async fn test_chunked_bytes_small_file() {
    // Create a small file of 1 MB
    let mut file_path = temp_dir();
    file_path.push("test_small_file");

    let mut file = File::create(&file_path).await.unwrap();
    file.write_all(&vec![0; 1024 * 1024]).await.unwrap(); // 1 MB
    file.flush().await.unwrap();

    // Create ChunkedBytes instance
    let mut chunked_bytes = ChunkedBytes::from_file(&file_path, MIN_CHUNK_SIZE)
      .await
      .unwrap();

    // Validate total chunks and read the data
    assert_eq!(chunked_bytes.total_chunks(), 1); // Only 1 chunk due to file size
    let chunk = chunked_bytes.next_chunk().await.unwrap().unwrap();
    assert_eq!(chunk.len(), 1024 * 1024); // The full 1 MB

    // Ensure no more chunks are available
    assert!(chunked_bytes.next_chunk().await.is_none());

    tokio::fs::remove_file(file_path).await.unwrap();
  }

  #[tokio::test]
  async fn test_chunked_bytes_large_file() {
    // Create a large file of 15 MB
    let mut file_path = temp_dir();
    file_path.push("test_large_file");

    let mut file = File::create(&file_path).await.unwrap();
    file.write_all(&vec![0; 15 * 1024 * 1024]).await.unwrap(); // 15 MB
    file.flush().await.unwrap();

    // Create ChunkedBytes instance
    let mut chunked_bytes = ChunkedBytes::from_file(&file_path, MIN_CHUNK_SIZE)
      .await
      .unwrap();

    // Validate total chunks
    assert_eq!(chunked_bytes.total_chunks(), 3); // 15 MB split into 3 chunks of 5 MB

    // Read and validate all chunks
    let mut chunk_sizes = vec![];
    while let Some(chunk_result) = chunked_bytes.next_chunk().await {
      chunk_sizes.push(chunk_result.unwrap().len());
    }
    assert_eq!(
      chunk_sizes,
      vec![5 * 1024 * 1024, 5 * 1024 * 1024, 5 * 1024 * 1024]
    );

    tokio::fs::remove_file(file_path).await.unwrap();
  }

  #[tokio::test]
  async fn test_set_offset() {
    // Create a file of 10 MB
    let mut file_path = temp_dir();
    file_path.push("test_offset_file");

    let mut file = File::create(&file_path).await.unwrap();
    file.write_all(&vec![0; 10 * 1024 * 1024]).await.unwrap(); // 10 MB
    file.flush().await.unwrap();

    // Create ChunkedBytes instance
    let mut chunked_bytes = ChunkedBytes::from_file(&file_path, MIN_CHUNK_SIZE)
      .await
      .unwrap();

    // Set the offset to 5 MB and read the next chunk
    chunked_bytes.set_offset(5 * 1024 * 1024).await.unwrap();
    let chunk = chunked_bytes.next_chunk().await.unwrap().unwrap();
    assert_eq!(chunk.len(), 5 * 1024 * 1024); // Read the second chunk

    // Ensure no more chunks are available
    assert!(chunked_bytes.next_chunk().await.is_none());

    tokio::fs::remove_file(file_path).await.unwrap();
  }

  #[tokio::test]
  async fn test_partial_chunk() {
    // Create a file of 6 MB (one full chunk and one partial chunk)
    let mut file_path = temp_dir();
    file_path.push("test_partial_chunk_file");

    let mut file = File::create(&file_path).await.unwrap();
    file.write_all(&vec![0; 6 * 1024 * 1024]).await.unwrap(); // 6 MB
    file.flush().await.unwrap();

    // Create ChunkedBytes instance
    let mut chunked_bytes = ChunkedBytes::from_file(&file_path, MIN_CHUNK_SIZE)
      .await
      .unwrap();

    // Validate total chunks
    assert_eq!(chunked_bytes.total_chunks(), 2); // 6 MB split into 1 full chunk and 1 partial chunk

    // Read the first chunk
    let chunk1 = chunked_bytes.next_chunk().await.unwrap().unwrap();
    assert_eq!(chunk1.len(), 5 * 1024 * 1024); // Full chunk

    // Read the second chunk
    let chunk2 = chunked_bytes.next_chunk().await.unwrap().unwrap();
    assert_eq!(chunk2.len(), 1024 * 1024); // Partial chunk

    // Ensure no more chunks are available
    assert!(chunked_bytes.next_chunk().await.is_none());

    tokio::fs::remove_file(file_path).await.unwrap();
  }

  #[tokio::test]
  async fn test_invalid_offset() {
    // Create a file of 5 MB
    let mut file_path = temp_dir();
    file_path.push("test_invalid_offset_file");

    let mut file = File::create(&file_path).await.unwrap();
    file.write_all(&vec![0; 5 * 1024 * 1024]).await.unwrap(); // 5 MB
    file.flush().await.unwrap();

    // Create ChunkedBytes instance
    let mut chunked_bytes = ChunkedBytes::from_file(&file_path, MIN_CHUNK_SIZE)
      .await
      .unwrap();

    // Try setting an invalid offset
    let result = chunked_bytes.set_offset(10 * 1024 * 1024).await;
    assert!(result.is_err()); // Offset out of range

    tokio::fs::remove_file(file_path).await.unwrap();
  }

  #[tokio::test]
  async fn test_exact_multiple_chunk_file() {
    // Create a file of 10 MB (exact multiple of 5 MB)
    let mut file_path = temp_dir();
    file_path.push("test_exact_multiple_chunk_file");

    let mut file = File::create(&file_path).await.unwrap();
    file.write_all(&vec![0; 10 * 1024 * 1024]).await.unwrap(); // 10 MB
    file.flush().await.unwrap();

    // Create ChunkedBytes instance
    let mut chunked_bytes = ChunkedBytes::from_file(&file_path, MIN_CHUNK_SIZE)
      .await
      .unwrap();

    // Validate total chunks
    let expected_offsets = calculate_offsets(10 * 1024 * 1024, MIN_CHUNK_SIZE);
    assert_eq!(chunked_bytes.total_chunks(), expected_offsets.len()); // 2 chunks

    // Read and validate all chunks
    let mut chunk_sizes = vec![];
    while let Some(chunk_result) = chunked_bytes.next_chunk().await {
      chunk_sizes.push(chunk_result.unwrap().len());
    }
    assert_eq!(chunk_sizes, vec![5 * 1024 * 1024, 5 * 1024 * 1024]); // 2 full chunks

    tokio::fs::remove_file(file_path).await.unwrap();
  }

  #[tokio::test]
  async fn test_small_file_less_than_chunk_size() {
    // Create a file of 2 MB (smaller than 5 MB)
    let mut file_path = temp_dir();
    file_path.push("test_small_file_less_than_chunk_size");

    let mut file = File::create(&file_path).await.unwrap();
    file.write_all(&vec![0; 2 * 1024 * 1024]).await.unwrap(); // 2 MB
    file.flush().await.unwrap();

    // Create ChunkedBytes instance
    let mut chunked_bytes = ChunkedBytes::from_file(&file_path, MIN_CHUNK_SIZE)
      .await
      .unwrap();

    // Validate total chunks
    let expected_offsets = calculate_offsets(2 * 1024 * 1024, MIN_CHUNK_SIZE);
    assert_eq!(chunked_bytes.total_chunks(), expected_offsets.len()); // 1 chunk

    // Read and validate all chunks
    let mut chunk_sizes = vec![];
    while let Some(chunk_result) = chunked_bytes.next_chunk().await {
      chunk_sizes.push(chunk_result.unwrap().len());
    }
    assert_eq!(chunk_sizes, vec![2 * 1024 * 1024]); // 1 partial chunk

    tokio::fs::remove_file(file_path).await.unwrap();
  }

  #[tokio::test]
  async fn test_file_slightly_larger_than_chunk_size() {
    // Create a file of 5.5 MB (slightly larger than 1 chunk)
    let mut file_path = temp_dir();
    file_path.push("test_file_slightly_larger_than_chunk_size");

    let mut file = File::create(&file_path).await.unwrap();
    file
      .write_all(&vec![0; 5 * 1024 * 1024 + 512 * 1024])
      .await
      .unwrap(); // 5.5 MB
    file.flush().await.unwrap();

    // Create ChunkedBytes instance
    let mut chunked_bytes = ChunkedBytes::from_file(&file_path, MIN_CHUNK_SIZE)
      .await
      .unwrap();

    // Validate total chunks
    let expected_offsets = calculate_offsets(5 * 1024 * 1024 + 512 * 1024, MIN_CHUNK_SIZE);
    assert_eq!(chunked_bytes.total_chunks(), expected_offsets.len()); // 2 chunks

    // Read and validate all chunks
    let mut chunk_sizes = vec![];
    while let Some(chunk_result) = chunked_bytes.next_chunk().await {
      chunk_sizes.push(chunk_result.unwrap().len());
    }
    assert_eq!(chunk_sizes, vec![5 * 1024 * 1024, 512 * 1024]); // 1 full chunk, 1 partial chunk

    tokio::fs::remove_file(file_path).await.unwrap();
  }

  #[tokio::test]
  async fn test_large_file_with_many_chunks() {
    // Create a file of 50 MB (10 chunks of 5 MB)
    let mut file_path = temp_dir();
    file_path.push("test_large_file_with_many_chunks");

    let mut file = File::create(&file_path).await.unwrap();
    file.write_all(&vec![0; 50 * 1024 * 1024]).await.unwrap(); // 50 MB
    file.flush().await.unwrap();

    // Create ChunkedBytes instance
    let mut chunked_bytes = ChunkedBytes::from_file(&file_path, MIN_CHUNK_SIZE)
      .await
      .unwrap();

    // Validate total chunks
    let expected_offsets = calculate_offsets(50 * 1024 * 1024, MIN_CHUNK_SIZE);
    assert_eq!(chunked_bytes.total_chunks(), expected_offsets.len()); // 10 chunks

    // Read and validate all chunks
    let mut chunk_sizes = vec![];
    while let Some(chunk_result) = chunked_bytes.next_chunk().await {
      chunk_sizes.push(chunk_result.unwrap().len());
    }
    assert_eq!(chunk_sizes, vec![5 * 1024 * 1024; 10]); // 10 full chunks

    tokio::fs::remove_file(file_path).await.unwrap();
  }

  #[tokio::test]
  async fn test_file_with_exact_chunk_size() {
    // Create a file of exactly 5 MB
    let mut file_path = temp_dir();
    file_path.push("test_file_with_exact_chunk_size");

    let mut file = File::create(&file_path).await.unwrap();
    file.write_all(&vec![0; 5 * 1024 * 1024]).await.unwrap(); // 5 MB
    file.flush().await.unwrap();

    // Create ChunkedBytes instance
    let mut chunked_bytes = ChunkedBytes::from_file(&file_path, MIN_CHUNK_SIZE)
      .await
      .unwrap();

    // Validate total chunks
    let expected_offsets = calculate_offsets(5 * 1024 * 1024, MIN_CHUNK_SIZE);
    assert_eq!(chunked_bytes.total_chunks(), expected_offsets.len()); // 1 chunk

    // Read and validate all chunks
    let mut chunk_sizes = vec![];
    while let Some(chunk_result) = chunked_bytes.next_chunk().await {
      chunk_sizes.push(chunk_result.unwrap().len());
    }
    assert_eq!(chunk_sizes, vec![5 * 1024 * 1024]); // 1 full chunk

    tokio::fs::remove_file(file_path).await.unwrap();
  }
}
