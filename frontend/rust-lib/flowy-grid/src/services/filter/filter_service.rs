use crate::dart_notification::{send_dart_notification, GridNotification};
use crate::entities::{FieldType, GridBlockChangeset, GridTextFilter};
use crate::services::block_manager::GridBlockManager;
use crate::services::field::RichTextTypeOption;
use crate::services::filter::filter_cache::{
    reload_filter_cache, FilterCache, FilterId, FilterResult, FilterResultCache,
};
use crate::services::grid_editor_task::GridServiceTaskScheduler;
use crate::services::row::{CellDataOperation, GridBlockSnapshot};
use crate::services::tasks::{FilterTaskContext, Task, TaskContent};
use dashmap::mapref::one::{Ref, RefMut};
use flowy_error::FlowyResult;
use flowy_grid_data_model::revision::{CellRevision, FieldId, FieldRevision, RowRevision};
use flowy_sync::client_grid::GridRevisionPad;
use flowy_sync::entities::grid::GridSettingChangesetParams;
use rayon::prelude::*;
use std::borrow::Cow;
use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::RwLock;

pub(crate) struct GridFilterService {
    #[allow(dead_code)]
    grid_id: String,
    scheduler: Arc<dyn GridServiceTaskScheduler>,
    grid_pad: Arc<RwLock<GridRevisionPad>>,
    block_manager: Arc<GridBlockManager>,
    filter_cache: Arc<FilterCache>,
    filter_result_cache: Arc<FilterResultCache>,
}
impl GridFilterService {
    pub async fn new<S: GridServiceTaskScheduler>(
        grid_pad: Arc<RwLock<GridRevisionPad>>,
        block_manager: Arc<GridBlockManager>,
        scheduler: S,
    ) -> Self {
        let grid_id = grid_pad.read().await.grid_id();
        let scheduler = Arc::new(scheduler);
        let filter_cache = FilterCache::from_grid_pad(&grid_pad).await;
        let filter_result_cache = FilterResultCache::new();
        Self {
            grid_id,
            grid_pad,
            block_manager,
            scheduler,
            filter_cache,
            filter_result_cache,
        }
    }

    pub async fn process(&self, task_context: FilterTaskContext) -> FlowyResult<()> {
        let field_revs = self
            .grid_pad
            .read()
            .await
            .get_field_revs(None)?
            .into_iter()
            .map(|field_rev| (field_rev.id.clone(), field_rev))
            .collect::<HashMap<String, Arc<FieldRevision>>>();

        let mut changesets = vec![];
        for (index, block) in task_context.blocks.into_iter().enumerate() {
            let results = block
                .row_revs
                .par_iter()
                .map(|row_rev| {
                    let filter_result_cache = self.filter_result_cache.clone();
                    let filter_cache = self.filter_cache.clone();
                    filter_row(index, row_rev, filter_cache, filter_result_cache, &field_revs)
                })
                .collect::<Vec<FilterResult>>();

            let mut visible_rows = vec![];
            let mut hide_rows = vec![];
            for result in results {
                if result.is_visible() {
                    visible_rows.push(result.row_id);
                } else {
                    hide_rows.push(result.row_id);
                }
            }

            let changeset = GridBlockChangeset {
                block_id: block.block_id,
                hide_rows,
                visible_rows,
                ..Default::default()
            };
            changesets.push(changeset);
        }
        self.notify(changesets).await;
        Ok(())
    }

    pub async fn apply_changeset(&self, changeset: GridFilterChangeset) {
        if !changeset.is_changed() {
            return;
        }

        if let Some(filter_id) = &changeset.insert_filter {
            let field_ids = Some(vec![filter_id.field_id.clone()]);
            reload_filter_cache(self.filter_cache.clone(), field_ids, &self.grid_pad).await;
            todo!()
        }

        if let Some(filter_id) = &changeset.delete_filter {
            self.filter_cache.remove(filter_id);
        }

        if let Ok(blocks) = self.block_manager.get_block_snapshots(None).await {
            let task = self.gen_task(blocks).await;
            let _ = self.scheduler.register_task(task).await;
        }
    }

    async fn gen_task(&self, blocks: Vec<GridBlockSnapshot>) -> Task {
        let task_id = self.scheduler.gen_task_id().await;
        let handler_id = self.grid_pad.read().await.grid_id();

        let context = FilterTaskContext { blocks };
        Task {
            handler_id,
            id: task_id,
            content: TaskContent::Filter(context),
        }
    }

    async fn notify(&self, changesets: Vec<GridBlockChangeset>) {
        for changeset in changesets {
            send_dart_notification(&self.grid_id, GridNotification::DidUpdateGridBlock)
                .payload(changeset)
                .send();
        }
    }
}

fn filter_row(
    index: usize,
    row_rev: &Arc<RowRevision>,
    filter_cache: Arc<FilterCache>,
    filter_result_cache: Arc<FilterResultCache>,
    field_revs: &HashMap<FieldId, Arc<FieldRevision>>,
) -> FilterResult {
    match filter_result_cache.get_mut(&row_rev.id) {
        None => {
            let mut filter_result = FilterResult::new(index as i32, row_rev);
            for (field_id, cell_rev) in row_rev.cells.iter() {
                let _ = update_filter_result(field_revs, &mut filter_result, &filter_cache, field_id, cell_rev);
            }
            filter_result_cache.insert(row_rev.id.clone(), filter_result);
        }
        Some(mut result) => {
            for (field_id, cell_rev) in row_rev.cells.iter() {
                let _ = update_filter_result(field_revs, result.value_mut(), &filter_cache, field_id, cell_rev);
            }
        }
    }

    todo!()
}

fn update_filter_result(
    field_revs: &HashMap<FieldId, Arc<FieldRevision>>,
    filter_result: &mut FilterResult,
    filter_cache: &Arc<FilterCache>,
    field_id: &str,
    cell_rev: &CellRevision,
) -> Option<()> {
    let field_rev = field_revs.get(field_id)?;
    let field_type = FieldType::from(field_rev.field_type_rev);
    let filter_id = FilterId {
        field_id: field_id.to_owned(),
        field_type,
    };
    match &filter_id.field_type {
        FieldType::RichText => match filter_cache.text_filter.get(&filter_id) {
            None => {}
            Some(filter) => {
                // let v = field_rev
                //     .get_type_option_entry::<RichTextTypeOption, _>(&filter_id.field_type)?
                //     .apply_filter(cell_rev, &filter);
            }
        },
        FieldType::Number => {}
        FieldType::DateTime => {}
        FieldType::SingleSelect => {}
        FieldType::MultiSelect => {}
        FieldType::Checkbox => {}
        FieldType::URL => {}
    }
    None
}

pub struct GridFilterChangeset {
    insert_filter: Option<FilterId>,
    delete_filter: Option<FilterId>,
}

impl GridFilterChangeset {
    fn is_changed(&self) -> bool {
        self.insert_filter.is_some() || self.delete_filter.is_some()
    }
}

impl std::convert::From<&GridSettingChangesetParams> for GridFilterChangeset {
    fn from(params: &GridSettingChangesetParams) -> Self {
        let insert_filter = params.insert_filter.as_ref().map(|insert_filter_params| FilterId {
            field_id: insert_filter_params.field_id.clone(),
            field_type: insert_filter_params.field_type_rev.into(),
        });

        let delete_filter = params.delete_filter.as_ref().map(|delete_filter_params| FilterId {
            field_id: delete_filter_params.filter_id.clone(),
            field_type: delete_filter_params.field_type_rev.into(),
        });
        GridFilterChangeset {
            insert_filter,
            delete_filter,
        }
    }
}
