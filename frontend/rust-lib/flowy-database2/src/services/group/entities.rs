use crate::entities::RowPB;
use crate::protobuf::CreateRowPayloadPB_oneof_one_of_data::data;
use anyhow::bail;
use collab::core::any_map::AnyMapExtension;
use collab_database::views::{GroupMap, GroupMapBuilder};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct Group {
  pub id: String,
  pub name: String,
  #[serde(default = "GROUP_REV_VISIBILITY")]
  pub visible: bool,
}

impl TryFrom<GroupMap> for Group {
  type Error = anyhow::Error;

  fn try_from(value: GroupMap) -> Result<Self, Self::Error> {
    match value.get_str_value("id") {
      None => bail!("Invalid group data"),
      Some(id) => {
        let name = value.get_str_value("name").unwrap_or_default();
        let visible = value.get_bool_value("visible").unwrap_or_default();
        Ok(Self { id, name, visible })
      },
    }
  }
}

impl From<Group> for GroupMap {
  fn from(group: Group) -> Self {
    GroupMapBuilder::new()
      .insert_str_value("id", group.id)
      .insert_str_value("name", group.name)
      .insert_bool_value("visible", group.visible)
      .build()
  }
}

const GROUP_REV_VISIBILITY: fn() -> bool = || true;

impl Group {
  pub fn new(id: String, name: String) -> Self {
    Self {
      id,
      name,
      visible: true,
    }
  }
}

#[derive(Clone, PartialEq, Debug, Eq)]
pub struct GroupData {
  pub id: String,
  pub field_id: String,
  pub name: String,
  pub is_default: bool,
  pub is_visible: bool,
  pub(crate) rows: Vec<RowPB>,

  /// [filter_content] is used to determine which group the cell belongs to.
  pub filter_content: String,
}

impl GroupData {
  pub fn new(id: String, field_id: String, name: String, filter_content: String) -> Self {
    let is_default = id == field_id;
    Self {
      id,
      field_id,
      is_default,
      is_visible: true,
      name,
      rows: vec![],
      filter_content,
    }
  }

  pub fn contains_row(&self, row_id: &str) -> bool {
    self.rows.iter().any(|row| row.id == row_id)
  }

  pub fn remove_row(&mut self, row_id: &str) {
    match self.rows.iter().position(|row| row.id == row_id) {
      None => {},
      Some(pos) => {
        self.rows.remove(pos);
      },
    }
  }

  pub fn add_row(&mut self, row_pb: RowPB) {
    match self.rows.iter().find(|row| row.id == row_pb.id) {
      None => {
        self.rows.push(row_pb);
      },
      Some(_) => {},
    }
  }

  pub fn insert_row(&mut self, index: usize, row_pb: RowPB) {
    if index < self.rows.len() {
      self.rows.insert(index, row_pb);
    } else {
      tracing::error!(
        "Insert row index:{} beyond the bounds:{},",
        index,
        self.rows.len()
      );
    }
  }

  pub fn index_of_row(&self, row_id: &str) -> Option<usize> {
    self.rows.iter().position(|row| row.id == row_id)
  }

  pub fn number_of_row(&self) -> usize {
    self.rows.len()
  }

  pub fn is_empty(&self) -> bool {
    self.rows.is_empty()
  }
}
