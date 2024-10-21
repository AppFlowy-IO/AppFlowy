#[cfg(test)]
mod tests {
  use collab_database::rows::Cell;

  use crate::services::cell::{CellDataChangeset, CellDataDecoder};
  use crate::services::field::DateCellChangeset;
  use collab_database::fields::date_type_option::{DateCellData, DateTypeOption};

  #[test]
  fn apply_changeset_to_empty_cell() {
    let type_option = DateTypeOption::default_utc();

    assert_date(
      &type_option,
      DateCellChangeset {
        timestamp: Some(1653782400),
        include_time: Some(true),
        ..Default::default()
      },
      None,
      &DateCellData {
        timestamp: Some(1653782400),
        include_time: true,
        ..Default::default()
      },
    );

    assert_date(
      &type_option,
      DateCellChangeset {
        timestamp: Some(1625130000),
        end_timestamp: Some(1653782400),
        is_range: Some(true),
        ..Default::default()
      },
      None,
      &DateCellData {
        timestamp: Some(1625130000),
        end_timestamp: Some(1653782400),
        is_range: true,
        ..Default::default()
      },
    );
  }

  #[test]
  fn apply_changeset_to_exsiting_cell() {
    let type_option = DateTypeOption::default_utc();

    let date_cell = initialize_date_cell(
      &type_option,
      DateCellChangeset {
        timestamp: Some(1653782400),
        ..Default::default()
      },
    );
    assert_date(
      &type_option,
      DateCellChangeset {
        timestamp: Some(1625130000),
        ..Default::default()
      },
      Some(date_cell.clone()),
      &DateCellData {
        timestamp: Some(1625130000),
        ..Default::default()
      },
    );

    let date_cell = initialize_date_cell(
      &type_option,
      DateCellChangeset {
        timestamp: Some(1653782400),
        ..Default::default()
      },
    );
    assert_date(
      &type_option,
      DateCellChangeset {
        timestamp: Some(1653782400),
        include_time: Some(true),
        ..Default::default()
      },
      Some(date_cell.clone()),
      &DateCellData {
        timestamp: Some(1653782400),
        include_time: true,
        ..Default::default()
      },
    );

    let date_cell = initialize_date_cell(
      &type_option,
      DateCellChangeset {
        timestamp: Some(1653782400),
        end_timestamp: Some(1653782400),
        is_range: Some(true),
        ..Default::default()
      },
    );
    assert_date(
      &type_option,
      DateCellChangeset {
        timestamp: Some(1625130000),
        end_timestamp: Some(1625130000),
        ..Default::default()
      },
      Some(date_cell.clone()),
      &DateCellData {
        timestamp: Some(1625130000),
        end_timestamp: Some(1625130000),
        is_range: true,
        ..Default::default()
      },
    );

    let date_cell = initialize_date_cell(
      &type_option,
      DateCellChangeset {
        timestamp: Some(1653782400),
        end_timestamp: Some(1653782400),
        is_range: Some(true),
        ..Default::default()
      },
    );
    assert_date(
      &type_option,
      DateCellChangeset {
        is_range: Some(false),
        ..Default::default()
      },
      Some(date_cell.clone()),
      &DateCellData {
        timestamp: Some(1653782400),
        is_range: false,
        ..Default::default()
      },
    );
  }

  #[test]
  fn apply_invalid_changeset_to_empty_cell() {
    let type_option = DateTypeOption::default_utc();

    assert_date(
      &type_option,
      DateCellChangeset {
        timestamp: Some(1653782400),
        end_timestamp: Some(1653782400),
        is_range: Some(false),
        ..Default::default()
      },
      None,
      &DateCellData::default(),
    );

    assert_date(
      &type_option,
      DateCellChangeset {
        timestamp: None,
        end_timestamp: Some(1653782400),
        is_range: Some(true),
        ..Default::default()
      },
      None,
      &DateCellData::default(),
    );
  }

  #[test]
  fn apply_invalid_changeset_to_existing_cell() {
    let type_option = DateTypeOption::default_utc();

    // is_range is false but a date range is passed in
    let date_cell = initialize_date_cell(
      &type_option,
      DateCellChangeset {
        timestamp: Some(1653782400),
        is_range: Some(false),
        ..Default::default()
      },
    );
    assert_date(
      &type_option,
      DateCellChangeset {
        timestamp: Some(1653782400),
        end_timestamp: Some(1653782400),
        ..Default::default()
      },
      Some(date_cell.clone()),
      &decode_cell_data(&date_cell, &type_option),
    );

    // is_range is true but either the start or end is missing
    let date_cell = initialize_date_cell(
      &type_option,
      DateCellChangeset {
        timestamp: Some(1653782400),
        end_timestamp: Some(1653782400),
        is_range: Some(false),
        ..Default::default()
      },
    );
    assert_date(
      &type_option,
      DateCellChangeset {
        timestamp: None,
        end_timestamp: Some(1653782400),
        ..Default::default()
      },
      Some(date_cell.clone()),
      &decode_cell_data(&date_cell, &type_option),
    );
  }

  fn assert_date(
    type_option: &DateTypeOption,
    changeset: DateCellChangeset,
    old_cell_data: Option<Cell>,
    expected: &DateCellData,
  ) {
    let (cell, _) = type_option
      .apply_changeset(changeset, old_cell_data)
      .unwrap();

    let actual = decode_cell_data(&cell, type_option);

    assert_eq!(expected.timestamp, actual.timestamp);
    assert_eq!(expected.end_timestamp, actual.end_timestamp);
    assert_eq!(expected.include_time, actual.include_time);
    assert_eq!(expected.is_range, actual.is_range);
  }

  fn decode_cell_data(cell: &Cell, type_option: &DateTypeOption) -> DateCellData {
    type_option.decode_cell(cell).unwrap()
  }

  fn initialize_date_cell(type_option: &DateTypeOption, changeset: DateCellChangeset) -> Cell {
    let (cell, _) = type_option.apply_changeset(changeset, None).unwrap();
    cell
  }
}
