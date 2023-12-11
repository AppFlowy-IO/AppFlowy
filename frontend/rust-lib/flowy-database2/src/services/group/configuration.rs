use std::collections::HashMap;
use std::fmt::Formatter;
use std::marker::PhantomData;
use std::sync::Arc;

use async_trait::async_trait;
use collab_database::fields::Field;
use collab_database::rows::{Cell, RowId};
use indexmap::IndexMap;
use serde::de::DeserializeOwned;
use serde::Serialize;
use tracing::event;

use flowy_error::{FlowyError, FlowyResult};
use lib_dispatch::prelude::af_spawn;
use lib_infra::future::Fut;

use crate::entities::{GroupChangesPB, GroupPB, InsertedGroupPB};
use crate::services::field::RowSingleCellData;
use crate::services::group::{
  default_group_setting, GeneratedGroups, Group, GroupChangeset, GroupData, GroupSetting,
};

pub trait GroupSettingReader: Send + Sync + 'static {
  fn get_group_setting(&self, view_id: &str) -> Fut<Option<Arc<GroupSetting>>>;
  fn get_configuration_cells(&self, view_id: &str, field_id: &str) -> Fut<Vec<RowSingleCellData>>;
}

pub trait GroupSettingWriter: Send + Sync + 'static {
  fn save_configuration(&self, view_id: &str, group_setting: GroupSetting) -> Fut<FlowyResult<()>>;
}

#[async_trait]
pub trait GroupTypeOptionCellOperation: Send + Sync + 'static {
  async fn get_cell(&self, row_id: &RowId, field_id: &str) -> FlowyResult<Option<Cell>>;
  async fn update_cell(
    &self,
    view_id: &str,
    row_id: &RowId,
    field_id: &str,
    cell: Cell,
  ) -> FlowyResult<()>;
}

impl<T> std::fmt::Display for GroupContext<T> {
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

/// A [GroupContext] represents as the groups memory cache
/// Each [GenericGroupController] has its own [GroupContext], the `context` has its own configuration
/// that is restored from the disk.
///
/// The `context` contains a list of [GroupData]s and the grouping [Field]
pub struct GroupContext<C> {
  pub view_id: String,
  /// The group configuration restored from the disk.
  ///
  /// Uses the [GroupSettingReader] to read the configuration data from disk
  setting: Arc<GroupSetting>,

  configuration_phantom: PhantomData<C>,

  /// The grouping field
  field: Arc<Field>,

  /// Cache all the groups. Cache the group by its id.
  /// We use the id of the [Field] as the [No Status] group id.
  group_by_id: IndexMap<String, GroupData>,

  /// A reader that implement the [GroupSettingReader] trait
  ///
  reader: Arc<dyn GroupSettingReader>,

  /// A writer that implement the [GroupSettingWriter] trait is used to save the
  /// configuration to disk  
  ///
  writer: Arc<dyn GroupSettingWriter>,
}

impl<C> GroupContext<C>
where
  C: Serialize + DeserializeOwned,
{
  #[tracing::instrument(level = "trace", skip_all, err)]
  pub async fn new(
    view_id: String,
    field: Arc<Field>,
    reader: Arc<dyn GroupSettingReader>,
    writer: Arc<dyn GroupSettingWriter>,
  ) -> FlowyResult<Self> {
    event!(tracing::Level::TRACE, "GroupContext::new");
    let setting = match reader.get_group_setting(&view_id).await {
      None => {
        let default_configuration = default_group_setting(&field);
        writer
          .save_configuration(&view_id, default_configuration.clone())
          .await?;
        Arc::new(default_configuration)
      },
      Some(setting) => setting,
    };

    Ok(Self {
      view_id,
      field,
      group_by_id: IndexMap::new(),
      reader,
      writer,
      setting,
      configuration_phantom: PhantomData,
    })
  }

  /// Returns the no `status` group
  ///
  /// We take the `id` of the `field` as the no status group id
  #[allow(dead_code)]
  pub(crate) fn get_no_status_group(&self) -> Option<&GroupData> {
    self.group_by_id.get(&self.field.id)
  }

  pub(crate) fn get_mut_no_status_group(&mut self) -> Option<&mut GroupData> {
    self.group_by_id.get_mut(&self.field.id)
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
      if group.id != self.field.id {
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
    let group_data = GroupData::new(
      group.id.clone(),
      self.field.id.clone(),
      group.name.clone(),
      group.id.clone(),
      group.visible,
    );
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
    self.group_by_id.remove(deleted_group_id);
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
              .map(|group| group.name.clone())
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
      group_configs,
    } = generated_groups;

    let mut new_groups = vec![];
    let mut filter_content_map = HashMap::new();
    group_configs.into_iter().for_each(|generate_group| {
      filter_content_map.insert(
        generate_group.group.id.clone(),
        generate_group.filter_content,
      );
      new_groups.push(generate_group.group);
    });

    let mut old_groups = self.setting.groups.clone();
    // clear all the groups if grouping by a new field
    if self.setting.field_id != self.field.id {
      old_groups.clear();
    }

    // The `all_group_revs` is the combination of the new groups and old groups
    let MergeGroupResult {
      mut all_groups,
      new_groups,
      deleted_groups,
    } = merge_groups(no_status_group, old_groups, new_groups);

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
            group.visible = old_group.visible;
            if !is_changed {
              is_changed = is_group_changed(group, old_group);
            }
            // Consider the the name of the `group_rev` as the newest.
            old_group.name = group.name.clone();
          },
        }
      }
      is_changed
    })?;

    // Update the memory cache of the groups
    all_groups.into_iter().for_each(|group| {
      let filter_content = filter_content_map
        .get(&group.id)
        .cloned()
        .unwrap_or_else(|| "".to_owned());
      let group = GroupData::new(
        group.id,
        self.field.id.clone(),
        group.name,
        filter_content,
        group.visible,
      );
      self.group_by_id.insert(group.id.clone(), group);
    });

    let initial_groups = new_groups
      .into_iter()
      .flat_map(|group_rev| {
        let filter_content = filter_content_map.get(&group_rev.id)?;
        let group = GroupData::new(
          group_rev.id,
          self.field.id.clone(),
          group_rev.name,
          filter_content.clone(),
          group_rev.visible,
        );
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
      if let Some(name) = &group_changeset.name {
        group.name = name.clone();
      }
    })?;

    if let Some(group) = update_group {
      if let Some(group_data) = self.group_by_id.get_mut(&group.id) {
        group_data.name = group.name.clone();
        group_data.is_visible = group.visible;
      };
    }
    Ok(())
  }

  pub(crate) async fn get_all_cells(&self) -> Vec<RowSingleCellData> {
    self
      .reader
      .get_configuration_cells(&self.view_id, &self.field.id)
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
      let writer = self.writer.clone();
      let view_id = self.view_id.clone();
      af_spawn(async move {
        match writer.save_configuration(&view_id, configuration).await {
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

  // The group is ordered in old groups. Add them before adding the new groups
  for old in old_groups {
    if let Some(new) = new_group_map.shift_remove(&old.id) {
      merge_result.all_groups.push(new.clone());
    } else {
      merge_result.deleted_groups.push(old);
    }
  }

  // Find out the new groups
  merge_result
    .all_groups
    .extend(new_group_map.values().cloned());
  merge_result.new_groups.extend(new_group_map.into_values());

  // The `No status` group index is initialized to 0
  if let Some(no_status_group) = no_status_group {
    merge_result.all_groups.insert(0, no_status_group);
  }
  merge_result
}

fn is_group_changed(new: &Group, old: &Group) -> bool {
  if new.name != old.name {
    return true;
  }
  false
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
