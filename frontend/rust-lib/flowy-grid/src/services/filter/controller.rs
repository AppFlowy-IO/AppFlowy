use crate::entities::filter_entities::*;

use crate::entities::FieldType;
use crate::services::cell::{CellFilterOperation, TypeCellData};
use crate::services::field::*;
use crate::services::filter::{
    FilterChangeset, FilterMap, FilterResult, FilterResultNotification, FilterType, FILTER_HANDLER_ID,
};
use crate::services::row::GridBlock;
use crate::services::view_editor::{GridViewChanged, GridViewChangedNotifier};
use flowy_error::FlowyResult;
use flowy_task::{QualityOfService, Task, TaskContent, TaskDispatcher};
use grid_rev_model::{CellRevision, FieldId, FieldRevision, FilterRevision, RowRevision};
use lib_infra::future::Fut;
use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::RwLock;

type RowId = String;
pub trait FilterDelegate: Send + Sync + 'static {
    fn get_filter_rev(&self, filter_id: FilterType) -> Fut<Vec<Arc<FilterRevision>>>;
    fn get_field_rev(&self, field_id: &str) -> Fut<Option<Arc<FieldRevision>>>;
    fn get_field_revs(&self, field_ids: Option<Vec<String>>) -> Fut<Vec<Arc<FieldRevision>>>;
    fn get_blocks(&self) -> Fut<Vec<GridBlock>>;
}

pub struct FilterController {
    view_id: String,
    delegate: Box<dyn FilterDelegate>,
    filter_map: FilterMap,
    result_by_row_id: HashMap<RowId, FilterResult>,
    task_scheduler: Arc<RwLock<TaskDispatcher>>,
    notifier: GridViewChangedNotifier,
}

impl FilterController {
    pub async fn new<T>(
        view_id: &str,
        delegate: T,
        task_scheduler: Arc<RwLock<TaskDispatcher>>,
        filter_revs: Vec<Arc<FilterRevision>>,
        notifier: GridViewChangedNotifier,
    ) -> Self
    where
        T: FilterDelegate,
    {
        let mut this = Self {
            view_id: view_id.to_string(),
            delegate: Box::new(delegate),
            filter_map: FilterMap::new(),
            result_by_row_id: HashMap::default(),
            task_scheduler,
            notifier,
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
        row_revs.iter().for_each(|row_rev| {
            let _ = filter_row(
                row_rev,
                &self.filter_map,
                &mut self.result_by_row_id,
                &field_rev_by_field_id,
            );
        });

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

    #[tracing::instrument(name = "receive_task_result", level = "trace", skip_all, fields(filter_result), err)]
    pub async fn process(&mut self, _predicate: &str) -> FlowyResult<()> {
        let field_rev_by_field_id = self.get_filter_revs_map().await;
        for block in self.delegate.get_blocks().await.into_iter() {
            // The row_ids contains the row that its visibility was changed.
            let mut visible_rows = vec![];
            let mut invisible_rows = vec![];

            for row_rev in &block.row_revs {
                let (row_id, is_visible) = filter_row(
                    row_rev,
                    &self.filter_map,
                    &mut self.result_by_row_id,
                    &field_rev_by_field_id,
                );
                if is_visible {
                    visible_rows.push(row_id)
                } else {
                    invisible_rows.push(row_id);
                }
            }

            let notification = FilterResultNotification {
                view_id: self.view_id.clone(),
                block_id: block.block_id,
                invisible_rows,
                visible_rows,
            };
            tracing::Span::current().record("filter_result", &format!("{:?}", &notification).as_str());
            let _ = self
                .notifier
                .send(GridViewChanged::DidReceiveFilterResult(notification));
        }

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
                            .insert(filter_type, TextFilterPB::from(filter_rev.as_ref()));
                    }
                    FieldType::Number => {
                        let _ = self
                            .filter_map
                            .number_filter
                            .insert(filter_type, NumberFilterPB::from(filter_rev.as_ref()));
                    }
                    FieldType::DateTime => {
                        let _ = self
                            .filter_map
                            .date_filter
                            .insert(filter_type, DateFilterPB::from(filter_rev.as_ref()));
                    }
                    FieldType::SingleSelect | FieldType::MultiSelect => {
                        let _ = self
                            .filter_map
                            .select_option_filter
                            .insert(filter_type, SelectOptionFilterPB::from(filter_rev.as_ref()));
                    }
                    FieldType::Checkbox => {
                        let _ = self
                            .filter_map
                            .checkbox_filter
                            .insert(filter_type, CheckboxFilterPB::from(filter_rev.as_ref()));
                    }
                    FieldType::URL => {
                        let _ = self
                            .filter_map
                            .url_filter
                            .insert(filter_type, TextFilterPB::from(filter_rev.as_ref()));
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
) -> (String, bool) {
    // Create a filter result cache if it's not exist
    let filter_result = result_by_row_id
        .entry(row_rev.id.clone())
        .or_insert_with(FilterResult::default);

    // Iterate each cell of the row to check its visibility
    for (field_id, field_rev) in field_rev_by_field_id {
        let filter_type = FilterType::from(field_rev);
        if !filter_map.has_filter(&filter_type) {
            continue;
        }

        let cell_rev = row_rev.cells.get(field_id);
        // if the visibility of the cell_rew is changed, which means the visibility of the
        // row is changed too.
        if let Some(is_visible) = filter_cell(&filter_type, field_rev, filter_map, cell_rev) {
            filter_result.visible_by_filter_id.insert(filter_type, is_visible);
            return (row_rev.id.clone(), is_visible);
        }
    }

    (row_rev.id.clone(), true)
}

// Returns None if there is no change in this cell after applying the filter
// Returns Some if the visibility of the cell is changed

#[tracing::instrument(level = "trace", skip_all)]
fn filter_cell(
    filter_id: &FilterType,
    field_rev: &Arc<FieldRevision>,
    filter_map: &FilterMap,
    cell_rev: Option<&CellRevision>,
) -> Option<bool> {
    let any_cell_data = match cell_rev {
        None => TypeCellData::from_field_type(&filter_id.field_type),
        Some(cell_rev) => match TypeCellData::try_from(cell_rev) {
            Ok(cell_data) => cell_data,
            Err(err) => {
                tracing::error!("Deserialize TypeCellData failed: {}", err);
                TypeCellData::from_field_type(&filter_id.field_type)
            }
        },
    };
    tracing::info!("filter cell: {:?}", any_cell_data);

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
