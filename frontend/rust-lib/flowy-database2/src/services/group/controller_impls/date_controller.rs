use std::format;
use std::str::FromStr;

use async_trait::async_trait;
use chrono::{
  DateTime, Datelike, Days, Duration, Local, NaiveDate, NaiveDateTime, Offset, TimeZone,
};
use chrono_tz::Tz;
use collab_database::database::timestamp;
use collab_database::fields::{Field, TypeOptionData};
use collab_database::rows::{new_cell_builder, Cell, Cells, Row, RowDetail};
use serde::{Deserialize, Serialize};
use serde_repr::{Deserialize_repr, Serialize_repr};

use flowy_error::FlowyResult;

use crate::entities::{
  FieldType, GroupPB, GroupRowsNotificationPB, InsertedGroupPB, InsertedRowPB, RowMetaPB,
};
use crate::services::cell::insert_date_cell;
use crate::services::field::{DateCellData, DateCellDataParser, DateTypeOption, TypeOption};
use crate::services::group::action::GroupCustomize;
use crate::services::group::configuration::GroupContext;
use crate::services::group::controller::{BaseGroupController, GroupController};
use crate::services::group::{
  make_no_status_group, move_group_row, GeneratedGroupConfig, GeneratedGroups, Group,
  GroupOperationInterceptor, GroupsBuilder, MoveGroupRowContext,
};

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

#[derive(Default, Serialize_repr, Deserialize_repr)]
#[repr(u8)]
pub enum DateCondition {
  #[default]
  Relative = 0,
  Day = 1,
  Week = 2,
  Month = 3,
  Year = 4,
}

pub type DateGroupController = BaseGroupController<
  DateGroupConfiguration,
  DateTypeOption,
  DateGroupBuilder,
  DateCellDataParser,
  DateGroupOperationInterceptorImpl,
>;

pub type DateGroupContext = GroupContext<DateGroupConfiguration>;

impl GroupCustomize for DateGroupController {
  type GroupTypeOption = DateTypeOption;

  fn placeholder_cell(&self) -> Option<Cell> {
    Some(
      new_cell_builder(FieldType::DateTime)
        .insert_str_value("data", "")
        .build(),
    )
  }

  fn can_group(
    &self,
    content: &str,
    cell_data: &<Self::GroupTypeOption as TypeOption>::CellData,
  ) -> bool {
    content
      == group_id(
        cell_data,
        &self.type_option,
        &self.context.get_setting_content(),
      )
  }

  fn create_or_delete_group_when_cell_changed(
    &mut self,
    _row_detail: &RowDetail,
    _old_cell_data: Option<&<Self::GroupTypeOption as TypeOption>::CellProtobufType>,
    _cell_data: &<Self::GroupTypeOption as TypeOption>::CellProtobufType,
  ) -> FlowyResult<(Option<InsertedGroupPB>, Option<GroupPB>)> {
    let setting_content = self.context.get_setting_content();
    let mut inserted_group = None;
    if self
      .context
      .get_group(&group_id(
        &_cell_data.into(),
        &self.type_option,
        &setting_content,
      ))
      .is_none()
    {
      let group =
        make_group_from_date_cell(&_cell_data.into(), &self.type_option, &setting_content);
      let mut new_group = self.context.add_new_group(group)?;
      new_group.group.rows.push(RowMetaPB::from(_row_detail));
      inserted_group = Some(new_group);
    }

    // Delete the old group if there are no rows in that group
    let deleted_group = match _old_cell_data.and_then(|old_cell_data| {
      self.context.get_group(&group_id(
        &old_cell_data.into(),
        &self.type_option,
        &setting_content,
      ))
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
    row_detail: &RowDetail,
    cell_data: &<Self::GroupTypeOption as TypeOption>::CellProtobufType,
  ) -> Vec<GroupRowsNotificationPB> {
    let mut changesets = vec![];
    let setting_content = self.context.get_setting_content();
    self.context.iter_mut_status_groups(|group| {
      let mut changeset = GroupRowsNotificationPB::new(group.id.clone());
      if group.id == group_id(&cell_data.into(), &self.type_option, &setting_content) {
        if !group.contains_row(&row_detail.row.id) {
          changeset
            .inserted_rows
            .push(InsertedRowPB::new(RowMetaPB::from(row_detail)));
          group.add_row(row_detail.clone());
        }
      } else if group.contains_row(&row_detail.row.id) {
        group.remove_row(&row_detail.row.id);
        changeset
          .deleted_rows
          .push(row_detail.row.id.clone().into_inner());
      }

      if !changeset.is_empty() {
        changesets.push(changeset);
      }
    });
    changesets
  }

  fn delete_row(
    &mut self,
    row: &Row,
    cell_data: &<Self::GroupTypeOption as TypeOption>::CellData,
  ) -> (Option<GroupPB>, Vec<GroupRowsNotificationPB>) {
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

    let setting_content = self.context.get_setting_content();
    let deleted_group =
      match self
        .context
        .get_group(&group_id(cell_data, &self.type_option, &setting_content))
      {
        Some((_, group)) if group.rows.len() == 1 => Some(group.clone()),
        _ => None,
      };

    let deleted_group = deleted_group.map(|group| {
      let _ = self.context.delete_group(&group.id);
      group.into()
    });

    (deleted_group, changesets)
  }

  fn move_row(
    &mut self,
    _cell_data: &<Self::GroupTypeOption as TypeOption>::CellProtobufType,
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
    _cell_data: &<Self::GroupTypeOption as TypeOption>::CellProtobufType,
  ) -> Option<GroupPB> {
    let mut deleted_group = None;
    let setting_content = self.context.get_setting_content();
    if let Some((_, group)) = self.context.get_group(&group_id(
      &_cell_data.into(),
      &self.type_option,
      &setting_content,
    )) {
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

  fn delete_group_custom(&mut self, group_id: &str) -> FlowyResult<Option<TypeOptionData>> {
    self.context.delete_group(group_id)?;
    Ok(None)
  }
}

impl GroupController for DateGroupController {
  fn did_update_field_type_option(&mut self, _field: &Field) {}

  fn will_create_row(&mut self, cells: &mut Cells, field: &Field, group_id: &str) {
    match self.context.get_group(group_id) {
      None => tracing::warn!("Can not find the group: {}", group_id),
      Some((_, _)) => {
        let date = DateTime::parse_from_str(group_id, GROUP_ID_DATE_FORMAT).unwrap();
        let cell = insert_date_cell(date.timestamp(), None, field);
        cells.insert(field.id.clone(), cell);
      },
    }
  }
}

pub struct DateGroupBuilder();
#[async_trait]
impl GroupsBuilder for DateGroupBuilder {
  type Context = DateGroupContext;
  type GroupTypeOption = DateTypeOption;

  async fn build(
    field: &Field,
    context: &Self::Context,
    type_option: &Self::GroupTypeOption,
  ) -> GeneratedGroups {
    // Read all the cells for the grouping field
    let cells = context.get_all_cells().await;

    // Generate the groups
    let mut group_configs: Vec<GeneratedGroupConfig> = cells
      .into_iter()
      .flat_map(|value| value.into_date_field_cell_data())
      .filter(|cell| cell.timestamp.is_some())
      .map(|cell| {
        let group = make_group_from_date_cell(&cell, type_option, &context.get_setting_content());
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

fn make_group_from_date_cell(
  cell_data: &DateCellData,
  type_option: &DateTypeOption,
  setting_content: &str,
) -> Group {
  let group_id = group_id(cell_data, type_option, setting_content);
  Group::new(
    group_id.clone(),
    group_name_from_id(&group_id, type_option, setting_content),
  )
}

const GROUP_ID_DATE_FORMAT: &str = "%Y/%m/%d";

fn group_id(
  cell_data: &DateCellData,
  type_option: &DateTypeOption,
  setting_content: &str,
) -> String {
  let config = DateGroupConfiguration::from_json(setting_content).unwrap_or_default();
  let date_time = date_time_from_timestamp(cell_data.timestamp, &type_option.timezone_id);

  let date_format = GROUP_ID_DATE_FORMAT;
  let month_format = &date_format.replace("%d", "01");
  let year_format = &month_format.replace("%m", "01");

  let date = match config.condition {
    DateCondition::Day => date_time.format(date_format),
    DateCondition::Month => date_time.format(month_format),
    DateCondition::Year => date_time.format(year_format),
    DateCondition::Week => date_time
      .checked_sub_days(Days::new(date_time.weekday().num_days_from_monday() as u64))
      .unwrap()
      .format(date_format),
    DateCondition::Relative => {
      let now = date_time_from_timestamp(Some(timestamp()), &type_option.timezone_id).date_naive();
      let date_time = date_time.date_naive();

      let diff = date_time.signed_duration_since(now).num_days();
      let result = if diff == 0 {
        Some(now)
      } else if diff == -1 {
        now.checked_add_signed(Duration::days(-1))
      } else if diff == 1 {
        now.checked_add_signed(Duration::days(1))
      } else if (-7..-1).contains(&diff) {
        now.checked_add_signed(Duration::days(-7))
      } else if diff > 1 && diff <= 7 {
        now.checked_add_signed(Duration::days(2))
      } else if (-30..-7).contains(&diff) {
        now.checked_add_signed(Duration::days(-30))
      } else if diff > 7 && diff <= 30 {
        now.checked_add_signed(Duration::days(8))
      } else {
        let mut res = date_time
          .checked_sub_days(Days::new(date_time.day() as u64 - 1))
          .unwrap();
        // if beginning of the month is within next 30 days of current day, change to
        // first day which is greater than 30 days far from current day.
        let diff = res.signed_duration_since(now).num_days();
        if diff > 7 && diff <= 30 {
          res = res
            .checked_add_days(Days::new((30 - diff + 1) as u64))
            .unwrap();
        }
        Some(res)
      };

      result.unwrap().format(GROUP_ID_DATE_FORMAT)
    },
  };

  date.to_string()
}

fn group_name_from_id(
  group_id: &str,
  type_option: &DateTypeOption,
  setting_content: &str,
) -> String {
  let config = DateGroupConfiguration::from_json(setting_content).unwrap_or_default();
  let date = NaiveDate::parse_from_str(group_id, GROUP_ID_DATE_FORMAT).unwrap();

  let tmp;
  match config.condition {
    DateCondition::Day => {
      tmp = format!("{} {}, {}", date.format("%b"), date.day(), date.year(),);
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
        date.format("%b"),
        begin_of_week,
        end_of_week,
        date.year()
      );
      tmp
    },
    DateCondition::Month => {
      tmp = format!("{} {}", date.format("%b"), date.year(),);
      tmp
    },
    DateCondition::Year => date.year().to_string(),
    DateCondition::Relative => {
      let now = date_time_from_timestamp(Some(timestamp()), &type_option.timezone_id);

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
          tmp = format!("{} {}", date.format("%b"), date.year(),);
          &tmp
        },
      };

      result.to_string()
    },
  }
}

fn date_time_from_timestamp(timestamp: Option<i64>, timezone_id: &str) -> DateTime<Local> {
  match timestamp {
    Some(timestamp) => {
      let naive = NaiveDateTime::from_timestamp_opt(timestamp, 0).unwrap();
      let offset = match Tz::from_str(timezone_id) {
        Ok(timezone) => timezone.offset_from_utc_datetime(&naive).fix(),
        Err(_) => *Local::now().offset(),
      };

      DateTime::<Local>::from_naive_utc_and_offset(naive, offset)
    },
    None => DateTime::default(),
  }
}

pub struct DateGroupOperationInterceptorImpl {}

#[async_trait]
impl GroupOperationInterceptor for DateGroupOperationInterceptorImpl {
  type GroupTypeOption = DateTypeOption;
}

#[cfg(test)]
mod tests {
  use std::vec;

  use chrono::{offset, Days, Duration, NaiveDateTime};

  use crate::services::{
    field::{date_type_option::DateTypeOption, DateCellData},
    group::controller_impls::date_controller::{
      group_id, group_name_from_id, GROUP_ID_DATE_FORMAT,
    },
  };

  #[test]
  fn group_id_name_test() {
    struct GroupIDTest<'a> {
      cell_data: DateCellData,
      setting_content: String,
      exp_group_id: String,
      exp_group_name: String,
      type_option: &'a DateTypeOption,
    }

    let mar_14_2022 = NaiveDateTime::from_timestamp_opt(1647251762, 0).unwrap();
    let mar_14_2022_cd = DateCellData {
      timestamp: Some(mar_14_2022.timestamp()),
      include_time: false,
      ..Default::default()
    };
    let today = offset::Local::now();
    let three_days_before = today.checked_add_signed(Duration::days(-3)).unwrap();

    let mut local_date_type_option = DateTypeOption::new();
    local_date_type_option.timezone_id = today.offset().to_string();
    let mut default_date_type_option = DateTypeOption::new();
    default_date_type_option.timezone_id = "".to_string();

    let tests = vec![
      GroupIDTest {
        cell_data: mar_14_2022_cd.clone(),
        type_option: &local_date_type_option,
        setting_content: r#"{"condition": 0, "hide_empty": false}"#.to_string(),
        exp_group_id: "2022/03/01".to_string(),
        exp_group_name: "Mar 2022".to_string(),
      },
      GroupIDTest {
        cell_data: DateCellData {
          timestamp: Some(today.timestamp()),
          include_time: false,
          ..Default::default()
        },
        type_option: &local_date_type_option,
        setting_content: r#"{"condition": 0, "hide_empty": false}"#.to_string(),
        exp_group_id: today.format(GROUP_ID_DATE_FORMAT).to_string(),
        exp_group_name: "Today".to_string(),
      },
      GroupIDTest {
        cell_data: DateCellData {
          timestamp: Some(three_days_before.timestamp()),
          include_time: false,
          ..Default::default()
        },
        type_option: &local_date_type_option,
        setting_content: r#"{"condition": 0, "hide_empty": false}"#.to_string(),
        exp_group_id: today
          .checked_sub_days(Days::new(7))
          .unwrap()
          .format(GROUP_ID_DATE_FORMAT)
          .to_string(),
        exp_group_name: "Last 7 days".to_string(),
      },
      GroupIDTest {
        cell_data: mar_14_2022_cd.clone(),
        type_option: &local_date_type_option,
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
          ..Default::default()
        },
        type_option: &local_date_type_option,
        setting_content: r#"{"condition": 2, "hide_empty": false}"#.to_string(),
        exp_group_id: "2022/03/14".to_string(),
        exp_group_name: "Week of Mar 14-20 2022".to_string(),
      },
      GroupIDTest {
        cell_data: mar_14_2022_cd.clone(),
        type_option: &local_date_type_option,
        setting_content: r#"{"condition": 3, "hide_empty": false}"#.to_string(),
        exp_group_id: "2022/03/01".to_string(),
        exp_group_name: "Mar 2022".to_string(),
      },
      GroupIDTest {
        cell_data: mar_14_2022_cd,
        type_option: &local_date_type_option,
        setting_content: r#"{"condition": 4, "hide_empty": false}"#.to_string(),
        exp_group_id: "2022/01/01".to_string(),
        exp_group_name: "2022".to_string(),
      },
      GroupIDTest {
        cell_data: DateCellData {
          timestamp: Some(1685715999),
          include_time: false,
          ..Default::default()
        },
        type_option: &default_date_type_option,
        setting_content: r#"{"condition": 1, "hide_empty": false}"#.to_string(),
        exp_group_id: "2023/06/02".to_string(),
        exp_group_name: "".to_string(),
      },
      GroupIDTest {
        cell_data: DateCellData {
          timestamp: Some(1685802386),
          include_time: false,
          ..Default::default()
        },
        type_option: &default_date_type_option,
        setting_content: r#"{"condition": 1, "hide_empty": false}"#.to_string(),
        exp_group_id: "2023/06/03".to_string(),
        exp_group_name: "".to_string(),
      },
    ];

    for (i, test) in tests.iter().enumerate() {
      let group_id = group_id(&test.cell_data, test.type_option, &test.setting_content);
      assert_eq!(test.exp_group_id, group_id, "test {}", i);

      if !test.exp_group_name.is_empty() {
        let group_name = group_name_from_id(&group_id, test.type_option, &test.setting_content);
        assert_eq!(test.exp_group_name, group_name, "test {}", i);
      }
    }
  }
}
