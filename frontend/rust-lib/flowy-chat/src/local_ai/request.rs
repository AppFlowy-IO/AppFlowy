use reqwest::{Client, Response, StatusCode};
use sha2::{Digest, Sha256};

use crate::chat_manager::ChatUserService;
use crate::local_ai::local_llm_chat::{LLMModelInfo, LLMSetting};
use anyhow::anyhow;
use appflowy_local_ai::llm_chat::ChatPluginConfig;
use base64::engine::general_purpose::STANDARD;
use base64::Engine;
use flowy_chat_pub::cloud::{LLMModel, LocalAIConfig};
use flowy_error::{FlowyError, FlowyResult};
use lib_infra::async_trait::async_trait;
use parking_lot::RwLock;
use std::path::{Path, PathBuf};
use std::sync::Arc;
use tokio::fs::{self, File};
use tokio::io::SeekFrom;
use tokio::io::{AsyncReadExt, AsyncSeekExt, AsyncWriteExt};
use tracing::{instrument, trace};

type ProgressCallback = Arc<dyn Fn(u64, u64) + Send + Sync>;

pub async fn retrieve_model(
  url: &str,
  model_path: &Path,
  model_filename: &str,
  progress_callback: ProgressCallback,
) -> Result<PathBuf, Box<dyn std::error::Error>> {
  let model_download_path =
    download_model(url, model_filename, model_path, None, progress_callback).await?;
  Ok(model_download_path)
}

async fn make_request(
  client: &Client,
  url: &str,
  offset: Option<u64>,
) -> Result<Response, anyhow::Error> {
  let mut request = client.get(url);
  if let Some(offset) = offset {
    println!(
      "\nDownload interrupted, resuming from byte position {}",
      offset
    );
    request = request.header("Range", format!("bytes={}-", offset));
  }
  let response = request.send().await?;
  if !(response.status().is_success() || response.status() == StatusCode::PARTIAL_CONTENT) {
    return Err(anyhow!(response.text().await?));
  }
  Ok(response)
}

async fn download_model(
  url: &str,
  model_filename: &str,
  model_path: &Path,
  expected_size: Option<u64>,
  progress_callback: ProgressCallback,
) -> Result<PathBuf, anyhow::Error> {
  let client = Client::new();
  // Make the initial request
  let mut response = make_request(&client, url, None).await?;
  let total_size_in_bytes = response.content_length().unwrap_or(0);
  let partial_path = model_path.join(format!("{}.part", model_filename));
  let download_path = model_path.join(model_filename);
  let mut part_file = File::create(&partial_path).await?;
  let mut downloaded: u64 = 0;
  while let Some(chunk) = response.chunk().await? {
    part_file.write_all(&chunk).await?;
    downloaded += chunk.len() as u64;
    progress_callback(downloaded, total_size_in_bytes);
  }

  // Verify file integrity
  let file_size = part_file.metadata().await?.len();
  trace!("Downloaded file:{}, size: {}", model_filename, file_size);
  if let Some(expected_size) = expected_size {
    if file_size != expected_size {
      return Err(anyhow!(
        "Expected file size of {} bytes, got {}",
        expected_size,
        file_size
      ));
    }
  }

  let header_md5 = response
    .headers()
    .get("Content-MD5")
    .map(|value| value.to_str().ok())
    .flatten()
    .map(|value| STANDARD.decode(value).ok())
    .flatten();
  part_file.seek(SeekFrom::Start(0)).await?;
  let mut hasher = Sha256::new();
  let block_size = 2_usize.pow(20); // 1 MB
  let mut buffer = vec![0; block_size];
  while let Ok(bytes_read) = part_file.read(&mut buffer).await {
    if bytes_read == 0 {
      break;
    }
    hasher.update(&buffer[..bytes_read]);
  }
  let calculated_md5 = hasher.finalize();
  if let Some(header_md5) = header_md5 {
    if calculated_md5.as_slice() != header_md5.as_slice() {
      // remove partial file
      fs::remove_file(&partial_path).await?;

      return Err(anyhow!(
        "MD5 mismatch: expected {:?}, got {:?}",
        header_md5,
        calculated_md5
      ));
    }
  }

  fs::rename(&partial_path, &download_path).await?;
  trace!("Model downloaded to {:?}", download_path);
  Ok(download_path)
}

// #[cfg(test)]
// mod test {
//   use super::*;
//   #[tokio::test]
//   async fn retrieve_gpt4all_model_test() {
//     let file_name = "all-MiniLM-L6-v2-f16.gguf";
//     let path = Path::new(".");
//     retrieve_model(
//       "https://gpt4all.io/models/gguf/all-MiniLM-L6-v2-f16.gguf",
//       &path,
//       file_name,
//       Arc::new(|a, b| {
//         println!("{}/{}", a, b);
//       }),
//     )
//     .await
//     .unwrap();
//
//     let file_path = path.join(file_name);
//     assert!(file_path.exists());
//     std::fs::remove_file(file_path).unwrap();
//   }
//
//   #[tokio::test]
//   async fn retrieve_hugging_face_model_test() {
//     let path = Path::new(".");
//     let file_name = "all-MiniLM-L6-v2-Q3_K_L.gguf";
//     retrieve_model(
//       "https://huggingface.co/second-state/All-MiniLM-L6-v2-Embedding-GGUF/resolve/main/all-MiniLM-L6-v2-Q3_K_L.gguf?download=true",
//       &path,
//       file_name,
//       Arc::new(|a, b| {
//         println!("{}/{}", a, b);
//       }),
//     )
//     .await
//     .unwrap();
//     let file_path = path.join(file_name);
//     assert!(file_path.exists());
//     std::fs::remove_file(file_path).unwrap();
//   }
// }
