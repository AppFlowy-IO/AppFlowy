#[derive(Debug)]
pub struct NotEmptyStr(pub String);

impl NotEmptyStr {
  pub fn parse(s: String) -> Result<Self, String> {
    if s.trim().is_empty() {
      return Err("Input string is empty".to_owned());
    }
    Ok(Self(s))
  }
}

#[derive(Debug)]
pub struct NotEmptyVec<T>(pub Vec<T>);

impl<T> NotEmptyVec<T> {
  pub fn parse(v: Vec<T>) -> Result<Self, String> {
    if v.is_empty() {
      return Err("Input vector is empty".to_owned());
    }
    Ok(Self(v))
  }
}
