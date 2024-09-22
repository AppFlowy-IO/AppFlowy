use crate::entities::{FieldType, SelectOptionCellDataPB, SelectOptionFilterPB};
use crate::services::cell::CellDataChangeset;
use crate::services::field::{
  default_order, MultiSelectTypeOption, TypeOption, TypeOptionCellDataCompare,
  TypeOptionCellDataFilter, TypeOptionCellDataSerde,
};
use crate::services::field::{
  SelectOptionCellChangeset, SelectOptionIds, SelectTypeOptionSharedAction,
};
use crate::services::sort::SortCondition;
use collab::util::AnyMapExt;
use collab_database::fields::select_type_option::{SelectOption, SelectTypeOption};
use collab_database::fields::{TypeOptionData, TypeOptionDataBuilder};
use collab_database::rows::Cell;
use flowy_error::FlowyResult;
use serde::{Deserialize, Serialize};
use std::cmp::Ordering;
use std::ops::{Deref, DerefMut};
// Single select

#[derive(Clone, Default, Debug)]
pub struct SingleSelectTypeOption(pub SelectTypeOption);

impl Deref for SingleSelectTypeOption {
  type Target = SelectTypeOption;

  fn deref(&self) -> &Self::Target {
    &self.0
  }
}

impl DerefMut for SingleSelectTypeOption {
  fn deref_mut(&mut self) -> &mut Self::Target {
    &mut self.0
  }
}

impl From<TypeOptionData> for SingleSelectTypeOption {
  fn from(data: TypeOptionData) -> Self {
    SingleSelectTypeOption(SelectTypeOption::from(data))
  }
}

impl From<SingleSelectTypeOption> for TypeOptionData {
  fn from(data: SingleSelectTypeOption) -> Self {
    data.0.into()
  }
}

impl TypeOption for SingleSelectTypeOption {
  type CellData = SelectOptionIds;
  type CellChangeset = SelectOptionCellChangeset;
  type CellProtobufType = SelectOptionCellDataPB;
  type CellFilter = SelectOptionFilterPB;
}

impl TypeOptionCellDataSerde for SingleSelectTypeOption {
  fn protobuf_encode(
    &self,
    cell_data: <Self as TypeOption>::CellData,
  ) -> <Self as TypeOption>::CellProtobufType {
    self.get_selected_options(cell_data).into()
  }

  fn parse_cell(&self, cell: &Cell) -> FlowyResult<<Self as TypeOption>::CellData> {
    Ok(SelectOptionIds::from(cell))
  }
}

impl SelectTypeOptionSharedAction for SingleSelectTypeOption {
  fn number_of_max_options(&self) -> Option<usize> {
    Some(1)
  }

  fn to_type_option_data(&self) -> TypeOptionData {
    self.clone().into()
  }

  fn options(&self) -> &Vec<SelectOption> {
    &self.options
  }

  fn mut_options(&mut self) -> &mut Vec<SelectOption> {
    &mut self.options
  }
}

impl CellDataChangeset for SingleSelectTypeOption {
  fn apply_changeset(
    &self,
    changeset: <Self as TypeOption>::CellChangeset,
    _cell: Option<Cell>,
  ) -> FlowyResult<(Cell, <Self as TypeOption>::CellData)> {
    let mut insert_option_ids = changeset
      .insert_option_ids
      .into_iter()
      .filter(|insert_option_id| {
        self
          .options
          .iter()
          .any(|option| &option.id == insert_option_id)
      })
      .collect::<Vec<String>>();

    // In single select, the insert_option_ids should only contain one select option id.
    // Sometimes, the insert_option_ids may contain list of option ids. For example,
    // copy/paste a ids string.
    let select_option_ids = if insert_option_ids.is_empty() {
      SelectOptionIds::from(insert_option_ids)
    } else {
      // Just take the first select option
      let _ = insert_option_ids.drain(1..);
      SelectOptionIds::from(insert_option_ids)
    };
    Ok((
      select_option_ids.to_cell_data(FieldType::SingleSelect),
      select_option_ids,
    ))
  }
}

impl TypeOptionCellDataFilter for SingleSelectTypeOption {
  fn apply_filter(
    &self,
    filter: &<Self as TypeOption>::CellFilter,
    cell_data: &<Self as TypeOption>::CellData,
  ) -> bool {
    let selected_options = self.get_selected_options(cell_data.clone()).select_options;
    filter.is_visible(&selected_options).unwrap_or(true)
  }
}

impl TypeOptionCellDataCompare for SingleSelectTypeOption {
  fn apply_cmp(
    &self,
    cell_data: &<Self as TypeOption>::CellData,
    other_cell_data: &<Self as TypeOption>::CellData,
    sort_condition: SortCondition,
  ) -> Ordering {
    match (
      cell_data
        .first()
        .and_then(|id| self.options.iter().find(|option| &option.id == id)),
      other_cell_data
        .first()
        .and_then(|id| self.options.iter().find(|option| &option.id == id)),
    ) {
      (Some(left), Some(right)) => {
        let order = left.name.cmp(&right.name);
        sort_condition.evaluate_order(order)
      },
      (Some(_), None) => Ordering::Less,
      (None, Some(_)) => Ordering::Greater,
      (None, None) => default_order(),
    }
  }
}

#[cfg(test)]
mod tests {
  use crate::services::cell::CellDataChangeset;
  use crate::services::field::type_options::*;
  use collab_database::fields::select_type_option::SelectOption;

  #[test]
  fn single_select_insert_multi_option_test() {
    let google = SelectOption::new("Google");
    let facebook = SelectOption::new("Facebook");
    let single_select = SelectTypeOption {
      options: vec![google.clone(), facebook.clone()],
      disable_color: false,
    };

    let option_ids = vec![google.id.clone(), facebook.id];
    let changeset = SelectOptionCellChangeset::from_insert_options(option_ids);
    let select_option_ids = single_select.apply_changeset(changeset, None).unwrap().1;
    assert_eq!(&*select_option_ids, &vec![google.id]);
  }

  #[test]
  fn single_select_unselect_multi_option_test() {
    let google = SelectOption::new("Google");
    let facebook = SelectOption::new("Facebook");
    let single_select = SelectTypeOption {
      options: vec![google.clone(), facebook.clone()],
      disable_color: false,
    };
    let option_ids = vec![google.id.clone(), facebook.id];

    // insert
    let changeset = SelectOptionCellChangeset::from_insert_options(option_ids.clone());
    let select_option_ids = single_select.apply_changeset(changeset, None).unwrap().1;
    assert_eq!(&*select_option_ids, &vec![google.id]);

    // delete
    let changeset = SelectOptionCellChangeset::from_delete_options(option_ids);
    let select_option_ids = single_select.apply_changeset(changeset, None).unwrap().1;
    assert!(select_option_ids.is_cell_empty());
  }
}
