use crate::entities::{ChecklistCellDataPB, ChecklistFilterPB, FieldType, SelectOptionPB};
use crate::services::cell::{CellDataChangeset, CellDataDecoder};
use crate::services::field::checklist_type_option::{ChecklistCellChangeset, ChecklistCellData};
use crate::services::field::{
  SelectOption, TypeOption, TypeOptionCellData, TypeOptionCellDataCompare,
  TypeOptionCellDataFilter, TypeOptionTransform, SELECTION_IDS_SEPARATOR,
};
use collab_database::fields::{Field, TypeOptionData, TypeOptionDataBuilder};
use collab_database::rows::Cell;
use flowy_error::FlowyResult;
use std::cmp::Ordering;

#[derive(Debug, Clone, Default)]
pub struct ChecklistTypeOption;

impl TypeOption for ChecklistTypeOption {
  type CellData = ChecklistCellData;
  type CellChangeset = ChecklistCellChangeset;
  type CellProtobufType = ChecklistCellDataPB;
  type CellFilter = ChecklistFilterPB;
}

impl From<TypeOptionData> for ChecklistTypeOption {
  fn from(_data: TypeOptionData) -> Self {
    Self
  }
}

impl From<ChecklistTypeOption> for TypeOptionData {
  fn from(_data: ChecklistTypeOption) -> Self {
    TypeOptionDataBuilder::new().build()
  }
}

impl TypeOptionCellData for ChecklistTypeOption {
  fn protobuf_encode(
    &self,
    cell_data: <Self as TypeOption>::CellData,
  ) -> <Self as TypeOption>::CellProtobufType {
    let percentage = cell_data.percentage_complete();
    let selected_options = cell_data
      .options
      .iter()
      .filter(|option| cell_data.selected_option_ids.contains(&option.id))
      .map(|option| SelectOptionPB::from(option.clone()))
      .collect();

    let options = cell_data
      .options
      .into_iter()
      .map(SelectOptionPB::from)
      .collect();

    ChecklistCellDataPB {
      options,
      selected_options,
      percentage,
    }
  }

  fn parse_cell(&self, cell: &Cell) -> FlowyResult<<Self as TypeOption>::CellData> {
    Ok(ChecklistCellData::from(cell))
  }
}

impl CellDataChangeset for ChecklistTypeOption {
  fn apply_changeset(
    &self,
    changeset: <Self as TypeOption>::CellChangeset,
    cell: Option<Cell>,
  ) -> FlowyResult<(Cell, <Self as TypeOption>::CellData)> {
    match cell {
      Some(cell) => {
        let mut cell_data = self.parse_cell(&cell)?;
        update_cell_data_with_changeset(&mut cell_data, changeset);
        Ok((Cell::from(cell_data.clone()), cell_data))
      },
      None => {
        let cell_data = ChecklistCellData::from_options(changeset.insert_options);
        Ok((Cell::from(cell_data.clone()), cell_data))
      },
    }
  }
}

#[inline]
fn update_cell_data_with_changeset(
  cell_data: &mut ChecklistCellData,
  mut changeset: ChecklistCellChangeset,
) {
  // Delete the options
  cell_data
    .options
    .retain(|option| !changeset.delete_option_ids.contains(&option.id));
  cell_data
    .selected_option_ids
    .retain(|option_id| !changeset.delete_option_ids.contains(option_id));

  // Insert new options
  changeset.insert_options.retain(|option_name| {
    !cell_data
      .options
      .iter()
      .any(|option| option.name == *option_name)
  });
  changeset
    .insert_options
    .into_iter()
    .for_each(|option_name| {
      let option = SelectOption::new(&option_name);
      cell_data.options.push(option);
    });

  // Update options
  changeset
    .update_options
    .into_iter()
    .for_each(|updated_option| {
      if let Some(option) = cell_data
        .options
        .iter_mut()
        .find(|option| option.id == updated_option.id)
      {
        option.name = updated_option.name;
      }
    });

  // Select the options
  changeset
    .selected_option_ids
    .into_iter()
    .for_each(|option_id| {
      if let Some(index) = cell_data
        .selected_option_ids
        .iter()
        .position(|id| **id == option_id)
      {
        cell_data.selected_option_ids.remove(index);
      } else {
        cell_data.selected_option_ids.push(option_id);
      }
    });
}

impl CellDataDecoder for ChecklistTypeOption {
  fn decode_cell(
    &self,
    cell: &Cell,
    decoded_field_type: &FieldType,
    _field: &Field,
  ) -> FlowyResult<<Self as TypeOption>::CellData> {
    if !decoded_field_type.is_checklist() {
      return Ok(Default::default());
    }

    self.parse_cell(cell)
  }

  fn stringify_cell_data(&self, cell_data: <Self as TypeOption>::CellData) -> String {
    cell_data
      .selected_options()
      .into_iter()
      .map(|option| option.name)
      .collect::<Vec<_>>()
      .join(SELECTION_IDS_SEPARATOR)
  }

  fn stringify_cell(&self, cell: &Cell) -> String {
    let cell_data = self.parse_cell(cell).unwrap_or_default();
    self.stringify_cell_data(cell_data)
  }
}

impl TypeOptionCellDataFilter for ChecklistTypeOption {
  fn apply_filter(
    &self,
    filter: &<Self as TypeOption>::CellFilter,
    field_type: &FieldType,
    cell_data: &<Self as TypeOption>::CellData,
  ) -> bool {
    if !field_type.is_checklist() {
      return true;
    }
    let selected_options = cell_data.selected_options();
    filter.is_visible(&cell_data.options, &selected_options)
  }
}

impl TypeOptionCellDataCompare for ChecklistTypeOption {
  fn apply_cmp(
    &self,
    cell_data: &<Self as TypeOption>::CellData,
    other_cell_data: &<Self as TypeOption>::CellData,
  ) -> Ordering {
    let left = cell_data.percentage_complete();
    let right = other_cell_data.percentage_complete();
    if left > right {
      Ordering::Greater
    } else if left < right {
      Ordering::Less
    } else {
      Ordering::Equal
    }
  }
}

impl TypeOptionTransform for ChecklistTypeOption {}
