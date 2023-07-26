use serde_json::Value;

pub struct InsertParamsBuilder {
  map: serde_json::Map<String, Value>,
}

impl InsertParamsBuilder {
  pub fn new() -> Self {
    Self {
      map: serde_json::Map::new(),
    }
  }

  pub fn insert<T: serde::Serialize>(mut self, key: &str, value: T) -> Self {
    self
      .map
      .insert(key.to_string(), serde_json::to_value(value).unwrap());
    self
  }

  pub fn build(self) -> String {
    serde_json::to_string(&self.map).unwrap()
  }
}
