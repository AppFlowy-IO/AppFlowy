use crate::entities::FieldType;
use crate::services::field::{TypeOptionCellData, CELL_DATA};
use collab::core::any_map::AnyMapExtension;
use collab_database::rows::{new_cell_builder, Cell};

#[derive(Clone, Debug, Default)]
pub struct TimerCellData(pub Option<i64>);

impl TypeOptionCellData for TimerCellData {
  fn is_cell_empty(&self) -> bool {
    self.0.is_none()
  }
}

impl From<&Cell> for TimerCellData {
  fn from(cell: &Cell) -> Self {
    Self(
      cell
        .get_str_value(CELL_DATA)
        .and_then(|data| data.parse::<i64>().ok()),
    )
  }
}

impl std::convert::From<String> for TimerCellData {
  fn from(s: String) -> Self {
    Self(s.trim().to_string().parse::<i64>().ok())
  }
}

impl ToString for TimerCellData {
  fn to_string(&self) -> String {
    if let Some(minutes) = self.0 {
      minutes.to_string()
    } else {
      "".to_string()
    }
  }
}

impl From<&TimerCellData> for Cell {
  fn from(data: &TimerCellData) -> Self {
    new_cell_builder(FieldType::Timer)
      .insert_str_value(CELL_DATA, data.to_string())
      .build()
  }
}
