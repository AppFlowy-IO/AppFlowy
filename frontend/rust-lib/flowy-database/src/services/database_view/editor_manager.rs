#![allow(clippy::while_let_loop)]
use crate::entities::{
  AlterFilterParams, AlterSortParams, CreateRowParams, DatabaseViewSettingPB, DeleteFilterParams,
  DeleteGroupParams, DeleteSortParams, GroupPB, InsertGroupParams, LayoutSettingParams,
  MoveGroupParams, RepeatedGroupPB, RowPB,
};
use crate::manager::DatabaseUser;
use crate::services::cell::AtomicCellDataCache;
use crate::services::database::DatabaseBlockEvent;
use crate::services::database_view::notifier::*;
use crate::services::database_view::trait_impl::{
  DatabaseViewRevisionMergeable, DatabaseViewRevisionSerde,
};
use crate::services::database_view::{DatabaseViewData, DatabaseViewEditor};
use crate::services::filter::FilterType;
use crate::services::persistence::rev_sqlite::{
  SQLiteDatabaseRevisionSnapshotPersistence, SQLiteDatabaseViewRevisionPersistence,
};
use database_model::{
  FieldRevision, FilterRevision, LayoutRevision, RowChangeset, RowRevision, SortRevision,
};
use flowy_client_sync::client_database::DatabaseViewRevisionPad;
use flowy_error::FlowyResult;
use flowy_revision::{RevisionManager, RevisionPersistence, RevisionPersistenceConfiguration};
use flowy_sqlite::ConnectionPool;
use lib_infra::future::Fut;
use std::borrow::Cow;
use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::{broadcast, RwLock};

/// It's used to manager the list of views that reference to the same database.
pub struct DatabaseViews {
  user: Arc<dyn DatabaseUser>,
  delegate: Arc<dyn DatabaseViewData>,
  view_editors: Arc<RwLock<HashMap<String, Arc<DatabaseViewEditor>>>>,
  cell_data_cache: AtomicCellDataCache,
}

impl DatabaseViews {
  pub async fn new(
    user: Arc<dyn DatabaseUser>,
    delegate: Arc<dyn DatabaseViewData>,
    cell_data_cache: AtomicCellDataCache,
    block_event_rx: broadcast::Receiver<DatabaseBlockEvent>,
  ) -> FlowyResult<Self> {
    let view_editors = Arc::new(RwLock::new(HashMap::default()));
    listen_on_database_block_event(block_event_rx, view_editors.clone());
    Ok(Self {
      user,
      delegate,
      view_editors,
      cell_data_cache,
    })
  }

  pub async fn open(&self, view_editor: DatabaseViewEditor) {
    let view_id = view_editor.view_id.clone();
    self
      .view_editors
      .write()
      .await
      .insert(view_id, Arc::new(view_editor));
  }

  pub async fn close(&self, view_id: &str) {
    if let Some(view_editor) = self.view_editors.write().await.remove(view_id) {
      view_editor.close().await;
    }
  }

  pub async fn number_of_views(&self) -> usize {
    self.view_editors.read().await.values().len()
  }

  pub async fn is_view_exist(&self, view_id: &str) -> bool {
    self.view_editors.read().await.get(view_id).is_some()
  }

  pub async fn subscribe_view_changed(
    &self,
    view_id: &str,
  ) -> FlowyResult<broadcast::Receiver<DatabaseViewChanged>> {
    Ok(self.get_view_editor(view_id).await?.notifier.subscribe())
  }

  pub async fn get_row_revs(
    &self,
    view_id: &str,
    block_id: &str,
  ) -> FlowyResult<Vec<Arc<RowRevision>>> {
    let mut row_revs = self
      .delegate
      .get_row_revs(Some(vec![block_id.to_owned()]))
      .await;
    if let Ok(view_editor) = self.get_view_editor(view_id).await {
      view_editor.v_filter_rows(block_id, &mut row_revs).await;
      view_editor.v_sort_rows(&mut row_revs).await;
    }

    Ok(row_revs)
  }

  pub async fn duplicate_database_view_setting(&self, view_id: &str) -> FlowyResult<String> {
    let editor = self.get_view_editor(view_id).await?;
    let view_data = editor.v_duplicate_view_setting().await?;
    Ok(view_data)
  }

  /// When the row was created, we may need to modify the [RowRevision] according to the [CreateRowParams].
  pub async fn will_create_row(&self, row_rev: &mut RowRevision, params: &CreateRowParams) {
    for view_editor in self.view_editors.read().await.values() {
      view_editor.v_will_create_row(row_rev, params).await;
    }
  }

  /// Notify the view that the row was created. For the moment, the view is just sending notifications.
  pub async fn did_create_row(&self, row_pb: &RowPB, params: &CreateRowParams) {
    for view_editor in self.view_editors.read().await.values() {
      view_editor.v_did_create_row(row_pb, params).await;
    }
  }

  /// Insert/Delete the group's row if the corresponding cell data was changed.  
  pub async fn did_update_row(&self, old_row_rev: Option<Arc<RowRevision>>, row_id: &str) {
    match self.delegate.get_row_rev(row_id).await {
      None => {
        tracing::warn!("Can not find the row in grid view");
      },
      Some((_, row_rev)) => {
        for view_editor in self.view_editors.read().await.values() {
          view_editor
            .v_did_update_row(old_row_rev.clone(), &row_rev)
            .await;
        }
      },
    }
  }

  pub async fn group_by_field(&self, view_id: &str, field_id: &str) -> FlowyResult<()> {
    let view_editor = self.get_view_editor(view_id).await?;
    view_editor.v_update_group_setting(field_id).await?;
    Ok(())
  }

  pub async fn did_delete_row(&self, row_rev: Arc<RowRevision>) {
    for view_editor in self.view_editors.read().await.values() {
      view_editor.v_did_delete_row(&row_rev).await;
    }
  }

  pub async fn get_setting(&self, view_id: &str) -> FlowyResult<DatabaseViewSettingPB> {
    let view_editor = self.get_view_editor(view_id).await?;
    Ok(view_editor.v_get_setting().await)
  }

  pub async fn get_all_filters(&self, view_id: &str) -> FlowyResult<Vec<Arc<FilterRevision>>> {
    let view_editor = self.get_view_editor(view_id).await?;
    Ok(view_editor.v_get_all_filters().await)
  }

  pub async fn get_filters(
    &self,
    view_id: &str,
    filter_id: &FilterType,
  ) -> FlowyResult<Vec<Arc<FilterRevision>>> {
    let view_editor = self.get_view_editor(view_id).await?;
    Ok(view_editor.v_get_filters(filter_id).await)
  }

  pub async fn create_or_update_filter(&self, params: AlterFilterParams) -> FlowyResult<()> {
    let view_editor = self.get_view_editor(&params.view_id).await?;
    view_editor.v_insert_filter(params).await
  }

  pub async fn delete_filter(&self, params: DeleteFilterParams) -> FlowyResult<()> {
    let view_editor = self.get_view_editor(&params.view_id).await?;
    view_editor.v_delete_filter(params).await
  }

  pub async fn get_all_sorts(&self, view_id: &str) -> FlowyResult<Vec<Arc<SortRevision>>> {
    let view_editor = self.get_view_editor(view_id).await?;
    Ok(view_editor.v_get_all_sorts().await)
  }

  pub async fn create_or_update_sort(&self, params: AlterSortParams) -> FlowyResult<SortRevision> {
    let view_editor = self.get_view_editor(&params.view_id).await?;
    view_editor.v_insert_sort(params).await
  }

  pub async fn delete_all_sorts(&self, view_id: &str) -> FlowyResult<()> {
    let view_editor = self.get_view_editor(view_id).await?;
    view_editor.v_delete_all_sorts().await
  }

  pub async fn delete_sort(&self, params: DeleteSortParams) -> FlowyResult<()> {
    let view_editor = self.get_view_editor(&params.view_id).await?;
    view_editor.v_delete_sort(params).await
  }

  pub async fn load_groups(&self, view_id: &str) -> FlowyResult<RepeatedGroupPB> {
    let view_editor = self.get_view_editor(view_id).await?;
    let groups = view_editor.v_load_groups().await?;
    Ok(RepeatedGroupPB { items: groups })
  }

  pub async fn get_group(&self, view_id: &str, group_id: &str) -> FlowyResult<GroupPB> {
    let view_editor = self.get_view_editor(view_id).await?;
    view_editor.v_get_group(group_id).await
  }

  pub async fn get_layout_setting(
    &self,
    view_id: &str,
    layout_ty: &LayoutRevision,
  ) -> FlowyResult<LayoutSettingParams> {
    let view_editor = self.get_view_editor(view_id).await?;
    view_editor.v_get_layout_settings(layout_ty).await
  }

  pub async fn set_layout_setting(
    &self,
    view_id: &str,
    layout_setting: LayoutSettingParams,
  ) -> FlowyResult<()> {
    let view_editor = self.get_view_editor(view_id).await?;
    view_editor.v_set_layout_settings(layout_setting).await
  }

  pub async fn insert_or_update_group(&self, params: InsertGroupParams) -> FlowyResult<()> {
    let view_editor = self.get_view_editor(&params.view_id).await?;
    view_editor.v_initialize_new_group(params).await
  }

  pub async fn delete_group(&self, params: DeleteGroupParams) -> FlowyResult<()> {
    let view_editor = self.get_view_editor(&params.view_id).await?;
    view_editor.v_delete_group(params).await
  }

  pub async fn move_group(&self, params: MoveGroupParams) -> FlowyResult<()> {
    let view_editor = self.get_view_editor(&params.view_id).await?;
    view_editor.v_move_group(params).await?;
    Ok(())
  }

  /// It may generate a RowChangeset when the Row was moved from one group to another.
  /// The return value, [RowChangeset], contains the changes made by the groups.
  ///
  pub async fn move_group_row(
    &self,
    view_id: &str,
    row_rev: Arc<RowRevision>,
    to_group_id: String,
    to_row_id: Option<String>,
    recv_row_changeset: impl FnOnce(RowChangeset) -> Fut<()>,
  ) -> FlowyResult<()> {
    let mut row_changeset = RowChangeset::new(row_rev.id.clone());
    let view_editor = self.get_view_editor(view_id).await?;
    view_editor
      .v_move_group_row(
        &row_rev,
        &mut row_changeset,
        &to_group_id,
        to_row_id.clone(),
      )
      .await;

    if !row_changeset.is_empty() {
      recv_row_changeset(row_changeset).await;
    }

    Ok(())
  }

  /// Notifies the view's field type-option data is changed
  /// For the moment, only the groups will be generated after the type-option data changed. A
  /// [FieldRevision] has a property named type_options contains a list of type-option data.
  /// # Arguments
  ///
  /// * `field_id`: the id of the field in current view
  ///
  #[tracing::instrument(level = "debug", skip(self, old_field_rev), err)]
  pub async fn did_update_field_type_option(
    &self,
    view_id: &str,
    field_id: &str,
    old_field_rev: Option<Arc<FieldRevision>>,
  ) -> FlowyResult<()> {
    let view_editor = self.get_view_editor(view_id).await?;
    // If the id of the grouping field is equal to the updated field's id, then we need to
    // update the group setting
    if view_editor.group_id().await == field_id {
      view_editor.v_update_group_setting(field_id).await?;
    }

    view_editor
      .v_did_update_field_type_option(field_id, old_field_rev)
      .await?;
    Ok(())
  }

  pub async fn get_view_editor(&self, view_id: &str) -> FlowyResult<Arc<DatabaseViewEditor>> {
    debug_assert!(!view_id.is_empty());
    if let Some(editor) = self.view_editors.read().await.get(view_id) {
      return Ok(editor.clone());
    }

    tracing::trace!("{:p} create view:{} editor", self, view_id);
    let mut view_editors = self.view_editors.write().await;
    let editor = Arc::new(self.make_view_editor(view_id).await?);
    view_editors.insert(view_id.to_owned(), editor.clone());
    Ok(editor)
  }

  async fn make_view_editor(&self, view_id: &str) -> FlowyResult<DatabaseViewEditor> {
    let user_id = self.user.user_id()?;
    let pool = self.user.db_pool()?;
    let rev_manager = make_database_view_rev_manager(&user_id, pool, view_id).await?;
    let user_id = self.user.user_id()?;
    let token = self.user.token()?;
    let view_id = view_id.to_owned();

    DatabaseViewEditor::new(
      &user_id,
      &token,
      view_id,
      self.delegate.clone(),
      self.cell_data_cache.clone(),
      rev_manager,
    )
    .await
  }
}

#[tracing::instrument(level = "trace", skip(user), err)]
pub async fn make_database_view_revision_pad(
  view_id: &str,
  user: Arc<dyn DatabaseUser>,
) -> FlowyResult<(
  DatabaseViewRevisionPad,
  RevisionManager<Arc<ConnectionPool>>,
)> {
  let user_id = user.user_id()?;
  let pool = user.db_pool()?;
  let mut rev_manager = make_database_view_rev_manager(&user_id, pool, view_id).await?;
  let view_rev_pad = rev_manager
    .initialize::<DatabaseViewRevisionSerde>(None)
    .await?;
  Ok((view_rev_pad, rev_manager))
}

pub async fn make_database_view_rev_manager(
  user_id: &str,
  pool: Arc<ConnectionPool>,
  view_id: &str,
) -> FlowyResult<RevisionManager<Arc<ConnectionPool>>> {
  // Create revision persistence
  let disk_cache = SQLiteDatabaseViewRevisionPersistence::new(user_id, pool.clone());
  let configuration = RevisionPersistenceConfiguration::new(2, false);
  let rev_persistence = RevisionPersistence::new(user_id, view_id, disk_cache, configuration);

  // Create snapshot persistence
  const DATABASE_VIEW_SP_PREFIX: &str = "grid_view";
  let snapshot_object_id = format!("{}:{}", DATABASE_VIEW_SP_PREFIX, view_id);
  let snapshot_persistence =
    SQLiteDatabaseRevisionSnapshotPersistence::new(&snapshot_object_id, pool);

  let rev_compress = DatabaseViewRevisionMergeable();
  Ok(RevisionManager::new(
    user_id,
    view_id,
    rev_persistence,
    rev_compress,
    snapshot_persistence,
  ))
}

fn listen_on_database_block_event(
  mut block_event_rx: broadcast::Receiver<DatabaseBlockEvent>,
  view_editors: Arc<RwLock<HashMap<String, Arc<DatabaseViewEditor>>>>,
) {
  tokio::spawn(async move {
    loop {
      match block_event_rx.recv().await {
        Ok(event) => {
          let read_guard = view_editors.read().await;
          let view_editors = read_guard.values();
          let event = if view_editors.len() == 1 {
            Cow::Owned(event)
          } else {
            Cow::Borrowed(&event)
          };
          for view_editor in view_editors {
            view_editor.handle_block_event(event.clone()).await;
          }
        },
        Err(_) => break,
      }
    }
  });
}
