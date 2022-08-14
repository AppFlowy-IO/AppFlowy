use crate::dart_notification::{send_dart_notification, GridNotification};
use crate::entities::{
    BoardCardChangesetPB, CheckboxGroupConfigurationPB, DateGroupConfigurationPB, FieldType, GroupPB,
    NumberGroupConfigurationPB, RowPB, SelectOptionGroupConfigurationPB, TextGroupConfigurationPB,
    UrlGroupConfigurationPB,
};
use crate::services::block_manager::GridBlockManager;
use crate::services::grid_editor_task::GridServiceTaskScheduler;
use crate::services::group::{
    CheckboxGroupController, GroupActionHandler, GroupCellContentProvider, MultiSelectGroupController,
    SingleSelectGroupController,
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

    #[tracing::instrument(level = "debug", skip(self, row_rev))]
    pub(crate) async fn update_board_card(&self, row_rev: &mut RowRevision, group_id: &str) {
        if let Some(group_action_handler) = self.group_action_handler.as_ref() {
            let field_id = group_action_handler.read().await.field_id().to_owned();

            match self.grid_pad.read().await.get_field_rev(&field_id) {
                None => tracing::warn!("Fail to create card because the field does not exist"),
                Some((_, field_rev)) => {
                    group_action_handler
                        .write()
                        .await
                        .update_card(row_rev, field_rev, group_id);
                }
            }
        }
    }

    pub(crate) async fn get_group_configuration(&self, field_rev: &FieldRevision) -> GroupConfigurationRevision {
        let grid_pad = self.grid_pad.read().await;
        let setting = grid_pad.get_setting_rev();
        let configurations = setting.get_groups(&field_rev.id, &field_rev.field_type_rev);
        match configurations {
            None => default_group_configuration(field_rev),
            Some(mut configurations) => {
                assert_eq!(configurations.len(), 1);
                (&*configurations.pop().unwrap()).clone()
            }
        }
    }

    pub async fn move_card(&self, _group_id: &str, _from: i32, _to: i32) {
        // BoardCardChangesetPB {
        //     group_id: "".to_string(),
        //     inserted_cards: vec![],
        //     deleted_cards: vec![],
        //     updated_cards: vec![]
        // }
        // let row_pb = make_row_from_row_rev(row_rev);
        todo!()
    }

    pub async fn did_delete_card(&self, _row_id: String) {
        // let changeset = BoardCardChangesetPB::delete(group_id.to_owned(), vec![row_id]);
        // self.notify_did_update_board(changeset).await;
        todo!()
    }

    pub async fn did_create_card(&self, group_id: &str, row_pb: &RowPB) {
        let changeset = BoardCardChangesetPB::insert(group_id.to_owned(), vec![row_pb.clone()]);
        self.notify_did_update_board(changeset).await;
    }

    pub async fn notify_did_update_board(&self, changeset: BoardCardChangesetPB) {
        if self.group_action_handler.is_none() {
            return;
        }
        send_dart_notification(&changeset.group_id, GridNotification::DidUpdateBoard)
            .payload(changeset)
            .send();
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
                let controller = SingleSelectGroupController::new(field_rev, configuration, &self.grid_pad)?;
                self.group_action_handler = Some(Arc::new(RwLock::new(controller)));
            }
            FieldType::MultiSelect => {
                let controller = MultiSelectGroupController::new(field_rev, configuration, &self.grid_pad)?;
                self.group_action_handler = Some(Arc::new(RwLock::new(controller)));
            }
            FieldType::Checkbox => {
                let controller = CheckboxGroupController::new(field_rev, configuration, &self.grid_pad)?;
                self.group_action_handler = Some(Arc::new(RwLock::new(controller)));
            }
            FieldType::URL => {
                // let generator = GroupGenerator::<UrlGroupConfigurationPB>::from_configuration(configuration);
            }
        };

        let mut groups = vec![];
        if let Some(group_action_handler) = self.group_action_handler.as_ref() {
            let mut write_guard = group_action_handler.write().await;
            let _ = write_guard.group_rows(&row_revs, field_rev)?;
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
    let field_type: FieldType = field_rev.field_type_rev.into();
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
        field_type_rev: field_rev.field_type_rev,
        content: Some(bytes.to_vec()),
    }
}
