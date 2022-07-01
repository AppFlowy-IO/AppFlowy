use crate::services::block_manager::GridBlockManager;
use crate::services::grid_editor_task::GridServiceTaskScheduler;
use crate::services::row::GridBlockSnapshot;
use crate::services::tasks::{FilterTaskContext, Task, TaskContent};
use flowy_error::FlowyResult;
use flowy_grid_data_model::entities::{
    FieldType, GridCheckboxFilter, GridDateFilter, GridNumberFilter, GridSelectOptionFilter,
    GridSettingChangesetParams, GridTextFilter,
};
use flowy_grid_data_model::revision::{FieldRevision, RowRevision};
use flowy_sync::client_grid::GridRevisionPad;
use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::RwLock;

pub(crate) struct GridFilterService {
    scheduler: Arc<dyn GridServiceTaskScheduler>,
    grid_pad: Arc<RwLock<GridRevisionPad>>,
    block_manager: Arc<GridBlockManager>,
    filter_cache: Arc<RwLock<FilterCache>>,
    filter_result: Arc<RwLock<GridFilterResult>>,
}
impl GridFilterService {
    pub async fn new<S: GridServiceTaskScheduler>(
        grid_pad: Arc<RwLock<GridRevisionPad>>,
        block_manager: Arc<GridBlockManager>,
        scheduler: S,
    ) -> Self {
        let filter_cache = Arc::new(RwLock::new(FilterCache::from_grid_pad(&grid_pad).await));
        let filter_result = Arc::new(RwLock::new(GridFilterResult::default()));
        Self {
            grid_pad,
            block_manager,
            scheduler: Arc::new(scheduler),
            filter_cache,
            filter_result,
        }
    }

    pub async fn process(&self, task_context: FilterTaskContext) -> FlowyResult<()> {
        let mut filter_result = self.filter_result.write().await;
        for block in task_context.blocks {
            for row_rev in block.row_revs {
                let row_filter_result = RowFilterResult::new(&row_rev);

                filter_result.insert(&row_rev.id, row_filter_result);
            }
        }
        Ok(())
    }

    pub async fn apply_changeset(&self, changeset: GridFilterChangeset) {
        if !changeset.is_changed() {
            return;
        }

        if let Some(filter_id) = &changeset.insert_filter {
            let mut cache = self.filter_cache.write().await;
            let field_ids = Some(vec![filter_id.field_id.clone()]);
            reload_filter_cache(&mut cache, field_ids, &self.grid_pad).await;
        }

        if let Some(filter_id) = &changeset.delete_filter {
            self.filter_cache.write().await.remove(filter_id);
        }

        match self.block_manager.get_block_snapshots(None).await {
            Ok(blocks) => {
                let task = self.gen_task(blocks).await;
                let _ = self.scheduler.register_task(task).await;
            }
            Err(_) => {}
        }
    }

    async fn gen_task(&self, blocks: Vec<GridBlockSnapshot>) -> Task {
        let task_id = self.scheduler.gen_task_id().await;
        let handler_id = self.grid_pad.read().await.grid_id();

        let context = FilterTaskContext { blocks };
        let task = Task {
            handler_id,
            id: task_id,
            content: TaskContent::Filter(context),
        };

        task
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
            field_type: insert_filter_params.field_type.clone(),
        });

        let delete_filter = params.delete_filter.as_ref().map(|delete_filter_params| FilterId {
            field_id: delete_filter_params.filter_id.clone(),
            field_type: delete_filter_params.field_type.clone(),
        });
        GridFilterChangeset {
            insert_filter,
            delete_filter,
        }
    }
}

#[derive(Default)]
struct GridFilterResult {
    rows: HashMap<String, RowFilterResult>,
}

impl GridFilterResult {
    fn insert(&mut self, row_id: &str, result: RowFilterResult) {
        self.rows.insert(row_id.to_owned(), result);
    }
}

#[derive(Default)]
struct RowFilterResult {
    cell_by_field_id: HashMap<String, bool>,
}

impl RowFilterResult {
    fn new(row_rev: &RowRevision) -> Self {
        Self {
            cell_by_field_id: row_rev.cells.iter().map(|(k, _)| (k.clone(), true)).collect(),
        }
    }

    fn update_cell(&mut self, cell_id: &str, exist: bool) {
        self.cell_by_field_id.insert(cell_id.to_owned(), exist);
    }
}

#[derive(Default)]
struct FilterCache {
    text_filter: HashMap<FilterId, GridTextFilter>,
    url_filter: HashMap<FilterId, GridTextFilter>,
    number_filter: HashMap<FilterId, GridNumberFilter>,
    date_filter: HashMap<FilterId, GridDateFilter>,
    select_option_filter: HashMap<FilterId, GridSelectOptionFilter>,
    checkbox_filter: HashMap<FilterId, GridCheckboxFilter>,
}

impl FilterCache {
    async fn from_grid_pad(grid_pad: &Arc<RwLock<GridRevisionPad>>) -> Self {
        let mut this = Self::default();
        let _ = reload_filter_cache(&mut this, None, grid_pad).await;
        this
    }

    fn remove(&mut self, filter_id: &FilterId) {
        let _ = match filter_id.field_type {
            FieldType::RichText => {
                let _ = self.text_filter.remove(filter_id);
            }
            FieldType::Number => {
                let _ = self.number_filter.remove(filter_id);
            }
            FieldType::DateTime => {
                let _ = self.date_filter.remove(filter_id);
            }
            FieldType::SingleSelect => {
                let _ = self.select_option_filter.remove(filter_id);
            }
            FieldType::MultiSelect => {
                let _ = self.select_option_filter.remove(filter_id);
            }
            FieldType::Checkbox => {
                let _ = self.checkbox_filter.remove(filter_id);
            }
            FieldType::URL => {
                let _ = self.url_filter.remove(filter_id);
            }
        };
    }
}

async fn reload_filter_cache(
    cache: &mut FilterCache,
    field_ids: Option<Vec<String>>,
    grid_pad: &Arc<RwLock<GridRevisionPad>>,
) {
    let grid_pad = grid_pad.read().await;
    let filters_revs = grid_pad.get_filters(None, field_ids).unwrap_or_default();

    for filter_rev in filters_revs {
        match grid_pad.get_field_rev(&filter_rev.field_id) {
            None => {}
            Some((_, field_rev)) => {
                let filter_id = FilterId::from(field_rev);
                match &field_rev.field_type {
                    FieldType::RichText => {
                        let _ = cache.text_filter.insert(filter_id, GridTextFilter::from(filter_rev));
                    }
                    FieldType::Number => {
                        let _ = cache
                            .number_filter
                            .insert(filter_id, GridNumberFilter::from(filter_rev));
                    }
                    FieldType::DateTime => {
                        let _ = cache.date_filter.insert(filter_id, GridDateFilter::from(filter_rev));
                    }
                    FieldType::SingleSelect | FieldType::MultiSelect => {
                        let _ = cache
                            .select_option_filter
                            .insert(filter_id, GridSelectOptionFilter::from(filter_rev));
                    }
                    FieldType::Checkbox => {
                        let _ = cache
                            .checkbox_filter
                            .insert(filter_id, GridCheckboxFilter::from(filter_rev));
                    }
                    FieldType::URL => {
                        let _ = cache.url_filter.insert(filter_id, GridTextFilter::from(filter_rev));
                    }
                }
            }
        }
    }
}
#[derive(Hash, Eq, PartialEq)]
struct FilterId {
    field_id: String,
    field_type: FieldType,
}

impl std::convert::From<&Arc<FieldRevision>> for FilterId {
    fn from(rev: &Arc<FieldRevision>) -> Self {
        Self {
            field_id: rev.id.clone(),
            field_type: rev.field_type.clone(),
        }
    }
}
