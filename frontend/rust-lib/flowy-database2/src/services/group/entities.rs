use collab::preclude::encoding::serde::{from_any, to_any};
use collab::preclude::Any;
use collab_database::database::gen_database_group_id;
use collab_database::rows::{Row, RowId};
use collab_database::views::{GroupMap, GroupMapBuilder, GroupSettingBuilder, GroupSettingMap};
use serde::{Deserialize, Serialize};
use std::sync::Arc;

#[derive(Debug, Clone, Default, Deserialize)]
pub struct GroupSetting {
  pub id: String,
  pub field_id: String,
  #[serde(rename = "ty")]
  pub field_type: i64,
  #[serde(default)]
  pub groups: Vec<Group>,
  #[serde(default)]
  pub content: String,
}

#[derive(Clone, Default, Debug)]
pub struct GroupChangeset {
  pub group_id: String,
  pub field_id: String,
  pub name: Option<String>,
  pub visible: Option<bool>,
}

impl GroupSetting {
  pub fn new(field_id: String, field_type: i64, content: String) -> Self {
    Self {
      id: gen_database_group_id(),
      field_id,
      field_type,
      groups: vec![],
      content,
    }
  }
}

const GROUP_ID: &str = "id";
const FIELD_ID: &str = "field_id";
const FIELD_TYPE: &str = "ty";
const GROUPS: &str = "groups";
const CONTENT: &str = "content";

impl TryFrom<GroupSettingMap> for GroupSetting {
  type Error = anyhow::Error;

  fn try_from(value: GroupSettingMap) -> Result<Self, Self::Error> {
    from_any(&Any::from(value)).map_err(|e| e.into())
  }
}

impl From<GroupSetting> for GroupSettingMap {
  fn from(setting: GroupSetting) -> Self {
    let groups = to_any(&setting.groups).unwrap_or_else(|_| Any::Array(Arc::from([])));
    GroupSettingBuilder::from([
      (GROUP_ID.into(), setting.id.into()),
      (FIELD_ID.into(), setting.field_id.into()),
      (FIELD_TYPE.into(), Any::BigInt(setting.field_type)),
      (GROUPS.into(), groups),
      (CONTENT.into(), setting.content.into()),
    ])
  }
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct Group {
  pub id: String,
  #[serde(default = "GROUP_VISIBILITY")]
  pub visible: bool,
}

impl TryFrom<GroupMap> for Group {
  type Error = anyhow::Error;

  fn try_from(value: GroupMap) -> Result<Self, Self::Error> {
    from_any(&Any::from(value)).map_err(|e| e.into())
  }
}

impl From<Group> for GroupMap {
  fn from(group: Group) -> Self {
    GroupMapBuilder::from([
      ("id".into(), group.id.into()),
      ("visible".into(), group.visible.into()),
    ])
  }
}

const GROUP_VISIBILITY: fn() -> bool = || true;

impl Group {
  pub fn new(id: String) -> Self {
    Self { id, visible: true }
  }
}

#[derive(Clone, Debug)]
pub struct GroupData {
  pub id: String,
  pub field_id: String,
  pub is_default: bool,
  pub is_visible: bool,
  pub(crate) rows: Vec<Row>,
}

impl GroupData {
  pub fn new(id: String, field_id: String, is_visible: bool) -> Self {
    let is_default = id == field_id;
    Self {
      id,
      field_id,
      is_default,
      is_visible,
      rows: vec![],
    }
  }

  pub fn contains_row(&self, row_id: &RowId) -> bool {
    self.rows.iter().any(|row| &row.id == row_id)
  }

  pub fn remove_row(&mut self, row_id: &RowId) {
    match self.rows.iter().position(|row| &row.id == row_id) {
      None => {},
      Some(pos) => {
        self.rows.remove(pos);
      },
    }
  }

  pub fn add_row(&mut self, row: Row) {
    match self.rows.iter().find(|r| r.id == row.id) {
      None => {
        self.rows.push(row);
      },
      Some(_) => {},
    }
  }

  pub fn insert_row(&mut self, index: usize, row: Row) {
    if index < self.rows.len() {
      self.rows.insert(index, row);
    } else {
      tracing::error!(
        "Insert row index:{} beyond the bounds:{},",
        index,
        self.rows.len()
      );
    }
  }

  pub fn index_of_row(&self, row_id: &RowId) -> Option<usize> {
    self.rows.iter().position(|row| &row.id == row_id)
  }

  pub fn number_of_row(&self) -> usize {
    self.rows.len()
  }

  pub fn is_empty(&self) -> bool {
    self.rows.is_empty()
  }
}
