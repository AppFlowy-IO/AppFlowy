use flowy_error::FlowyResult;
use flowy_grid_data_model::revision::{
    FieldRevision, FieldTypeRevision, GroupConfigurationContentSerde, GroupConfigurationRevision, GroupRecordRevision,
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
        configuration: Arc<GroupConfigurationRevision>,
    ) -> AFFuture<FlowyResult<()>>;
}

pub trait GroupConfigurationAction: Send + Sync {
    fn group_records(&self) -> &[GroupRecordRevision];
    fn save_groups(&self) -> FlowyResult<()>;
    fn hide_group(&self, group_id: &str) -> FlowyResult<()>;
    fn show_group(&self, group_id: &str) -> FlowyResult<()>;
}

pub struct GenericGroupConfiguration<C> {
    field_rev: Arc<FieldRevision>,
    reader: Arc<dyn GroupConfigurationReader>,
    writer: Arc<dyn GroupConfigurationWriter>,
    configuration: C,
}

impl<C> GenericGroupConfiguration<C>
where
    C: GroupConfigurationContentSerde,
{
    pub async fn new(
        field_rev: Arc<FieldRevision>,
        reader: Arc<dyn GroupConfigurationReader>,
        writer: Arc<dyn GroupConfigurationWriter>,
    ) -> FlowyResult<Self> {
        let configuration = reader.get_group_configuration(field_rev.clone()).await;
        let configuration = C::from_configuration(&configuration.content)?;
        Ok(Self {
            field_rev,
            reader,
            writer,
            configuration,
        })
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

impl<T> GroupConfigurationWriter for Arc<T>
where
    T: GroupConfigurationWriter,
{
    fn save_group_configuration(
        &self,
        field_id: &str,
        field_type: FieldTypeRevision,
        configuration: Arc<GroupConfigurationRevision>,
    ) -> AFFuture<FlowyResult<()>> {
        (**self).save_group_configuration(field_id, field_type, configuration)
    }
}
