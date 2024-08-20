use anyhow::anyhow;
use bytes::Bytes;
use std::fmt::Display;
use std::ops::Deref;
use std::path::Path;

use tokio::io::AsyncReadExt;

/// In Amazon S3, the minimum chunk size for multipart uploads is 5 MB,except for the last part,
/// which can be smaller.(https://docs.aws.amazon.com/AmazonS3/latest/userguide/qfacts.html)
pub const MIN_CHUNK_SIZE: usize = 5 * 1024 * 1024; // Minimum Chunk Size 5 MB
#[derive(Debug, Clone)]
pub struct ChunkedBytes {
  pub data: Bytes,
  pub chunk_size: i32,
  pub offsets: Vec<(usize, usize)>,
  pub current_offset: i32,
}

impl Deref for ChunkedBytes {
  type Target = Bytes;

  fn deref(&self) -> &Self::Target {
    &self.data
  }
}

impl Display for ChunkedBytes {
  fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
    write!(
      f,
      "data:{}, chunk_size:{}, num chunk:{}, offset:{}",
      self.data.len(),
      self.chunk_size,
      self.offsets.len(),
      self.current_offset
    )
  }
}

impl ChunkedBytes {
  pub fn from_bytes_with_chunk_size(data: Bytes, chunk_size: i32) -> Result<Self, anyhow::Error> {
    if chunk_size < MIN_CHUNK_SIZE as i32 {
      return Err(anyhow!(
        "Chunk size should be greater than or equal to {}",
        MIN_CHUNK_SIZE
      ));
    }

    let offsets = split_into_chunks(&data, chunk_size as usize);
    Ok(ChunkedBytes {
      data,
      offsets,
      chunk_size,
      current_offset: 0,
    })
  }

  /// Used to create a `ChunkedBytes` from a `Bytes` object. The default chunk size is 5 MB.
  pub fn from_bytes(data: Bytes) -> Self {
    let chunk_size = MIN_CHUNK_SIZE as i32;
    let offsets = split_into_chunks(&data, MIN_CHUNK_SIZE);
    ChunkedBytes {
      data,
      offsets,
      chunk_size,
      current_offset: 0,
    }
  }

  pub async fn from_file<P: AsRef<Path>>(
    file_path: P,
    chunk_size: i32,
  ) -> Result<Self, tokio::io::Error> {
    let mut file = tokio::fs::File::open(file_path).await?;
    let mut buffer = Vec::new();
    file.read_to_end(&mut buffer).await?;
    let data = Bytes::from(buffer);

    let offsets = split_into_chunks(&data, chunk_size as usize);
    Ok(ChunkedBytes {
      data,
      offsets,
      chunk_size,
      current_offset: 0,
    })
  }

  pub fn set_current_offset(&mut self, offset: i32) {
    self.current_offset = offset;
  }

  pub fn iter(&self) -> ChunkedBytesIterator {
    ChunkedBytesIterator {
      chunked_data: self,
      current_index: self.current_offset as usize,
    }
  }
}

pub struct ChunkedBytesIterator<'a> {
  chunked_data: &'a ChunkedBytes,
  current_index: usize,
}
impl<'a> Iterator for ChunkedBytesIterator<'a> {
  type Item = Bytes;

  fn next(&mut self) -> Option<Self::Item> {
    if self.current_index >= self.chunked_data.offsets.len() {
      None
    } else {
      let (start, end) = self.chunked_data.offsets[self.current_index];
      self.current_index += 1;
      Some(self.chunked_data.data.slice(start..end))
    }
  }
}
// Function to split input bytes into several chunks and return offsets
pub fn split_into_chunks(data: &Bytes, chunk_size: usize) -> Vec<(usize, usize)> {
  let mut offsets = Vec::new();
  let mut start = 0;

  while start < data.len() {
    let end = std::cmp::min(start + chunk_size, data.len());
    offsets.push((start, end));
    start = end;
  }
  offsets
}

// Function to get chunk data using chunk number
pub async fn get_chunk(
  data: Bytes,
  chunk_number: usize,
  offsets: &[(usize, usize)],
) -> Result<Bytes, anyhow::Error> {
  if chunk_number >= offsets.len() {
    return Err(anyhow!("Chunk number out of range"));
  }

  let (start, end) = offsets[chunk_number];
  let chunk = data.slice(start..end);

  Ok(chunk)
}

#[cfg(test)]
mod tests {
  use crate::chunked_byte::{ChunkedBytes, MIN_CHUNK_SIZE};
  use bytes::Bytes;
  use std::env::temp_dir;
  use tokio::io::AsyncWriteExt;

  #[tokio::test]
  async fn test_chunked_bytes_less_than_chunk_size() {
    let data = Bytes::from(vec![0; 1024 * 1024]); // 1 MB of zeroes
    let chunked_data =
      ChunkedBytes::from_bytes_with_chunk_size(data.clone(), MIN_CHUNK_SIZE as i32).unwrap();

    // Check if the offsets are correct
    assert_eq!(chunked_data.offsets.len(), 1); // Should have 1 chunk
    assert_eq!(chunked_data.offsets[0], (0, 1024 * 1024));

    // Check if the data can be iterated correctly
    let mut iter = chunked_data.iter();
    assert_eq!(iter.next().unwrap().len(), 1024 * 1024);
    assert!(iter.next().is_none());
  }

  #[tokio::test]
  async fn test_chunked_bytes_from_bytes() {
    let data = Bytes::from(vec![0; 15 * 1024 * 1024]); // 15 MB of zeroes
    let chunked_data =
      ChunkedBytes::from_bytes_with_chunk_size(data.clone(), MIN_CHUNK_SIZE as i32).unwrap();

    // Check if the offsets are correct
    assert_eq!(chunked_data.offsets.len(), 3); // Should have 3 chunks
    assert_eq!(chunked_data.offsets[0], (0, 5 * 1024 * 1024));
    assert_eq!(chunked_data.offsets[1], (5 * 1024 * 1024, 10 * 1024 * 1024));
    assert_eq!(
      chunked_data.offsets[2],
      (10 * 1024 * 1024, 15 * 1024 * 1024)
    );

    // Check if the data can be iterated correctly
    let mut iter = chunked_data.iter();
    assert_eq!(iter.next().unwrap().len(), 5 * 1024 * 1024);
    assert_eq!(iter.next().unwrap().len(), 5 * 1024 * 1024);
    assert_eq!(iter.next().unwrap().len(), 5 * 1024 * 1024);
    assert!(iter.next().is_none());
  }

  #[tokio::test]
  async fn test_chunked_bytes_from_file() {
    // Create a temporary file with 15 MB of zeroes
    let mut file_path = temp_dir();
    file_path.push("test_file");

    let mut file = tokio::fs::File::create(&file_path).await.unwrap();
    file.write_all(&vec![0; 15 * 1024 * 1024]).await.unwrap();
    file.flush().await.unwrap();

    // Read the file into ChunkedBytes
    let chunked_data = ChunkedBytes::from_file(&file_path, MIN_CHUNK_SIZE as i32)
      .await
      .unwrap();

    // Check if the offsets are correct
    assert_eq!(chunked_data.offsets.len(), 3); // Should have 3 chunks
    assert_eq!(chunked_data.offsets[0], (0, 5 * 1024 * 1024));
    assert_eq!(chunked_data.offsets[1], (5 * 1024 * 1024, 10 * 1024 * 1024));
    assert_eq!(
      chunked_data.offsets[2],
      (10 * 1024 * 1024, 15 * 1024 * 1024)
    );

    // Check if the data can be iterated correctly
    let mut iter = chunked_data.iter();
    assert_eq!(iter.next().unwrap().len(), 5 * 1024 * 1024);
    assert_eq!(iter.next().unwrap().len(), 5 * 1024 * 1024);
    assert_eq!(iter.next().unwrap().len(), 5 * 1024 * 1024);
    assert!(iter.next().is_none());

    // Clean up the temporary file
    tokio::fs::remove_file(file_path).await.unwrap();
  }

  #[tokio::test]
  async fn test_chunked_bytes_with_current_offset() {
    let data = Bytes::from(vec![0; 15 * 1024 * 1024]); // 15 MB of zeroes
    let mut chunked_data =
      ChunkedBytes::from_bytes_with_chunk_size(data.clone(), MIN_CHUNK_SIZE as i32).unwrap();

    // Set the current offset to the second chunk
    chunked_data.set_current_offset(1);

    // Check if the iterator starts from the second chunk
    let mut iter = chunked_data.iter();
    assert_eq!(iter.next().unwrap().len(), 5 * 1024 * 1024); // Second chunk
    assert_eq!(iter.next().unwrap().len(), 5 * 1024 * 1024); // Third chunk
    assert!(iter.next().is_none());
  }
}
