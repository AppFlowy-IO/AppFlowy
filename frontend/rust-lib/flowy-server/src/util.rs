use std::collections::HashMap;
use std::str::FromStr;

use serde::{Deserialize, Deserializer};
use uuid::Uuid;

use flowy_error::{internal_error, ErrorCode, FlowyError};
use lib_infra::box_any::BoxAny;

/// Handles the case where the value is null. If the value is null, return the default value of the
/// type. Otherwise, deserialize the value.
pub(crate) fn deserialize_null_or_default<'de, D, T>(deserializer: D) -> Result<T, D::Error>
where
  T: Default + Deserialize<'de>,
  D: Deserializer<'de>,
{
  let opt = Option::deserialize(deserializer)?;
  Ok(opt.unwrap_or_default())
}
