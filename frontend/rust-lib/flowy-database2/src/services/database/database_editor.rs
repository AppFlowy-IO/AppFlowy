use crate::entities::{
  AlterFilterParams, AlterSortParams, CalendarLayoutSettingsPB, DatabaseFieldChangesetPB,
  DatabaseLayoutPB, DatabasePB, DatabaseViewSettingPB, DeleteFilterParams, DeleteGroupParams,
  DeleteSortParams, FieldChangesetParams, FieldIdPB, FieldPB, FieldType, FilterPB, GroupSettingPB,
  InsertGroupParams, LayoutSettingPB, RepeatedFieldPB, RepeatedFilterPB, RepeatedGroupPB,
  RepeatedGroupSettingPB, RepeatedSortPB, RowPB, SortPB,
};
use crate::services::cell::{AnyTypeCache, CellCache};
use crate::services::database::util::{database_view_setting_pb_from_view, get_database_data};
use crate::services::database_view::{DatabaseViewData, DatabaseViews, RowEventSender};
use crate::services::field::TypeOptionCellDataHandler;
use crate::services::group::{default_group_setting, GroupSetting};
use crate::services::sort::Sort;
use collab_database::database::Database as InnerDatabase;
use collab_database::fields::{Field, TypeOptionData};
use collab_database::rows::{Row, RowCell, RowId};
use collab_database::views::{DatabaseLayout, DatabaseView, LayoutSetting};

use crate::notification::{send_notification, DatabaseNotification};
use crate::services::filter::Filter;
use flowy_error::{FlowyError, FlowyResult};
use flowy_task::TaskDispatcher;
use lib_infra::future::{to_fut, Fut};
use parking_lot::Mutex;
use std::ops::Deref;
use std::sync::Arc;
use tokio::sync::{broadcast, RwLock};

#[derive(Clone)]
pub struct DatabaseEditor {
  database: MutexDatabase,
  pub cell_cache: CellCache,
  database_views: Arc<DatabaseViews>,
  row_event_tx: RowEventSender,
}

impl DatabaseEditor {
  pub async fn new(
    database: MutexDatabase,
    task_scheduler: Arc<RwLock<TaskDispatcher>>,
  ) -> FlowyResult<Self> {
    let cell_cache = AnyTypeCache::<u64>::new();
    let (row_event_tx, block_event_rx) = broadcast::channel(100);
    let database_view_data = Arc::new(DatabaseViewDataImpl {
      database: database.clone(),
      task_scheduler: task_scheduler.clone(),
    });

    let database_views = Arc::new(
      DatabaseViews::new(
        database.clone(),
        cell_cache.clone(),
        database_view_data,
        block_event_rx,
      )
      .await?,
    );
    Ok(Self {
      database,
      cell_cache,
      database_views,
      row_event_tx,
    })
  }

  pub fn get_field(&self, field_id: &str) -> Option<Field> {
    self.database.lock().fields.get_field(field_id)
  }

  pub async fn insert_group(&self, params: InsertGroupParams) -> FlowyResult<()> {
    if let Some(field) = self.database.lock().fields.get_field(&params.field_id) {
      let group_setting = default_group_setting(&field);
      self
        .database
        .lock()
        .insert_group_setting(&params.view_id, group_setting);
    }
    let view_editor = self.database_views.get_view_editor(&params.view_id).await?;
    view_editor.v_initialize_new_group(params).await?;
    Ok(())
  }

  pub async fn delete_group(&self, params: DeleteGroupParams) -> FlowyResult<()> {
    self
      .database
      .lock()
      .delete_group_setting(&params.view_id, &params.group_id);
    let view_editor = self.database_views.get_view_editor(&params.view_id).await?;
    view_editor.v_delete_group(params).await?;

    Ok(())
  }

  pub async fn create_or_update_filter(&self, params: AlterFilterParams) -> FlowyResult<()> {
    let view_editor = self.database_views.get_view_editor(&params.view_id).await?;
    view_editor.v_insert_filter(params).await?;
    Ok(())
  }

  pub async fn delete_filter(&self, params: DeleteFilterParams) -> FlowyResult<()> {
    let view_editor = self.database_views.get_view_editor(&params.view_id).await?;
    view_editor.v_delete_filter(params).await?;
    Ok(())
  }

  pub async fn create_or_update_sort(&self, params: AlterSortParams) -> FlowyResult<Sort> {
    let view_editor = self.database_views.get_view_editor(&params.view_id).await?;
    let sort = view_editor.v_insert_sort(params).await?;
    Ok(sort)
  }

  pub async fn delete_sort(&self, params: DeleteSortParams) -> FlowyResult<()> {
    let view_editor = self.database_views.get_view_editor(&params.view_id).await?;
    view_editor.v_delete_sort(params).await?;
    Ok(())
  }

  pub async fn get_all_filters(&self, view_id: &str) -> RepeatedFilterPB {
    if let Ok(view_editor) = self.database_views.get_view_editor(view_id).await {
      view_editor.v_get_all_filters().await.into()
    } else {
      RepeatedFilterPB { items: vec![] }
    }
  }

  pub async fn get_all_sorts(&self, view_id: &str) -> RepeatedSortPB {
    if let Ok(view_editor) = self.database_views.get_view_editor(view_id).await {
      view_editor.v_get_all_sorts().await.into()
    } else {
      RepeatedSortPB { items: vec![] }
    }
  }

  pub async fn delete_all_sorts(&self, view_id: &str) {
    if let Ok(view_editor) = self.database_views.get_view_editor(view_id).await {
      let _ = view_editor.v_delete_all_sorts().await;
    }
  }

  pub async fn get_fields(&self, view_id: &str, field_ids: Option<Vec<String>>) -> RepeatedFieldPB {
    let fields = self.database.lock().get_fields(view_id, field_ids);
    fields
      .into_iter()
      .map(FieldPB::from)
      .collect::<Vec<FieldPB>>()
      .into()
  }

  pub async fn update_field(&self, params: FieldChangesetParams) -> FlowyResult<()> {
    self
      .database
      .lock()
      .fields
      .update_field(&params.field_id, |update| {
        update
          .set_name_if_not_none(params.name)
          .set_field_type_if_not_none(params.field_type.map(|field_type| field_type.into()))
          .set_width_at_if_not_none(params.width.map(|value| value as i64))
          .set_visibility_if_not_none(params.visibility);
      });
    self
      .notify_did_update_database_field(&params.field_id)
      .await?;
    Ok(())
  }

  pub fn update_field_type_option(
    &self,
    _view_id: &str,
    _field_id: &str,
    _type_option_data: TypeOptionData,
    _old_field: Option<Field>,
  ) {
  }

  #[tracing::instrument(level = "trace", skip_all, err)]
  async fn notify_did_update_database_field(&self, field_id: &str) -> FlowyResult<()> {
    let (database_id, field) = {
      let database = self.database.lock();
      let database_id = database.get_database_id();
      let field = database.fields.get_field(field_id);
      (database_id, field)
    };

    if let Some(field) = field {
      let updated_field = FieldPB::from(field);
      let notified_changeset =
        DatabaseFieldChangesetPB::update(&database_id, vec![updated_field.clone()]);
      self.notify_did_update_database(notified_changeset).await?;
      send_notification(field_id, DatabaseNotification::DidUpdateField)
        .payload(updated_field)
        .send();
    }

    Ok(())
  }

  async fn notify_did_update_database(
    &self,
    changeset: DatabaseFieldChangesetPB,
  ) -> FlowyResult<()> {
    let views = self.database.lock().get_all_views_description();
    for view in views {
      send_notification(&view.id, DatabaseNotification::DidUpdateFields)
        .payload(changeset.clone())
        .send();
    }

    Ok(())
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
pub struct MutexDatabase(Arc<Mutex<Arc<InnerDatabase>>>);
impl MutexDatabase {
  pub(crate) fn new(database: Arc<InnerDatabase>) -> Self {
    Self(Arc::new(Mutex::new(database)))
  }
}

impl Deref for MutexDatabase {
  type Target = Arc<Mutex<Arc<InnerDatabase>>>;
  fn deref(&self) -> &Self::Target {
    &self.0
  }
}
unsafe impl Sync for MutexDatabase {}
unsafe impl Send for MutexDatabase {}

struct DatabaseViewDataImpl {
  database: MutexDatabase,
  task_scheduler: Arc<RwLock<TaskDispatcher>>,
}

impl DatabaseViewData for DatabaseViewDataImpl {
  fn get_view_setting(&self, view_id: &str) -> Fut<Option<DatabaseView>> {
    let view = self.database.lock().get_view(view_id);
    to_fut(async move { view })
  }

  fn get_fields(&self, view_id: &str, field_ids: Option<Vec<String>>) -> Fut<Vec<Arc<Field>>> {
    let fields = self.database.lock().get_fields(view_id, field_ids);
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

  fn get_cells_for_field(&self, view_id: &str, field_id: &str) -> Fut<Vec<Arc<RowCell>>> {
    let cells = self.database.lock().get_cells_for_field(view_id, field_id);
    to_fut(async move { cells.into_iter().map(Arc::new).collect() })
  }

  fn get_layout_for_view(&self, view_id: &str) -> DatabaseLayout {
    self
      .database
      .lock()
      .views
      .get_view_layout(view_id)
      .unwrap_or_default()
  }

  fn get_group_setting(&self, view_id: &str) -> Vec<GroupSetting> {
    self.database.lock().get_all_group_setting(view_id)
  }

  fn insert_group_setting(&self, view_id: &str, setting: GroupSetting) {
    self.database.lock().insert_group_setting(view_id, setting);
  }

  fn get_sort(&self, view_id: &str, sort_id: &str) -> Option<Sort> {
    self.database.lock().get_sort::<Sort>(view_id, sort_id)
  }

  fn insert_sort(&self, view_id: &str, sort: Sort) {
    self.database.lock().insert_sort(view_id, sort);
  }

  fn remove_sort(&self, view_id: &str, sort_id: &str) {
    self.database.lock().remove_sort(view_id, sort_id);
  }

  fn get_all_sorts(&self, view_id: &str) -> Vec<Sort> {
    self.database.lock().get_all_sorts::<Sort>(view_id)
  }

  fn remove_all_sorts(&self, view_id: &str) {
    self.database.lock().remove_all_sorts(view_id);
  }

  fn get_all_filters(&self, view_id: &str) -> Vec<Arc<Filter>> {
    self
      .database
      .lock()
      .get_all_filters(view_id)
      .into_iter()
      .map(Arc::new)
      .collect()
  }

  fn delete_filter(&self, view_id: &str, filter_id: &str) {
    self.database.lock().remove_filter(view_id, filter_id);
  }

  fn insert_filter(&self, view_id: &str, filter: Filter) {
    self.database.lock().insert_filter(view_id, filter);
  }

  fn get_filter(&self, view_id: &str, filter_id: &str) -> Option<Filter> {
    self
      .database
      .lock()
      .get_filter::<Filter>(view_id, filter_id)
  }

  fn get_filter_by_field_id(&self, view_id: &str, field_id: &str) -> Option<Filter> {
    self
      .database
      .lock()
      .get_filter_by_field_id::<Filter>(view_id, field_id)
  }

  fn get_layout_setting(&self, view_id: &str, layout_ty: &DatabaseLayout) -> Option<LayoutSetting> {
    self
      .database
      .lock()
      .views
      .get_layout_setting(view_id, layout_ty)
  }

  fn insert_layout_setting(
    &self,
    _view_id: &str,
    _layout_setting: collab_database::views::LayoutSetting,
  ) {
    todo!()
  }

  fn get_task_scheduler(&self) -> Arc<RwLock<TaskDispatcher>> {
    self.task_scheduler.clone()
  }

  fn get_type_option_cell_handler(
    &self,
    _field: &Field,
    _field_type: &FieldType,
  ) -> Option<Box<dyn TypeOptionCellDataHandler>> {
    todo!()
  }
}
