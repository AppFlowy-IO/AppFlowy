use crate::entities::{
  CalendarLayoutSettingsPB, DatabaseLayoutPB, DatabasePB, DatabaseViewSettingPB, FieldIdPB,
  FieldType, FilterPB, GroupSettingPB, LayoutSettingPB, RepeatedFilterPB, RepeatedGroupPB,
  RepeatedGroupSettingPB, RowPB, SortPB,
};
use crate::services::cell::{AnyTypeCache, CellCache};
use crate::services::database::util::{database_view_setting_pb_from_view, get_database_data};
use crate::services::database_view::{DatabaseViewData, DatabaseViews, RowEventSender};
use crate::services::field::TypeOptionCellDataHandler;
use crate::services::filter::Filter;
use crate::services::group::GroupSetting;
use crate::services::setting::CalendarLayoutSetting;
use crate::services::sort::Sort;
use anyhow::Error;
use collab::plugin_impl::disk::CollabDiskPlugin;
use collab::plugin_impl::snapshot::CollabSnapshotPlugin;
use collab::preclude::{Collab, CollabBuilder};
use collab_database::database::{Database as InnerDatabase, DatabaseContext};
use collab_database::fields::{Field, TypeOptionData};
use collab_database::rows::{Row, RowId};
use collab_persistence::CollabKV;
use flowy_error::{FlowyError, FlowyResult};
use flowy_task::TaskDispatcher;
use lib_infra::future::{to_fut, Fut};
use parking_lot::Mutex;
use std::ops::Deref;
use std::sync::Arc;
use tokio::sync::{broadcast, RwLock};

#[derive(Clone)]
pub struct DatabaseEditor {
  database: Database,
  pub cell_cache: CellCache,
  database_views: Arc<DatabaseViews>,
  row_event_tx: RowEventSender,
}

impl DatabaseEditor {
  pub async fn new(
    database: Database,
    task_scheduler: Arc<RwLock<TaskDispatcher>>,
  ) -> FlowyResult<Self> {
    let cell_cache = AnyTypeCache::<u64>::new();
    let (row_event_tx, block_event_rx) = broadcast::channel(100);
    let database_view_data = Arc::new(DatabaseViewDataImpl {
      database: database.clone(),
      task_scheduler: task_scheduler.clone(),
    });

    let database_views =
      Arc::new(DatabaseViews::new(cell_cache.clone(), database_view_data, block_event_rx).await?);
    Ok(Self {
      database,
      cell_cache,
      database_views,
      row_event_tx,
    })
  }

  pub fn get_field(&self, _field_id: &str) -> Option<Field> {
    todo!()
  }

  pub fn update_field_type_option(
    &self,
    _view_id: &str,
    _field_id: &str,
    _type_option_data: TypeOptionData,
    _old_field: Option<Field>,
  ) {
  }

  pub async fn get_database_view_setting(
    &self,
    view_id: &str,
  ) -> FlowyResult<DatabaseViewSettingPB> {
    let view = self
      .database
      .lock()
      .get_view(view_id)
      .ok_or(FlowyError::record_not_found().context("Can't find the database view"))?;
    Ok(database_view_setting_pb_from_view(view))
  }

  pub async fn get_database_data(&self) -> DatabasePB {
    let database = self.database.lock();
    get_database_data(&database)
  }

  pub async fn get_rows(&self, view_id: &str) -> FlowyResult<Vec<Row>> {
    let rows = self.database.lock().get_rows_for_view(view_id);
    Ok(rows)
  }
}

#[derive(Clone)]
pub struct Database(Arc<Mutex<Arc<InnerDatabase>>>);
impl Database {
  pub(crate) fn new(database: Arc<InnerDatabase>) -> Self {
    Self(Arc::new(Mutex::new(database)))
  }
}

impl Deref for Database {
  type Target = Arc<Mutex<Arc<InnerDatabase>>>;
  fn deref(&self) -> &Self::Target {
    &self.0
  }
}
unsafe impl Sync for Database {}
unsafe impl Send for Database {}

struct DatabaseViewDataImpl {
  database: Database,
  task_scheduler: Arc<RwLock<TaskDispatcher>>,
}

impl DatabaseViewData for DatabaseViewDataImpl {
  fn get_fields(&self, field_ids: Option<Vec<String>>) -> Fut<Vec<Arc<Field>>> {
    let fields = self.database.lock().fields.get_fields(field_ids);
    to_fut(async move { fields.into_iter().map(|field| Arc::new(field)).collect() })
  }

  fn get_field(&self, field_id: &str) -> Fut<Option<Arc<Field>>> {
    let field = self
      .database
      .lock()
      .fields
      .get_field(field_id)
      .map(Arc::new);
    to_fut(async move { field })
  }

  fn get_primary_field(&self) -> Fut<Option<Arc<Field>>> {
    let field = self
      .database
      .lock()
      .fields
      .get_primary_field()
      .map(Arc::new);
    to_fut(async move { field })
  }

  fn index_of_row(&self, view_id: &str, row_id: RowId) -> Fut<Option<usize>> {
    let index = self.database.lock().index_of_row(view_id, row_id);
    to_fut(async move { index })
  }

  fn get_row(&self, view_id: &str, row_id: RowId) -> Fut<Option<(usize, Arc<Row>)>> {
    let index = self.database.lock().index_of_row(view_id, row_id);
    let row = self.database.lock().get_row(row_id);
    to_fut(async move {
      match (index, row) {
        (Some(index), Some(row)) => Some((index, Arc::new(row))),
        _ => None,
      }
    })
  }

  fn get_rows(&self, view_id: &str) -> Fut<Vec<Arc<Row>>> {
    let rows = self.database.lock().get_rows_for_view(view_id);
    to_fut(async move { rows.into_iter().map(|row| Arc::new(row)).collect() })
  }

  fn get_task_scheduler(&self) -> Arc<RwLock<TaskDispatcher>> {
    self.task_scheduler.clone()
  }

  fn get_type_option_cell_handler(
    &self,
    field: &Field,
    field_type: &FieldType,
  ) -> Option<Box<dyn TypeOptionCellDataHandler>> {
    todo!()
  }
}
