use crate::services::group::{default_group_configuration, Group};
use flowy_error::{FlowyError, FlowyResult};
use flowy_grid_data_model::revision::{
    FieldRevision, FieldTypeRevision, GroupConfigurationContentSerde, GroupConfigurationRevision, GroupRecordRevision,
};
use std::marker::PhantomData;

use indexmap::IndexMap;
use lib_infra::future::AFFuture;
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

pub struct GenericGroupConfiguration<C> {
    pub configuration: Arc<GroupConfigurationRevision>,
    configuration_content: PhantomData<C>,
    field_rev: Arc<FieldRevision>,
    groups_map: IndexMap<String, Group>,
    writer: Arc<dyn GroupConfigurationWriter>,
}

impl<C> GenericGroupConfiguration<C>
where
    C: GroupConfigurationContentSerde,
{
    #[tracing::instrument(level = "trace", skip_all, err)]
    pub async fn new(
        field_rev: Arc<FieldRevision>,
        reader: Arc<dyn GroupConfigurationReader>,
        writer: Arc<dyn GroupConfigurationWriter>,
    ) -> FlowyResult<Self> {
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
            field_rev,
            groups_map: IndexMap::new(),
            writer,
            configuration,
            configuration_content: PhantomData,
        })
    }

    pub(crate) fn groups(&self) -> Vec<&Group> {
        self.groups_map.values().collect()
    }

    pub(crate) fn clone_groups(&self) -> Vec<Group> {
        self.groups_map.values().cloned().collect()
    }

    pub(crate) async fn merge_groups(&mut self, groups: Vec<Group>) -> FlowyResult<()> {
        let (group_revs, groups) = merge_groups(&self.configuration.groups, groups);
        self.mut_configuration(move |configuration| {
            configuration.groups = group_revs;
            true
        })?;

        groups.into_iter().for_each(|group| {
            self.groups_map.insert(group.id.clone(), group);
        });
        Ok(())
    }

    #[allow(dead_code)]
    pub(crate) async fn hide_group(&mut self, group_id: &str) -> FlowyResult<()> {
        self.mut_configuration_group(group_id, |group_rev| {
            group_rev.visible = false;
        })?;
        Ok(())
    }

    #[allow(dead_code)]
    pub(crate) async fn show_group(&mut self, group_id: &str) -> FlowyResult<()> {
        self.mut_configuration_group(group_id, |group_rev| {
            group_rev.visible = true;
        })?;
        Ok(())
    }

    pub(crate) fn with_mut_groups(&mut self, mut each: impl FnMut(&mut Group)) {
        self.groups_map.iter_mut().for_each(|(_, group)| {
            each(group);
        })
    }

    pub(crate) fn get_mut_group(&mut self, group_id: &str) -> Option<&mut Group> {
        self.groups_map.get_mut(group_id)
    }

    pub(crate) fn move_group(&mut self, from_id: &str, to_id: &str) -> FlowyResult<()> {
        let from_index = self.groups_map.get_index_of(from_id);
        let to_index = self.groups_map.get_index_of(to_id);
        match (from_index, to_index) {
            (Some(from_index), Some(to_index)) => {
                self.groups_map.swap_indices(from_index, to_index);

                self.mut_configuration(|configuration| {
                    let from_index = configuration.groups.iter().position(|group| group.group_id == from_id);
                    let to_index = configuration.groups.iter().position(|group| group.group_id == to_id);
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

    fn mut_configuration_group(
        &mut self,
        group_id: &str,
        mut_groups_fn: impl Fn(&mut GroupRecordRevision),
    ) -> FlowyResult<()> {
        self.mut_configuration(|configuration| {
            match configuration.groups.iter_mut().find(|group| group.group_id == group_id) {
                None => false,
                Some(group_rev) => {
                    mut_groups_fn(group_rev);
                    true
                }
            }
        })
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
}

fn merge_groups(old_group_revs: &[GroupRecordRevision], groups: Vec<Group>) -> (Vec<GroupRecordRevision>, Vec<Group>) {
    if old_group_revs.is_empty() {
        let new_groups = groups
            .iter()
            .map(|group| GroupRecordRevision::new(group.id.clone()))
            .collect();
        return (new_groups, groups);
    }

    let mut group_map: IndexMap<String, Group> = IndexMap::new();
    groups.into_iter().for_each(|group| {
        group_map.insert(group.id.clone(), group);
    });

    // Inert
    let mut sorted_groups: Vec<Group> = vec![];
    for group_rev in old_group_revs {
        if let Some(group) = group_map.remove(&group_rev.group_id) {
            sorted_groups.push(group);
        }
    }
    sorted_groups.extend(group_map.into_values().collect::<Vec<Group>>());
    let new_group_revs = sorted_groups
        .iter()
        .map(|group| GroupRecordRevision::new(group.id.clone()))
        .collect::<Vec<GroupRecordRevision>>();

    tracing::trace!("group revs: {}, groups: {}", new_group_revs.len(), sorted_groups.len());
    (new_group_revs, sorted_groups)
}
