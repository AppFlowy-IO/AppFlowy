use async_trait::async_trait;
use std::fmt::Formatter;
use std::marker::PhantomData;
use std::sync::Arc;

use collab_database::fields::Field;
use indexmap::IndexMap;
use serde::de::DeserializeOwned;
use serde::Serialize;
use tracing::event;

use flowy_error::{FlowyError, FlowyResult};
use lib_dispatch::prelude::af_spawn;

use crate::entities::{GroupChangesPB, GroupPB, InsertedGroupPB};
use crate::services::field::RowSingleCellData;
use crate::services::group::{
  default_group_setting, GeneratedGroups, Group, GroupChangeset, GroupData, GroupSetting,
};

#[async_trait]
pub trait GroupContextDelegate: Send + Sync + 'static {
  async fn get_group_setting(&self, view_id: &str) -> Option<Arc<GroupSetting>>;

  async fn get_configuration_cells(&self, view_id: &str, field_id: &str) -> Vec<RowSingleCellData>;

  async fn save_configuration(&self, view_id: &str, group_setting: GroupSetting)
    -> FlowyResult<()>;
}

impl<T> std::fmt::Display for GroupControllerContext<T> {
  fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
    self.group_by_id.iter().for_each(|(_, group)| {
      let _ = f.write_fmt(format_args!(
        "Group:{} has {} rows \n",
        group.id,
        group.rows.len()
      ));
    });

    Ok(())
  }
}

/// A [GroupControllerContext] represents as the groups memory cache
/// Each [GenericGroupController] has its own [GroupControllerContext], the `context` has its own configuration
/// that is restored from the disk.
///
/// The `context` contains a list of [GroupData]s and the grouping [Field]
pub struct GroupControllerContext<C> {
  pub view_id: String,
  /// The group configuration restored from the disk.
  ///
  /// Uses the [GroupSettingReader] to read the configuration data from disk
  setting: Arc<GroupSetting>,

  configuration_phantom: PhantomData<C>,

  /// The grouping field id
  field_id: String,

  /// Cache all the groups. Cache the group by its id.
  /// We use the id of the [Field] as the [No Status] group id.
  group_by_id: IndexMap<String, GroupData>,

  /// delegate that reads and writes data to and from disk
  delegate: Arc<dyn GroupContextDelegate>,
}

impl<C> GroupControllerContext<C>
where
  C: Serialize + DeserializeOwned,
{
  #[tracing::instrument(level = "trace", skip_all, err)]
  pub async fn new(
    view_id: String,
    field: Field,
    delegate: Arc<dyn GroupContextDelegate>,
  ) -> FlowyResult<Self> {
    event!(tracing::Level::TRACE, "GroupControllerContext::new");
    let setting = match delegate.get_group_setting(&view_id).await {
      None => {
        let default_configuration = default_group_setting(&field);
        delegate
          .save_configuration(&view_id, default_configuration.clone())
          .await?;
        Arc::new(default_configuration)
      },
      Some(setting) => setting,
    };

    Ok(Self {
      view_id,
      field_id: field.id,
      group_by_id: IndexMap::new(),
      delegate,
      setting,
      configuration_phantom: PhantomData,
    })
  }

  /// Returns the no `status` group
  ///
  /// We take the `id` of the `field` as the no status group id
  #[allow(dead_code)]
  pub(crate) fn get_no_status_group(&self) -> Option<&GroupData> {
    self.group_by_id.get(&self.field_id)
  }

  pub(crate) fn get_mut_no_status_group(&mut self) -> Option<&mut GroupData> {
    self.group_by_id.get_mut(&self.field_id)
  }

  pub(crate) fn groups(&self) -> Vec<&GroupData> {
    self.group_by_id.values().collect()
  }

  pub(crate) fn get_mut_group(&mut self, group_id: &str) -> Option<&mut GroupData> {
    self.group_by_id.get_mut(group_id)
  }

  // Returns the index and group specified by the group_id
  pub(crate) fn get_group(&self, group_id: &str) -> Option<(usize, &GroupData)> {
    match (
      self.group_by_id.get_index_of(group_id),
      self.group_by_id.get(group_id),
    ) {
      (Some(index), Some(group)) => Some((index, group)),
      _ => None,
    }
  }

  /// Iterate mut the groups without `No status` group
  pub(crate) fn iter_mut_status_groups(&mut self, mut each: impl FnMut(&mut GroupData)) {
    self.group_by_id.iter_mut().for_each(|(_, group)| {
      if group.id != self.field_id {
        each(group);
      }
    });
  }

  pub(crate) fn iter_mut_groups(&mut self, mut each: impl FnMut(&mut GroupData)) {
    self.group_by_id.iter_mut().for_each(|(_, group)| {
      each(group);
    });
  }
  #[tracing::instrument(level = "trace", skip(self), err)]
  pub(crate) fn add_new_group(&mut self, group: Group) -> FlowyResult<InsertedGroupPB> {
    let group_data = GroupData::new(group.id.clone(), self.field_id.clone(), group.visible);
    self.group_by_id.insert(group.id.clone(), group_data);
    let (index, group_data) = self.get_group(&group.id).unwrap();
    let insert_group = InsertedGroupPB {
      group: GroupPB::from(group_data.clone()),
      index: index as i32,
    };

    self.mut_configuration(|configuration| {
      configuration.groups.push(group);
      true
    })?;

    Ok(insert_group)
  }

  #[tracing::instrument(level = "trace", skip(self))]
  pub(crate) fn delete_group(&mut self, deleted_group_id: &str) -> FlowyResult<()> {
    self.group_by_id.shift_remove(deleted_group_id);
    self.mut_configuration(|configuration| {
      configuration
        .groups
        .retain(|group| group.id != deleted_group_id);
      true
    })?;
    Ok(())
  }

  pub(crate) fn move_group(&mut self, from_id: &str, to_id: &str) -> FlowyResult<()> {
    let from_index = self.group_by_id.get_index_of(from_id);
    let to_index = self.group_by_id.get_index_of(to_id);
    match (from_index, to_index) {
      (Some(from_index), Some(to_index)) => {
        self.group_by_id.move_index(from_index, to_index);

        self.mut_configuration(|configuration| {
          let from_index = configuration
            .groups
            .iter()
            .position(|group| group.id == from_id);
          let to_index = configuration
            .groups
            .iter()
            .position(|group| group.id == to_id);
          if let (Some(from), Some(to)) = &(from_index, to_index) {
            tracing::trace!(
              "Move group from index:{:?} to index:{:?}",
              from_index,
              to_index
            );
            let group = configuration.groups.remove(*from);
            configuration.groups.insert(*to, group);
          }
          tracing::trace!(
            "Group order: {:?} ",
            configuration
              .groups
              .iter()
              .map(|group| group.id.clone())
              .collect::<Vec<String>>()
              .join(",")
          );

          from_index.is_some() && to_index.is_some()
        })?;
        Ok(())
      },
      _ => Err(
        FlowyError::record_not_found().with_context("Moving group failed. Groups are not exist"),
      ),
    }
  }

  ///  Reset the memory cache of the groups and update the group configuration
  ///
  /// # Arguments
  ///
  /// * `generated_groups`: the generated groups contains a list of [GeneratedGroupConfig].
  ///
  /// Each [FieldType] can implement the [GroupGenerator] trait in order to generate different
  /// groups. For example, the FieldType::Checkbox has the [CheckboxGroupGenerator] that implements
  /// the [GroupGenerator] trait.
  ///
  /// Consider the passed-in generated_group_configs as new groups, the groups in the current
  /// [GroupConfigurationRevision] as old groups. The old groups and the new groups will be merged
  /// while keeping the order of the old groups.
  ///
  #[tracing::instrument(level = "trace", skip_all, err)]
  pub(crate) fn init_groups(
    &mut self,
    generated_groups: GeneratedGroups,
  ) -> FlowyResult<Option<GroupChangesPB>> {
    let GeneratedGroups {
      no_status_group,
      groups,
    } = generated_groups;

    let mut old_groups = self.setting.groups.clone();
    // clear all the groups if grouping by a new field
    if self.setting.field_id != self.field_id {
      old_groups.clear();
    }

    // The `all_group` is the combination of the new groups and old groups
    let MergeGroupResult {
      mut all_groups,
      new_groups,
      deleted_groups,
    } = merge_groups(no_status_group, old_groups, groups);

    let deleted_group_ids = deleted_groups
      .into_iter()
      .map(|group_rev| group_rev.id)
      .collect::<Vec<String>>();

    self.mut_configuration(|configuration| {
      let mut is_changed = !deleted_group_ids.is_empty();
      // Remove the groups
      configuration
        .groups
        .retain(|group| !deleted_group_ids.contains(&group.id));

      // Update/Insert new groups
      for group in &mut all_groups {
        match configuration
          .groups
          .iter()
          .position(|old_group_rev| old_group_rev.id == group.id)
        {
          None => {
            // Push the group to the end of the list if it doesn't exist in the group
            configuration.groups.push(group.clone());
            is_changed = true;
          },
          Some(pos) => {
            let old_group = configuration.groups.get_mut(pos).unwrap();
            // Take the old group setting
            if group.visible != old_group.visible {
              is_changed = true;
            }
            group.visible = old_group.visible;
          },
        }
      }
      is_changed
    })?;

    // Update the memory cache of the groups
    all_groups.into_iter().for_each(|group| {
      let group = GroupData::new(group.id, self.field_id.clone(), group.visible);
      self.group_by_id.insert(group.id.clone(), group);
    });

    let initial_groups = new_groups
      .into_iter()
      .flat_map(|group_rev| {
        let group = GroupData::new(group_rev.id, self.field_id.clone(), group_rev.visible);
        Some(GroupPB::from(group))
      })
      .collect();

    let changeset = GroupChangesPB {
      view_id: self.view_id.clone(),
      initial_groups,
      deleted_groups: deleted_group_ids,
      update_groups: vec![],
      inserted_groups: vec![],
    };

    tracing::trace!("Group changeset: {:?}", changeset);
    if changeset.is_empty() {
      Ok(None)
    } else {
      Ok(Some(changeset))
    }
  }

  pub(crate) fn update_group(&mut self, group_changeset: &GroupChangeset) -> FlowyResult<()> {
    let update_group = self.mut_group(&group_changeset.group_id, |group| {
      if let Some(visible) = group_changeset.visible {
        group.visible = visible;
      }
    })?;

    if let Some(group) = update_group {
      if let Some(group_data) = self.group_by_id.get_mut(&group.id) {
        group_data.is_visible = group.visible;
      };
    }
    Ok(())
  }

  pub(crate) async fn get_all_cells(&self) -> Vec<RowSingleCellData> {
    self
      .delegate
      .get_configuration_cells(&self.view_id, &self.field_id)
      .await
  }

  pub fn get_setting_content(&self) -> String {
    self.setting.content.clone()
  }

  /// # Arguments
  ///
  /// * `mut_configuration_fn`: mutate the [GroupSetting] and return whether the [GroupSetting] is
  /// changed. If the [GroupSetting] is changed, the [GroupSetting] will be saved to the storage.
  ///
  fn mut_configuration(
    &mut self,
    mut_configuration_fn: impl FnOnce(&mut GroupSetting) -> bool,
  ) -> FlowyResult<()> {
    let configuration = Arc::make_mut(&mut self.setting);
    let is_changed = mut_configuration_fn(configuration);
    if is_changed {
      let configuration = (*self.setting).clone();
      let delegate = self.delegate.clone();
      let view_id = self.view_id.clone();
      af_spawn(async move {
        match delegate.save_configuration(&view_id, configuration).await {
          Ok(_) => {},
          Err(e) => {
            tracing::error!("Save group configuration failed: {}", e);
          },
        }
      });
    }
    Ok(())
  }

  fn mut_group(
    &mut self,
    group_id: &str,
    mut_groups_fn: impl Fn(&mut Group),
  ) -> FlowyResult<Option<Group>> {
    let mut updated_group = None;
    self.mut_configuration(|configuration| {
      match configuration
        .groups
        .iter_mut()
        .find(|group| group.id == group_id)
      {
        None => false,
        Some(group) => {
          mut_groups_fn(group);
          updated_group = Some(group.clone());
          true
        },
      }
    })?;
    Ok(updated_group)
  }
}

/// Merge the new groups into old groups while keeping the order in the old groups
///
fn merge_groups(
  no_status_group: Option<Group>,
  old_groups: Vec<Group>,
  new_groups: Vec<Group>,
) -> MergeGroupResult {
  let mut merge_result = MergeGroupResult::new();
  // group_map is a helper map is used to filter out the new groups.
  let mut new_group_map: IndexMap<String, Group> = new_groups
    .into_iter()
    .map(|group| (group.id.clone(), group))
    .collect();
  let mut no_status_group_inserted = false;

  // The group is ordered in old groups. Add them before adding the new groups
  for old in old_groups {
    if let Some(new) = new_group_map.shift_remove(&old.id) {
      merge_result.all_groups.push(new.clone());
    } else if matches!(&no_status_group, Some(group) if group.id == old.id) {
      merge_result
        .all_groups
        .push(no_status_group.clone().unwrap());
      no_status_group_inserted = true;
    } else {
      merge_result.deleted_groups.push(old);
    }
  }

  merge_result
    .all_groups
    .extend(new_group_map.values().cloned());
  merge_result.new_groups.extend(new_group_map.into_values());

  // The `No status` group index is initialized to 0
  if !no_status_group_inserted {
    if let Some(group) = no_status_group {
      merge_result.all_groups.insert(0, group);
    }
  }
  merge_result
}

struct MergeGroupResult {
  // Contains the new groups and the updated groups
  all_groups: Vec<Group>,
  new_groups: Vec<Group>,
  deleted_groups: Vec<Group>,
}

impl MergeGroupResult {
  fn new() -> Self {
    Self {
      all_groups: vec![],
      new_groups: vec![],
      deleted_groups: vec![],
    }
  }
}

#[cfg(test)]
mod tests {
  use crate::services::group::Group;

  use super::{merge_groups, MergeGroupResult};

  #[test]
  fn merge_groups_test() {
    struct GroupMergeTest<'a> {
      no_status_group: &'a str,
      old_groups: Vec<&'a str>,
      new_groups: Vec<&'a str>,
      exp_all_groups: Vec<&'a str>,
      exp_new_groups: Vec<&'a str>,
      exp_deleted_groups: Vec<&'a str>,
    }

    let new_group = |name: &str| Group::new(name.to_string());
    let groups_from_strings =
      |strings: Vec<&str>| strings.iter().map(|s| new_group(s)).collect::<Vec<Group>>();
    let group_stringify = |groups: Vec<Group>| {
      groups
        .iter()
        .map(|group| group.id.clone())
        .collect::<Vec<String>>()
        .join(",")
    };

    let tests = vec![
      GroupMergeTest {
        no_status_group: "No Status",
        old_groups: vec!["Doing", "Done", "To Do", "No Status"],
        new_groups: vec!["To Do", "Doing", "Done"],
        exp_all_groups: vec!["Doing", "Done", "To Do", "No Status"],
        exp_new_groups: vec![],
        exp_deleted_groups: vec![],
      },
      GroupMergeTest {
        no_status_group: "No Status",
        old_groups: vec!["To Do", "Doing", "Done", "No Status", "Archive"],
        new_groups: vec!["backlog", "To Do", "Doing", "Done"],
        exp_all_groups: vec!["To Do", "Doing", "Done", "No Status", "backlog"],
        exp_new_groups: vec!["backlog"],
        exp_deleted_groups: vec!["Archive"],
      },
    ];

    for test in tests {
      let MergeGroupResult {
        all_groups,
        new_groups,
        deleted_groups,
      } = merge_groups(
        Some(new_group(test.no_status_group)),
        groups_from_strings(test.old_groups),
        groups_from_strings(test.new_groups),
      );

      let exp_all_groups = groups_from_strings(test.exp_all_groups);
      let exp_new_groups = groups_from_strings(test.exp_new_groups);
      let exp_deleted_groups = groups_from_strings(test.exp_deleted_groups);
      assert_eq!(group_stringify(all_groups), group_stringify(exp_all_groups));
      assert_eq!(group_stringify(new_groups), group_stringify(exp_new_groups));
      assert_eq!(
        group_stringify(deleted_groups),
        group_stringify(exp_deleted_groups)
      );
    }
  }
}
