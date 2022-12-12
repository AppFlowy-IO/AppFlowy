#![allow(clippy::all)]
#[allow(unused_attributes)]
use crate::entities::{GridSortPB, SortChangesetNotificationPB};
use crate::services::sort::{SortChangeset, SortType};
use flowy_task::TaskDispatcher;
use grid_rev_model::{FieldRevision, RowRevision, SortRevision};
use lib_infra::future::Fut;
use std::sync::Arc;
use tokio::sync::RwLock;

pub trait SortDelegate: Send + Sync {
    fn get_sort_rev(&self, sort_type: SortType) -> Fut<Vec<Arc<SortRevision>>>;
    fn get_field_rev(&self, field_id: &str) -> Fut<Option<Arc<FieldRevision>>>;
    fn get_field_revs(&self, field_ids: Option<Vec<String>>) -> Fut<Vec<Arc<FieldRevision>>>;
}

pub struct SortController {
    #[allow(dead_code)]
    view_id: String,
    #[allow(dead_code)]
    handler_id: String,
    #[allow(dead_code)]
    delegate: Box<dyn SortDelegate>,
    task_scheduler: Arc<RwLock<TaskDispatcher>>,
    #[allow(dead_code)]
    sorts: Vec<GridSortPB>,
}

impl SortController {
    pub fn new<T>(view_id: &str, handler_id: &str, delegate: T, task_scheduler: Arc<RwLock<TaskDispatcher>>) -> Self
    where
        T: SortDelegate + 'static,
    {
        Self {
            view_id: view_id.to_string(),
            handler_id: handler_id.to_string(),
            delegate: Box::new(delegate),
            task_scheduler,
            sorts: vec![],
        }
    }

    pub async fn close(&self) {
        self.task_scheduler
            .write()
            .await
            .unregister_handler(&self.handler_id)
            .await;
    }

    pub fn sort_rows(&self, _rows: &mut Vec<Arc<RowRevision>>) {
        //
    }

    pub async fn did_receive_changes(&mut self, _changeset: SortChangeset) -> Option<SortChangesetNotificationPB> {
        None
    }
}
