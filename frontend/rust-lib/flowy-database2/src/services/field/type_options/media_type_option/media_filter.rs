use collab_database::{fields::Field, rows::Cell};

use crate::{
  entities::{MediaFilterConditionPB, MediaFilterPB},
  services::{cell::insert_text_cell, filter::PreFillCellsWithFilter},
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
  fn get_compliant_cell(&self, field: &Field) -> (Option<Cell>, bool) {
    let text = match self.condition {
      MediaFilterConditionPB::MediaIsNotEmpty if !self.content.is_empty() => {
        Some(self.content.clone())
      },
      _ => None,
    };

    let open_after_create = matches!(self.condition, MediaFilterConditionPB::MediaIsNotEmpty);

    (text.map(|s| insert_text_cell(s, field)), open_after_create)
  }
}
