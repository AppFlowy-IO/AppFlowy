use crate::entities::{
    CheckboxGroupConfigurationPB, DateGroupConfigurationPB, FieldType, GroupPB, NumberGroupConfigurationPB,
    SelectOptionGroupConfigurationPB, TextGroupConfigurationPB, UrlGroupConfigurationPB,
};
use crate::services::block_manager::GridBlockManager;
use crate::services::cell::{decode_any_cell_data, CellBytes};
use crate::services::field::TextCellDataParser;
use crate::services::grid_editor_task::GridServiceTaskScheduler;
use crate::services::group::{GroupAction, GroupCellContentProvider, SingleSelectGroupController};
use bytes::Bytes;
use flowy_error::FlowyResult;
use flowy_grid_data_model::revision::{CellRevision, FieldRevision, GroupConfigurationRevision, RowRevision};
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
        let field_rev = find_group_field(grid_pad.fields())?;
        let field_type: FieldType = field_rev.field_type_rev.clone().into();
        let setting = grid_pad.get_setting_rev();
        let mut configurations = setting.get_groups(&setting.layout, &field_rev.id, &field_rev.field_type_rev)?;

        if configurations.is_empty() {
            return None;
        }
        assert_eq!(configurations.len(), 1);
        let configuration = (&*configurations.pop().unwrap()).clone();

        let blocks = self.block_manager.get_block_snapshots(None).await.unwrap();

        let row_revs = blocks
            .into_iter()
            .map(|block| block.row_revs)
            .flatten()
            .collect::<Vec<Arc<RowRevision>>>();

        // let a = SingleSelectGroupController::new;
        // let b = a(field_rev.clone(), configuration, &self.grid_pad);

        let groups = match field_type {
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
                let group_controller =
                    SingleSelectGroupController::new(field_rev.clone(), configuration, &self.grid_pad);
            }
            FieldType::MultiSelect => {
                // let group_generator = MultiSelectGroupControllern(configuration);
            }
            FieldType::Checkbox => {
                // let generator = GroupGenerator::<CheckboxGroupConfigurationPB>::from_configuration(configuration);
            }
            FieldType::URL => {
                // let generator = GroupGenerator::<UrlGroupConfigurationPB>::from_configuration(configuration);
            }
        };
        None
    }
}

fn find_group_field(field_revs: &[Arc<FieldRevision>]) -> Option<&Arc<FieldRevision>> {
    field_revs.iter().find(|field_rev| {
        let field_type: FieldType = field_rev.field_type_rev.into();
        field_type.can_be_group()
    })
}

impl GroupCellContentProvider for Arc<RwLock<GridRevisionPad>> {}
