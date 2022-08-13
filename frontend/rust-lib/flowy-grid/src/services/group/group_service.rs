use crate::services::block_manager::GridBlockManager;
use crate::services::grid_editor_task::GridServiceTaskScheduler;
use crate::services::group::{
    CheckboxGroupController, Group, GroupActionHandler, GroupCellContentProvider, MultiSelectGroupController,
    SingleSelectGroupController,
};

use crate::entities::{
    CheckboxGroupConfigurationPB, CreateBoardCardParams, DateGroupConfigurationPB, FieldType, GroupPB,
    NumberGroupConfigurationPB, RowPB, SelectOptionGroupConfigurationPB, TextGroupConfigurationPB,
    UrlGroupConfigurationPB,
};
use bytes::Bytes;
use flowy_error::FlowyResult;
use flowy_grid_data_model::revision::{gen_grid_group_id, FieldRevision, GroupConfigurationRevision, RowRevision};
use flowy_sync::client_grid::GridRevisionPad;
use std::sync::Arc;
use tokio::sync::RwLock;

pub(crate) struct GridGroupService {
    #[allow(dead_code)]
    scheduler: Arc<dyn GridServiceTaskScheduler>,
    grid_pad: Arc<RwLock<GridRevisionPad>>,
    block_manager: Arc<GridBlockManager>,
    group_action_handler: Option<Arc<RwLock<dyn GroupActionHandler>>>,
}

impl GridGroupService {
    pub(crate) async fn new<S: GridServiceTaskScheduler>(
        grid_pad: Arc<RwLock<GridRevisionPad>>,
        block_manager: Arc<GridBlockManager>,
        scheduler: S,
    ) -> Self {
        let scheduler = Arc::new(scheduler);
        Self {
            scheduler,
            grid_pad,
            block_manager,
            group_action_handler: None,
        }
    }

    pub(crate) async fn load_groups(&mut self) -> Option<Vec<GroupPB>> {
        let field_rev = find_group_field(self.grid_pad.read().await.fields()).unwrap();
        let field_type: FieldType = field_rev.field_type_rev.into();
        let configuration = self.get_group_configuration(&field_rev).await;

        let blocks = self.block_manager.get_block_snapshots(None).await.unwrap();
        let row_revs = blocks
            .into_iter()
            .map(|block| block.row_revs)
            .flatten()
            .collect::<Vec<Arc<RowRevision>>>();

        match self
            .build_groups(&field_type, &field_rev, row_revs, configuration)
            .await
        {
            Ok(groups) => Some(groups),
            Err(_) => None,
        }
    }

    pub(crate) async fn create_board_card(&self, row_rev: &mut RowRevision) {
        if let Some(group_action_handler) = self.group_action_handler.as_ref() {
            group_action_handler.write().await.create_card(row_rev);
        }
    }

    pub(crate) async fn get_group_configuration(&self, field_rev: &FieldRevision) -> GroupConfigurationRevision {
        let grid_pad = self.grid_pad.read().await;
        let setting = grid_pad.get_setting_rev();
        let layout = &setting.layout;
        let configurations = setting.get_groups(layout, &field_rev.id, &field_rev.field_type_rev);
        match configurations {
            None => default_group_configuration(field_rev),
            Some(mut configurations) => {
                assert_eq!(configurations.len(), 1);
                (&*configurations.pop().unwrap()).clone()
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
    ) -> FlowyResult<Vec<GroupPB>> {
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
                let controller = SingleSelectGroupController::new(field_rev.clone(), configuration, &self.grid_pad)?;
                self.group_action_handler = Some(Arc::new(RwLock::new(controller)));
            }
            FieldType::MultiSelect => {
                let controller = MultiSelectGroupController::new(field_rev.clone(), configuration, &self.grid_pad)?;
                self.group_action_handler = Some(Arc::new(RwLock::new(controller)));
            }
            FieldType::Checkbox => {
                let controller = CheckboxGroupController::new(field_rev.clone(), configuration, &self.grid_pad)?;
                self.group_action_handler = Some(Arc::new(RwLock::new(controller)));
            }
            FieldType::URL => {
                // let generator = GroupGenerator::<UrlGroupConfigurationPB>::from_configuration(configuration);
            }
        };

        let mut groups = vec![];
        if let Some(group_action_handler) = self.group_action_handler.as_ref() {
            let mut write_guard = group_action_handler.write().await;
            let _ = write_guard.group_rows(&row_revs)?;
            groups = write_guard.get_groups();
            drop(write_guard);
        }

        Ok(groups.into_iter().map(GroupPB::from).collect())
    }
}

fn find_group_field(field_revs: &[Arc<FieldRevision>]) -> Option<Arc<FieldRevision>> {
    let field_rev = field_revs
        .iter()
        .find(|field_rev| {
            let field_type: FieldType = field_rev.field_type_rev.into();
            field_type.can_be_group()
        })
        .cloned();
    field_rev
}

impl GroupCellContentProvider for Arc<RwLock<GridRevisionPad>> {}

fn default_group_configuration(field_rev: &FieldRevision) -> GroupConfigurationRevision {
    let field_type: FieldType = field_rev.field_type_rev.clone().into();
    let bytes: Bytes = match field_type {
        FieldType::RichText => TextGroupConfigurationPB::default().try_into().unwrap(),
        FieldType::Number => NumberGroupConfigurationPB::default().try_into().unwrap(),
        FieldType::DateTime => DateGroupConfigurationPB::default().try_into().unwrap(),
        FieldType::SingleSelect => SelectOptionGroupConfigurationPB::default().try_into().unwrap(),
        FieldType::MultiSelect => SelectOptionGroupConfigurationPB::default().try_into().unwrap(),
        FieldType::Checkbox => CheckboxGroupConfigurationPB::default().try_into().unwrap(),
        FieldType::URL => UrlGroupConfigurationPB::default().try_into().unwrap(),
    };
    GroupConfigurationRevision {
        id: gen_grid_group_id(),
        field_id: field_rev.id.clone(),
        field_type_rev: field_rev.field_type_rev.clone(),
        content: Some(bytes.to_vec()),
    }
}
