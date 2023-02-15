use crate::{FilterConfiguration, GroupConfiguration, SortConfiguration};
use indexmap::IndexMap;
use nanoid::nanoid;
use serde::{Deserialize, Serialize};
use serde_repr::*;

#[allow(dead_code)]
pub fn gen_grid_view_id() -> String {
  nanoid!(6)
}

#[derive(Debug, PartialEq, Eq, Hash, Clone, Serialize_repr, Deserialize_repr)]
#[repr(u8)]
pub enum LayoutRevision {
  Grid = 0,
  Board = 1,
  Calendar = 2,
}

impl ToString for LayoutRevision {
  fn to_string(&self) -> String {
    let layout_rev = self.clone() as u8;
    layout_rev.to_string()
  }
}

impl std::default::Default for LayoutRevision {
  fn default() -> Self {
    LayoutRevision::Grid
  }
}

#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct DatabaseViewRevision {
  pub view_id: String,

  pub grid_id: String,

  pub layout: LayoutRevision,

  #[serde(default)]
  pub layout_settings: LayoutSettings,

  #[serde(default)]
  pub filters: FilterConfiguration,

  #[serde(default)]
  pub groups: GroupConfiguration,

  #[serde(default)]
  pub sorts: SortConfiguration,
}

impl DatabaseViewRevision {
  pub fn new(grid_id: String, view_id: String, layout: LayoutRevision) -> Self {
    DatabaseViewRevision {
      view_id,
      grid_id,
      layout,
      layout_settings: Default::default(),
      filters: Default::default(),
      groups: Default::default(),
      sorts: Default::default(),
    }
  }

  pub fn from_json(json: String) -> Result<Self, serde_json::Error> {
    serde_json::from_str(&json)
  }
}

#[derive(Debug, Clone, Default, Serialize, Deserialize)]
#[serde(transparent)]
pub struct LayoutSettings {
  #[serde(with = "indexmap::serde_seq")]
  inner: IndexMap<LayoutRevision, String>,
}

impl std::ops::Deref for LayoutSettings {
  type Target = IndexMap<LayoutRevision, String>;

  fn deref(&self) -> &Self::Target {
    &self.inner
  }
}

impl std::ops::DerefMut for LayoutSettings {
  fn deref_mut(&mut self) -> &mut Self::Target {
    &mut self.inner
  }
}

#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct RowOrderRevision {
  pub row_id: String,
}

#[cfg(test)]
mod tests {
  use crate::DatabaseViewRevision;

  #[test]
  fn grid_view_revision_serde_test() {
    let grid_view_revision = DatabaseViewRevision {
      view_id: "1".to_string(),
      grid_id: "1".to_string(),
      layout: Default::default(),
      layout_settings: Default::default(),
      filters: Default::default(),
      groups: Default::default(),
      sorts: Default::default(),
    };
    let s = serde_json::to_string(&grid_view_revision).unwrap();
    assert_eq!(
      s,
      r#"{"view_id":"1","grid_id":"1","layout":0,"layout_settings":[],"filters":[],"groups":[],"sorts":[]}"#
    );
  }
}
