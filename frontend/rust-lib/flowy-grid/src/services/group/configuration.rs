use crate::services::group::Group;
use flowy_error::FlowyResult;
use flowy_grid_data_model::revision::{
    FieldRevision, FieldTypeRevision, GroupConfigurationContent, GroupConfigurationRevision, GroupRecordRevision,
};

use lib_infra::future::AFFuture;
use std::sync::Arc;

pub trait GroupConfigurationReader: Send + Sync + 'static {
    fn get_group_configuration(&self, field_rev: Arc<FieldRevision>) -> AFFuture<Arc<GroupConfigurationRevision>>;
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
    // pub groups_map: IndexMap<String, Group>,
    configuration_id: String,
    field_rev: Arc<FieldRevision>,
    reader: Arc<dyn GroupConfigurationReader>,
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
        let configuration_rev = reader.get_group_configuration(field_rev.clone()).await;
        let configuration_id = configuration_rev.id.clone();
        let configuration = C::from_configuration_content(&configuration_rev.content)?;
        Ok(Self {
            configuration_id,
            field_rev,
            reader,
            writer,
            configuration,
        })
    }

    #[allow(dead_code)]
    fn group_records(&self) -> &[GroupRecordRevision] {
        todo!()
    }
    pub(crate) async fn merge_groups(&mut self, groups: &[Group]) -> FlowyResult<()> {
        match merge_groups(self.configuration.get_groups(), groups) {
            None => Ok(()),
            Some(new_groups) => {
                self.configuration.set_groups(new_groups);
                let _ = self.save_configuration().await?;
                Ok(())
            }
        }
    }

    #[allow(dead_code)]
    pub(crate) async fn hide_group(&mut self, group_id: &str) -> FlowyResult<()> {
        self.configuration.mut_group(group_id, |group_rev| {
            group_rev.visible = false;
        });
        let _ = self.save_configuration().await?;
        Ok(())
    }

    #[allow(dead_code)]
    pub(crate) async fn show_group(&mut self, group_id: &str) -> FlowyResult<()> {
        self.configuration.mut_group(group_id, |group_rev| {
            group_rev.visible = true;
        });
        let _ = self.save_configuration().await?;
        Ok(())
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

impl<T> GroupConfigurationReader for Arc<T>
where
    T: GroupConfigurationReader,
{
    fn get_group_configuration(&self, field_rev: Arc<FieldRevision>) -> AFFuture<Arc<GroupConfigurationRevision>> {
        (**self).get_group_configuration(field_rev)
    }
}

fn merge_groups(old_group: &[GroupRecordRevision], groups: &[Group]) -> Option<Vec<GroupRecordRevision>> {
    // tracing::trace!("Merge group: old: {}, new: {}", old_group.len(), groups.len());
    if old_group.is_empty() {
        let new_groups = groups
            .iter()
            .map(|group| GroupRecordRevision::new(group.id.clone()))
            .collect();
        return Some(new_groups);
    }

    let new_groups = groups
        .iter()
        .filter(|group| !old_group.iter().any(|group_rev| group_rev.group_id == group.id))
        .collect::<Vec<&Group>>();

    if new_groups.is_empty() {
        return None;
    }

    let mut old_group = old_group.to_vec();
    let new_groups = new_groups
        .iter()
        .map(|group| GroupRecordRevision::new(group.id.clone()));
    old_group.extend(new_groups);
    Some(old_group)
}
