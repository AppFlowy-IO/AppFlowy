use std::collections::HashMap;

use serde::{Deserialize, Serialize};
use serde_json::Value;

/// Json format:
/// {
///   'type': string,
///   'data': Map<String, Object>
///   'children': [Block],
/// }
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Block {
  #[serde(rename = "type")]
  pub ty: String,
  #[serde(default)]
  pub data: HashMap<String, Value>,
  #[serde(default)]
  pub children: Vec<Block>,
}
