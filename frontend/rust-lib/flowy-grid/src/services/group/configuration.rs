use crate::entities::{GroupPB, GroupViewChangesetPB};
use crate::services::group::{default_group_configuration, GeneratedGroup, Group};
use flowy_error::{FlowyError, FlowyResult};
use flowy_grid_data_model::revision::{
    FieldRevision, FieldTypeRevision, GroupConfigurationContentSerde, GroupConfigurationRevision, GroupRevision,
};
use indexmap::IndexMap;
use lib_infra::future::AFFuture;
use std::collections::HashMap;
use std::fmt::Formatter;
use std::marker::PhantomData;
use std::sync::Arc;

pub trait GroupConfigurationReader: Send + Sync + 'static {
    fn get_configuration(&self) -> AFFuture<Option<Arc<GroupConfigurationRevision>>>;
}

pub trait GroupConfigurationWriter: Send + Sync + 'static {
    fn save_configuration(
        &self,
        field_id: &str,
        field_type: FieldTypeRevision,
        group_configuration: GroupConfigurationRevision,
    ) -> AFFuture<FlowyResult<()>>;
}

impl<T> std::fmt::Display for GroupContext<T> {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        self.groups_map.iter().for_each(|(_, group)| {
            let _ = f.write_fmt(format_args!("Group:{} has {} rows \n", group.id, group.rows.len()));
        });
        let _ = f.write_fmt(format_args!(
            "Default group has {} rows \n",
            self.default_group.rows.len()
        ));
        Ok(())
    }
}

pub struct GroupContext<C> {
    pub view_id: String,
    configuration: Arc<GroupConfigurationRevision>,
    configuration_content: PhantomData<C>,
    field_rev: Arc<FieldRevision>,
    groups_map: IndexMap<String, Group>,
    /// default_group is used to store the rows that don't belong to any groups.
    default_group: Group,
    writer: Arc<dyn GroupConfigurationWriter>,
}

impl<C> GroupContext<C>
where
    C: GroupConfigurationContentSerde,
{
    #[tracing::instrument(level = "trace", skip_all, err)]
    pub async fn new(
        view_id: String,
        field_rev: Arc<FieldRevision>,
        reader: Arc<dyn GroupConfigurationReader>,
        writer: Arc<dyn GroupConfigurationWriter>,
    ) -> FlowyResult<Self> {
        let default_group_id = format!("{}_default_group", view_id);
        let default_group = Group {
            id: default_group_id,
            field_id: field_rev.id.clone(),
            name: format!("No {}", field_rev.name),
            is_default: true,
            is_visible: true,
            rows: vec![],
            filter_content: "".to_string(),
        };
        let configuration = match reader.get_configuration().await {
            None => {
                let default_configuration = default_group_configuration(&field_rev);
                writer
                    .save_configuration(&field_rev.id, field_rev.ty, default_configuration.clone())
                    .await?;
                Arc::new(default_configuration)
            }
            Some(configuration) => configuration,
        };

        // let configuration = C::from_configuration_content(&configuration_rev.content)?;
        Ok(Self {
            view_id,
            field_rev,
            groups_map: IndexMap::new(),
            default_group,
            writer,
            configuration,
            configuration_content: PhantomData,
        })
    }

    /// Returns the groups without the default group
    pub(crate) fn concrete_groups(&self) -> Vec<&Group> {
        self.groups_map.values().collect()
    }

    /// Returns the all the groups that contain the default group.
    pub(crate) fn clone_groups(&self) -> Vec<Group> {
        let mut groups: Vec<Group> = self.groups_map.values().cloned().collect();
        groups.push(self.default_group.clone());
        groups
    }

    /// Iterate mut the groups. The default group will be the last one that get mutated.
    pub(crate) fn iter_mut_groups(&mut self, mut each: impl FnMut(&mut Group)) {
        self.groups_map.iter_mut().for_each(|(_, group)| {
            each(group);
        });

        each(&mut self.default_group);
    }

    pub(crate) fn move_group(&mut self, from_id: &str, to_id: &str) -> FlowyResult<()> {
        let from_index = self.groups_map.get_index_of(from_id);
        let to_index = self.groups_map.get_index_of(to_id);
        match (from_index, to_index) {
            (Some(from_index), Some(to_index)) => {
                self.groups_map.swap_indices(from_index, to_index);
                self.mut_configuration(|configuration| {
                    let from_index = configuration.groups.iter().position(|group| group.id == from_id);
                    let to_index = configuration.groups.iter().position(|group| group.id == to_id);
                    if let (Some(from), Some(to)) = (from_index, to_index) {
                        configuration.groups.swap(from, to);
                    }
                    true
                })?;
                Ok(())
            }
            _ => Err(FlowyError::out_of_bounds()),
        }
    }

    #[tracing::instrument(level = "debug", skip(self, generated_groups), err)]
    pub(crate) fn init_groups(
        &mut self,
        generated_groups: Vec<GeneratedGroup>,
        reset: bool,
    ) -> FlowyResult<Option<GroupViewChangesetPB>> {
        let mut new_groups = vec![];
        let mut filter_content_map = HashMap::new();
        generated_groups.into_iter().for_each(|generate_group| {
            filter_content_map.insert(generate_group.group_rev.id.clone(), generate_group.filter_content);
            new_groups.push(generate_group.group_rev);
        });

        let MergeGroupResult {
            mut all_group_revs,
            new_group_revs,
            updated_group_revs: _,
            deleted_group_revs,
        } = if reset {
            merge_groups(&[], new_groups)
        } else {
            merge_groups(&self.configuration.groups, new_groups)
        };

        let deleted_group_ids = deleted_group_revs
            .into_iter()
            .map(|group_rev| group_rev.id)
            .collect::<Vec<String>>();

        self.mut_configuration(|configuration| {
            let mut is_changed = false;
            if !deleted_group_ids.is_empty() {
                configuration
                    .groups
                    .retain(|group| !deleted_group_ids.contains(&group.id));
                is_changed = true;
            }

            for group_rev in &mut all_group_revs {
                match configuration
                    .groups
                    .iter()
                    .position(|old_group_rev| old_group_rev.id == group_rev.id)
                {
                    None => {
                        configuration.groups.push(group_rev.clone());
                        is_changed = true;
                    }
                    Some(pos) => {
                        let mut old_group = configuration.groups.remove(pos);
                        group_rev.update_with_other(&old_group);

                        // Take the GroupRevision if the name has changed
                        if is_group_changed(group_rev, &old_group) {
                            old_group.name = group_rev.name.clone();
                            is_changed = true;
                            configuration.groups.insert(pos, old_group);
                        }
                    }
                }
            }
            is_changed
        })?;

        // The len of the filter_content_map should equal to the len of the all_group_revs
        debug_assert_eq!(filter_content_map.len(), all_group_revs.len());
        all_group_revs.into_iter().for_each(|group_rev| {
            if let Some(filter_content) = filter_content_map.get(&group_rev.id) {
                let group = Group::new(
                    group_rev.id,
                    self.field_rev.id.clone(),
                    group_rev.name,
                    filter_content.clone(),
                );
                self.groups_map.insert(group.id.clone(), group);
            }
        });

        let new_groups = new_group_revs
            .into_iter()
            .flat_map(|group_rev| {
                let filter_content = filter_content_map.get(&group_rev.id)?;
                let group = Group::new(
                    group_rev.id,
                    self.field_rev.id.clone(),
                    group_rev.name,
                    filter_content.clone(),
                );
                Some(GroupPB::from(group))
            })
            .collect();

        let changeset = GroupViewChangesetPB {
            view_id: self.view_id.clone(),
            new_groups,
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

    #[allow(dead_code)]
    pub(crate) async fn hide_group(&mut self, group_id: &str) -> FlowyResult<()> {
        self.mut_group_rev(group_id, |group_rev| {
            group_rev.visible = false;
        })?;
        Ok(())
    }

    #[allow(dead_code)]
    pub(crate) async fn show_group(&mut self, group_id: &str) -> FlowyResult<()> {
        self.mut_group_rev(group_id, |group_rev| {
            group_rev.visible = true;
        })?;
        Ok(())
    }

    pub(crate) fn get_mut_default_group(&mut self) -> &mut Group {
        &mut self.default_group
    }

    pub(crate) fn get_mut_group(&mut self, group_id: &str) -> Option<&mut Group> {
        self.groups_map.get_mut(group_id)
    }

    // Returns the index and group specified by the group_id
    pub(crate) fn get_group(&self, group_id: &str) -> Option<(usize, &Group)> {
        match (self.groups_map.get_index_of(group_id), self.groups_map.get(group_id)) {
            (Some(index), Some(group)) => Some((index, group)),
            _ => None,
        }
    }

    pub fn save_configuration(&self) -> FlowyResult<()> {
        let configuration = (&*self.configuration).clone();
        let writer = self.writer.clone();
        let field_id = self.field_rev.id.clone();
        let field_type = self.field_rev.ty;
        tokio::spawn(async move {
            match writer.save_configuration(&field_id, field_type, configuration).await {
                Ok(_) => {}
                Err(e) => {
                    tracing::error!("Save group configuration failed: {}", e);
                }
            }
        });

        Ok(())
    }

    fn mut_configuration(
        &mut self,
        mut_configuration_fn: impl FnOnce(&mut GroupConfigurationRevision) -> bool,
    ) -> FlowyResult<()> {
        let configuration = Arc::make_mut(&mut self.configuration);
        let is_changed = mut_configuration_fn(configuration);
        if is_changed {
            let _ = self.save_configuration()?;
        }
        Ok(())
    }

    fn mut_group_rev(&mut self, group_id: &str, mut_groups_fn: impl Fn(&mut GroupRevision)) -> FlowyResult<()> {
        self.mut_configuration(|configuration| {
            match configuration.groups.iter_mut().find(|group| group.id == group_id) {
                None => false,
                Some(group_rev) => {
                    mut_groups_fn(group_rev);
                    true
                }
            }
        })
    }
}

fn merge_groups(old_groups: &[GroupRevision], new_groups: Vec<GroupRevision>) -> MergeGroupResult {
    let mut merge_result = MergeGroupResult::new();
    if old_groups.is_empty() {
        merge_result.all_group_revs = new_groups.clone();
        merge_result.new_group_revs = new_groups;
        return merge_result;
    }

    // group_map is a helper map is used to filter out the new groups.
    let mut new_group_map: IndexMap<String, GroupRevision> = IndexMap::new();
    new_groups.into_iter().for_each(|group_rev| {
        new_group_map.insert(group_rev.id.clone(), group_rev);
    });

    // The group is ordered in old groups. Add them before adding the new groups
    for old in old_groups {
        if let Some(new) = new_group_map.remove(&old.id) {
            merge_result.all_group_revs.push(new.clone());
            if is_group_changed(&new, old) {
                merge_result.updated_group_revs.push(new);
            }
        } else {
            merge_result.deleted_group_revs.push(old.clone());
        }
    }

    // Find out the new groups
    let new_groups = new_group_map.into_values();
    for (_, group) in new_groups.into_iter().enumerate() {
        merge_result.all_group_revs.push(group.clone());
        merge_result.new_group_revs.push(group);
    }
    merge_result
}

fn is_group_changed(new: &GroupRevision, old: &GroupRevision) -> bool {
    if new.name != old.name {
        return true;
    }

    false
}

struct MergeGroupResult {
    // Contains the new groups and the updated groups
    all_group_revs: Vec<GroupRevision>,
    new_group_revs: Vec<GroupRevision>,
    updated_group_revs: Vec<GroupRevision>,
    deleted_group_revs: Vec<GroupRevision>,
}

impl MergeGroupResult {
    fn new() -> Self {
        Self {
            all_group_revs: vec![],
            new_group_revs: vec![],
            updated_group_revs: vec![],
            deleted_group_revs: vec![],
        }
    }
}
