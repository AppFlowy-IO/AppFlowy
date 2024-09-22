use async_trait::async_trait;
use collab::util::AnyMapExt;
use collab_database::database::Database;
use collab_database::fields::time_type_option::{DateCellData, DateTypeOption};
use collab_database::fields::{Field, TypeOptionData};
use collab_database::rows::Cell;
use collab_database::template::date_parse::cast_string_to_timestamp;
use flowy_error::FlowyResult;

use std::cmp::Ordering;

use tracing::info;

use crate::entities::{DateCellDataPB, DateFilterPB, FieldType};
use crate::services::cell::{CellDataChangeset, CellDataDecoder};
use crate::services::field::{
  default_order, DateCellChangeset, TypeOption, TypeOptionCellDataCompare,
  TypeOptionCellDataFilter, TypeOptionCellDataSerde, TypeOptionTransform, CELL_DATA,
};
use crate::services::sort::SortCondition;
impl TypeOption for DateTypeOption {
  type CellData = DateCellData;
  type CellChangeset = DateCellChangeset;
  type CellProtobufType = DateCellDataPB;
  type CellFilter = DateFilterPB;
}

impl TypeOptionCellDataSerde for DateTypeOption {
  fn protobuf_encode(
    &self,
    cell_data: <Self as TypeOption>::CellData,
  ) -> <Self as TypeOption>::CellProtobufType {
    let include_time = cell_data.include_time;
    let is_range = cell_data.is_range;

    let timestamp = cell_data.timestamp;
    let (date, time) = self.formatted_date_time_from_timestamp(&timestamp);

    let end_timestamp = cell_data.end_timestamp;
    let (end_date, end_time) = self.formatted_date_time_from_timestamp(&end_timestamp);

    let reminder_id = cell_data.reminder_id;

    DateCellDataPB {
      date,
      time,
      timestamp: timestamp.unwrap_or_default(),
      end_date,
      end_time,
      end_timestamp: end_timestamp.unwrap_or_default(),
      include_time,
      is_range,
      reminder_id,
    }
  }

  fn parse_cell(&self, cell: &Cell) -> FlowyResult<<Self as TypeOption>::CellData> {
    Ok(DateCellData::from(cell))
  }
}

#[async_trait]
impl TypeOptionTransform for DateTypeOption {
  async fn transform_type_option(
    &mut self,
    view_id: &str,
    field_id: &str,
    old_type_option_field_type: FieldType,
    _old_type_option_data: TypeOptionData,
    _new_type_option_field_type: FieldType,
    database: &mut Database,
  ) {
    match old_type_option_field_type {
      FieldType::RichText => {
        let rows = database
          .get_cells_for_field(view_id, field_id)
          .await
          .into_iter()
          .filter_map(|row| row.cell.map(|cell| (row.row_id, cell)))
          .collect::<Vec<_>>();

        info!(
          "Transforming RichText to DateTypeOption, updating {} row's cell content",
          rows.len()
        );
        for (row_id, cell_data) in rows {
          if let Some(cell_data) = cell_data
            .get_as::<String>(CELL_DATA)
            .and_then(|s| cast_string_to_timestamp(&s))
            .map(DateCellData::from_timestamp)
          {
            database
              .update_row(row_id, |row| {
                row.update_cells(|cell| {
                  cell.insert(field_id, Cell::from(&cell_data));
                });
              })
              .await;
          }
        }
      },
      _ => {
        // do nothing
      },
    }
  }
}

impl CellDataDecoder for DateTypeOption {
  fn decode_cell(&self, cell: &Cell) -> FlowyResult<<Self as TypeOption>::CellData> {
    self.parse_cell(cell)
  }

  fn stringify_cell_data(&self, cell_data: <Self as TypeOption>::CellData) -> String {
    let include_time = cell_data.include_time;
    let timestamp = cell_data.timestamp;
    let is_range = cell_data.is_range;

    let (date, time) = self.formatted_date_time_from_timestamp(&timestamp);

    if is_range {
      let (end_date, end_time) = match cell_data.end_timestamp {
        Some(timestamp) => self.formatted_date_time_from_timestamp(&Some(timestamp)),
        None => (date.clone(), time.clone()),
      };
      if include_time && timestamp.is_some() {
        format!("{} {} → {} {}", date, time, end_date, end_time)
          .trim()
          .to_string()
      } else if timestamp.is_some() {
        format!("{} → {}", date, end_date).trim().to_string()
      } else {
        "".to_string()
      }
    } else if include_time {
      format!("{} {}", date, time).trim().to_string()
    } else {
      date
    }
  }

  fn decode_cell_with_transform(
    &self,
    cell: &Cell,
    _from_field_type: FieldType,
    _field: &Field,
  ) -> Option<<Self as TypeOption>::CellData> {
    let s = cell.get_as::<String>(CELL_DATA)?;
    let timestamp = cast_string_to_timestamp(&s)?;
    Some(DateCellData::from_timestamp(timestamp))
  }

  fn numeric_cell(&self, _cell: &Cell) -> Option<f64> {
    None
  }
}

impl CellDataChangeset for DateTypeOption {
  fn apply_changeset(
    &self,
    changeset: <Self as TypeOption>::CellChangeset,
    cell: Option<Cell>,
  ) -> FlowyResult<(Cell, <Self as TypeOption>::CellData)> {
    // old date cell data
    let (previous_timestamp, previous_end_timestamp, include_time, is_range, reminder_id) =
      match cell {
        Some(cell) => {
          let cell_data = DateCellData::from(&cell);
          (
            cell_data.timestamp,
            cell_data.end_timestamp,
            cell_data.include_time,
            cell_data.is_range,
            cell_data.reminder_id,
          )
        },
        None => (None, None, false, false, String::new()),
      };

    if changeset.clear_flag == Some(true) {
      let cell_data = DateCellData {
        timestamp: None,
        end_timestamp: None,
        include_time,
        is_range,
        reminder_id: String::new(),
      };

      return Ok((Cell::from(&cell_data), cell_data));
    }

    // update include_time and is_range if necessary
    let include_time = changeset.include_time.unwrap_or(include_time);
    let is_range = changeset.is_range.unwrap_or(is_range);
    let reminder_id = changeset.reminder_id.unwrap_or(reminder_id);

    // Calculate the timestamp in the time zone specified in type option. If
    // a new timestamp is included in the changeset without an accompanying
    // time string, the old timestamp will simply be overwritten. Meaning, in
    // order to change the day without changing the time, the old time string
    // should be passed in as well.

    // parse the time string, which is in the local timezone
    let parsed_start_time = self.naive_time_from_time_string(include_time, changeset.time)?;

    let timestamp = self.timestamp_from_parsed_time_previous_and_new_timestamp(
      parsed_start_time,
      previous_timestamp,
      changeset.date,
    );

    let end_timestamp =
      if is_range && changeset.end_date.is_none() && previous_end_timestamp.is_none() {
        // just toggled is_range so no passed in or existing end time data
        timestamp
      } else if is_range {
        // parse the changeset's end time data or fallback to previous version
        let parsed_end_time = self.naive_time_from_time_string(include_time, changeset.end_time)?;

        self.timestamp_from_parsed_time_previous_and_new_timestamp(
          parsed_end_time,
          previous_end_timestamp,
          changeset.end_date,
        )
      } else {
        // clear the end time data
        None
      };

    let cell_data = DateCellData {
      timestamp,
      end_timestamp,
      include_time,
      is_range,
      reminder_id,
    };

    Ok((Cell::from(&cell_data), cell_data))
  }
}

impl TypeOptionCellDataFilter for DateTypeOption {
  fn apply_filter(
    &self,
    filter: &<Self as TypeOption>::CellFilter,
    cell_data: &<Self as TypeOption>::CellData,
  ) -> bool {
    filter.is_visible(cell_data).unwrap_or(true)
  }
}

impl TypeOptionCellDataCompare for DateTypeOption {
  fn apply_cmp(
    &self,
    cell_data: &<Self as TypeOption>::CellData,
    other_cell_data: &<Self as TypeOption>::CellData,
    sort_condition: SortCondition,
  ) -> Ordering {
    match (cell_data.timestamp, other_cell_data.timestamp) {
      (Some(left), Some(right)) => {
        let order = left.cmp(&right);
        sort_condition.evaluate_order(order)
      },
      (Some(_), None) => Ordering::Less,
      (None, Some(_)) => Ordering::Greater,
      (None, None) => default_order(),
    }
  }
}
