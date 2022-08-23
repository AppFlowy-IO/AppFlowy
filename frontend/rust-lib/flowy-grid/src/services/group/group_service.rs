use crate::entities::{FieldType, GroupRowsChangesetPB};
use crate::services::group::configuration::GroupConfigurationReader;
use crate::services::group::controller::{GroupController, MoveGroupRowContext};
use crate::services::group::{
    CheckboxGroupConfiguration, CheckboxGroupController, Group, GroupConfigurationWriter, MultiSelectGroupController,
    SelectOptionGroupConfiguration, SingleSelectGroupController,
};
use flowy_error::FlowyResult;
use flowy_grid_data_model::revision::{
    CheckboxGroupConfigurationRevision, DateGroupConfigurationRevision, FieldRevision, GroupConfigurationRevision,
    NumberGroupConfigurationRevision, RowChangeset, RowRevision, SelectOptionGroupConfigurationRevision,
    TextGroupConfigurationRevision, UrlGroupConfigurationRevision,
};
use std::future::Future;
use std::sync::Arc;

pub(crate) struct GroupService {
    configuration_reader: Arc<dyn GroupConfigurationReader>,
    configuration_writer: Arc<dyn GroupConfigurationWriter>,
    group_controller: Option<Box<dyn GroupController>>,
}

impl GroupService {
    pub(crate) async fn new<R, W>(configuration_reader: R, configuration_writer: W) -> Self
    where
        R: GroupConfigurationReader,
        W: GroupConfigurationWriter,
    {
        Self {
            configuration_reader: Arc::new(configuration_reader),
            configuration_writer: Arc::new(configuration_writer),
            group_controller: None,
        }
    }

    pub(crate) async fn groups(&self) -> Vec<Group> {
        self.group_controller
            .as_ref()
            .and_then(|group_controller| Some(group_controller.groups()))
            .unwrap_or(vec![])
    }

    pub(crate) async fn get_group(&self, group_id: &str) -> Option<(usize, Group)> {
        self.group_controller
            .as_ref()
            .and_then(|group_controller| group_controller.get_group(group_id))
    }

    pub(crate) async fn load_groups(
        &mut self,
        field_revs: &[Arc<FieldRevision>],
        row_revs: Vec<Arc<RowRevision>>,
    ) -> Option<Vec<Group>> {
        let field_rev = find_group_field(field_revs)?;
        let field_type: FieldType = field_rev.ty.into();

        let mut group_controller = self.make_group_controller(&field_type, &field_rev).await.ok()??;
        let groups = match group_controller.fill_groups(&row_revs, &field_rev) {
            Ok(groups) => groups,
            Err(e) => {
                tracing::error!("Fill groups failed:{:?}", e);
                vec![]
            }
        };
        self.group_controller = Some(group_controller);
        Some(groups)
    }

    pub(crate) async fn will_create_row<F, O>(&mut self, row_rev: &mut RowRevision, group_id: &str, get_field_fn: F)
    where
        F: FnOnce(String) -> O,
        O: Future<Output = Option<Arc<FieldRevision>>> + Send + Sync + 'static,
    {
        if let Some(group_controller) = self.group_controller.as_mut() {
            let field_id = group_controller.field_id().to_owned();
            match get_field_fn(field_id).await {
                None => {}
                Some(field_rev) => {
                    group_controller.will_create_row(row_rev, &field_rev, group_id);
                }
            }
        }
    }

    pub(crate) async fn did_delete_row<F, O>(
        &mut self,
        row_rev: &RowRevision,
        get_field_fn: F,
    ) -> Option<Vec<GroupRowsChangesetPB>>
    where
        F: FnOnce(String) -> O,
        O: Future<Output = Option<Arc<FieldRevision>>> + Send + Sync + 'static,
    {
        let group_controller = self.group_controller.as_mut()?;
        let field_id = group_controller.field_id().to_owned();
        let field_rev = get_field_fn(field_id).await?;

        match group_controller.did_delete_row(row_rev, &field_rev) {
            Ok(changesets) => Some(changesets),
            Err(e) => {
                tracing::error!("Delete group data failed, {:?}", e);
                None
            }
        }
    }

    pub(crate) async fn move_group_row<F, O>(
        &mut self,
        row_rev: &RowRevision,
        row_changeset: &mut RowChangeset,
        to_group_id: &str,
        to_row_id: Option<String>,
        get_field_fn: F,
    ) -> Option<Vec<GroupRowsChangesetPB>>
    where
        F: FnOnce(String) -> O,
        O: Future<Output = Option<Arc<FieldRevision>>> + Send + Sync + 'static,
    {
        let group_controller = self.group_controller.as_mut()?;
        let field_id = group_controller.field_id().to_owned();
        let field_rev = get_field_fn(field_id).await?;
        let move_row_context = MoveGroupRowContext {
            row_rev,
            row_changeset,
            field_rev: field_rev.as_ref(),
            to_group_id,
            to_row_id,
        };

        match group_controller.move_group_row(move_row_context) {
            Ok(changesets) => Some(changesets),
            Err(e) => {
                tracing::error!("Move group data failed, {:?}", e);
                None
            }
        }
    }

    #[tracing::instrument(level = "trace", skip_all)]
    pub(crate) async fn did_update_row<F, O>(
        &mut self,
        row_rev: &RowRevision,
        get_field_fn: F,
    ) -> Option<Vec<GroupRowsChangesetPB>>
    where
        F: FnOnce(String) -> O,
        O: Future<Output = Option<Arc<FieldRevision>>> + Send + Sync + 'static,
    {
        let group_controller = self.group_controller.as_mut()?;
        let field_id = group_controller.field_id().to_owned();
        let field_rev = get_field_fn(field_id).await?;

        match group_controller.did_update_row(row_rev, &field_rev) {
            Ok(changeset) => Some(changeset),
            Err(e) => {
                tracing::error!("Update group data failed, {:?}", e);
                None
            }
        }
    }

    #[tracing::instrument(level = "trace", skip_all)]
    pub(crate) async fn move_group(&mut self, from_group_id: &str, to_group_id: &str) -> FlowyResult<()> {
        match self.group_controller.as_mut() {
            None => Ok(()),
            Some(group_controller) => {
                let _ = group_controller.move_group(from_group_id, to_group_id)?;
                Ok(())
            }
        }
    }

    #[tracing::instrument(level = "trace", skip(self, field_rev), err)]
    async fn make_group_controller(
        &self,
        field_type: &FieldType,
        field_rev: &Arc<FieldRevision>,
    ) -> FlowyResult<Option<Box<dyn GroupController>>> {
        let mut group_controller: Option<Box<dyn GroupController>> = None;
        match field_type {
            FieldType::RichText => {
                // let generator = GroupGenerator::<TextGroupConfigurationPB>::from_configuration(configuration);
            }
            FieldType::Number => {
                // let generator = GroupGenerator::<NumberGroupConfigurationPB>::from_configuration(configuration);
            }
            FieldType::DateTime => {
                // let generator = GroupGenerator::<DateGroupConfigurationPB>::from_configuration(configuration);
            }
            FieldType::SingleSelect => {
                let configuration = SelectOptionGroupConfiguration::new(
                    field_rev.clone(),
                    self.configuration_reader.clone(),
                    self.configuration_writer.clone(),
                )
                .await?;
                let controller = SingleSelectGroupController::new(field_rev, configuration).await?;
                group_controller = Some(Box::new(controller));
            }
            FieldType::MultiSelect => {
                let configuration = SelectOptionGroupConfiguration::new(
                    field_rev.clone(),
                    self.configuration_reader.clone(),
                    self.configuration_writer.clone(),
                )
                .await?;
                let controller = MultiSelectGroupController::new(field_rev, configuration).await?;
                group_controller = Some(Box::new(controller));
            }
            FieldType::Checkbox => {
                let configuration = CheckboxGroupConfiguration::new(
                    field_rev.clone(),
                    self.configuration_reader.clone(),
                    self.configuration_writer.clone(),
                )
                .await?;
                let controller = CheckboxGroupController::new(field_rev, configuration).await?;
                group_controller = Some(Box::new(controller));
            }
            FieldType::URL => {
                // let generator = GroupGenerator::<UrlGroupConfigurationPB>::from_configuration(configuration);
            }
        }
        Ok(group_controller)
    }
}

fn find_group_field(field_revs: &[Arc<FieldRevision>]) -> Option<Arc<FieldRevision>> {
    let field_rev = field_revs
        .iter()
        .find(|field_rev| {
            let field_type: FieldType = field_rev.ty.into();
            field_type.can_be_group()
        })
        .cloned();
    field_rev
}

pub fn default_group_configuration(field_rev: &FieldRevision) -> GroupConfigurationRevision {
    let field_id = field_rev.id.clone();
    let field_type_rev = field_rev.ty;
    let field_type: FieldType = field_rev.ty.into();
    match field_type {
        FieldType::RichText => {
            GroupConfigurationRevision::new(field_id, field_type_rev, TextGroupConfigurationRevision::default())
                .unwrap()
        }
        FieldType::Number => {
            GroupConfigurationRevision::new(field_id, field_type_rev, NumberGroupConfigurationRevision::default())
                .unwrap()
        }
        FieldType::DateTime => {
            GroupConfigurationRevision::new(field_id, field_type_rev, DateGroupConfigurationRevision::default())
                .unwrap()
        }

        FieldType::SingleSelect => GroupConfigurationRevision::new(
            field_id,
            field_type_rev,
            SelectOptionGroupConfigurationRevision::default(),
        )
        .unwrap(),
        FieldType::MultiSelect => GroupConfigurationRevision::new(
            field_id,
            field_type_rev,
            SelectOptionGroupConfigurationRevision::default(),
        )
        .unwrap(),
        FieldType::Checkbox => {
            GroupConfigurationRevision::new(field_id, field_type_rev, CheckboxGroupConfigurationRevision::default())
                .unwrap()
        }
        FieldType::URL => {
            GroupConfigurationRevision::new(field_id, field_type_rev, UrlGroupConfigurationRevision::default()).unwrap()
        }
    }
}
