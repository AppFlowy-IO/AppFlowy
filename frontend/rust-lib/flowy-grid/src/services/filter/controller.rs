use crate::entities::filter_entities::*;
use crate::entities::{FieldType, InsertedRowPB, RowPB};
use crate::services::cell::{AnyTypeCache, AtomicCellDataCache, AtomicCellFilterCache, TypeCellData};
use crate::services::field::*;
use crate::services::filter::{FilterChangeset, FilterResult, FilterResultNotification, FilterType};
use crate::services::row::GridBlockRowRevision;
use crate::services::view_editor::{GridViewChanged, GridViewChangedNotifier};
use flowy_error::FlowyResult;
use flowy_task::{QualityOfService, Task, TaskContent, TaskDispatcher};
use grid_rev_model::{CellRevision, FieldId, FieldRevision, FilterRevision, RowRevision};
use lib_infra::future::Fut;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::str::FromStr;
use std::sync::Arc;
use tokio::sync::RwLock;

type RowId = String;
pub trait FilterDelegate: Send + Sync + 'static {
    fn get_filter_rev(&self, filter_type: FilterType) -> Fut<Option<Arc<FilterRevision>>>;
    fn get_field_rev(&self, field_id: &str) -> Fut<Option<Arc<FieldRevision>>>;
    fn get_field_revs(&self, field_ids: Option<Vec<String>>) -> Fut<Vec<Arc<FieldRevision>>>;
    fn get_blocks(&self) -> Fut<Vec<GridBlockRowRevision>>;
    fn get_row_rev(&self, rows_id: &str) -> Fut<Option<(usize, Arc<RowRevision>)>>;
}

pub trait FromFilterString {
    fn from_filter_rev(filter_rev: &FilterRevision) -> Self
    where
        Self: Sized;
}

pub struct FilterController {
    view_id: String,
    handler_id: String,
    delegate: Box<dyn FilterDelegate>,
    result_by_row_id: HashMap<RowId, FilterResult>,
    cell_data_cache: AtomicCellDataCache,
    cell_filter_cache: AtomicCellFilterCache,
    task_scheduler: Arc<RwLock<TaskDispatcher>>,
    notifier: GridViewChangedNotifier,
}

impl FilterController {
    pub async fn new<T>(
        view_id: &str,
        handler_id: &str,
        delegate: T,
        task_scheduler: Arc<RwLock<TaskDispatcher>>,
        filter_revs: Vec<Arc<FilterRevision>>,
        cell_data_cache: AtomicCellDataCache,
        notifier: GridViewChangedNotifier,
    ) -> Self
    where
        T: FilterDelegate + 'static,
    {
        let mut this = Self {
            view_id: view_id.to_string(),
            handler_id: handler_id.to_string(),
            delegate: Box::new(delegate),
            result_by_row_id: HashMap::default(),
            cell_data_cache,
            cell_filter_cache: AnyTypeCache::<FilterType>::new(),
            task_scheduler,
            notifier,
        };
        this.refresh_filters(filter_revs).await;
        this
    }

    pub async fn close(&self) {
        self.task_scheduler
            .write()
            .await
            .unregister_handler(&self.handler_id)
            .await;
    }

    #[tracing::instrument(name = "schedule_filter_task", level = "trace", skip(self))]
    async fn gen_task(&self, task_type: FilterEvent, qos: QualityOfService) {
        let task_id = self.task_scheduler.read().await.next_task_id();
        let task = Task::new(&self.handler_id, task_id, TaskContent::Text(task_type.to_string()), qos);
        self.task_scheduler.write().await.add_task(task);
    }

    pub async fn filter_row_revs(&mut self, row_revs: &mut Vec<Arc<RowRevision>>) {
        if self.cell_filter_cache.read().is_empty() {
            return;
        }
        let field_rev_by_field_id = self.get_filter_revs_map().await;
        row_revs.iter().for_each(|row_rev| {
            let _ = filter_row(
                row_rev,
                &mut self.result_by_row_id,
                &field_rev_by_field_id,
                &self.cell_data_cache,
                &self.cell_filter_cache,
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

    #[tracing::instrument(name = "process_filter_task", level = "trace", skip_all, fields(filter_result), err)]
    pub async fn process(&mut self, predicate: &str) -> FlowyResult<()> {
        let event_type = FilterEvent::from_str(predicate).unwrap();
        match event_type {
            FilterEvent::FilterDidChanged => self.filter_all_rows().await?,
            FilterEvent::RowDidChanged(row_id) => self.filter_row(row_id).await?,
        }
        Ok(())
    }

    async fn filter_row(&mut self, row_id: String) -> FlowyResult<()> {
        if let Some((_, row_rev)) = self.delegate.get_row_rev(&row_id).await {
            let field_rev_by_field_id = self.get_filter_revs_map().await;
            let mut notification = FilterResultNotification::new(self.view_id.clone(), row_rev.block_id.clone());
            if let Some((row_id, is_visible)) = filter_row(
                &row_rev,
                &mut self.result_by_row_id,
                &field_rev_by_field_id,
                &self.cell_data_cache,
                &self.cell_filter_cache,
            ) {
                if is_visible {
                    if let Some((index, row_rev)) = self.delegate.get_row_rev(&row_id).await {
                        let row_pb = RowPB::from(row_rev.as_ref());
                        notification
                            .visible_rows
                            .push(InsertedRowPB::with_index(row_pb, index as i32))
                    }
                } else {
                    notification.invisible_rows.push(row_id);
                }
            }

            let _ = self.notifier.send(GridViewChanged::FilterNotification(notification));
        }
        Ok(())
    }

    async fn filter_all_rows(&mut self) -> FlowyResult<()> {
        let field_rev_by_field_id = self.get_filter_revs_map().await;
        for block in self.delegate.get_blocks().await.into_iter() {
            // The row_ids contains the row that its visibility was changed.
            let mut visible_rows = vec![];
            let mut invisible_rows = vec![];

            for (index, row_rev) in block.row_revs.iter().enumerate() {
                if let Some((row_id, is_visible)) = filter_row(
                    row_rev,
                    &mut self.result_by_row_id,
                    &field_rev_by_field_id,
                    &self.cell_data_cache,
                    &self.cell_filter_cache,
                ) {
                    if is_visible {
                        let row_pb = RowPB::from(row_rev.as_ref());
                        visible_rows.push(InsertedRowPB::with_index(row_pb, index as i32))
                    } else {
                        invisible_rows.push(row_id);
                    }
                }
            }

            let notification = FilterResultNotification {
                view_id: self.view_id.clone(),
                block_id: block.block_id,
                invisible_rows,
                visible_rows,
            };
            tracing::Span::current().record("filter_result", &format!("{:?}", &notification).as_str());
            let _ = self.notifier.send(GridViewChanged::FilterNotification(notification));
        }
        Ok(())
    }

    pub async fn did_receive_row_changed(&self, row_id: &str) {
        self.gen_task(
            FilterEvent::RowDidChanged(row_id.to_string()),
            QualityOfService::UserInteractive,
        )
        .await
    }

    #[tracing::instrument(level = "trace", skip(self))]
    pub async fn did_receive_changes(&mut self, changeset: FilterChangeset) -> Option<FilterChangesetNotificationPB> {
        let mut notification: Option<FilterChangesetNotificationPB> = None;
        if let Some(filter_type) = &changeset.insert_filter {
            if let Some(filter) = self.filter_from_filter_type(filter_type).await {
                notification = Some(FilterChangesetNotificationPB::from_insert(&self.view_id, vec![filter]));
            }
            if let Some(filter_rev) = self.delegate.get_filter_rev(filter_type.clone()).await {
                self.refresh_filters(vec![filter_rev]).await;
            }
        }

        if let Some(updated_filter_type) = changeset.update_filter {
            if let Some(old_filter_type) = updated_filter_type.old {
                let new_filter = self.filter_from_filter_type(&updated_filter_type.new).await;
                let old_filter = self.filter_from_filter_type(&old_filter_type).await;

                // Get the filter id
                let mut filter_id = old_filter.map(|filter| filter.id);
                if filter_id.is_none() {
                    filter_id = new_filter.as_ref().map(|filter| filter.id.clone());
                }

                // Update the corresponding filter in the cache
                if let Some(filter_rev) = self.delegate.get_filter_rev(updated_filter_type.new.clone()).await {
                    self.refresh_filters(vec![filter_rev]).await;
                }

                if let Some(filter_id) = filter_id {
                    notification = Some(FilterChangesetNotificationPB::from_update(
                        &self.view_id,
                        vec![UpdatedFilter {
                            filter_id,
                            filter: new_filter,
                        }],
                    ));
                }
            }
        }

        if let Some(filter_type) = &changeset.delete_filter {
            if let Some(filter) = self.filter_from_filter_type(filter_type).await {
                notification = Some(FilterChangesetNotificationPB::from_delete(&self.view_id, vec![filter]));
            }
            self.cell_filter_cache.write().remove(filter_type);
        }

        self.gen_task(FilterEvent::FilterDidChanged, QualityOfService::Background)
            .await;
        tracing::trace!("{:?}", notification);
        notification
    }

    async fn filter_from_filter_type(&self, filter_type: &FilterType) -> Option<FilterPB> {
        self.delegate
            .get_filter_rev(filter_type.clone())
            .await
            .map(|filter| FilterPB::from(filter.as_ref()))
    }

    #[tracing::instrument(level = "trace", skip_all)]
    async fn refresh_filters(&mut self, filter_revs: Vec<Arc<FilterRevision>>) {
        for filter_rev in filter_revs {
            if let Some(field_rev) = self.delegate.get_field_rev(&filter_rev.field_id).await {
                let filter_type = FilterType::from(&field_rev);
                tracing::trace!("Create filter with type: {:?}", filter_type);
                match &filter_type.field_type {
                    FieldType::RichText => {
                        self.cell_filter_cache
                            .write()
                            .insert(&filter_type, TextFilterPB::from_filter_rev(filter_rev.as_ref()));
                    }
                    FieldType::Number => {
                        self.cell_filter_cache
                            .write()
                            .insert(&filter_type, NumberFilterPB::from_filter_rev(filter_rev.as_ref()));
                    }
                    FieldType::DateTime => {
                        self.cell_filter_cache
                            .write()
                            .insert(&filter_type, DateFilterPB::from_filter_rev(filter_rev.as_ref()));
                    }
                    FieldType::SingleSelect | FieldType::MultiSelect => {
                        self.cell_filter_cache
                            .write()
                            .insert(&filter_type, SelectOptionFilterPB::from_filter_rev(filter_rev.as_ref()));
                    }
                    FieldType::Checkbox => {
                        self.cell_filter_cache
                            .write()
                            .insert(&filter_type, CheckboxFilterPB::from_filter_rev(filter_rev.as_ref()));
                    }
                    FieldType::URL => {
                        self.cell_filter_cache
                            .write()
                            .insert(&filter_type, TextFilterPB::from_filter_rev(filter_rev.as_ref()));
                    }
                    FieldType::Checklist => {
                        self.cell_filter_cache
                            .write()
                            .insert(&filter_type, ChecklistFilterPB::from_filter_rev(filter_rev.as_ref()));
                    }
                }
            }
        }
    }
}

/// Returns None if there is no change in this row after applying the filter
#[tracing::instrument(level = "trace", skip_all)]
fn filter_row(
    row_rev: &Arc<RowRevision>,
    result_by_row_id: &mut HashMap<RowId, FilterResult>,
    field_rev_by_field_id: &HashMap<FieldId, Arc<FieldRevision>>,
    cell_data_cache: &AtomicCellDataCache,
    cell_filter_cache: &AtomicCellFilterCache,
) -> Option<(String, bool)> {
    // Create a filter result cache if it's not exist
    let filter_result = result_by_row_id
        .entry(row_rev.id.clone())
        .or_insert_with(FilterResult::default);
    let old_is_visible = filter_result.is_visible();

    // Iterate each cell of the row to check its visibility
    for (field_id, field_rev) in field_rev_by_field_id {
        let filter_type = FilterType::from(field_rev);
        if !cell_filter_cache.read().contains(&filter_type) {
            filter_result.visible_by_filter_id.remove(&filter_type);
            continue;
        }

        let cell_rev = row_rev.cells.get(field_id);
        // if the visibility of the cell_rew is changed, which means the visibility of the
        // row is changed too.
        if let Some(is_visible) = filter_cell(&filter_type, field_rev, cell_rev, cell_data_cache, cell_filter_cache) {
            filter_result.visible_by_filter_id.insert(filter_type, is_visible);
        }
    }

    let is_visible = filter_result.is_visible();
    if old_is_visible != is_visible {
        Some((row_rev.id.clone(), is_visible))
    } else {
        None
    }
}

// Returns None if there is no change in this cell after applying the filter
// Returns Some if the visibility of the cell is changed

#[tracing::instrument(level = "trace", skip_all, fields(cell_content))]
fn filter_cell(
    filter_type: &FilterType,
    field_rev: &Arc<FieldRevision>,
    cell_rev: Option<&CellRevision>,
    cell_data_cache: &AtomicCellDataCache,
    cell_filter_cache: &AtomicCellFilterCache,
) -> Option<bool> {
    let type_cell_data = match cell_rev {
        None => TypeCellData::from_field_type(&filter_type.field_type),
        Some(cell_rev) => match TypeCellData::try_from(cell_rev) {
            Ok(cell_data) => cell_data,
            Err(err) => {
                tracing::error!("Deserialize TypeCellData failed: {}", err);
                TypeCellData::from_field_type(&filter_type.field_type)
            }
        },
    };

    let handler = TypeOptionCellExt::new(
        field_rev.as_ref(),
        Some(cell_data_cache.clone()),
        Some(cell_filter_cache.clone()),
    )
    .get_type_option_cell_data_handler(&filter_type.field_type)?;

    let is_visible = handler.handle_cell_filter(filter_type, field_rev.as_ref(), type_cell_data);
    Some(is_visible)
}

#[derive(Serialize, Deserialize, Clone, Debug)]
enum FilterEvent {
    FilterDidChanged,
    RowDidChanged(String),
}

impl ToString for FilterEvent {
    fn to_string(&self) -> String {
        serde_json::to_string(self).unwrap()
    }
}

impl FromStr for FilterEvent {
    type Err = serde_json::Error;
    fn from_str(s: &str) -> Result<Self, Self::Err> {
        serde_json::from_str(s)
    }
}
