use chrono::Duration;

use collab_database::database::timestamp;
use flowy_database2::entities::FieldType;
use flowy_database2::services::field::{
  ChecklistCellChangeset, DateCellChangeset, DateCellData, MultiSelectTypeOption,
  RelationCellChangeset, SelectOptionCellChangeset, SingleSelectTypeOption, StringCellData,
  TimeCellChangeset, TimeCellData, TimePrecision, TimeTrack, TimeType, TimeTypeOption, URLCellData,
};
use lib_infra::box_any::BoxAny;

use crate::database::cell_test::script::CellScript::UpdateCell;
use crate::database::cell_test::script::DatabaseCellTest;

#[tokio::test]
async fn grid_cell_update() {
  let mut test = DatabaseCellTest::new().await;
  let fields = test.get_fields();
  let rows = &test.row_details;

  let mut scripts = vec![];
  for row_detail in rows.iter() {
    for field in &fields {
      let field_type = FieldType::from(field.field_type);
      if field_type == FieldType::LastEditedTime || field_type == FieldType::CreatedTime {
        continue;
      }
      let cell_changeset = match field_type {
        FieldType::RichText => BoxAny::new("".to_string()),
        FieldType::Number => BoxAny::new("123".to_string()),
        FieldType::DateTime => BoxAny::new(DateCellChangeset {
          date: Some(123),
          ..Default::default()
        }),
        FieldType::SingleSelect => {
          let type_option = field
            .get_type_option::<SingleSelectTypeOption>(field.field_type)
            .unwrap();
          BoxAny::new(SelectOptionCellChangeset::from_insert_option_id(
            &type_option.options.first().unwrap().id,
          ))
        },
        FieldType::MultiSelect => {
          let type_option = field
            .get_type_option::<MultiSelectTypeOption>(field.field_type)
            .unwrap();
          BoxAny::new(SelectOptionCellChangeset::from_insert_option_id(
            &type_option.options.first().unwrap().id,
          ))
        },
        FieldType::Checklist => BoxAny::new(ChecklistCellChangeset {
          insert_options: vec![("new option".to_string(), false)],
          ..Default::default()
        }),
        FieldType::Checkbox => BoxAny::new("1".to_string()),
        FieldType::URL => BoxAny::new("1".to_string()),
        FieldType::Relation => BoxAny::new(RelationCellChangeset {
          inserted_row_ids: vec!["abcdefabcdef".to_string().into()],
          ..Default::default()
        }),
        FieldType::Time => BoxAny::new(TimeCellChangeset {
          time: Some(45),
          ..Default::default()
        }),
        _ => BoxAny::new("".to_string()),
      };

      scripts.push(UpdateCell {
        view_id: test.view_id.clone(),
        field_id: field.id.clone(),
        row_id: row_detail.row.id.clone(),
        changeset: cell_changeset,
        is_err: false,
      });
    }
  }

  test.run_scripts(scripts).await;
}

#[tokio::test]
async fn text_cell_data_test() {
  let test = DatabaseCellTest::new().await;
  let text_field = test.get_first_field(FieldType::RichText);

  let cells = test
    .editor
    .get_cells_for_field(&test.view_id, &text_field.id)
    .await;

  for (i, row_cell) in cells.into_iter().enumerate() {
    let text = StringCellData::from(row_cell.cell.as_ref().unwrap());
    match i {
      0 => assert_eq!(text.as_str(), "A"),
      1 => assert_eq!(text.as_str(), ""),
      2 => assert_eq!(text.as_str(), "C"),
      3 => assert_eq!(text.as_str(), "DA"),
      4 => assert_eq!(text.as_str(), "AE"),
      5 => assert_eq!(text.as_str(), "AE"),
      _ => {},
    }
  }
}

#[tokio::test]
async fn url_cell_data_test() {
  let test = DatabaseCellTest::new().await;
  let url_field = test.get_first_field(FieldType::URL);
  let cells = test
    .editor
    .get_cells_for_field(&test.view_id, &url_field.id)
    .await;

  for (i, row_cell) in cells.into_iter().enumerate() {
    if let Some(cell) = row_cell.cell.as_ref() {
      let cell = URLCellData::from(cell);
      if i == 0 {
        assert_eq!(
          cell.data.as_str(),
          "AppFlowy website - https://www.appflowy.io"
        );
      }
    }
  }
}

#[tokio::test]
async fn update_updated_at_field_on_other_cell_update() {
  let mut test = DatabaseCellTest::new().await;
  let updated_at_field = test.get_first_field(FieldType::LastEditedTime);

  let text_field = test
    .fields
    .iter()
    .find(|&f| FieldType::from(f.field_type) == FieldType::RichText)
    .unwrap();

  let before_update_timestamp = chrono::offset::Utc::now().timestamp();
  test
    .run_script(UpdateCell {
      view_id: test.view_id.clone(),
      row_id: test.row_details[0].row.id.clone(),
      field_id: text_field.id.clone(),
      changeset: BoxAny::new("change".to_string()),
      is_err: false,
    })
    .await;

  let cells = test
    .editor
    .get_cells_for_field(&test.view_id, &updated_at_field.id)
    .await;

  tokio::time::sleep(std::time::Duration::from_millis(500)).await;
  let after_update_timestamp = chrono::offset::Utc::now().timestamp();
  assert!(!cells.is_empty());
  for (i, row_cell) in cells.into_iter().enumerate() {
    let timestamp = DateCellData::from(row_cell.cell.as_ref().unwrap())
      .timestamp
      .unwrap();
    println!(
      "{}, bf: {}, af: {}",
      timestamp, before_update_timestamp, after_update_timestamp
    );
    match i {
      0 => assert!(
        timestamp >= before_update_timestamp && timestamp <= after_update_timestamp,
        "{} >= {} && {} <= {}",
        timestamp,
        before_update_timestamp,
        timestamp,
        after_update_timestamp
      ),
      1 => assert!(
        timestamp <= before_update_timestamp,
        "{} <= {}",
        timestamp,
        before_update_timestamp
      ),
      2 => assert!(
        timestamp <= before_update_timestamp,
        "{} <= {}",
        timestamp,
        before_update_timestamp
      ),
      3 => assert!(
        timestamp <= before_update_timestamp,
        "{} <= {}",
        timestamp,
        before_update_timestamp
      ),
      4 => assert!(
        timestamp <= before_update_timestamp,
        "{} <= {}",
        timestamp,
        before_update_timestamp
      ),
      5 => assert!(
        timestamp <= before_update_timestamp,
        "{} <= {}",
        timestamp,
        before_update_timestamp
      ),
      _ => {},
    }
  }
}

#[tokio::test]
async fn time_cell_data_test() {
  let test = DatabaseCellTest::new().await;
  let time_field = test.get_first_field(FieldType::Time);
  let cells = test
    .editor
    .get_cells_for_field(&test.view_id, &time_field.id)
    .await;

  assert!(cells[0].cell.as_ref().is_some());
  let cell = TimeCellData::from(cells[0].cell.as_ref().unwrap());

  assert!(cell.time.is_some());
  assert_eq!(cell.time.unwrap(), 75);
}

#[tokio::test]
async fn time_cell_stopwatch_add_time_tracking_test() {
  let mut test = DatabaseCellTest::new().await;
  let time_field = test.get_first_field(FieldType::Time);

  let type_option = TimeTypeOption {
    time_type: TimeType::Stopwatch,
    precision: TimePrecision::Seconds,
  };
  test
    .editor
    .update_field_type_option(
      &time_field.id.clone(),
      type_option.into(),
      time_field.clone(),
    )
    .await
    .unwrap();

  let now_timestamp = timestamp();
  let hour_before_timestamp = now_timestamp - Duration::hours(1).num_seconds();
  test
    .run_script(UpdateCell {
      view_id: test.view_id.clone(),
      row_id: test.row_details[0].row.id.clone(),
      field_id: time_field.id.clone(),
      changeset: BoxAny::new(TimeCellChangeset {
        add_time_trackings: vec![
          TimeTrack {
            from_timestamp: now_timestamp,
            to_timestamp: Some(now_timestamp + Duration::minutes(30).num_seconds()),
            ..Default::default()
          },
          TimeTrack {
            from_timestamp: hour_before_timestamp,
            to_timestamp: Some(hour_before_timestamp + Duration::minutes(15).num_seconds()),
            ..Default::default()
          },
        ],
        ..Default::default()
      }),
      is_err: false,
    })
    .await;

  test
    .assert_time(time_field.id, Duration::minutes(45).num_seconds())
    .await;
}

#[tokio::test]
async fn time_cell_stopwatch_delete_time_tracking_test() {
  let mut test = DatabaseCellTest::new().await;
  let time_field = test.get_first_field(FieldType::Time);

  let type_option = TimeTypeOption {
    time_type: TimeType::Stopwatch,
    precision: TimePrecision::Minutes,
  };
  test
    .editor
    .update_field_type_option(
      &time_field.id.clone(),
      type_option.into(),
      time_field.clone(),
    )
    .await
    .unwrap();

  let now_timestamp = timestamp();
  let hour_before_timestamp = now_timestamp - Duration::hours(1).num_seconds();
  test
    .run_script(UpdateCell {
      view_id: test.view_id.clone(),
      row_id: test.row_details[0].row.id.clone(),
      field_id: time_field.id.clone(),
      changeset: BoxAny::new(TimeCellChangeset {
        add_time_trackings: vec![
          TimeTrack {
            from_timestamp: now_timestamp,
            to_timestamp: Some(now_timestamp + Duration::minutes(30).num_seconds()),
            ..Default::default()
          },
          TimeTrack {
            from_timestamp: hour_before_timestamp,
            to_timestamp: Some(hour_before_timestamp + Duration::minutes(15).num_seconds()),
            ..Default::default()
          },
        ],
        ..Default::default()
      }),
      is_err: false,
    })
    .await;

  let cell = test.get_time_cell_data(time_field.clone().id).await;
  let time_track_id = &cell
    .time_tracks
    .iter()
    .find(|tt| tt.from_timestamp == now_timestamp)
    .unwrap()
    .id;
  test
    .run_script(UpdateCell {
      view_id: test.view_id.clone(),
      row_id: test.row_details[0].row.id.clone(),
      field_id: time_field.id.clone(),
      changeset: BoxAny::new(TimeCellChangeset {
        delete_time_tracking_ids: vec![time_track_id.to_string()],
        ..Default::default()
      }),
      is_err: false,
    })
    .await;

  test
    .assert_time(time_field.id, Duration::minutes(15).num_seconds())
    .await;
}

#[tokio::test]
async fn time_cell_stopwatch_update_time_tracking_test() {
  let mut test = DatabaseCellTest::new().await;
  let time_field = test.get_first_field(FieldType::Time);

  let type_option = TimeTypeOption {
    time_type: TimeType::Stopwatch,
    precision: TimePrecision::Minutes,
  };
  test
    .editor
    .update_field_type_option(
      &time_field.id.clone(),
      type_option.into(),
      time_field.clone(),
    )
    .await
    .unwrap();

  let now_timestamp = timestamp();
  let hour_before_timestamp = now_timestamp - Duration::hours(1).num_seconds();
  test
    .run_script(UpdateCell {
      view_id: test.view_id.clone(),
      row_id: test.row_details[0].row.id.clone(),
      field_id: time_field.id.clone(),
      changeset: BoxAny::new(TimeCellChangeset {
        add_time_trackings: vec![
          TimeTrack {
            from_timestamp: now_timestamp,
            to_timestamp: Some(now_timestamp + Duration::minutes(30).num_seconds()),
            ..Default::default()
          },
          TimeTrack {
            from_timestamp: hour_before_timestamp,
            to_timestamp: Some(hour_before_timestamp + Duration::minutes(15).num_seconds()),
            ..Default::default()
          },
        ],
        ..Default::default()
      }),
      is_err: false,
    })
    .await;

  let cell = test.get_time_cell_data(time_field.clone().id).await;
  let time_track = &cell
    .time_tracks
    .iter()
    .find(|tt| tt.from_timestamp == now_timestamp)
    .unwrap();
  test
    .run_script(UpdateCell {
      view_id: test.view_id.clone(),
      row_id: test.row_details[0].row.id.clone(),
      field_id: time_field.id.clone(),
      changeset: BoxAny::new(TimeCellChangeset {
        update_time_trackings: vec![TimeTrack {
          id: time_track.id.to_string(),
          from_timestamp: time_track.from_timestamp + Duration::minutes(5).num_seconds(),
          to_timestamp: time_track.to_timestamp,
        }],
        ..Default::default()
      }),
      is_err: false,
    })
    .await;

  test
    .assert_time(time_field.id, Duration::minutes(40).num_seconds())
    .await;
}

#[tokio::test]
async fn time_cell_timer_add_time_tracking_test() {
  let mut test = DatabaseCellTest::new().await;
  let time_field = test.get_first_field(FieldType::Time);

  let type_option = TimeTypeOption {
    time_type: TimeType::Timer,
    precision: TimePrecision::Minutes,
  };
  test
    .editor
    .update_field_type_option(
      &time_field.id.clone(),
      type_option.into(),
      time_field.clone(),
    )
    .await
    .unwrap();

  let now_timestamp = timestamp();
  let hour_before_timestamp = now_timestamp - Duration::hours(1).num_seconds();
  test
    .run_script(UpdateCell {
      view_id: test.view_id.clone(),
      row_id: test.row_details[0].row.id.clone(),
      field_id: time_field.id.clone(),
      changeset: BoxAny::new(TimeCellChangeset {
        timer_start: Some(Duration::minutes(50).num_seconds()),
        add_time_trackings: vec![
          TimeTrack {
            from_timestamp: now_timestamp,
            to_timestamp: Some(now_timestamp + Duration::minutes(30).num_seconds()),
            ..Default::default()
          },
          TimeTrack {
            from_timestamp: hour_before_timestamp,
            to_timestamp: Some(hour_before_timestamp + Duration::minutes(15).num_seconds()),
            ..Default::default()
          },
        ],
        ..Default::default()
      }),
      is_err: false,
    })
    .await;

  test
    .assert_time(time_field.id, Duration::minutes(5).num_seconds())
    .await;
}
