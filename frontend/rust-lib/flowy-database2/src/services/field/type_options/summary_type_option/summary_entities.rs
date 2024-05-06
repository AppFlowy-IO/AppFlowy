use crate::entities::FieldType;
use crate::services::field::{TypeOptionCellData, CELL_DATA};
use collab::core::any_map::AnyMapExtension;
use collab_database::rows::{new_cell_builder, Cell};

#[derive(Default, Debug, Clone)]
pub struct SummaryCellData(pub String);
impl std::ops::Deref for SummaryCellData {
  type Target = String;

  fn deref(&self) -> &Self::Target {
    &self.0
  }
}

impl TypeOptionCellData for SummaryCellData {
  fn is_cell_empty(&self) -> bool {
    self.0.is_empty()
  }
}

impl From<&Cell> for SummaryCellData {
  fn from(cell: &Cell) -> Self {
    Self(cell.get_str_value(CELL_DATA).unwrap_or_default())
  }
}

impl From<SummaryCellData> for Cell {
  fn from(data: SummaryCellData) -> Self {
    new_cell_builder(FieldType::Summary)
      .insert_str_value(CELL_DATA, data.0)
      .build()
  }
}

impl ToString for SummaryCellData {
  fn to_string(&self) -> String {
    self.0.clone()
  }
}

impl AsRef<str> for SummaryCellData {
  fn as_ref(&self) -> &str {
    &self.0
  }
}
