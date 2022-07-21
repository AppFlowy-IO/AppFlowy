#[cfg(test)]
mod tests {
    use crate::entities::FieldType;
    use crate::services::cell::{CellDataChangeset, CellDataOperation};
    use crate::services::field::*;
    // use crate::services::field::{DateCellChangeset, DateCellData, DateFormat, DateTypeOption, TimeFormat};
    use flowy_grid_data_model::revision::FieldRevision;
    use strum::IntoEnumIterator;

    #[test]
    fn date_type_option_invalid_input_test() {
        let type_option = DateTypeOption::default();
        let field_type = FieldType::DateTime;
        let field_rev = FieldBuilder::from_field_type(&field_type).build();
        assert_changeset_result(
            &type_option,
            DateCellChangesetPB {
                date: Some("1e".to_string()),
                time: Some("23:00".to_owned()),
            },
            &field_type,
            &field_rev,
            "",
        );
    }

    #[test]
    fn date_type_option_date_format_test() {
        let mut type_option = DateTypeOption::default();
        let field_rev = FieldBuilder::from_field_type(&FieldType::DateTime).build();
        for date_format in DateFormat::iter() {
            type_option.date_format = date_format;
            match date_format {
                DateFormat::Friendly => {
                    assert_decode_timestamp(1647251762, &type_option, &field_rev, "Mar 14,2022");
                }
                DateFormat::US => {
                    assert_decode_timestamp(1647251762, &type_option, &field_rev, "2022/03/14");
                }
                DateFormat::ISO => {
                    assert_decode_timestamp(1647251762, &type_option, &field_rev, "2022-03-14");
                }
                DateFormat::Local => {
                    assert_decode_timestamp(1647251762, &type_option, &field_rev, "2022/03/14");
                }
            }
        }
    }

    #[test]
    fn date_type_option_time_format_test() {
        let mut type_option = DateTypeOption::default();
        let field_type = FieldType::DateTime;
        let field_rev = FieldBuilder::from_field_type(&field_type).build();

        for time_format in TimeFormat::iter() {
            type_option.time_format = time_format;
            type_option.include_time = true;
            match time_format {
                TimeFormat::TwentyFourHour => {
                    assert_changeset_result(
                        &type_option,
                        DateCellChangesetPB {
                            date: Some(1653609600.to_string()),
                            time: None,
                        },
                        &field_type,
                        &field_rev,
                        "May 27,2022",
                    );
                    assert_changeset_result(
                        &type_option,
                        DateCellChangesetPB {
                            date: Some(1653609600.to_string()),
                            time: Some("23:00".to_owned()),
                        },
                        &field_type,
                        &field_rev,
                        "May 27,2022 23:00",
                    );
                }
                TimeFormat::TwelveHour => {
                    assert_changeset_result(
                        &type_option,
                        DateCellChangesetPB {
                            date: Some(1653609600.to_string()),
                            time: None,
                        },
                        &field_type,
                        &field_rev,
                        "May 27,2022",
                    );
                    //
                    assert_changeset_result(
                        &type_option,
                        DateCellChangesetPB {
                            date: Some(1653609600.to_string()),
                            time: Some("".to_owned()),
                        },
                        &field_type,
                        &field_rev,
                        "May 27,2022",
                    );

                    assert_changeset_result(
                        &type_option,
                        DateCellChangesetPB {
                            date: Some(1653609600.to_string()),
                            time: Some("11:23 pm".to_owned()),
                        },
                        &field_type,
                        &field_rev,
                        "May 27,2022 11:23 PM",
                    );
                }
            }
        }
    }

    #[test]
    fn date_type_option_apply_changeset_test() {
        let mut type_option = DateTypeOption::new();
        let field_type = FieldType::DateTime;
        let field_rev = FieldBuilder::from_field_type(&field_type).build();
        let date_timestamp = "1653609600".to_owned();

        assert_changeset_result(
            &type_option,
            DateCellChangesetPB {
                date: Some(date_timestamp.clone()),
                time: None,
            },
            &field_type,
            &field_rev,
            "May 27,2022",
        );

        type_option.include_time = true;
        assert_changeset_result(
            &type_option,
            DateCellChangesetPB {
                date: Some(date_timestamp.clone()),
                time: None,
            },
            &field_type,
            &field_rev,
            "May 27,2022",
        );

        assert_changeset_result(
            &type_option,
            DateCellChangesetPB {
                date: Some(date_timestamp.clone()),
                time: Some("1:00".to_owned()),
            },
            &field_type,
            &field_rev,
            "May 27,2022 01:00",
        );

        type_option.time_format = TimeFormat::TwelveHour;
        assert_changeset_result(
            &type_option,
            DateCellChangesetPB {
                date: Some(date_timestamp),
                time: Some("1:00 am".to_owned()),
            },
            &field_type,
            &field_rev,
            "May 27,2022 01:00 AM",
        );
    }

    #[test]
    #[should_panic]
    fn date_type_option_apply_changeset_error_test() {
        let mut type_option = DateTypeOption::new();
        type_option.include_time = true;
        let field_rev = FieldBuilder::from_field_type(&FieldType::DateTime).build();
        let date_timestamp = "1653609600".to_owned();

        assert_changeset_result(
            &type_option,
            DateCellChangesetPB {
                date: Some(date_timestamp.clone()),
                time: Some("1:".to_owned()),
            },
            &FieldType::DateTime,
            &field_rev,
            "May 27,2022 01:00",
        );

        assert_changeset_result(
            &type_option,
            DateCellChangesetPB {
                date: Some(date_timestamp),
                time: Some("1:00".to_owned()),
            },
            &FieldType::DateTime,
            &field_rev,
            "May 27,2022 01:00",
        );
    }

    #[test]
    #[should_panic]
    fn date_type_option_twelve_hours_to_twenty_four_hours() {
        let mut type_option = DateTypeOption::new();
        type_option.include_time = true;
        let field_rev = FieldBuilder::from_field_type(&FieldType::DateTime).build();
        let date_timestamp = "1653609600".to_owned();

        assert_changeset_result(
            &type_option,
            DateCellChangesetPB {
                date: Some(date_timestamp),
                time: Some("1:00 am".to_owned()),
            },
            &FieldType::DateTime,
            &field_rev,
            "May 27,2022 01:00",
        );
    }

    fn assert_changeset_result(
        type_option: &DateTypeOption,
        changeset: DateCellChangesetPB,
        _field_type: &FieldType,
        field_rev: &FieldRevision,
        expected: &str,
    ) {
        let changeset = CellDataChangeset(Some(changeset));
        let encoded_data = type_option.apply_changeset(changeset, None).unwrap();
        assert_eq!(
            expected.to_owned(),
            decode_cell_data(encoded_data, type_option, field_rev)
        );
    }

    fn assert_decode_timestamp(
        timestamp: i64,
        type_option: &DateTypeOption,
        field_rev: &FieldRevision,
        expected: &str,
    ) {
        let s = serde_json::to_string(&DateCellChangesetPB {
            date: Some(timestamp.to_string()),
            time: None,
        })
        .unwrap();
        let encoded_data = type_option.apply_changeset(s.into(), None).unwrap();

        assert_eq!(
            expected.to_owned(),
            decode_cell_data(encoded_data, type_option, field_rev)
        );
    }

    fn decode_cell_data(encoded_data: String, type_option: &DateTypeOption, field_rev: &FieldRevision) -> String {
        let decoded_data = type_option
            .decode_cell_data(encoded_data.into(), &FieldType::DateTime, field_rev)
            .unwrap()
            .with_parser(DateCellDataParser())
            .unwrap();

        if type_option.include_time {
            format!("{}{}", decoded_data.date, decoded_data.time)
        } else {
            decoded_data.date
        }
    }
}
