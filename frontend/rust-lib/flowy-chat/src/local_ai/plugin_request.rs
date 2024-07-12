use anyhow::anyhow;
use futures_util::StreamExt;
use md5::Context;
use reqwest::Client;
use sha2::{Digest, Sha256};
use std::error::Error;
use std::path::PathBuf;
use std::sync::Arc;
use tokio::fs;
use tokio::fs::File;
use tokio::io::{AsyncReadExt, AsyncSeekExt, AsyncWriteExt};
use tokio_util::sync::CancellationToken;
use tracing::trace;

type ProgressCallback = Arc<dyn Fn(u64, u64) + Send + Sync>;

pub async fn download_plugin(
  url: &str,
  plugin_dir: &PathBuf,
  file_name: &str,
  cancel_token: Option<CancellationToken>,
  progress_callback: Option<ProgressCallback>,
) -> Result<PathBuf, anyhow::Error> {
  let client = Client::new();
  let response = client.get(url).send().await?;

  if !response.status().is_success() {
    return Err(anyhow!("Failed to download file: {}", response.status()));
  }

  let total_size = response
    .content_length()
    .ok_or(anyhow!("Failed to get content length"))?;

  // Create paths for the partial and final files
  let partial_path = plugin_dir.join(format!("{}.part", file_name));
  let final_path = plugin_dir.join(file_name);
  let mut part_file = File::create(&partial_path).await?;
  let mut stream = response.bytes_stream();
  let mut downloaded: u64 = 0;

  while let Some(chunk) = stream.next().await {
    if let Some(cancel_token) = &cancel_token {
      if cancel_token.is_cancelled() {
        trace!("Download canceled");
        fs::remove_file(&partial_path).await?;
        return Err(anyhow!("Download canceled"));
      }
    }

    let bytes = chunk?;
    part_file.write_all(&bytes).await?;
    downloaded += bytes.len() as u64;

    // Call the progress callback
    if let Some(progress_callback) = &progress_callback {
      progress_callback(downloaded, total_size);
    }
  }

  // Ensure all data is written to disk
  part_file.sync_all().await?;

  // Move the temporary file to the final destination
  fs::rename(&partial_path, &final_path).await?;
  trace!("Plugin downloaded to {:?}", final_path);
  Ok(final_path)
}

#[cfg(test)]
mod test {
  use super::*;
  use std::env::temp_dir;

  #[tokio::test]
  async fn download_plugin_test() {
    let url = "https://appflowy-local-ai.s3.amazonaws.com/windows-latest/AppFlowyLLM_release.zip?AWSAccessKeyId=AKIAVQA4ULIFKSXHI6PI&Signature=RyHlKjiB5AFSv2S7NFMt7Kr8cyo%3D&Expires=1720788887";
    if url.is_empty() {
      return;
    }

    let progress_callback: ProgressCallback = Arc::new(|downloaded, total_size| {
      let progress = (downloaded as f64 / total_size as f64) * 100.0;
      println!("Download progress: {:.2}%", progress);
    });

    let temp_dir = temp_dir().join("download_plugin");
    if !temp_dir.exists() {
      std::fs::create_dir(&temp_dir).unwrap();
    }

    download_plugin(
      url,
      &temp_dir,
      "AppFlowyLLM.zip",
      None,
      Some(progress_callback),
    )
    .await
    .unwrap();
  }
}
