#![allow(clippy::all)]
#![allow(unused_attributes)]
#![allow(dead_code)]
#![allow(unused_imports)]
#![allow(unused_results)]
use crate::dart_notification::{send_dart_notification, GridNotification};
use crate::entities::{FieldType, GridBlockChangesetPB, GridSettingChangesetParams};
use crate::services::block_manager::GridBlockManager;
use crate::services::cell::{AnyCellData, CellFilterOperation};
use crate::services::field::{
    CheckboxTypeOptionPB, DateTypeOptionPB, MultiSelectTypeOptionPB, NumberTypeOptionPB, RichTextTypeOptionPB,
    SingleSelectTypeOptionPB, URLTypeOptionPB,
};
use crate::services::filter::filter_cache::{
    refresh_filter_cache, FilterCache, FilterId, FilterResult, FilterResultCache,
};
use crate::services::grid_editor_task::GridServiceTaskScheduler;
use crate::services::row::GridBlockSnapshot;
use crate::services::tasks::{FilterTaskContext, Task, TaskContent};
use flowy_error::FlowyResult;
use flowy_sync::client_grid::GridRevisionPad;
use grid_rev_model::{CellRevision, FieldId, FieldRevision, RowRevision};
use rayon::prelude::*;
use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::RwLock;

pub(crate) struct GridFilterService {
    #[allow(dead_code)]
    scheduler: Arc<dyn GridServiceTaskScheduler>,
    grid_pad: Arc<RwLock<GridRevisionPad>>,
    #[allow(dead_code)]
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
        let scheduler = Arc::new(scheduler);
        let filter_cache = FilterCache::from_grid_pad(&grid_pad).await;
        let filter_result_cache = FilterResultCache::new();
        Self {
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
            // The row_ids contains the row that its visibility was changed.
            let row_ids = block
                .row_revs
                .par_iter()
                .flat_map(|row_rev| {
                    let filter_result_cache = self.filter_result_cache.clone();
                    let filter_cache = self.filter_cache.clone();
                    filter_row(index, row_rev, filter_cache, filter_result_cache, &field_revs)
                })
                .collect::<Vec<String>>();

            let mut visible_rows = vec![];
            let mut hide_rows = vec![];

            // Query the filter result from the cache
            for row_id in row_ids {
                if self
                    .filter_result_cache
                    .get(&row_id)
                    .map(|result| result.is_visible())
                    .unwrap_or(false)
                {
                    visible_rows.push(row_id);
                } else {
                    hide_rows.push(row_id);
                }
            }

            let changeset = GridBlockChangesetPB {
                block_id: block.block_id,
                hide_rows,
                visible_rows,
                ..Default::default()
            };

            // Save the changeset for each block
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
            refresh_filter_cache(self.filter_cache.clone(), field_ids, &self.grid_pad).await;
        }

        if let Some(filter_id) = &changeset.delete_filter {
            self.filter_cache.remove(filter_id);
        }

        if let Ok(blocks) = self.block_manager.get_block_snapshots(None).await {
            let _task = self.gen_task(blocks).await;
            // let _ = self.scheduler.register_task(task).await;
        }
    }

    async fn gen_task(&self, blocks: Vec<GridBlockSnapshot>) -> Task {
        let task_id = self.scheduler.gen_task_id().await;
        let handler_id = self.grid_pad.read().await.grid_id();

        let context = FilterTaskContext { blocks };
        Task::new(&handler_id, task_id, TaskContent::Filter(context))
    }

    async fn notify(&self, changesets: Vec<GridBlockChangesetPB>) {
        let grid_id = self.grid_pad.read().await.grid_id();
        for changeset in changesets {
            send_dart_notification(&grid_id, GridNotification::DidUpdateGridBlock)
                .payload(changeset)
                .send();
        }
    }
}

// Return None if there is no change in this row after applying the filter
fn filter_row(
    index: usize,
    row_rev: &Arc<RowRevision>,
    filter_cache: Arc<FilterCache>,
    filter_result_cache: Arc<FilterResultCache>,
    field_revs: &HashMap<FieldId, Arc<FieldRevision>>,
) -> Option<String> {
    let mut result = filter_result_cache
        .entry(row_rev.id.clone())
        .or_insert(FilterResult::new(index as i32, row_rev));

    for (field_id, cell_rev) in row_rev.cells.iter() {
        match filter_cell(field_revs, result.value_mut(), &filter_cache, field_id, cell_rev) {
            None => {}
            Some(_) => {
                return Some(row_rev.id.clone());
            }
        }
    }
    None
}

// Return None if there is no change in this cell after applying the filter
fn filter_cell(
    field_revs: &HashMap<FieldId, Arc<FieldRevision>>,
    filter_result: &mut FilterResult,
    filter_cache: &Arc<FilterCache>,
    field_id: &str,
    cell_rev: &CellRevision,
) -> Option<()> {
    let field_rev = field_revs.get(field_id)?;
    let field_type = FieldType::from(field_rev.ty);
    let field_type_rev = field_type.clone().into();
    let filter_id = FilterId {
        field_id: field_id.to_owned(),
        field_type,
    };
    let any_cell_data = AnyCellData::try_from(cell_rev).ok()?;
    let is_visible = match &filter_id.field_type {
        FieldType::RichText => filter_cache.text_filter.get(&filter_id).and_then(|filter| {
            Some(
                field_rev
                    .get_type_option::<RichTextTypeOptionPB>(field_type_rev)?
                    .apply_filter(any_cell_data, filter.value())
                    .ok(),
            )
        }),
        FieldType::Number => filter_cache.number_filter.get(&filter_id).and_then(|filter| {
            Some(
                field_rev
                    .get_type_option::<NumberTypeOptionPB>(field_type_rev)?
                    .apply_filter(any_cell_data, filter.value())
                    .ok(),
            )
        }),
        FieldType::DateTime => filter_cache.date_filter.get(&filter_id).and_then(|filter| {
            Some(
                field_rev
                    .get_type_option::<DateTypeOptionPB>(field_type_rev)?
                    .apply_filter(any_cell_data, filter.value())
                    .ok(),
            )
        }),
        FieldType::SingleSelect => filter_cache.select_option_filter.get(&filter_id).and_then(|filter| {
            Some(
                field_rev
                    .get_type_option::<SingleSelectTypeOptionPB>(field_type_rev)?
                    .apply_filter(any_cell_data, filter.value())
                    .ok(),
            )
        }),
        FieldType::MultiSelect => filter_cache.select_option_filter.get(&filter_id).and_then(|filter| {
            Some(
                field_rev
                    .get_type_option::<MultiSelectTypeOptionPB>(field_type_rev)?
                    .apply_filter(any_cell_data, filter.value())
                    .ok(),
            )
        }),
        FieldType::Checkbox => filter_cache.checkbox_filter.get(&filter_id).and_then(|filter| {
            Some(
                field_rev
                    .get_type_option::<CheckboxTypeOptionPB>(field_type_rev)?
                    .apply_filter(any_cell_data, filter.value())
                    .ok(),
            )
        }),
        FieldType::URL => filter_cache.url_filter.get(&filter_id).and_then(|filter| {
            Some(
                field_rev
                    .get_type_option::<URLTypeOptionPB>(field_type_rev)?
                    .apply_filter(any_cell_data, filter.value())
                    .ok(),
            )
        }),
    }?;

    let is_visible = !is_visible.unwrap_or(true);
    match filter_result.visible_by_field_id.get(&filter_id) {
        None => {
            if is_visible {
                None
            } else {
                filter_result.visible_by_field_id.insert(filter_id, is_visible);
                Some(())
            }
        }
        Some(old_is_visible) => {
            if old_is_visible != &is_visible {
                filter_result.visible_by_field_id.insert(filter_id, is_visible);
                Some(())
            } else {
                None
            }
        }
    }
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
