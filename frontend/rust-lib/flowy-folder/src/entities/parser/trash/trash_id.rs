#[derive(Debug)]
pub struct TrashIdentify(pub String);

impl TrashIdentify {
  #[allow(dead_code)]
  pub fn parse(s: String) -> Result<TrashIdentify, String> {
    if s.trim().is_empty() {
      return Err("Trash id can not be empty or whitespace".to_string());
    }

    Ok(Self(s))
  }
}

impl AsRef<str> for TrashIdentify {
  fn as_ref(&self) -> &str {
    &self.0
  }
}
