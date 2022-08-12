use crate::services::block_manager::GridBlockManager;
use crate::services::grid_editor_task::GridServiceTaskScheduler;
use crate::services::group::{
    CheckboxGroupController, Group, GroupCellContentProvider, MultiSelectGroupController, SingleSelectGroupController,
};

use crate::entities::{
    CheckboxGroupConfigurationPB, DateGroupConfigurationPB, FieldType, GroupPB, NumberGroupConfigurationPB,
    SelectOptionGroupConfigurationPB, TextGroupConfigurationPB, UrlGroupConfigurationPB,
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
    #[allow(dead_code)]
    grid_pad: Arc<RwLock<GridRevisionPad>>,
    #[allow(dead_code)]
    block_manager: Arc<GridBlockManager>,
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
        }
    }

    pub(crate) async fn load_groups(&self) -> Option<Vec<GroupPB>> {
        let grid_pad = self.grid_pad.read().await;
        let field_rev = find_group_field(grid_pad.fields()).unwrap();
        let field_type: FieldType = field_rev.field_type_rev.into();
        let configuration = self.get_group_configuration(field_rev).await;

        let blocks = self.block_manager.get_block_snapshots(None).await.unwrap();
        let row_revs = blocks
            .into_iter()
            .map(|block| block.row_revs)
            .flatten()
            .collect::<Vec<Arc<RowRevision>>>();

        match self.build_groups(&field_type, field_rev, row_revs, configuration) {
            Ok(groups) => Some(groups),
            Err(_) => None,
        }
    }

    async fn get_group_configuration(&self, field_rev: &FieldRevision) -> GroupConfigurationRevision {
        let grid_pad = self.grid_pad.read().await;
        let setting = grid_pad.get_setting_rev();
        let layout = &setting.layout;
        let configurations = setting.get_groups(layout, &field_rev.id, &field_rev.field_type_rev);
        match configurations {
            None => self.default_group_configuration(field_rev),
            Some(mut configurations) => {
                assert_eq!(configurations.len(), 1);
                (&*configurations.pop().unwrap()).clone()
            }
        }
    }

    fn default_group_configuration(&self, field_rev: &FieldRevision) -> GroupConfigurationRevision {
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

    #[tracing::instrument(level = "trace", skip_all, err)]
    fn build_groups(
        &self,
        field_type: &FieldType,
        field_rev: &Arc<FieldRevision>,
        row_revs: Vec<Arc<RowRevision>>,
        configuration: GroupConfigurationRevision,
    ) -> FlowyResult<Vec<GroupPB>> {
        let groups: Vec<Group> = match field_type {
            FieldType::RichText => {
                // let generator = GroupGenerator::<TextGroupConfigurationPB>::from_configuration(configuration);
                vec![]
            }
            FieldType::Number => {
                // let generator = GroupGenerator::<NumberGroupConfigurationPB>::from_configuration(configuration);
                vec![]
            }
            FieldType::DateTime => {
                // let generator = GroupGenerator::<DateGroupConfigurationPB>::from_configuration(configuration);
                vec![]
            }
            FieldType::SingleSelect => {
                let mut group_controller =
                    SingleSelectGroupController::new(field_rev.clone(), configuration, &self.grid_pad)?;
                let _ = group_controller.group_rows(&row_revs)?;
                group_controller.take_groups()
            }
            FieldType::MultiSelect => {
                let mut group_controller =
                    MultiSelectGroupController::new(field_rev.clone(), configuration, &self.grid_pad)?;
                let _ = group_controller.group_rows(&row_revs)?;
                group_controller.take_groups()
            }
            FieldType::Checkbox => {
                let mut group_controller =
                    CheckboxGroupController::new(field_rev.clone(), configuration, &self.grid_pad)?;
                let _ = group_controller.group_rows(&row_revs)?;
                group_controller.take_groups()
            }
            FieldType::URL => {
                // let generator = GroupGenerator::<UrlGroupConfigurationPB>::from_configuration(configuration);
                vec![]
            }
        };

        Ok(groups.into_iter().map(GroupPB::from).collect())
    }
}

fn find_group_field(field_revs: &[Arc<FieldRevision>]) -> Option<&Arc<FieldRevision>> {
    field_revs.iter().find(|field_rev| {
        let field_type: FieldType = field_rev.field_type_rev.into();
        field_type.can_be_group()
    })
}

impl GroupCellContentProvider for Arc<RwLock<GridRevisionPad>> {}
