use anyhow::bail;
use collab::core::any_map::AnyMapExtension;
use collab_database::database::gen_database_group_id;
use collab_database::rows::{RowDetail, RowId};
use collab_database::views::{GroupMap, GroupMapBuilder, GroupSettingBuilder, GroupSettingMap};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Default)]
pub struct GroupSetting {
  pub id: String,
  pub field_id: String,
  pub field_type: i64,
  pub groups: Vec<Group>,
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
    match (
      value.get_str_value(GROUP_ID),
      value.get_str_value(FIELD_ID),
      value.get_i64_value(FIELD_TYPE),
    ) {
      (Some(id), Some(field_id), Some(field_type)) => {
        let content = value.get_str_value(CONTENT).unwrap_or_default();
        let groups = value.try_get_array(GROUPS);
        Ok(Self {
          id,
          field_id,
          field_type,
          groups,
          content,
        })
      },
      _ => {
        bail!("Invalid group setting data")
      },
    }
  }
}

impl From<GroupSetting> for GroupSettingMap {
  fn from(setting: GroupSetting) -> Self {
    GroupSettingBuilder::new()
      .insert_str_value(GROUP_ID, setting.id)
      .insert_str_value(FIELD_ID, setting.field_id)
      .insert_i64_value(FIELD_TYPE, setting.field_type)
      .insert_maps(GROUPS, setting.groups)
      .insert_str_value(CONTENT, setting.content)
      .build()
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
    match value.get_str_value("id") {
      None => bail!("Invalid group data"),
      Some(id) => {
        let visible = value.get_bool_value("visible").unwrap_or_default();
        Ok(Self { id, visible })
      },
    }
  }
}

impl From<Group> for GroupMap {
  fn from(group: Group) -> Self {
    GroupMapBuilder::new()
      .insert_str_value("id", group.id)
      .insert_bool_value("visible", group.visible)
      .build()
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
  pub(crate) rows: Vec<RowDetail>,
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
    self
      .rows
      .iter()
      .any(|row_detail| &row_detail.row.id == row_id)
  }

  pub fn remove_row(&mut self, row_id: &RowId) {
    match self
      .rows
      .iter()
      .position(|row_detail| &row_detail.row.id == row_id)
    {
      None => {},
      Some(pos) => {
        self.rows.remove(pos);
      },
    }
  }

  pub fn add_row(&mut self, row_detail: RowDetail) {
    match self.rows.iter().find(|r| r.row.id == row_detail.row.id) {
      None => {
        self.rows.push(row_detail);
      },
      Some(_) => {},
    }
  }

  pub fn insert_row(&mut self, index: usize, row_detail: RowDetail) {
    if index < self.rows.len() {
      self.rows.insert(index, row_detail);
    } else {
      tracing::error!(
        "Insert row index:{} beyond the bounds:{},",
        index,
        self.rows.len()
      );
    }
  }

  pub fn index_of_row(&self, row_id: &RowId) -> Option<usize> {
    self
      .rows
      .iter()
      .position(|row_detail| &row_detail.row.id == row_id)
  }

  pub fn number_of_row(&self) -> usize {
    self.rows.len()
  }

  pub fn is_empty(&self) -> bool {
    self.rows.is_empty()
  }
}
