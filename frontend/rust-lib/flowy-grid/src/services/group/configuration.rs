use crate::entities::{GroupPB, GroupViewChangesetPB, InsertedGroupPB};
use crate::services::group::{default_group_configuration, Group};
use flowy_error::{FlowyError, FlowyResult};
use flowy_grid_data_model::revision::{
    FieldRevision, FieldTypeRevision, GroupConfigurationContentSerde, GroupConfigurationRevision, GroupRevision,
};
use indexmap::IndexMap;
use lib_infra::future::AFFuture;
use std::fmt::Formatter;
use std::marker::PhantomData;
use std::sync::Arc;

pub trait GroupConfigurationReader: Send + Sync + 'static {
    fn get_group_configuration(
        &self,
        field_rev: Arc<FieldRevision>,
    ) -> AFFuture<Option<Arc<GroupConfigurationRevision>>>;
}

pub trait GroupConfigurationWriter: Send + Sync + 'static {
    fn save_group_configuration(
        &self,
        field_id: &str,
        field_type: FieldTypeRevision,
        group_configuration: GroupConfigurationRevision,
    ) -> AFFuture<FlowyResult<()>>;
}

impl<T> std::fmt::Display for GenericGroupConfiguration<T> {
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

pub struct GenericGroupConfiguration<C> {
    view_id: String,
    pub configuration: Arc<GroupConfigurationRevision>,
    configuration_content: PhantomData<C>,
    field_rev: Arc<FieldRevision>,
    groups_map: IndexMap<String, Group>,
    /// default_group is used to store the rows that don't belong to any groups.
    default_group: Group,
    writer: Arc<dyn GroupConfigurationWriter>,
}

impl<C> GenericGroupConfiguration<C>
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
            rows: vec![],
            content: "".to_string(),
        };
        let configuration = match reader.get_group_configuration(field_rev.clone()).await {
            None => {
                let default_group_configuration = default_group_configuration(&field_rev);
                writer
                    .save_group_configuration(&field_rev.id, field_rev.ty, default_group_configuration.clone())
                    .await?;
                Arc::new(default_group_configuration)
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

    pub(crate) fn merge_groups(&mut self, groups: Vec<Group>) -> FlowyResult<Option<GroupViewChangesetPB>> {
        let MergeGroupResult {
            groups,
            inserted_groups,
            updated_groups,
        } = merge_groups(&self.configuration.groups, groups);

        let group_revs = groups
            .iter()
            .map(|group| GroupRevision::new(group.id.clone(), group.name.clone()))
            .collect::<Vec<GroupRevision>>();

        self.mut_configuration(move |configuration| {
            let mut is_changed = false;
            for new_group_rev in group_revs {
                match configuration
                    .groups
                    .iter()
                    .position(|group_rev| group_rev.id == new_group_rev.id)
                {
                    None => {
                        configuration.groups.push(new_group_rev);
                        is_changed = true;
                    }
                    Some(pos) => {
                        let removed_group = configuration.groups.remove(pos);
                        if removed_group != new_group_rev {
                            is_changed = true;
                        }
                        configuration.groups.insert(pos, new_group_rev);
                    }
                }
            }
            is_changed
        })?;

        groups.into_iter().for_each(|group| {
            self.groups_map.insert(group.id.clone(), group);
        });

        let changeset = make_group_view_changeset(self.view_id.clone(), inserted_groups, updated_groups);
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
            match writer
                .save_group_configuration(&field_id, field_type, configuration)
                .await
            {
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

fn merge_groups(old_groups: &[GroupRevision], groups: Vec<Group>) -> MergeGroupResult {
    let mut merge_result = MergeGroupResult::new();
    if old_groups.is_empty() {
        merge_result.groups = groups;
        return merge_result;
    }

    // group_map is a helper map is used to filter out the new groups.
    let mut group_map: IndexMap<String, Group> = IndexMap::new();
    groups.into_iter().for_each(|group| {
        group_map.insert(group.id.clone(), group);
    });

    // The group is ordered in old groups. Add them before adding the new groups
    for group_rev in old_groups {
        if let Some(group) = group_map.remove(&group_rev.id) {
            if group.name == group_rev.name {
                merge_result.add_group(group);
            } else {
                merge_result.add_updated_group(group);
            }
        }
    }

    // Find out the new groups
    let new_groups = group_map.into_values();
    for (index, group) in new_groups.into_iter().enumerate() {
        merge_result.add_insert_group(index, group);
    }
    merge_result
}

struct MergeGroupResult {
    groups: Vec<Group>,
    inserted_groups: Vec<InsertedGroupPB>,
    updated_groups: Vec<Group>,
}

impl MergeGroupResult {
    fn new() -> Self {
        Self {
            groups: vec![],
            inserted_groups: vec![],
            updated_groups: vec![],
        }
    }

    fn add_updated_group(&mut self, group: Group) {
        self.groups.push(group.clone());
        self.updated_groups.push(group);
    }

    fn add_group(&mut self, group: Group) {
        self.groups.push(group);
    }

    fn add_insert_group(&mut self, index: usize, group: Group) {
        self.groups.push(group.clone());
        let inserted_group = InsertedGroupPB {
            group: GroupPB::from(group),
            index: index as i32,
        };
        self.inserted_groups.push(inserted_group);
    }
}

fn make_group_view_changeset(
    view_id: String,
    inserted_groups: Vec<InsertedGroupPB>,
    updated_group: Vec<Group>,
) -> GroupViewChangesetPB {
    GroupViewChangesetPB {
        view_id,
        inserted_groups,
        deleted_groups: vec![],
        update_groups: updated_group.into_iter().map(GroupPB::from).collect(),
    }
}
