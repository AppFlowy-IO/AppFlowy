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
use grid_rev_model::{CellRevision, FieldId, FieldRevision, FieldTypeRevision, FilterRevision, RowRevision};
use lib_infra::future::Fut;
use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::RwLock;

type RowId = String;
pub trait GridViewFilterDelegate: Send + Sync + 'static {
    fn get_filter_rev(&self, filter_id: FilterType) -> Fut<Vec<Arc<FilterRevision>>>;
    fn get_field_rev(&self, field_id: &str) -> Fut<Option<Arc<FieldRevision>>>;
    fn get_field_revs(&self, field_ids: Option<Vec<String>>) -> Fut<Vec<Arc<FieldRevision>>>;
    fn get_blocks(&self) -> Fut<Vec<GridBlock>>;
}

pub struct FilterController {
    view_id: String,
    delegate: Box<dyn GridViewFilterDelegate>,
    filter_map: FilterMap,
    result_by_row_id: HashMap<RowId, FilterResult>,
    task_scheduler: Arc<RwLock<TaskDispatcher>>,
}
impl FilterController {
    pub async fn new<T>(
        view_id: &str,
        delegate: T,
        task_scheduler: Arc<RwLock<TaskDispatcher>>,
        filter_revs: Vec<Arc<FilterRevision>>,
    ) -> Self
    where
        T: GridViewFilterDelegate,
    {
        let mut this = Self {
            view_id: view_id.to_string(),
            delegate: Box::new(delegate),
            filter_map: FilterMap::new(),
            result_by_row_id: HashMap::default(),
            task_scheduler,
        };
        this.load_filters(filter_revs).await;
        this
    }

    pub async fn close(&self) {
        self.task_scheduler.write().await.unregister_handler(FILTER_HANDLER_ID);
    }

    #[tracing::instrument(name = "schedule_filter_task", level = "trace", skip(self))]
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

    pub async fn filter_row_revs(&mut self, row_revs: &mut Vec<Arc<RowRevision>>) {
        if self.filter_map.is_empty() {
            return;
        }
        let field_rev_by_field_id = self.get_filter_revs_map().await;
        let _ = row_revs
            .iter()
            .flat_map(|row_rev| {
                filter_row(
                    row_rev,
                    &self.filter_map,
                    &mut self.result_by_row_id,
                    &field_rev_by_field_id,
                )
            })
            .collect::<Vec<String>>();

        row_revs.retain(|row_rev| {
            self.result_by_row_id
                .get(&row_rev.id)
                .map(|result| result.is_visible())
                .unwrap_or(false)
        });
    }

    async fn get_filter_revs_map(&self) -> HashMap<String, Arc<FieldRevision>> {
        self.delegate
            .get_field_revs(None)
            .await
            .into_iter()
            .map(|field_rev| (field_rev.id.clone(), field_rev))
            .collect::<HashMap<String, Arc<FieldRevision>>>()
    }

    pub async fn process(&mut self, _predicate: &str) -> FlowyResult<()> {
        let field_rev_by_field_id = self.get_filter_revs_map().await;
        let mut changesets = vec![];
        for block in self.delegate.get_blocks().await.into_iter() {
            // The row_ids contains the row that its visibility was changed.
            let row_ids = block
                .row_revs
                .iter()
                .flat_map(|row_rev| {
                    filter_row(
                        row_rev,
                        &self.filter_map,
                        &mut self.result_by_row_id,
                        &field_rev_by_field_id,
                    )
                })
                .collect::<Vec<String>>();

            let mut visible_rows = vec![];
            let mut hide_rows = vec![];

            // Query the filter result from the cache
            for row_id in row_ids {
                if self
                    .result_by_row_id
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

    pub async fn apply_changeset(&mut self, changeset: FilterChangeset) {
        if let Some(filter_id) = &changeset.insert_filter {
            let filter_revs = self.delegate.get_filter_rev(filter_id.clone()).await;
            let _ = self.load_filters(filter_revs).await;
        }

        if let Some(filter_id) = &changeset.delete_filter {
            self.filter_map.remove(filter_id);
        }

        self.gen_task("").await;
    }

    async fn notify(&self, changesets: Vec<GridBlockChangesetPB>) {
        for changeset in changesets {
            send_dart_notification(&self.view_id, GridNotification::DidUpdateGridBlock)
                .payload(changeset)
                .send();
        }
    }

    async fn load_filters(&mut self, filter_revs: Vec<Arc<FilterRevision>>) {
        for filter_rev in filter_revs {
            if let Some(field_rev) = self.delegate.get_field_rev(&filter_rev.field_id).await {
                let filter_type = FilterType::from(&field_rev);
                let field_type: FieldType = field_rev.ty.into();
                match &field_type {
                    FieldType::RichText => {
                        let _ = self
                            .filter_map
                            .text_filter
                            .insert(filter_type, TextFilterPB::from(filter_rev));
                    }
                    FieldType::Number => {
                        let _ = self
                            .filter_map
                            .number_filter
                            .insert(filter_type, NumberFilterPB::from(filter_rev));
                    }
                    FieldType::DateTime => {
                        let _ = self
                            .filter_map
                            .date_filter
                            .insert(filter_type, DateFilterPB::from(filter_rev));
                    }
                    FieldType::SingleSelect | FieldType::MultiSelect => {
                        let _ = self
                            .filter_map
                            .select_option_filter
                            .insert(filter_type, SelectOptionFilterPB::from(filter_rev));
                    }
                    FieldType::Checkbox => {
                        let _ = self
                            .filter_map
                            .checkbox_filter
                            .insert(filter_type, CheckboxFilterPB::from(filter_rev));
                    }
                    FieldType::URL => {
                        let _ = self
                            .filter_map
                            .url_filter
                            .insert(filter_type, TextFilterPB::from(filter_rev));
                    }
                }
            }
        }
    }
}

/// Returns None if there is no change in this row after applying the filter
fn filter_row(
    row_rev: &Arc<RowRevision>,
    filter_map: &FilterMap,
    result_by_row_id: &mut HashMap<RowId, FilterResult>,
    field_rev_by_field_id: &HashMap<FieldId, Arc<FieldRevision>>,
) -> Option<String> {
    // Create a filter result cache if it's not exist
    let filter_result = result_by_row_id
        .entry(row_rev.id.clone())
        .or_insert_with(FilterResult::default);

    // Iterate each cell of the row to check its visibility
    for (field_id, cell_rev) in row_rev.cells.iter() {
        let field_rev = field_rev_by_field_id.get(field_id)?;
        let filter_type = FilterType::from(field_rev);

        // if the visibility of the cell_rew is changed, which means the visibility of the
        // row is changed too.
        if let Some(is_visible) = filter_cell(&filter_type, field_rev, filter_map, cell_rev) {
            let prev_is_visible = filter_result.visible_by_filter_id.get(&filter_type).cloned();
            filter_result.visible_by_filter_id.insert(filter_type, is_visible);
            match prev_is_visible {
                None => {
                    if !is_visible {
                        return Some(row_rev.id.clone());
                    }
                }
                Some(prev_is_visible) => {
                    if prev_is_visible != is_visible {
                        return Some(row_rev.id.clone());
                    }
                }
            }
        }
    }
    None
}

// Return None if there is no change in this cell after applying the filter
fn filter_cell(
    filter_id: &FilterType,
    field_rev: &Arc<FieldRevision>,
    filter_map: &FilterMap,
    cell_rev: &CellRevision,
) -> Option<bool> {
    let any_cell_data = AnyCellData::try_from(cell_rev).ok()?;
    let is_visible = match &filter_id.field_type {
        FieldType::RichText => filter_map.text_filter.get(filter_id).and_then(|filter| {
            Some(
                field_rev
                    .get_type_option::<RichTextTypeOptionPB>(field_rev.ty)?
                    .apply_filter(any_cell_data, filter)
                    .ok(),
            )
        }),
        FieldType::Number => filter_map.number_filter.get(filter_id).and_then(|filter| {
            Some(
                field_rev
                    .get_type_option::<NumberTypeOptionPB>(field_rev.ty)?
                    .apply_filter(any_cell_data, filter)
                    .ok(),
            )
        }),
        FieldType::DateTime => filter_map.date_filter.get(filter_id).and_then(|filter| {
            Some(
                field_rev
                    .get_type_option::<DateTypeOptionPB>(field_rev.ty)?
                    .apply_filter(any_cell_data, filter)
                    .ok(),
            )
        }),
        FieldType::SingleSelect => filter_map.select_option_filter.get(filter_id).and_then(|filter| {
            Some(
                field_rev
                    .get_type_option::<SingleSelectTypeOptionPB>(field_rev.ty)?
                    .apply_filter(any_cell_data, filter)
                    .ok(),
            )
        }),
        FieldType::MultiSelect => filter_map.select_option_filter.get(filter_id).and_then(|filter| {
            Some(
                field_rev
                    .get_type_option::<MultiSelectTypeOptionPB>(field_rev.ty)?
                    .apply_filter(any_cell_data, filter)
                    .ok(),
            )
        }),
        FieldType::Checkbox => filter_map.checkbox_filter.get(filter_id).and_then(|filter| {
            Some(
                field_rev
                    .get_type_option::<CheckboxTypeOptionPB>(field_rev.ty)?
                    .apply_filter(any_cell_data, filter)
                    .ok(),
            )
        }),
        FieldType::URL => filter_map.url_filter.get(filter_id).and_then(|filter| {
            Some(
                field_rev
                    .get_type_option::<URLTypeOptionPB>(field_rev.ty)?
                    .apply_filter(any_cell_data, filter)
                    .ok(),
            )
        }),
    }?;

    is_visible
}

pub struct FilterChangeset {
    insert_filter: Option<FilterType>,
    delete_filter: Option<FilterType>,
}

impl FilterChangeset {
    pub fn from_insert(filter_id: FilterType) -> Self {
        Self {
            insert_filter: Some(filter_id),
            delete_filter: None,
        }
    }

    pub fn from_delete(filter_id: FilterType) -> Self {
        Self {
            insert_filter: None,
            delete_filter: Some(filter_id),
        }
    }
}

impl std::convert::From<&GridSettingChangesetParams> for FilterChangeset {
    fn from(params: &GridSettingChangesetParams) -> Self {
        let insert_filter = params.insert_filter.as_ref().map(|insert_filter_params| FilterType {
            field_id: insert_filter_params.field_id.clone(),
            field_type: insert_filter_params.field_type_rev.into(),
        });

        let delete_filter = params
            .delete_filter
            .as_ref()
            .map(|delete_filter_params| delete_filter_params.filter_type.clone());
        FilterChangeset {
            insert_filter,
            delete_filter,
        }
    }
}

#[derive(Hash, Eq, PartialEq, Clone)]
pub struct FilterType {
    pub field_id: String,
    pub field_type: FieldType,
}

impl FilterType {
    pub fn field_type_rev(&self) -> FieldTypeRevision {
        self.field_type.clone().into()
    }
}

impl std::convert::From<&Arc<FieldRevision>> for FilterType {
    fn from(rev: &Arc<FieldRevision>) -> Self {
        Self {
            field_id: rev.id.clone(),
            field_type: rev.ty.into(),
        }
    }
}

impl std::convert::From<&InsertFilterParams> for FilterType {
    fn from(params: &InsertFilterParams) -> Self {
        let field_type: FieldType = params.field_type_rev.into();
        Self {
            field_id: params.field_id.clone(),
            field_type,
        }
    }
}

impl std::convert::From<&DeleteFilterParams> for FilterType {
    fn from(params: &DeleteFilterParams) -> Self {
        params.filter_type.clone()
    }
}
