use crate::entities::{
    CheckboxGroupConfigurationPB, DateGroupConfigurationPB, FieldType, GroupPB, NumberGroupConfigurationPB,
    SelectOptionGroupConfigurationPB, TextGroupConfigurationPB, UrlGroupConfigurationPB,
};
use crate::services::block_manager::GridBlockManager;
use crate::services::cell::{decode_any_cell_data, CellBytes};
use crate::services::grid_editor_task::GridServiceTaskScheduler;
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

        let groups = match field_type {
            FieldType::RichText => {
                let generator = GroupGenerator::<TextGroupConfigurationPB>::from_configuration(configuration);
            }
            FieldType::Number => {
                let generator = GroupGenerator::<NumberGroupConfigurationPB>::from_configuration(configuration);
            }
            FieldType::DateTime => {
                let generator = GroupGenerator::<DateGroupConfigurationPB>::from_configuration(configuration);
            }
            FieldType::SingleSelect => {
                let generator = GroupGenerator::<SelectOptionGroupConfigurationPB>::from_configuration(configuration);
            }
            FieldType::MultiSelect => {
                let generator = GroupGenerator::<SelectOptionGroupConfigurationPB>::from_configuration(configuration);
            }
            FieldType::Checkbox => {
                let generator = GroupGenerator::<CheckboxGroupConfigurationPB>::from_configuration(configuration);
            }
            FieldType::URL => {
                let generator = GroupGenerator::<UrlGroupConfigurationPB>::from_configuration(configuration);
            }
        };
        None
    }
}

pub struct GroupGenerator<T> {
    field_id: String,
    groups: Vec<Group>,
    configuration: Option<T>,
}

pub struct Group {
    row_ids: Vec<String>,
    content: String,
}

impl<T> GroupGenerator<T>
where
    T: TryFrom<Bytes, Error = protobuf::ProtobufError>,
{
    pub fn from_configuration(configuration: GroupConfigurationRevision) -> FlowyResult<Self> {
        let bytes = Bytes::from(configuration.content.unwrap_or(vec![]));
        Self::from_bytes(&configuration.field_id, bytes)
    }

    pub fn from_bytes(field_id: &str, bytes: Bytes) -> FlowyResult<Self> {
        let configuration = if bytes.is_empty() {
            None
        } else {
            Some(T::try_from(bytes)?)
        };
        Ok(Self {
            field_id: field_id.to_owned(),
            groups: vec![],
            configuration,
        })
    }
}
pub trait GroupConfiguration {
    fn should_group(&self, content: &str, cell_bytes: CellBytes) -> bool;
}

impl<T> GroupGenerator<T>
where
    T: GroupConfiguration,
{
    pub fn group_row(&mut self, field_rev: &Arc<FieldRevision>, row: &RowRevision) {
        if self.configuration.is_none() {
            return;
        }
        let configuration = self.configuration.as_ref().unwrap();
        if let Some(cell_rev) = row.cells.get(&self.field_id) {
            for group in self.groups.iter_mut() {
                let cell_rev: CellRevision = cell_rev.clone();
                let cell_bytes = decode_any_cell_data(cell_rev.data, field_rev);
                if configuration.should_group(&group.content, cell_bytes) {
                    group.row_ids.push(row.id.clone());
                }
            }
        }
    }
}

fn find_group_field(field_revs: &[Arc<FieldRevision>]) -> Option<&Arc<FieldRevision>> {
    field_revs.iter().find(|field_rev| {
        let field_type: FieldType = field_rev.field_type_rev.into();
        field_type.can_be_group()
    })
}
