#[cfg(test)]
mod tests {
  use chrono::format::strftime::StrftimeItems;
  use chrono::{FixedOffset, NaiveDateTime};
  use collab_database::fields::Field;
  use collab_database::rows::Cell;
  use strum::IntoEnumIterator;

  use crate::entities::FieldType;
  use crate::services::cell::{CellDataChangeset, CellDataDecoder};
  use crate::services::field::{
    DateCellChangeset, DateFormat, DateTypeOption, FieldBuilder, TimeFormat, TypeOptionCellData,
  };

  #[test]
  fn date_type_option_date_format_test() {
    let mut type_option = DateTypeOption::test();
    let field = FieldBuilder::from_field_type(FieldType::DateTime).build();
    for date_format in DateFormat::iter() {
      type_option.date_format = date_format;
      match date_format {
        DateFormat::Friendly => {
          assert_date(
            &type_option,
            &field,
            DateCellChangeset {
              date: Some("1647251762".to_owned()),
              time: None,
              include_time: None,
            },
            None,
            "Mar 14, 2022",
          );
        },
        DateFormat::US => {
          assert_date(
            &type_option,
            &field,
            DateCellChangeset {
              date: Some("1647251762".to_owned()),
              time: None,
              include_time: None,
            },
            None,
            "2022/03/14",
          );
        },
        DateFormat::ISO => {
          assert_date(
            &type_option,
            &field,
            DateCellChangeset {
              date: Some("1647251762".to_owned()),
              time: None,
              include_time: None,
            },
            None,
            "2022-03-14",
          );
        },
        DateFormat::Local => {
          assert_date(
            &type_option,
            &field,
            DateCellChangeset {
              date: Some("1647251762".to_owned()),
              time: None,
              include_time: None,
            },
            None,
            "03/14/2022",
          );
        },
        DateFormat::DayMonthYear => {
          assert_date(
            &type_option,
            &field,
            DateCellChangeset {
              date: Some("1647251762".to_owned()),
              time: None,
              include_time: None,
            },
            None,
            "14/03/2022",
          );
        },
      }
    }
  }

  #[test]
  fn date_type_option_different_time_format_test() {
    let mut type_option = DateTypeOption::test();
    let field = FieldBuilder::from_field_type(FieldType::DateTime).build();

    for time_format in TimeFormat::iter() {
      type_option.time_format = time_format;
      match time_format {
        TimeFormat::TwentyFourHour => {
          assert_date(
            &type_option,
            &field,
            DateCellChangeset {
              date: Some("1653609600".to_owned()),
              time: None,
              include_time: Some(true),
            },
            None,
            "May 27, 2022 00:00",
          );
          assert_date(
            &type_option,
            &field,
            DateCellChangeset {
              date: Some("1653609600".to_owned()),
              time: Some("9:00".to_owned()),
              include_time: Some(true),
            },
            None,
            "May 27, 2022 09:00",
          );
          assert_date(
            &type_option,
            &field,
            DateCellChangeset {
              date: Some("1653609600".to_owned()),
              time: Some("23:00".to_owned()),
              include_time: Some(true),
            },
            None,
            "May 27, 2022 23:00",
          );
        },
        TimeFormat::TwelveHour => {
          assert_date(
            &type_option,
            &field,
            DateCellChangeset {
              date: Some("1653609600".to_owned()),
              time: None,
              include_time: Some(true),
            },
            None,
            "May 27, 2022 12:00 AM",
          );
          assert_date(
            &type_option,
            &field,
            DateCellChangeset {
              date: Some("1653609600".to_owned()),
              time: Some("9:00 AM".to_owned()),
              include_time: Some(true),
            },
            None,
            "May 27, 2022 09:00 AM",
          );
          assert_date(
            &type_option,
            &field,
            DateCellChangeset {
              date: Some("1653609600".to_owned()),
              time: Some("11:23 pm".to_owned()),
              include_time: Some(true),
            },
            None,
            "May 27, 2022 11:23 PM",
          );
        },
      }
    }
  }

  #[test]
  fn date_type_option_invalid_date_str_test() {
    let field_type = FieldType::DateTime;
    let type_option = DateTypeOption::test();
    let field = FieldBuilder::from_field_type(field_type).build();
    assert_date(
      &type_option,
      &field,
      DateCellChangeset {
        date: Some("abc".to_owned()),
        time: None,
        include_time: None,
      },
      None,
      "",
    );
  }

  #[test]
  #[should_panic]
  fn date_type_option_invalid_include_time_str_test() {
    let field_type = FieldType::DateTime;
    let type_option = DateTypeOption::test();
    let field = FieldBuilder::from_field_type(field_type).build();

    assert_date(
      &type_option,
      &field,
      DateCellChangeset {
        date: Some("1653609600".to_owned()),
        time: Some("1:".to_owned()),
        include_time: Some(true),
      },
      None,
      "May 27, 2022 01:00",
    );
  }

  #[test]
  #[should_panic]
  fn date_type_option_empty_include_time_str_test() {
    let field_type = FieldType::DateTime;
    let type_option = DateTypeOption::test();
    let field = FieldBuilder::from_field_type(field_type).build();

    assert_date(
      &type_option,
      &field,
      DateCellChangeset {
        date: Some("1653609600".to_owned()),
        time: Some("".to_owned()),
        include_time: Some(true),
      },
      None,
      "May 27, 2022 01:00",
    );
  }

  #[test]
  fn date_type_midnight_include_time_str_test() {
    let field_type = FieldType::DateTime;
    let type_option = DateTypeOption::test();
    let field = FieldBuilder::from_field_type(field_type).build();
    assert_date(
      &type_option,
      &field,
      DateCellChangeset {
        date: Some("1653609600".to_owned()),
        time: Some("00:00".to_owned()),
        include_time: Some(true),
      },
      None,
      "May 27, 2022 00:00",
    );
  }

  /// The default time format is TwentyFourHour, so the include_time_str in
  /// twelve_hours_format will cause parser error.
  #[test]
  #[should_panic]
  fn date_type_option_twelve_hours_include_time_str_in_twenty_four_hours_format() {
    let type_option = DateTypeOption::test();
    let field = FieldBuilder::from_field_type(FieldType::DateTime).build();
    assert_date(
      &type_option,
      &field,
      DateCellChangeset {
        date: Some("1653609600".to_owned()),
        time: Some("1:00 am".to_owned()),
        include_time: Some(true),
      },
      None,
      "May 27, 2022 01:00 AM",
    );
  }

  /// Attempting to parse include_time_str as TwelveHour when TwentyFourHour
  /// format is given should cause parser error.
  #[test]
  #[should_panic]
  fn date_type_option_twenty_four_hours_include_time_str_in_twelve_hours_format() {
    let field_type = FieldType::DateTime;
    let mut type_option = DateTypeOption::test();
    type_option.time_format = TimeFormat::TwelveHour;
    let field = FieldBuilder::from_field_type(field_type).build();

    assert_date(
      &type_option,
      &field,
      DateCellChangeset {
        date: Some("1653609600".to_owned()),
        time: Some("20:00".to_owned()),
        include_time: Some(true),
      },
      None,
      "May 27, 2022 08:00 PM",
    );
  }

  #[test]
  fn utc_to_native_test() {
    let native_timestamp = 1647251762;
    let native = NaiveDateTime::from_timestamp_opt(native_timestamp, 0).unwrap();

    let utc = chrono::DateTime::<chrono::Utc>::from_utc(native, chrono::Utc);
    // utc_timestamp doesn't  carry timezone
    let utc_timestamp = utc.timestamp();
    assert_eq!(native_timestamp, utc_timestamp);

    let format = "%m/%d/%Y %I:%M %p".to_string();
    let native_time_str = format!("{}", native.format_with_items(StrftimeItems::new(&format)));
    let utc_time_str = format!("{}", utc.format_with_items(StrftimeItems::new(&format)));
    assert_eq!(native_time_str, utc_time_str);

    // Mon Mar 14 2022 17:56:02 GMT+0800 (China Standard Time)
    let gmt_8_offset = FixedOffset::east_opt(8 * 3600).unwrap();
    let china_local = chrono::DateTime::<chrono::Local>::from_utc(native, gmt_8_offset);
    let china_local_time = format!(
      "{}",
      china_local.format_with_items(StrftimeItems::new(&format))
    );

    assert_eq!(china_local_time, "03/14/2022 05:56 PM");
  }

  /// The time component shouldn't remain the same since the timestamp is
  /// completely overwritten. To achieve the desired result, also pass in the
  /// time string along with the new timestamp.
  #[test]
  #[should_panic]
  fn update_date_keep_time() {
    let type_option = DateTypeOption::test();
    let field = FieldBuilder::from_field_type(FieldType::DateTime).build();

    let old_cell_data = initialize_date_cell(
      &type_option,
      DateCellChangeset {
        date: Some("1700006400".to_owned()),
        time: Some("08:00".to_owned()),
        include_time: Some(true),
      },
    );
    assert_date(
      &type_option,
      &field,
      DateCellChangeset {
        date: Some("1701302400".to_owned()),
        time: None,
        include_time: None,
      },
      Some(old_cell_data),
      "Nov 30, 2023 08:00",
    );
  }

  #[test]
  fn update_time_keep_date() {
    let type_option = DateTypeOption::test();
    let field = FieldBuilder::from_field_type(FieldType::DateTime).build();

    let old_cell_data = initialize_date_cell(
      &type_option,
      DateCellChangeset {
        date: Some("1700006400".to_owned()),
        time: Some("08:00".to_owned()),
        include_time: Some(true),
      },
    );
    assert_date(
      &type_option,
      &field,
      DateCellChangeset {
        date: None,
        time: Some("14:00".to_owned()),
        include_time: None,
      },
      Some(old_cell_data),
      "Nov 15, 2023 14:00",
    );
  }

  fn assert_date(
    type_option: &DateTypeOption,
    field: &Field,
    changeset: DateCellChangeset,
    old_cell_data: Option<Cell>,
    expected_str: &str,
  ) {
    let (cell, cell_data) = type_option
      .apply_changeset(changeset, old_cell_data)
      .unwrap();

    assert_eq!(
      decode_cell_data(&cell, type_option, cell_data.include_time, field),
      expected_str,
    );
  }

  fn decode_cell_data(
    cell: &Cell,
    type_option: &DateTypeOption,
    include_time: bool,
    field: &Field,
  ) -> String {
    let decoded_data = type_option
      .decode_cell(cell, &FieldType::DateTime, field)
      .unwrap();
    let decoded_data = type_option.protobuf_encode(decoded_data);
    if include_time {
      format!("{} {}", decoded_data.date, decoded_data.time)
        .trim_end()
        .to_owned()
    } else {
      decoded_data.date
    }
  }

  fn initialize_date_cell(type_option: &DateTypeOption, changeset: DateCellChangeset) -> Cell {
    let (cell, _) = type_option.apply_changeset(changeset, None).unwrap();
    cell
  }
}
