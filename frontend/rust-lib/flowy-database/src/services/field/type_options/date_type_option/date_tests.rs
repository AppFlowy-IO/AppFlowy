#[cfg(test)]
mod tests {
  use crate::entities::FieldType;
  use crate::services::cell::{CellDataChangeset, CellDataDecoder};

  use crate::services::field::{
    DateCellChangeset, DateFormat, DateTypeOptionPB, FieldBuilder, TimeFormat, TypeOptionCellData,
  };
  use chrono::format::strftime::StrftimeItems;
  use chrono::{FixedOffset, NaiveDateTime};
  use database_model::FieldRevision;
  use strum::IntoEnumIterator;

  #[test]
  fn date_type_option_date_format_test() {
    let mut type_option = DateTypeOptionPB::default();
    let field_rev = FieldBuilder::from_field_type(&FieldType::DateTime).build();
    for date_format in DateFormat::iter() {
      type_option.date_format = date_format;
      match date_format {
        DateFormat::Friendly => {
          assert_date(
            &type_option,
            1647251762,
            None,
            "Mar 14, 2022",
            false,
            &field_rev,
          );
        },
        DateFormat::US => {
          assert_date(
            &type_option,
            1647251762,
            None,
            "2022/03/14",
            false,
            &field_rev,
          );
        },
        DateFormat::ISO => {
          assert_date(
            &type_option,
            1647251762,
            None,
            "2022-03-14",
            false,
            &field_rev,
          );
        },
        DateFormat::Local => {
          assert_date(
            &type_option,
            1647251762,
            None,
            "03/14/2022",
            false,
            &field_rev,
          );
        },
        DateFormat::DayMonthYear => {
          assert_date(
            &type_option,
            1647251762,
            None,
            "14/03/2022",
            false,
            &field_rev,
          );
        },
      }
    }
  }

  // #[test]
  // fn date_type_option_different_time_format_test() {
  //   let mut type_option = DateTypeOptionPB::default();
  //   let field_type = FieldType::DateTime;
  //   let field_rev = FieldBuilder::from_field_type(&field_type).build();
  //
  //   for time_format in TimeFormat::iter() {
  //     type_option.time_format = time_format;
  //     match time_format {
  //       TimeFormat::TwentyFourHour => {
  //         assert_date(
  //           &type_option,
  //           1653609600,
  //           None,
  //           "May 27,2022 00:00",
  //           true,
  //           &field_rev,
  //         );
  //         assert_date(
  //           &type_option,
  //           1653609600,
  //           Some("9:00".to_owned()),
  //           "May 27,2022 09:00",
  //           true,
  //           &field_rev,
  //         );
  //         assert_date(
  //           &type_option,
  //           1653609600,
  //           Some("23:00".to_owned()),
  //           "May 27,2022 23:00",
  //           true,
  //           &field_rev,
  //         );
  //       },
  //       TimeFormat::TwelveHour => {
  //         assert_date(
  //           &type_option,
  //           1653609600,
  //           None,
  //           "May 27,2022 12:00 AM",
  //           true,
  //           &field_rev,
  //         );
  //         assert_date(
  //           &type_option,
  //           1653609600,
  //           Some("9:00 AM".to_owned()),
  //           "May 27,2022 09:00 AM",
  //           true,
  //           &field_rev,
  //         );
  //         assert_date(
  //           &type_option,
  //           1653609600,
  //           Some("11:23 pm".to_owned()),
  //           "May 27,2022 11:23 PM",
  //           true,
  //           &field_rev,
  //         );
  //       },
  //     }
  //   }
  // }

  #[test]
  fn date_type_option_invalid_date_str_test() {
    let type_option = DateTypeOptionPB::default();
    let field_type = FieldType::DateTime;
    let field_rev = FieldBuilder::from_field_type(&field_type).build();
    assert_date(&type_option, "abc", None, "", false, &field_rev);
  }

  #[test]
  #[should_panic]
  fn date_type_option_invalid_include_time_str_test() {
    let type_option = DateTypeOptionPB::new();
    let field_rev = FieldBuilder::from_field_type(&FieldType::DateTime).build();

    assert_date(
      &type_option,
      1653609600,
      Some("1:".to_owned()),
      "May 27,2022 01:00",
      true,
      &field_rev,
    );
  }

  // #[test]
  // fn date_type_option_empty_include_time_str_test() {
  //   let type_option = DateTypeOptionPB::new();
  //   let field_rev = FieldBuilder::from_field_type(&FieldType::DateTime).build();
  //
  //   assert_date(
  //     &type_option,
  //     1653609600,
  //     Some("".to_owned()),
  //     "May 27,2022 00:00",
  //     true,
  //     &field_rev,
  //   );
  // }

  #[test]
  fn date_type_midnight_include_time_str_test() {
    let type_option = DateTypeOptionPB::new();
    let field_type = FieldType::DateTime;
    let field_rev = FieldBuilder::from_field_type(&field_type).build();
    assert_date(
      &type_option,
      1653609600,
      Some("00:00".to_owned()),
      "May 27, 2022 00:00",
      true,
      &field_rev,
    );
  }

  /// The default time format is TwentyFourHour, so the include_time_str in twelve_hours_format will cause parser error.
  #[test]
  #[should_panic]
  fn date_type_option_twelve_hours_include_time_str_in_twenty_four_hours_format() {
    let type_option = DateTypeOptionPB::new();
    let field_rev = FieldBuilder::from_field_type(&FieldType::DateTime).build();

    assert_date(
      &type_option,
      1653609600,
      Some("1:00 am".to_owned()),
      "May 27,2022 01:00 AM",
      true,
      &field_rev,
    );
  }

  // Attempting to parse include_time_str as TwelveHour when TwentyFourHour format is given should cause parser error.
  #[test]
  #[should_panic]
  fn date_type_option_twenty_four_hours_include_time_str_in_twelve_hours_format() {
    let mut type_option = DateTypeOptionPB::new();
    type_option.time_format = TimeFormat::TwelveHour;
    let field_rev = FieldBuilder::from_field_type(&FieldType::DateTime).build();

    assert_date(
      &type_option,
      1653609600,
      Some("20:00".to_owned()),
      "May 27,2022 08:00 PM",
      true,
      &field_rev,
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

  fn assert_date<T: ToString>(
    type_option: &DateTypeOptionPB,
    timestamp: T,
    include_time_str: Option<String>,
    expected_str: &str,
    include_time: bool,
    field_rev: &FieldRevision,
  ) {
    let changeset = DateCellChangeset {
      date: Some(timestamp.to_string()),
      time: include_time_str,
      is_utc: false,
      include_time: Some(include_time),
    };
    let (cell_str, _) = type_option.apply_changeset(changeset, None).unwrap();

    assert_eq!(
      decode_cell_data(cell_str, type_option, include_time, field_rev),
      expected_str.to_owned(),
    );
  }

  fn decode_cell_data(
    cell_str: String,
    type_option: &DateTypeOptionPB,
    include_time: bool,
    field_rev: &FieldRevision,
  ) -> String {
    let decoded_data = type_option
      .decode_cell_str(cell_str, &FieldType::DateTime, field_rev)
      .unwrap();
    let decoded_data = type_option.convert_to_protobuf(decoded_data);
    if include_time {
      format!("{} {}", decoded_data.date, decoded_data.time)
        .trim_end()
        .to_owned()
    } else {
      decoded_data.date
    }
  }
}
