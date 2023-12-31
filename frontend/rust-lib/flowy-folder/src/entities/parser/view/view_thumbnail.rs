use flowy_error::ErrorCode;

#[derive(Debug)]
pub struct ViewThumbnail(pub String);

impl ViewThumbnail {
  pub fn parse(s: String) -> Result<ViewThumbnail, ErrorCode> {
    // if s.trim().is_empty() {
    //     return Err(format!("View thumbnail can not be empty or whitespace"));
    // }
    // TODO: verify the thumbnail url is valid or not

    Ok(Self(s))
  }
}

impl AsRef<str> for ViewThumbnail {
  fn as_ref(&self) -> &str {
    &self.0
  }
}
