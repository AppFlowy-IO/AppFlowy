use collab_database::{fields::Field, rows::Cell};

use crate::{
  entities::{MediaFilterConditionPB, MediaFilterPB},
  services::filter::PreFillCellsWithFilter,
};

impl MediaFilterPB {
  pub fn is_visible<T: AsRef<str>>(&self, cell_data: T) -> bool {
    let cell_data = cell_data.as_ref().to_lowercase();
    match self.condition {
      MediaFilterConditionPB::MediaIsEmpty => cell_data.is_empty(),
      MediaFilterConditionPB::MediaIsNotEmpty => !cell_data.is_empty(),
    }
  }
}

impl PreFillCellsWithFilter for MediaFilterPB {
  fn get_compliant_cell(&self, _field: &Field) -> Option<Cell> {
    None
  }
}
