use crate::entities::{
  DateCellDataPB, FieldType, GroupPB, GroupRowsNotificationPB, InsertedGroupPB, InsertedRowPB,
  RowPB,
};
use crate::services::cell::insert_date_cell;
use crate::services::field::{DateCellData, DateCellDataParser, DateTypeOption};
use crate::services::group::action::GroupCustomize;
use crate::services::group::configuration::GroupContext;
use crate::services::group::controller::{
  BaseGroupController, GroupController, GroupsBuilder, MoveGroupRowContext,
};
use crate::services::group::{
  make_no_status_group, move_group_row, GeneratedGroupConfig, GeneratedGroups, Group,
};
use chrono::{
  DateTime, Datelike, Days, Duration, Local, NaiveDate, NaiveDateTime, Offset, TimeZone,
};
use chrono_tz::Tz;
use collab_database::database::timestamp;
use collab_database::fields::Field;
use collab_database::rows::{new_cell_builder, Cell, Cells, Row};
use flowy_error::FlowyResult;
use serde::{Deserialize, Serialize};
use serde_repr::{Deserialize_repr, Serialize_repr};
use std::format;
use std::str::FromStr;
use std::sync::Arc;

pub trait GroupConfigurationContentSerde: Sized + Send + Sync {
  fn from_json(s: &str) -> Result<Self, serde_json::Error>;
  fn to_json(&self) -> Result<String, serde_json::Error>;
}

#[derive(Default, Serialize, Deserialize)]
pub struct DateGroupConfiguration {
  pub hide_empty: bool,
  pub condition: DateCondition,
}

impl GroupConfigurationContentSerde for DateGroupConfiguration {
  fn from_json(s: &str) -> Result<Self, serde_json::Error> {
    serde_json::from_str(s)
  }
  fn to_json(&self) -> Result<String, serde_json::Error> {
    serde_json::to_string(self)
  }
}

#[derive(Serialize_repr, Deserialize_repr)]
#[repr(u8)]
pub enum DateCondition {
  Relative = 0,
  Day = 1,
  Week = 2,
  Month = 3,
  Year = 4,
}

impl std::default::Default for DateCondition {
  fn default() -> Self {
    DateCondition::Relative
  }
}

pub type DateGroupController = BaseGroupController<
  DateGroupConfiguration,
  DateTypeOption,
  DateGroupGenerator,
  DateCellDataParser,
>;

pub type DateGroupContext = GroupContext<DateGroupConfiguration>;

impl GroupCustomize for DateGroupController {
  type CellData = DateCellDataPB;

  fn placeholder_cell(&self) -> Option<Cell> {
    Some(
      new_cell_builder(FieldType::DateTime)
        .insert_str_value("data", "")
        .build(),
    )
  }

  fn can_group(&self, content: &str, cell_data: &Self::CellData) -> bool {
    group_id(&cell_data.into(), &self.context.get_setting_content()) == content
  }

  fn create_or_delete_group_when_cell_changed(
    &mut self,
    row: &Row,
    old_cell_data: Option<&Self::CellData>,
    cell_data: &Self::CellData,
  ) -> FlowyResult<(Option<InsertedGroupPB>, Option<GroupPB>)> {
    let setting_content = self.context.get_setting_content();
    let mut inserted_group = None;
    if self
      .context
      .get_group(&group_id(&cell_data.into(), &setting_content))
      .is_none()
    {
      let group = make_group_from_date_cell(&cell_data.into(), &setting_content);
      let mut new_group = self.context.add_new_group(group)?;
      new_group.group.rows.push(RowPB::from(row));
      inserted_group = Some(new_group);
    }

    // Delete the old group if there are no rows in that group
    let deleted_group = match old_cell_data.and_then(|old_cell_data| {
      self
        .context
        .get_group(&group_id(&old_cell_data.into(), &setting_content))
    }) {
      None => None,
      Some((_, group)) => {
        if group.rows.len() == 1 {
          Some(group.clone())
        } else {
          None
        }
      },
    };

    let deleted_group = match deleted_group {
      None => None,
      Some(group) => {
        self.context.delete_group(&group.id)?;
        Some(GroupPB::from(group.clone()))
      },
    };

    Ok((inserted_group, deleted_group))
  }

  fn add_or_remove_row_when_cell_changed(
    &mut self,
    row: &Row,
    cell_data: &Self::CellData,
  ) -> Vec<GroupRowsNotificationPB> {
    let mut changesets = vec![];
    let setting_content = self.context.get_setting_content();
    self.context.iter_mut_status_groups(|group| {
      let mut changeset = GroupRowsNotificationPB::new(group.id.clone());
      if group.id == group_id(&cell_data.into(), &setting_content) {
        if !group.contains_row(&row.id) {
          changeset
            .inserted_rows
            .push(InsertedRowPB::new(RowPB::from(row)));
          group.add_row(row.clone());
        }
      } else if group.contains_row(&row.id) {
        group.remove_row(&row.id);
        changeset.deleted_rows.push(row.id.clone().into_inner());
      }

      if !changeset.is_empty() {
        changesets.push(changeset);
      }
    });
    changesets
  }

  fn delete_row(&mut self, row: &Row, _cell_data: &Self::CellData) -> Vec<GroupRowsNotificationPB> {
    let mut changesets = vec![];
    self.context.iter_mut_groups(|group| {
      let mut changeset = GroupRowsNotificationPB::new(group.id.clone());
      if group.contains_row(&row.id) {
        group.remove_row(&row.id);
        changeset.deleted_rows.push(row.id.clone().into_inner());
      }

      if !changeset.is_empty() {
        changesets.push(changeset);
      }
    });
    changesets
  }

  fn move_row(
    &mut self,
    _cell_data: &Self::CellData,
    mut context: MoveGroupRowContext,
  ) -> Vec<GroupRowsNotificationPB> {
    let mut group_changeset = vec![];
    self.context.iter_mut_groups(|group| {
      if let Some(changeset) = move_group_row(group, &mut context) {
        group_changeset.push(changeset);
      }
    });
    group_changeset
  }

  fn delete_group_when_move_row(
    &mut self,
    _row: &Row,
    cell_data: &Self::CellData,
  ) -> Option<GroupPB> {
    let mut deleted_group = None;
    let setting_content = self.context.get_setting_content();
    if let Some((_, group)) = self
      .context
      .get_group(&group_id(&cell_data.into(), &setting_content))
    {
      if group.rows.len() == 1 {
        deleted_group = Some(GroupPB::from(group.clone()));
      }
    }
    if deleted_group.is_some() {
      let _ = self
        .context
        .delete_group(&deleted_group.as_ref().unwrap().group_id);
    }
    deleted_group
  }
}

impl GroupController for DateGroupController {
  fn did_update_field_type_option(&mut self, _field: &Arc<Field>) {}

  fn will_create_row(&mut self, cells: &mut Cells, field: &Field, group_id: &str) {
    match self.context.get_group(group_id) {
      None => tracing::warn!("Can not find the group: {}", group_id),
      Some((_, _)) => {
        let date = DateTime::parse_from_str(&group_id, "%Y/%m/%d").unwrap();
        let cell = insert_date_cell(date.timestamp(), None, field);
        cells.insert(field.id.clone(), cell);
      },
    }
  }

  fn did_create_row(&mut self, row: &Row, group_id: &str) {
    if let Some(group) = self.context.get_mut_group(group_id) {
      group.add_row(row.clone())
    }
  }
}

pub struct DateGroupGenerator();
impl GroupsBuilder for DateGroupGenerator {
  type Context = DateGroupContext;
  type TypeOptionType = DateTypeOption;

  fn build(
    field: &Field,
    context: &Self::Context,
    _type_option: &Option<Self::TypeOptionType>,
  ) -> GeneratedGroups {
    // Read all the cells for the grouping field
    let cells = futures::executor::block_on(context.get_all_cells());

    // Generate the groups
    let mut group_configs: Vec<GeneratedGroupConfig> = cells
      .into_iter()
      .flat_map(|value| value.into_date_field_cell_data())
      .filter(|cell| cell.timestamp.is_some())
      .map(|cell| {
        let group = make_group_from_date_cell(&cell, &context.get_setting_content());
        GeneratedGroupConfig {
          filter_content: group.id.clone(),
          group,
        }
      })
      .collect();
    group_configs.sort_by(|a, b| a.filter_content.cmp(&b.filter_content));

    let no_status_group = Some(make_no_status_group(field));
    GeneratedGroups {
      no_status_group,
      group_configs,
    }
  }
}

fn make_group_from_date_cell(cell_data: &DateCellData, setting_content: &String) -> Group {
  let group_id = group_id(cell_data, setting_content);
  Group::new(
    group_id.clone(),
    group_name_from_id(&group_id, &cell_data.timezone_id, setting_content),
  )
}

fn group_id(cell_data: &DateCellData, setting_content: &String) -> String {
  let config = DateGroupConfiguration::from_json(setting_content).unwrap_or_default();
  let date_time = DateTime::from(cell_data);

  let date = match config.condition {
    DateCondition::Day => date_time.format("%Y/%m/%d"),
    DateCondition::Month => date_time.format("%Y/%m/01"),
    DateCondition::Year => date_time.format("%Y/01/01"),
    DateCondition::Week => date_time
      .checked_sub_days(Days::new(date_time.weekday().num_days_from_monday() as u64))
      .unwrap()
      .format("%Y/%m/%d"),
    DateCondition::Relative => {
      let naive = NaiveDateTime::from_timestamp_opt(timestamp(), 0).unwrap();
      let offset = match Tz::from_str(&cell_data.timezone_id) {
        Ok(timezone) => timezone.offset_from_utc_datetime(&naive).fix(),
        Err(_) => *Local::now().offset(),
      };
      let now = DateTime::<Local>::from_utc(naive, offset);

      let diff = date_time.signed_duration_since(now).num_days();
      let result = if diff == 0 {
        Some(now)
      } else if diff == -1 {
        now.checked_add_signed(Duration::days(-1))
      } else if diff == 1 {
        now.checked_add_signed(Duration::days(1))
      } else if diff >= -7 && diff < -1 {
        now.checked_add_signed(Duration::days(-7))
      } else if diff > 1 && diff <= 7 {
        now.checked_add_signed(Duration::days(2))
      } else if diff >= -30 && diff < -7 {
        now.checked_add_signed(Duration::days(-30))
      } else if diff > 7 && diff <= 30 {
        now.checked_add_signed(Duration::days(8))
      } else {
        date_time.checked_sub_days(Days::new(date_time.day() as u64 - 1))
      };

      result.unwrap().format("%Y/%m/%d")
    },
  };

  date.to_string()
}

fn group_name_from_id(group_id: &String, timezone_id: &String, setting_content: &String) -> String {
  let config = DateGroupConfiguration::from_json(setting_content).unwrap_or_default();
  let date = NaiveDate::parse_from_str(group_id, "%Y/%m/%d").unwrap();

  let tmp;
  match config.condition {
    DateCondition::Day => {
      tmp = format!(
        "{} {}, {}",
        date.format("%b").to_string(),
        date.day(),
        date.year(),
      );
      tmp
    },
    DateCondition::Week => {
      let begin_of_week = date
        .checked_sub_days(Days::new(date.weekday().num_days_from_monday() as u64))
        .unwrap()
        .format("%d");
      let end_of_week = date
        .checked_add_days(Days::new(6 - date.weekday().num_days_from_monday() as u64))
        .unwrap()
        .format("%d");

      tmp = format!(
        "Week of {} {}-{} {}",
        date.format("%b").to_string(),
        begin_of_week.to_string(),
        end_of_week.to_string(),
        date.year()
      );
      tmp
    },
    DateCondition::Month => {
      tmp = format!("{} {}", date.format("%b").to_string(), date.year(),);
      tmp
    },
    DateCondition::Year => date.year().to_string(),
    DateCondition::Relative => {
      let naive = NaiveDateTime::from_timestamp_opt(timestamp(), 0).unwrap();
      let offset = match Tz::from_str(timezone_id) {
        Ok(timezone) => timezone.offset_from_utc_datetime(&naive).fix(),
        Err(_) => *Local::now().offset(),
      };
      let now = DateTime::<Local>::from_utc(naive, offset);

      let diff = date.signed_duration_since(now.date_naive());
      let result = match diff.num_days() {
        0 => "Today",
        -1 => "Yesterday",
        1 => "Tomorrow",
        -7 => "Last 7 days",
        2 => "Next 7 days",
        -30 => "Last 30 days",
        8 => "Next 30 days",
        _ => {
          tmp = format!("{} {}", date.format("%b").to_string(), date.year(),);
          &tmp
        },
      };

      result.to_string()
    },
  }
}

#[cfg(test)]
mod tests {
  use std::vec;

  use chrono::{offset, Days, Duration, NaiveDateTime};

  use crate::services::{
    field::DateCellData,
    group::controller_impls::date_controller::{group_id, group_name_from_id},
  };

  #[test]
  fn group_id_name_test() {
    struct GroupIDTest {
      cell_data: DateCellData,
      setting_content: String,
      exp_group_id: String,
      exp_group_name: String,
    }

    let mar_14_2022 = NaiveDateTime::from_timestamp_opt(1647251762, 0).unwrap();
    let mar_14_2022_cd = DateCellData {
      timestamp: Some(mar_14_2022.timestamp()),
      include_time: false,
      timezone_id: "Etc/UTC".to_string(),
    };
    let today = offset::Local::now();
    let three_days_before = today.checked_add_signed(Duration::days(-3)).unwrap();

    let tests = vec![
      GroupIDTest {
        cell_data: mar_14_2022_cd.clone(),
        setting_content: r#"{"condition": 0, "hide_empty": false}"#.to_string(),
        exp_group_id: "2022/03/01".to_string(),
        exp_group_name: "Mar 2022".to_string(),
      },
      GroupIDTest {
        cell_data: DateCellData {
          timestamp: Some(today.timestamp()),
          include_time: false,
          timezone_id: "Etc/UTC".to_string(),
        },
        setting_content: r#"{"condition": 0, "hide_empty": false}"#.to_string(),
        exp_group_id: today.format("%Y/%m/%d").to_string(),
        exp_group_name: "Today".to_string(),
      },
      GroupIDTest {
        cell_data: DateCellData {
          timestamp: Some(three_days_before.timestamp()),
          include_time: false,
          timezone_id: "Etc/UTC".to_string(),
        },
        setting_content: r#"{"condition": 0, "hide_empty": false}"#.to_string(),
        exp_group_id: today
          .checked_sub_days(Days::new(7))
          .unwrap()
          .format("%Y/%m/%d")
          .to_string(),
        exp_group_name: "Last 7 days".to_string(),
      },
      GroupIDTest {
        cell_data: mar_14_2022_cd.clone(),
        setting_content: r#"{"condition": 1, "hide_empty": false}"#.to_string(),
        exp_group_id: "2022/03/14".to_string(),
        exp_group_name: "Mar 14, 2022".to_string(),
      },
      GroupIDTest {
        cell_data: DateCellData {
          timestamp: Some(
            mar_14_2022
              .checked_add_signed(Duration::days(3))
              .unwrap()
              .timestamp(),
          ),
          include_time: false,
          timezone_id: "Etc/UTC".to_string(),
        },
        setting_content: r#"{"condition": 2, "hide_empty": false}"#.to_string(),
        exp_group_id: "2022/03/14".to_string(),
        exp_group_name: "Week of Mar 14-20 2022".to_string(),
      },
      GroupIDTest {
        cell_data: mar_14_2022_cd.clone(),
        setting_content: r#"{"condition": 3, "hide_empty": false}"#.to_string(),
        exp_group_id: "2022/03/01".to_string(),
        exp_group_name: "Mar 2022".to_string(),
      },
      GroupIDTest {
        cell_data: mar_14_2022_cd.clone(),
        setting_content: r#"{"condition": 4, "hide_empty": false}"#.to_string(),
        exp_group_id: "2022/01/01".to_string(),
        exp_group_name: "2022".to_string(),
      },
    ];

    for (i, test) in tests.iter().enumerate() {
      let group_id = group_id(&test.cell_data, &test.setting_content);
      assert_eq!(test.exp_group_id, group_id, "test {}", i);

      let group_name = group_name_from_id(
        &group_id,
        &test.cell_data.timezone_id,
        &test.setting_content,
      );
      assert_eq!(test.exp_group_name, group_name, "test {}", i);
    }
  }
}
