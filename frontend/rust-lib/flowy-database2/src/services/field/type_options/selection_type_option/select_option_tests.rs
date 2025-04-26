#[cfg(test)]
mod tests {
  use crate::services::{cell::CellDataChangeset, field::SelectOptionCellChangeset};

  use collab_database::{
    entity::FieldType,
    fields::select_type_option::{
      MultiSelectTypeOption, SelectOption, SelectOptionIds, SelectTypeOption,
      SingleSelectTypeOption,
    },
  };

  #[test]
  fn empty_select_type_option_test() {
    let type_option = SingleSelectTypeOption::default();
    let google = SelectOption::new("Google");

    let (_, cell_data) = type_option
      .apply_changeset(
        SelectOptionCellChangeset::from_insert_option_id(&google.id),
        None,
      )
      .unwrap();
    assert_eq!(cell_data.into_inner(), Vec::<String>::new());

    let (_, cell_data) = type_option
      .apply_changeset(
        SelectOptionCellChangeset::from_delete_option_id(&google.id),
        None,
      )
      .unwrap();
    assert_eq!(cell_data.into_inner(), Vec::<String>::new());

    let type_option = MultiSelectTypeOption::default();

    let (_, cell_data) = type_option
      .apply_changeset(
        SelectOptionCellChangeset::from_insert_option_id(&google.id),
        None,
      )
      .unwrap();
    assert_eq!(cell_data.into_inner(), Vec::<String>::new());

    let (_, cell_data) = type_option
      .apply_changeset(
        SelectOptionCellChangeset::from_delete_option_id(&google.id),
        None,
      )
      .unwrap();
    assert_eq!(cell_data.into_inner(), Vec::<String>::new());
  }

  #[test]
  fn single_select_insert_option_test() {
    let google = SelectOption::new("Google");
    let facebook = SelectOption::new("Facebook");
    let type_option = SelectTypeOption {
      options: vec![google.clone(), facebook.clone()],
      disable_color: false,
    };
    let single_select_type_option = SingleSelectTypeOption(type_option);

    // insert a single option
    let changeset = SelectOptionCellChangeset::from_insert_options(vec![google.id.clone()]);
    let (_, select_option_ids) = single_select_type_option
      .apply_changeset(changeset, None)
      .unwrap();
    assert_eq!(select_option_ids.into_inner(), vec![google.id.clone()]);

    // insert multiple options, including an invalid one
    let changeset = SelectOptionCellChangeset::from_insert_options(vec![
      google.id.clone(),
      facebook.id.clone(),
      "".to_string(),
    ]);
    let (_, select_option_ids) = single_select_type_option
      .apply_changeset(changeset, None)
      .unwrap();
    assert_eq!(select_option_ids.into_inner(), vec![google.id.clone()]);

    // insert an option when one is already selected
    let cell = SelectOptionIds::from(vec![google.id]).to_cell(FieldType::SingleSelect);
    let changeset = SelectOptionCellChangeset::from_insert_options(vec![facebook.id.clone()]);
    let (_, select_option_ids) = single_select_type_option
      .apply_changeset(changeset, Some(cell))
      .unwrap();
    assert_eq!(select_option_ids.into_inner(), vec![facebook.id]);
  }

  #[test]
  fn multi_select_insert_option_test() {
    let amazon = SelectOption::new("Amazon");
    let google = SelectOption::new("Google");
    let facebook = SelectOption::new("Facebook");
    let type_option = SelectTypeOption {
      options: vec![amazon.clone(), google.clone(), facebook.clone()],
      disable_color: false,
    };
    let multi_select_type_option = MultiSelectTypeOption(type_option);

    // insert a single option
    let changeset = SelectOptionCellChangeset::from_insert_options(vec![google.id.clone()]);
    let (_, select_option_ids) = multi_select_type_option
      .apply_changeset(changeset, None)
      .unwrap();
    assert_eq!(select_option_ids.into_inner(), vec![google.id.clone()]);

    // insert multiple options
    let changeset = SelectOptionCellChangeset::from_insert_options(vec![
      google.id.clone(),
      facebook.id.clone(),
      "".to_string(),
    ]);
    let (_, select_option_ids) = multi_select_type_option
      .apply_changeset(changeset, None)
      .unwrap();
    assert_eq!(
      select_option_ids.into_inner(),
      vec![google.id.clone(), facebook.id.clone()]
    );

    // insert an option when one is already selected
    let cell = SelectOptionIds::from(vec![google.id.clone(), facebook.id.clone()])
      .to_cell(FieldType::MultiSelect);
    let changeset =
      SelectOptionCellChangeset::from_insert_options(vec![google.id.clone(), amazon.id.clone()]);
    let (_, select_option_ids) = multi_select_type_option
      .apply_changeset(changeset, Some(cell))
      .unwrap();
    assert_eq!(
      select_option_ids.into_inner(),
      vec![google.id, facebook.id, amazon.id]
    );
  }

  #[test]
  fn single_select_unselect_multi_option_test() {
    let google = SelectOption::new("Google");
    let facebook = SelectOption::new("Facebook");
    let single_select = SingleSelectTypeOption(SelectTypeOption {
      options: vec![google.clone(), facebook.clone()],
      disable_color: false,
    });
    let option_ids = vec![google.id.clone(), facebook.id];

    // insert
    let changeset = SelectOptionCellChangeset::from_insert_options(option_ids.clone());
    let select_option_ids = single_select.apply_changeset(changeset, None).unwrap().1;
    assert_eq!(&*select_option_ids, &vec![google.id]);

    // delete
    let changeset = SelectOptionCellChangeset::from_delete_options(option_ids);
    let select_option_ids = single_select.apply_changeset(changeset, None).unwrap().1;
    assert!(select_option_ids.is_empty());
  }

  #[test]
  fn multi_select_unselect_multi_option_test() {
    let google = SelectOption::new("Google");
    let facebook = SelectOption::new("Facebook");
    let multi_select = MultiSelectTypeOption(SelectTypeOption {
      options: vec![google.clone(), facebook.clone()],
      disable_color: false,
    });
    let option_ids = vec![google.id, facebook.id];

    // insert
    let changeset = SelectOptionCellChangeset::from_insert_options(option_ids.clone());
    let select_option_ids = multi_select.apply_changeset(changeset, None).unwrap().1;
    assert_eq!(&*select_option_ids, &option_ids);

    // delete
    let changeset = SelectOptionCellChangeset::from_delete_options(option_ids);
    let select_option_ids = multi_select.apply_changeset(changeset, None).unwrap().1;
    assert!(select_option_ids.is_empty());
  }
}
