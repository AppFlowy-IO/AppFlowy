use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct SupabaseStorageError {
  pub status_code: String,
  pub error: String,
  pub message: String,
}

#[derive(Serialize)]
pub struct NewBucket {
  pub name: String,
  pub id: String,
  pub public: bool,
  pub file_size_limit: Option<u32>,
  pub allowed_mime_types: Option<Vec<String>>,
}

impl NewBucket {
  pub fn new(name: String) -> Self {
    Self {
      name: name.clone(),
      id: name,
      public: false,
      file_size_limit: None,
      allowed_mime_types: None,
    }
  }
}

pub struct FileOptions {
  pub cache_control: String,
  pub upsert: bool,
  pub content_type: String,
}

impl FileOptions {
  pub fn from_file_path(file_path: &str) -> Self {
    let mime = mime_guess::from_path(file_path)
      .first_or_octet_stream()
      .to_string();

    Self {
      cache_control: "3600".to_string(),
      upsert: false,
      content_type: mime,
    }
  }

  pub fn with_cache_control(mut self, cache_control: &str) -> Self {
    self.cache_control = cache_control.to_string();
    self
  }

  pub fn with_upsert(mut self, upsert: bool) -> Self {
    self.upsert = upsert;
    self
  }

  pub fn with_content_type(mut self, content_type: &str) -> Self {
    self.content_type = content_type.to_string();
    self
  }
}
#[derive(Serialize)]
pub struct DeleteObjects {
  pub prefixes: Vec<String>,
}

impl DeleteObjects {
  pub fn new(prefixes: Vec<String>) -> Self {
    Self { prefixes }
  }
}
