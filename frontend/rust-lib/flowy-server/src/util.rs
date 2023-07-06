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

pub(crate) fn uuid_from_box_any(any: BoxAny) -> Result<Uuid, FlowyError> {
  let map: HashMap<String, String> = any.unbox_or_error()?;
  let uuid = map
    .get("uuid")
    .ok_or_else(|| FlowyError::new(ErrorCode::MissingAuthField, "Missing uuid field"))?;
  Uuid::from_str(uuid).map_err(internal_error)
}
