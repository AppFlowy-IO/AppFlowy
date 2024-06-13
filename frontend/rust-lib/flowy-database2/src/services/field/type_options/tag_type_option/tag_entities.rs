use crate::entities::FieldType;
use crate::services::field::{TypeOptionCellData, CELL_DATA};
use collab::core::any_map::AnyMapExtension;
use collab_database::rows::{new_cell_builder, Cell};

#[derive(Default, Debug, Clone)]
pub struct TagCellData(pub String);
impl std::ops::Deref for TagCellData {
  type Target = String;

  fn deref(&self) -> &Self::Target {
    &self.0
  }
}

impl TypeOptionCellData for TagCellData {
  fn is_cell_empty(&self) -> bool {
    self.0.is_empty()
  }
}

impl From<&Cell> for TagCellData {
  fn from(cell: &Cell) -> Self {
    Self(cell.get_str_value(CELL_DATA).unwrap_or_default())
  }
}

impl From<TagCellData> for Cell {
  fn from(data: TagCellData) -> Self {
    new_cell_builder(FieldType::Tag)
      .insert_str_value(CELL_DATA, data.0)
      .build()
  }
}

impl ToString for TagCellData {
  fn to_string(&self) -> String {
    self.0.clone()
  }
}

impl AsRef<str> for TagCellData {
  fn as_ref(&self) -> &str {
    &self.0
  }
}
