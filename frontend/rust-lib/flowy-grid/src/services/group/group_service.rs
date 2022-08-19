use crate::entities::{
    CheckboxGroupConfigurationPB, DateGroupConfigurationPB, FieldType, GroupRowsChangesetPB,
    NumberGroupConfigurationPB, SelectOptionGroupConfigurationPB, TextGroupConfigurationPB, UrlGroupConfigurationPB,
};
use crate::services::group::{
    CheckboxGroupController, Group, GroupController, MultiSelectGroupController, SingleSelectGroupController,
};
use bytes::Bytes;
use flowy_error::FlowyResult;
use flowy_grid_data_model::revision::{
    gen_grid_group_id, CheckboxGroupConfigurationRevision, DateGroupConfigurationRevision, FieldRevision,
    GroupConfigurationRevision, NumberGroupConfigurationRevision, RowChangeset, RowRevision,
    SelectOptionGroupConfigurationRevision, TextGroupConfigurationRevision, UrlGroupConfigurationRevision,
};
use lib_infra::future::AFFuture;
use std::future::Future;
use std::sync::Arc;
use tokio::sync::RwLock;

pub trait GroupConfigurationDelegate: Send + Sync + 'static {
    fn get_group_configuration(&self, field_rev: Arc<FieldRevision>) -> AFFuture<GroupConfigurationRevision>;
}

pub(crate) struct GroupService {
    delegate: Box<dyn GroupConfigurationDelegate>,
    group_controller: Option<Arc<RwLock<dyn GroupController>>>,
}

impl GroupService {
    pub(crate) async fn new(delegate: Box<dyn GroupConfigurationDelegate>) -> Self {
        Self {
            delegate,
            group_controller: None,
        }
    }

    pub(crate) async fn groups(&self) -> Vec<Group> {
        if let Some(group_action_handler) = self.group_controller.as_ref() {
            group_action_handler.read().await.groups()
        } else {
            vec![]
        }
    }

    pub(crate) async fn load_groups(
        &mut self,
        field_revs: &[Arc<FieldRevision>],
        row_revs: Vec<Arc<RowRevision>>,
    ) -> Option<Vec<Group>> {
        let field_rev = find_group_field(field_revs)?;
        let field_type: FieldType = field_rev.ty.into();
        let configuration = self.delegate.get_group_configuration(field_rev.clone()).await;
        match self
            .build_groups(&field_type, &field_rev, row_revs, configuration)
            .await
        {
            Ok(groups) => Some(groups),
            Err(_) => None,
        }
    }

    pub(crate) async fn will_create_row<F, O>(&self, row_rev: &mut RowRevision, group_id: &str, get_field_fn: F)
    where
        F: FnOnce(String) -> O,
        O: Future<Output = Option<Arc<FieldRevision>>> + Send + Sync + 'static,
    {
        if let Some(group_controller) = self.group_controller.as_ref() {
            let field_id = group_controller.read().await.field_id().to_owned();
            match get_field_fn(field_id).await {
                None => {}
                Some(field_rev) => {
                    group_controller
                        .write()
                        .await
                        .will_create_row(row_rev, &field_rev, group_id);
                }
            }
        }
    }

    pub(crate) async fn did_delete_row<F, O>(
        &self,
        row_rev: &RowRevision,
        get_field_fn: F,
    ) -> Option<Vec<GroupRowsChangesetPB>>
    where
        F: FnOnce(String) -> O,
        O: Future<Output = Option<Arc<FieldRevision>>> + Send + Sync + 'static,
    {
        let group_controller = self.group_controller.as_ref()?;
        let field_id = group_controller.read().await.field_id().to_owned();
        let field_rev = get_field_fn(field_id).await?;

        match group_controller.write().await.did_delete_row(row_rev, &field_rev) {
            Ok(changesets) => Some(changesets),
            Err(e) => {
                tracing::error!("Delete group data failed, {:?}", e);
                None
            }
        }
    }

    pub(crate) async fn did_move_row<F, O>(
        &self,
        row_rev: &RowRevision,
        row_changeset: &mut RowChangeset,
        upper_row_id: &str,
        get_field_fn: F,
    ) -> Option<Vec<GroupRowsChangesetPB>>
    where
        F: FnOnce(String) -> O,
        O: Future<Output = Option<Arc<FieldRevision>>> + Send + Sync + 'static,
    {
        let group_controller = self.group_controller.as_ref()?;
        let field_id = group_controller.read().await.field_id().to_owned();
        let field_rev = get_field_fn(field_id).await?;

        match group_controller
            .write()
            .await
            .did_move_row(row_rev, row_changeset, &field_rev, upper_row_id)
        {
            Ok(changesets) => Some(changesets),
            Err(e) => {
                tracing::error!("Move group data failed, {:?}", e);
                None
            }
        }
    }

    #[tracing::instrument(level = "trace", skip_all)]
    pub(crate) async fn did_update_row<F, O>(
        &self,
        row_rev: &RowRevision,
        get_field_fn: F,
    ) -> Option<Vec<GroupRowsChangesetPB>>
    where
        F: FnOnce(String) -> O,
        O: Future<Output = Option<Arc<FieldRevision>>> + Send + Sync + 'static,
    {
        let group_controller = self.group_controller.as_ref()?;
        let field_id = group_controller.read().await.field_id().to_owned();
        let field_rev = get_field_fn(field_id).await?;

        match group_controller.write().await.did_update_row(row_rev, &field_rev) {
            Ok(changeset) => Some(changeset),
            Err(e) => {
                tracing::error!("Update group data failed, {:?}", e);
                None
            }
        }
    }

    #[tracing::instrument(level = "trace", skip_all, err)]
    async fn build_groups(
        &mut self,
        field_type: &FieldType,
        field_rev: &Arc<FieldRevision>,
        row_revs: Vec<Arc<RowRevision>>,
        configuration: GroupConfigurationRevision,
    ) -> FlowyResult<Vec<Group>> {
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
                let controller = SingleSelectGroupController::new(field_rev, configuration)?;
                self.group_controller = Some(Arc::new(RwLock::new(controller)));
            }
            FieldType::MultiSelect => {
                let controller = MultiSelectGroupController::new(field_rev, configuration)?;
                self.group_controller = Some(Arc::new(RwLock::new(controller)));
            }
            FieldType::Checkbox => {
                let controller = CheckboxGroupController::new(field_rev, configuration)?;
                self.group_controller = Some(Arc::new(RwLock::new(controller)));
            }
            FieldType::URL => {
                // let generator = GroupGenerator::<UrlGroupConfigurationPB>::from_configuration(configuration);
            }
        };

        let mut groups = vec![];
        if let Some(group_action_handler) = self.group_controller.as_ref() {
            let mut write_guard = group_action_handler.write().await;
            let _ = write_guard.group_rows(&row_revs, field_rev)?;
            groups = write_guard.groups();
            drop(write_guard);
        }

        Ok(groups)
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
    let field_type_rev = field_rev.ty.clone();
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
