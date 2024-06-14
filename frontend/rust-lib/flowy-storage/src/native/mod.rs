use flowy_error::FlowyError;
use flowy_storage_pub::cloud::{ObjectIdentity, ObjectValue};
use std::path::Path;
use tokio::io::AsyncReadExt;
use tracing::info;

pub async fn object_from_disk(
  workspace_id: &str,
  local_file_path: &str,
) -> Result<(ObjectIdentity, ObjectValue), FlowyError> {
  let ext = Path::new(local_file_path)
    .extension()
    .and_then(std::ffi::OsStr::to_str)
    .unwrap_or("")
    .to_owned();
  let mut file = tokio::fs::File::open(local_file_path).await?;
  let mut content = Vec::new();
  let n = file.read_to_end(&mut content).await?;
  info!("read {} bytes from file: {}", n, local_file_path);
  let mime = mime_guess::from_path(local_file_path).first_or_octet_stream();
  let hash = fxhash::hash(&content);

  Ok((
    ObjectIdentity {
      workspace_id: workspace_id.to_owned(),
      file_id: hash.to_string(),
      ext,
    },
    ObjectValue {
      raw: content.into(),
      mime,
    },
  ))
}
