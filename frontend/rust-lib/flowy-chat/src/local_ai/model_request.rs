use anyhow::{anyhow, Result};
use base64::engine::general_purpose::STANDARD;
use base64::Engine;
use reqwest::{Client, Response, StatusCode};
use sha2::{Digest, Sha256};
use std::path::{Path, PathBuf};
use std::sync::Arc;
use tokio::fs::{self, File};
use tokio::io::{AsyncReadExt, AsyncSeekExt, AsyncWriteExt};
use tokio::sync::watch;
use tokio_util::sync::CancellationToken;
use tracing::{instrument, trace};

type ProgressCallback = Arc<dyn Fn(u64, u64) + Send + Sync>;

#[instrument(level = "trace", skip_all, err)]
pub async fn download_model(
  url: &str,
  model_path: &Path,
  model_filename: &str,
  progress_callback: Option<ProgressCallback>,
  cancel_token: Option<CancellationToken>,
) -> Result<PathBuf, anyhow::Error> {
  let client = Client::new();
  let mut response = make_request(&client, url, None).await?;
  let total_size_in_bytes = response.content_length().unwrap_or(0);
  let partial_path = model_path.join(format!("{}.part", model_filename));
  let download_path = model_path.join(model_filename);
  let mut part_file = File::create(&partial_path).await?;
  let mut downloaded: u64 = 0;

  while let Some(chunk) = response.chunk().await? {
    if let Some(cancel_token) = &cancel_token {
      if cancel_token.is_cancelled() {
        trace!("Download canceled by client");
        fs::remove_file(&partial_path).await?;
        return Err(anyhow!("Download canceled"));
      }
    }

    part_file.write_all(&chunk).await?;
    downloaded += chunk.len() as u64;

    if let Some(progress_callback) = &progress_callback {
      progress_callback(downloaded, total_size_in_bytes);
    }
  }

  // Verify file integrity
  let header_sha256 = response
    .headers()
    .get("SHA256")
    .map(|value| value.to_str().ok())
    .flatten()
    .map(|value| STANDARD.decode(value).ok())
    .flatten();

  part_file.seek(tokio::io::SeekFrom::Start(0)).await?;
  let mut hasher = Sha256::new();
  let block_size = 2_usize.pow(20); // 1 MB
  let mut buffer = vec![0; block_size];
  while let Ok(bytes_read) = part_file.read(&mut buffer).await {
    if bytes_read == 0 {
      break;
    }
    hasher.update(&buffer[..bytes_read]);
  }
  let calculated_sha256 = hasher.finalize();
  if let Some(header_sha256) = header_sha256 {
    if calculated_sha256.as_slice() != header_sha256.as_slice() {
      trace!(
        "Header Sha256: {:?}, calculated Sha256:{:?}",
        header_sha256,
        calculated_sha256
      );

      fs::remove_file(&partial_path).await?;
      return Err(anyhow!(
        "Sha256 mismatch: expected {:?}, got {:?}",
        header_sha256,
        calculated_sha256
      ));
    }
  }

  fs::rename(&partial_path, &download_path).await?;
  Ok(download_path)
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

#[cfg(test)]
mod test {
  use super::*;
  use std::env::temp_dir;
  #[tokio::test]
  async fn retrieve_gpt4all_model_test() {
    for url in [
      "https://gpt4all.io/models/gguf/all-MiniLM-L6-v2-f16.gguf",
      "https://huggingface.co/second-state/All-MiniLM-L6-v2-Embedding-GGUF/resolve/main/all-MiniLM-L6-v2-Q3_K_L.gguf?download=true",
      // "https://huggingface.co/MaziyarPanahi/Mistral-7B-Instruct-v0.3-GGUF/resolve/main/Mistral-7B-Instruct-v0.3.Q4_K_M.gguf?download=true",
    ] {
      let temp_dir = temp_dir().join("download_llm");
      if !temp_dir.exists() {
        fs::create_dir(&temp_dir).await.unwrap();
      }
      let file_name = "llm_model.gguf";
      let cancel_token = CancellationToken::new();
      let token = cancel_token.clone();
      tokio::spawn(async move {
        tokio::time::sleep(tokio::time::Duration::from_secs(30)).await;
        token.cancel();
      });

      let download_file = download_model(
        url,
        &temp_dir,
        file_name,
        Some(Arc::new(|a, b| {
          println!("{}/{}", a, b);
        })),
        Some(cancel_token),
      ).await.unwrap();

      let file_path = temp_dir.join(file_name);
      assert_eq!(download_file, file_path);

      println!("File path: {:?}", file_path);
      assert!(file_path.exists());
      std::fs::remove_file(file_path).unwrap();
    }
  }
}
