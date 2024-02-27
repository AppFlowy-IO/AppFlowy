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

#[derive(Debug)]
pub struct TrashIds(pub Vec<String>);

impl TrashIds {
  #[allow(dead_code)]
  pub fn parse(ids: Vec<String>) -> Result<TrashIds, String> {
    let mut trash_ids = vec![];
    for id in ids {
      let id = TrashIdentify::parse(id)?;
      trash_ids.push(id.0);
    }
    Ok(Self(trash_ids))
  }
}
