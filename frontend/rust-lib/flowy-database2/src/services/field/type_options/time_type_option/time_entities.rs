use crate::entities::FieldType;
use crate::services::field::{TypeOptionCellData, CELL_DATA};
use collab::util::AnyMapExt;
use collab_database::rows::{new_cell_builder, Cell};

#[derive(Clone, Debug, Default)]
pub struct TimeCellData(pub Option<i64>);

impl TypeOptionCellData for TimeCellData {
  fn is_cell_empty(&self) -> bool {
    self.0.is_none()
  }
}

impl From<&Cell> for TimeCellData {
  fn from(cell: &Cell) -> Self {
    Self(
      cell
        .get_as::<String>(CELL_DATA)
        .and_then(|data| data.parse::<i64>().ok()),
    )
  }
}

impl std::convert::From<String> for TimeCellData {
  fn from(s: String) -> Self {
    Self(s.trim().to_string().parse::<i64>().ok())
  }
}

impl ToString for TimeCellData {
  fn to_string(&self) -> String {
    if let Some(time) = self.0 {
      time.to_string()
    } else {
      "".to_string()
    }
  }
}

impl From<&TimeCellData> for Cell {
  fn from(data: &TimeCellData) -> Self {
    let mut cell = new_cell_builder(FieldType::Time);
    cell.insert(CELL_DATA.into(), data.to_string().into());
    cell
  }
}
