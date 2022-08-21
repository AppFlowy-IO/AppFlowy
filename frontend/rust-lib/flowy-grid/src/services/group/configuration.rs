use crate::services::group::{default_group_configuration, Group};
use flowy_error::{FlowyError, FlowyResult};
use flowy_grid_data_model::revision::{
    FieldRevision, FieldTypeRevision, GroupConfigurationContent, GroupConfigurationRevision, GroupRecordRevision,
};

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
        configuration_id: &str,
        content: String,
    ) -> AFFuture<FlowyResult<()>>;
}

pub struct GenericGroupConfiguration<C> {
    pub configuration: C,
    configuration_id: String,
    field_rev: Arc<FieldRevision>,
    groups_map: IndexMap<String, Group>,
    writer: Arc<dyn GroupConfigurationWriter>,
}

impl<C> GenericGroupConfiguration<C>
where
    C: GroupConfigurationContent,
{
    pub async fn new(
        field_rev: Arc<FieldRevision>,
        reader: Arc<dyn GroupConfigurationReader>,
        writer: Arc<dyn GroupConfigurationWriter>,
    ) -> FlowyResult<Self> {
        let configuration_rev = match reader.get_group_configuration(field_rev.clone()).await {
            None => {
                let default_group_configuration = default_group_configuration(&field_rev);
                writer
                    .save_group_configuration(
                        &field_rev.id,
                        field_rev.ty,
                        &default_group_configuration.id,
                        default_group_configuration.content.clone(),
                    )
                    .await?;
                Arc::new(default_group_configuration)
            }
            Some(configuration) => configuration,
        };

        let configuration_id = configuration_rev.id.clone();
        let configuration = C::from_configuration_content(&configuration_rev.content)?;
        Ok(Self {
            configuration_id,
            field_rev,
            groups_map: IndexMap::new(),
            writer,
            configuration,
        })
    }

    pub(crate) fn groups(&self) -> Vec<&Group> {
        self.groups_map.values().collect()
    }

    pub(crate) fn clone_groups(&self) -> Vec<Group> {
        self.groups_map.values().cloned().collect()
    }

    pub(crate) async fn merge_groups(&mut self, groups: Vec<Group>) -> FlowyResult<()> {
        let (group_revs, groups) = merge_groups(self.configuration.get_groups(), groups);
        self.configuration.set_groups(group_revs);
        let _ = self.save_configuration().await?;

        tracing::trace!("merge new groups: {}", groups.len());
        groups.into_iter().for_each(|group| {
            self.groups_map.insert(group.id.clone(), group);
        });
        Ok(())
    }

    #[allow(dead_code)]
    pub(crate) async fn hide_group(&mut self, group_id: &str) -> FlowyResult<()> {
        self.configuration.with_mut_group(group_id, |group_rev| {
            group_rev.visible = false;
        });
        let _ = self.save_configuration().await?;
        Ok(())
    }

    #[allow(dead_code)]
    pub(crate) async fn show_group(&mut self, group_id: &str) -> FlowyResult<()> {
        self.configuration.with_mut_group(group_id, |group_rev| {
            group_rev.visible = true;
        });
        let _ = self.save_configuration().await?;
        Ok(())
    }

    pub(crate) fn with_mut_groups(&mut self, mut mut_groups_fn: impl FnMut(&mut Group)) {
        self.groups_map.iter_mut().for_each(|(_, group)| {
            mut_groups_fn(group);
        })
    }

    pub(crate) fn get_mut_group(&mut self, group_id: &str) -> Option<&mut Group> {
        self.groups_map.get_mut(group_id)
    }

    pub(crate) fn move_group(&mut self, from_group_id: &str, to_group_id: &str) -> FlowyResult<()> {
        let from_group_index = self.groups_map.get_index_of(from_group_id);
        let to_group_index = self.groups_map.get_index_of(to_group_id);
        match (from_group_index, to_group_index) {
            (Some(from_index), Some(to_index)) => {
                self.groups_map.swap_indices(from_index, to_index);
                self.configuration.swap_group(from_group_id, to_group_id);
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

    pub async fn save_configuration(&self) -> FlowyResult<()> {
        let content = self.configuration.to_configuration_content()?;
        let _ = self
            .writer
            .save_group_configuration(&self.field_rev.id, self.field_rev.ty, &self.configuration_id, content)
            .await?;
        Ok(())
    }
}

// impl<T> GroupConfigurationReader for Arc<T>
// where
//     T: GroupConfigurationReader,
// {
//     fn get_group_configuration(&self, field_rev: Arc<FieldRevision>) -> AFFuture<Arc<GroupConfigurationRevision>> {
//         (**self).get_group_configuration(field_rev)
//     }
// }

fn merge_groups(old_group_revs: &[GroupRecordRevision], groups: Vec<Group>) -> (Vec<GroupRecordRevision>, Vec<Group>) {
    tracing::trace!("Merge group: old: {}, new: {}", old_group_revs.len(), groups.len());
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

    (new_group_revs, sorted_groups)
}
