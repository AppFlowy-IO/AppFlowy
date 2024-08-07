use crate::entities::FieldType;
use crate::services::field::{TypeOptionCellData, CELL_DATA};
use collab::util::AnyMapExt;
use collab_database::rows::{new_cell_builder, Cell};

#[derive(Default, Debug, Clone)]
pub struct TranslateCellData(pub String);
impl std::ops::Deref for TranslateCellData {
  type Target = String;

  fn deref(&self) -> &Self::Target {
    &self.0
  }
}

impl TypeOptionCellData for TranslateCellData {
  fn is_cell_empty(&self) -> bool {
    self.0.is_empty()
  }
}

impl From<&Cell> for TranslateCellData {
  fn from(cell: &Cell) -> Self {
    Self(cell.get_as(CELL_DATA).unwrap_or_default())
  }
}

impl From<TranslateCellData> for Cell {
  fn from(data: TranslateCellData) -> Self {
    let mut cell = new_cell_builder(FieldType::Translate);
    cell.insert(CELL_DATA.into(), data.0.into());
    cell
  }
}

impl ToString for TranslateCellData {
  fn to_string(&self) -> String {
    self.0.clone()
  }
}

impl AsRef<str> for TranslateCellData {
  fn as_ref(&self) -> &str {
    &self.0
  }
}
