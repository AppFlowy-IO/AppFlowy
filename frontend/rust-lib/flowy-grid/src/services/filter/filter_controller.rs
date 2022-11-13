use crate::dart_notification::{send_dart_notification, GridNotification};
use crate::entities::filter_entities::*;
use crate::entities::setting_entities::*;
use crate::entities::{FieldType, GridBlockChangesetPB};
use crate::services::cell::{AnyCellData, CellFilterOperation};
use crate::services::field::*;
use crate::services::filter::{FilterMap, FilterResult, FILTER_HANDLER_ID};
use crate::services::row::GridBlock;
use flowy_error::FlowyResult;
use flowy_task::{QualityOfService, Task, TaskContent, TaskDispatcher};
use grid_rev_model::{CellRevision, FieldId, FieldRevision, FilterConfigurationRevision, RowRevision};
use lib_infra::future::Fut;
use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::RwLock;

type RowId = String;
pub trait GridViewFilterDelegate: Send + Sync + 'static {
    fn get_filter_configuration(&self, filter_id: FilterId) -> Fut<Vec<Arc<FilterConfigurationRevision>>>;
    fn get_field_rev(&self, field_id: &str) -> Fut<Option<Arc<FieldRevision>>>;
    fn get_field_revs(&self, field_ids: Option<Vec<String>>) -> Fut<Vec<Arc<FieldRevision>>>;
    fn get_blocks(&self) -> Fut<Vec<GridBlock>>;
}

pub struct FilterController {
    view_id: String,
    delegate: Box<dyn GridViewFilterDelegate>,
    filter_map: FilterMap,
    filter_results: HashMap<RowId, FilterResult>,
    task_scheduler: Arc<RwLock<TaskDispatcher>>,
}
impl FilterController {
    pub async fn new<T>(
        view_id: &str,
        delegate: T,
        task_scheduler: Arc<RwLock<TaskDispatcher>>,
        filter_configurations: Vec<Arc<FilterConfigurationRevision>>,
    ) -> Self
    where
        T: GridViewFilterDelegate,
    {
        let filter_map = FilterMap::new();
        let filter_results = HashMap::default();
        let filter_delegate = Box::new(delegate);
        let mut this = Self {
            view_id: view_id.to_string(),
            delegate: filter_delegate,
            filter_map,
            filter_results,
            task_scheduler,
        };
        this.load_filters(filter_configurations).await;
        this
    }

    pub async fn close(&self) {
        self.task_scheduler.write().await.unregister_handler(FILTER_HANDLER_ID);
    }

    async fn gen_task(&mut self, predicate: &str) {
        let task_id = self.task_scheduler.read().await.next_task_id();
        let task = Task::new(
            FILTER_HANDLER_ID,
            task_id,
            TaskContent::Text(predicate.to_owned()),
            QualityOfService::UserInteractive,
        );
        self.task_scheduler.write().await.add_task(task);
    }

    pub async fn process(&self, _predicate: &str) -> FlowyResult<()> {
        let field_revs = self
            .delegate
            .get_field_revs(None)
            .await
            .into_iter()
            .map(|field_rev| (field_rev.id.clone(), field_rev))
            .collect::<HashMap<String, Arc<FieldRevision>>>();

        // let mut changesets = vec![];
        // for (index, block) in task_context.blocks.into_iter().enumerate() {
        //     // The row_ids contains the row that its visibility was changed.
        //     let row_ids = block
        //         .row_revs
        //         .par_iter()
        //         .flat_map(|row_rev| {
        //             let filter_result_cache = self.filter_result_cache.clone();
        //             let filter_cache = self.filter_cache.clone();
        //             filter_row(index, row_rev, filter_cache, filter_result_cache, &field_revs)
        //         })
        //         .collect::<Vec<String>>();
        //
        //     let mut visible_rows = vec![];
        //     let mut hide_rows = vec![];
        //
        //     // Query the filter result from the cache
        //     for row_id in row_ids {
        //         if self
        //             .filter_result_cache
        //             .get(&row_id)
        //             .map(|result| result.is_visible())
        //             .unwrap_or(false)
        //         {
        //             visible_rows.push(row_id);
        //         } else {
        //             hide_rows.push(row_id);
        //         }
        //     }
        //
        //     let changeset = GridBlockChangesetPB {
        //         block_id: block.block_id,
        //         hide_rows,
        //         visible_rows,
        //         ..Default::default()
        //     };
        //
        //     // Save the changeset for each block
        //     changesets.push(changeset);
        // }
        //
        // self.notify(changesets).await;
        Ok(())
    }

    pub async fn apply_changeset(&mut self, changeset: FilterChangeset) {
        if let Some(filter_id) = &changeset.insert_filter {
            let filter_configurations = self.delegate.get_filter_configuration(filter_id.clone()).await;
            let _ = self.load_filters(filter_configurations).await;
        }

        if let Some(filter_id) = &changeset.delete_filter {
            self.filter_map.remove(filter_id);
        }

        self.gen_task("");
    }

    async fn notify(&self, changesets: Vec<GridBlockChangesetPB>) {
        for changeset in changesets {
            send_dart_notification(&self.view_id, GridNotification::DidUpdateGridBlock)
                .payload(changeset)
                .send();
        }
    }

    async fn load_filters(&mut self, filter_configurations: Vec<Arc<FilterConfigurationRevision>>) {
        for configuration in filter_configurations {
            if let Some(field_rev) = self.delegate.get_field_rev(&configuration.field_id).await {
                let filter_id = FilterId::from(&field_rev);
                let field_type: FieldType = field_rev.ty.into();
                match &field_type {
                    FieldType::RichText => {
                        let _ = self
                            .filter_map
                            .text_filter
                            .insert(filter_id, TextFilterConfigurationPB::from(configuration));
                    }
                    FieldType::Number => {
                        let _ = self
                            .filter_map
                            .number_filter
                            .insert(filter_id, NumberFilterConfigurationPB::from(configuration));
                    }
                    FieldType::DateTime => {
                        let _ = self
                            .filter_map
                            .date_filter
                            .insert(filter_id, DateFilterConfigurationPB::from(configuration));
                    }
                    FieldType::SingleSelect | FieldType::MultiSelect => {
                        let _ = self
                            .filter_map
                            .select_option_filter
                            .insert(filter_id, SelectOptionFilterConfigurationPB::from(configuration));
                    }
                    FieldType::Checkbox => {
                        let _ = self
                            .filter_map
                            .checkbox_filter
                            .insert(filter_id, CheckboxFilterConfigurationPB::from(configuration));
                    }
                    FieldType::URL => {
                        let _ = self
                            .filter_map
                            .url_filter
                            .insert(filter_id, TextFilterConfigurationPB::from(configuration));
                    }
                }
            }
        }
    }
}

// Return None if there is no change in this row after applying the filter
fn filter_row(
    index: usize,
    row_rev: &Arc<RowRevision>,
    filter_map: Arc<FilterMap>,
    filter_results: &mut HashMap<RowId, FilterResult>,
    field_revs: &HashMap<FieldId, Arc<FieldRevision>>,
) -> Option<String> {
    let result = filter_results
        .entry(row_rev.id.clone())
        .or_insert(FilterResult::new(row_rev));

    for (field_id, cell_rev) in row_rev.cells.iter() {
        match filter_cell(field_revs, result, &filter_map, field_id, cell_rev) {
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
    filter_map: &Arc<FilterMap>,
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
        FieldType::RichText => filter_map.text_filter.get(&filter_id).and_then(|filter| {
            Some(
                field_rev
                    .get_type_option::<RichTextTypeOptionPB>(field_type_rev)?
                    .apply_filter(any_cell_data, filter)
                    .ok(),
            )
        }),
        FieldType::Number => filter_map.number_filter.get(&filter_id).and_then(|filter| {
            Some(
                field_rev
                    .get_type_option::<NumberTypeOptionPB>(field_type_rev)?
                    .apply_filter(any_cell_data, filter)
                    .ok(),
            )
        }),
        FieldType::DateTime => filter_map.date_filter.get(&filter_id).and_then(|filter| {
            Some(
                field_rev
                    .get_type_option::<DateTypeOptionPB>(field_type_rev)?
                    .apply_filter(any_cell_data, filter)
                    .ok(),
            )
        }),
        FieldType::SingleSelect => filter_map.select_option_filter.get(&filter_id).and_then(|filter| {
            Some(
                field_rev
                    .get_type_option::<SingleSelectTypeOptionPB>(field_type_rev)?
                    .apply_filter(any_cell_data, filter)
                    .ok(),
            )
        }),
        FieldType::MultiSelect => filter_map.select_option_filter.get(&filter_id).and_then(|filter| {
            Some(
                field_rev
                    .get_type_option::<MultiSelectTypeOptionPB>(field_type_rev)?
                    .apply_filter(any_cell_data, filter)
                    .ok(),
            )
        }),
        FieldType::Checkbox => filter_map.checkbox_filter.get(&filter_id).and_then(|filter| {
            Some(
                field_rev
                    .get_type_option::<CheckboxTypeOptionPB>(field_type_rev)?
                    .apply_filter(any_cell_data, filter)
                    .ok(),
            )
        }),
        FieldType::URL => filter_map.url_filter.get(&filter_id).and_then(|filter| {
            Some(
                field_rev
                    .get_type_option::<URLTypeOptionPB>(field_type_rev)?
                    .apply_filter(any_cell_data, filter)
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

pub struct FilterChangeset {
    insert_filter: Option<FilterId>,
    delete_filter: Option<FilterId>,
}

impl FilterChangeset {
    pub fn from_insert(filter_id: FilterId) -> Self {
        Self {
            insert_filter: Some(filter_id),
            delete_filter: None,
        }
    }

    pub fn from_delete(filter_id: FilterId) -> Self {
        Self {
            insert_filter: None,
            delete_filter: Some(filter_id),
        }
    }
}

impl std::convert::From<&GridSettingChangesetParams> for FilterChangeset {
    fn from(params: &GridSettingChangesetParams) -> Self {
        let insert_filter = params.insert_filter.as_ref().map(|insert_filter_params| FilterId {
            field_id: insert_filter_params.field_id.clone(),
            field_type: insert_filter_params.field_type_rev.into(),
        });

        let delete_filter = params.delete_filter.as_ref().map(|delete_filter_params| FilterId {
            field_id: delete_filter_params.filter_id.clone(),
            field_type: delete_filter_params.field_type_rev.into(),
        });
        FilterChangeset {
            insert_filter,
            delete_filter,
        }
    }
}

#[derive(Hash, Eq, PartialEq, Clone)]
pub struct FilterId {
    pub field_id: String,
    pub field_type: FieldType,
}

impl std::convert::From<&Arc<FieldRevision>> for FilterId {
    fn from(rev: &Arc<FieldRevision>) -> Self {
        Self {
            field_id: rev.id.clone(),
            field_type: rev.ty.into(),
        }
    }
}

impl std::convert::From<&InsertFilterParams> for FilterId {
    fn from(params: &InsertFilterParams) -> Self {
        let field_type: FieldType = params.field_type_rev.into();
        Self {
            field_id: params.field_id.clone(),
            field_type,
        }
    }
}

impl std::convert::From<&DeleteFilterParams> for FilterId {
    fn from(params: &DeleteFilterParams) -> Self {
        let field_type: FieldType = params.field_type_rev.into();
        Self {
            field_id: params.field_id.clone(),
            field_type,
        }
    }
}
