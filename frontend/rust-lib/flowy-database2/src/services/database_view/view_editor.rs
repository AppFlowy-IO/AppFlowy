use crate::entities::{CreateRowParams, DeleteGroupParams, FieldType, GroupChangesetPB, GroupPB, GroupRowsNotificationPB, InsertGroupParams, InsertedGroupPB, InsertedRowPB, MoveGroupParams, RowPB, RowsChangesetPB, AlterSortParams};
use crate::notification::{send_notification, DatabaseNotification};
use crate::services::database::DatabaseRowEvent;
use crate::services::database_view::{
  notify_did_update_group_rows, notify_did_update_groups, DatabaseViewChangedNotifier,
};
use crate::services::field::TypeOptionCellDataHandler;
use crate::services::filter::FilterController;
use crate::services::group::{
  default_group_setting, Group, GroupController, MoveGroupRowContext, RowChangeset,
};
use crate::services::sort::{Sort, SortController};
use collab_database::fields::Field;
use collab_database::rows::{Row, RowId};
use flowy_error::{FlowyError, FlowyResult};
use flowy_task::TaskDispatcher;
use lib_infra::future::Fut;
use std::borrow::Cow;
use std::sync::Arc;
use tokio::sync::RwLock;

pub trait DatabaseViewData: Send + Sync + 'static {
  /// If the field_ids is None, then it will return all the field revisions
  fn get_fields(&self, field_ids: Option<Vec<String>>) -> Fut<Vec<Arc<Field>>>;

  /// Returns the field with the field_id
  fn get_field(&self, field_id: &str) -> Fut<Option<Arc<Field>>>;

  fn get_primary_field(&self) -> Fut<Option<Arc<Field>>>;

  /// Returns the index of the row with row_id
  fn index_of_row(&self, view_id: &str, row_id: RowId) -> Fut<Option<usize>>;

  /// Returns the `index` and `RowRevision` with row_id
  fn get_row(&self, view_id: &str, row_id: RowId) -> Fut<Option<(usize, Arc<Row>)>>;

  fn get_rows(&self, view_id: &str) -> Fut<Vec<Arc<Row>>>;

  /// Returns a `TaskDispatcher` used to poll a `Task`
  fn get_task_scheduler(&self) -> Arc<RwLock<TaskDispatcher>>;

  fn get_type_option_cell_handler(
    &self,
    field: &Field,
    field_type: &FieldType,
  ) -> Option<Box<dyn TypeOptionCellDataHandler>>;
}

pub struct DatabaseViewEditor {
  pub view_id: String,
  delegate: Arc<dyn DatabaseViewData>,
  group_controller: Arc<RwLock<Box<dyn GroupController>>>,
  filter_controller: Arc<FilterController>,
  sort_controller: Arc<RwLock<SortController>>,
  pub notifier: DatabaseViewChangedNotifier,
}

impl Drop for DatabaseViewEditor {
  fn drop(&mut self) {
    tracing::trace!("Drop {}", std::any::type_name::<Self>());
  }
}

impl DatabaseViewEditor {
  pub async fn v_will_create_row(&self, row: &mut Row, params: CreateRowParams) {
    if params.group_id.is_none() {
      return;
    }
    let group_id = params.group_id.as_ref().unwrap();
    let _ = self
      .mut_group_controller(|group_controller, field| {
        group_controller.will_create_row(row, &field, group_id);
        Ok(())
      })
      .await;
  }

  pub async fn v_did_create_row(&self, row: &Row, params: &CreateRowParams) {
    // Send the group notification if the current view has groups
    match params.group_id.as_ref() {
      None => {},
      Some(group_id) => {
        let index = match params.start_row_id {
          None => Some(0),
          Some(_) => None,
        };

        self
          .group_controller
          .write()
          .await
          .did_create_row(row, group_id);
        let inserted_row = InsertedRowPB {
          row: RowPB::from(row),
          index,
          is_new: true,
        };
        let changeset = GroupRowsNotificationPB::insert(group_id.clone(), vec![inserted_row]);
        notify_did_update_group_rows(changeset).await;
      },
    }
  }

  #[tracing::instrument(level = "trace", skip_all)]
  pub async fn v_did_delete_row(&self, row: &Row) {
    // Send the group notification if the current view has groups;
    let result = self
      .mut_group_controller(|group_controller, field| {
        group_controller.did_delete_delete_row(row, &field)
      })
      .await;

    if let Some(result) = result {
      tracing::trace!("Delete row in view changeset: {:?}", result.row_changesets);
      for changeset in result.row_changesets {
        notify_did_update_group_rows(changeset).await;
      }
    }
  }

  pub async fn v_did_update_row(&self, old_row: Option<Arc<Row>>, row: &Row) {
    let result = self
      .mut_group_controller(|group_controller, field| {
        Ok(group_controller.did_update_group_row(&old_row, row, &field))
      })
      .await;

    if let Some(Ok(result)) = result {
      let mut changeset = GroupChangesetPB {
        view_id: self.view_id.clone(),
        ..Default::default()
      };
      if let Some(inserted_group) = result.inserted_group {
        tracing::trace!("Create group after editing the row: {:?}", inserted_group);
        changeset.inserted_groups.push(inserted_group);
      }
      if let Some(delete_group) = result.deleted_group {
        tracing::trace!("Delete group after editing the row: {:?}", delete_group);
        changeset.deleted_groups.push(delete_group.group_id);
      }
      notify_did_update_groups(&self.view_id, changeset).await;

      tracing::trace!(
        "Group changesets after editing the row: {:?}",
        result.row_changesets
      );
      for changeset in result.row_changesets {
        notify_did_update_group_rows(changeset).await;
      }
    }

    let filter_controller = self.filter_controller.clone();
    let sort_controller = self.sort_controller.clone();
    let row_id = row.id.clone();
    tokio::spawn(async move {
      filter_controller.did_receive_row_changed(row_id).await;
      sort_controller
        .read()
        .await
        .did_receive_row_changed(row_id)
        .await;
    });
  }

  pub async fn v_move_group_row(
    &self,
    row: &Row,
    row_changeset: &mut RowChangeset,
    to_group_id: &str,
    to_row_id: Option<RowId>,
  ) {
    let result = self
      .mut_group_controller(|group_controller, field| {
        let move_row_context = MoveGroupRowContext {
          row,
          row_changeset,
          field: field.as_ref(),
          to_group_id,
          to_row_id,
        };
        group_controller.move_group_row(move_row_context)
      })
      .await;

    if let Some(result) = result {
      let mut changeset = GroupChangesetPB {
        view_id: self.view_id.clone(),
        ..Default::default()
      };
      if let Some(delete_group) = result.deleted_group {
        tracing::info!("Delete group after moving the row: {:?}", delete_group);
        changeset.deleted_groups.push(delete_group.group_id);
      }
      notify_did_update_groups(&self.view_id, changeset).await;

      for changeset in result.row_changesets {
        notify_did_update_group_rows(changeset).await;
      }
    }
  }
  /// Only call once after database view editor initialized
  #[tracing::instrument(level = "trace", skip(self))]
  pub async fn v_load_groups(&self) -> FlowyResult<Vec<GroupPB>> {
    let groups = self
      .group_controller
      .read()
      .await
      .groups()
      .into_iter()
      .map(|group_data| GroupPB::from(group_data.clone()))
      .collect::<Vec<_>>();
    tracing::trace!("Number of groups: {}", groups.len());
    Ok(groups)
  }

  #[tracing::instrument(level = "trace", skip(self))]
  pub async fn v_get_group(&self, group_id: &str) -> FlowyResult<GroupPB> {
    match self.group_controller.read().await.get_group(group_id) {
      None => Err(FlowyError::record_not_found().context("Can't find the group")),
      Some((_, group)) => Ok(GroupPB::from(group)),
    }
  }

  #[tracing::instrument(level = "trace", skip(self), err)]
  pub async fn v_move_group(&self, params: MoveGroupParams) -> FlowyResult<()> {
    self
      .group_controller
      .write()
      .await
      .move_group(&params.from_group_id, &params.to_group_id)?;
    match self
      .group_controller
      .read()
      .await
      .get_group(&params.from_group_id)
    {
      None => tracing::warn!("Can not find the group with id: {}", params.from_group_id),
      Some((index, group)) => {
        let inserted_group = InsertedGroupPB {
          group: GroupPB::from(group),
          index: index as i32,
        };

        let changeset = GroupChangesetPB {
          view_id: self.view_id.clone(),
          inserted_groups: vec![inserted_group],
          deleted_groups: vec![params.from_group_id.clone()],
          update_groups: vec![],
          initial_groups: vec![],
        };

        notify_did_update_groups(&self.view_id, changeset).await;
      },
    }
    Ok(())
  }

  pub async fn group_id(&self) -> String {
    self.group_controller.read().await.field_id().to_string()
  }

  pub async fn v_initialize_new_group(&self, params: InsertGroupParams) -> FlowyResult<()> {
    if self.group_controller.read().await.field_id() != params.field_id {
      self.v_update_group_setting(&params.field_id).await?;
      self.notify_did_update_setting().await;
    }
    Ok(())
  }

  pub async fn v_delete_group(&self, params: DeleteGroupParams) -> FlowyResult<()> {
    Ok(())
  }

  pub async fn v_get_all_sorts(&self) -> Vec<Arc<Sort>> {
    // let field_revs = self.delegate.get_field_revs(None).await;
    // self.pad.read().await.get_all_sorts(&field_revs)
    vec1[]
  }

  #[tracing::instrument(level = "trace", skip(self), err)]
  pub async fn v_insert_sort(&self, params: AlterSortParams) -> FlowyResult<Sort> {
    let sort_type = SortType::from(&params);
    let is_exist = params.sort_id.is_some();
    let sort_id = match params.sort_id {
      None => gen_database_sort_id(),
      Some(sort_id) => sort_id,
    };

    let sort_rev = SortRevision {
      id: sort_id,
      field_id: params.field_id.clone(),
      field_type: params.field_type,
      condition: params.condition.into(),
    };

    let mut sort_controller = self.sort_controller.write().await;
    let changeset = if is_exist {
      self
        .modify(|pad| {
          let changeset = pad.update_sort(&params.field_id, sort_rev.clone())?;
          Ok(changeset)
        })
        .await?;
      sort_controller
        .did_receive_changes(SortChangeset::from_update(sort_type))
        .await
    } else {
      self
        .modify(|pad| {
          let changeset = pad.insert_sort(&params.field_id, sort_rev.clone())?;
          Ok(changeset)
        })
        .await?;
      sort_controller
        .did_receive_changes(SortChangeset::from_insert(sort_type))
        .await
    };
    drop(sort_controller);
    self.notify_did_update_sort(changeset).await;
    Ok(sort_rev)
  }

  pub async fn v_delete_sort(&self, params: DeleteSortParams) -> FlowyResult<()> {
    let notification = self
      .sort_controller
      .write()
      .await
      .did_receive_changes(SortChangeset::from_delete(DeletedSortType::from(
        params.clone(),
      )))
      .await;

    let sort_type = params.sort_type;
    self
      .modify(|pad| {
        let changeset =
          pad.delete_sort(&params.sort_id, &sort_type.field_id, sort_type.field_type)?;
        Ok(changeset)
      })
      .await?;

    self.notify_did_update_sort(notification).await;
    Ok(())
  }

  pub async fn v_delete_all_sorts(&self) -> FlowyResult<()> {
    let all_sorts = self.v_get_all_sorts().await;
    // self.sort_controller.write().await.delete_all_sorts().await;
    self
      .modify(|pad| {
        let changeset = pad.delete_all_sorts()?;
        Ok(changeset)
      })
      .await?;

    let mut notification = SortChangesetNotificationPB::new(self.view_id.clone());
    notification.delete_sorts = all_sorts
      .into_iter()
      .map(|sort| SortPB::from(sort.as_ref()))
      .collect();
    self.notify_did_update_sort(notification).await;
    Ok(())
  }

  pub async fn handle_block_event(&self, event: Cow<'_, DatabaseRowEvent>) {
    let changeset = match event.into_owned() {
      DatabaseRowEvent::InsertRow { row } => {
        RowsChangesetPB::from_insert(self.view_id.clone(), vec![row.into()])
      },
      DatabaseRowEvent::UpdateRow { row } => {
        RowsChangesetPB::from_update(self.view_id.clone(), vec![row.into()])
      },
      DatabaseRowEvent::DeleteRow { row_id } => {
        RowsChangesetPB::from_delete(self.view_id.clone(), vec![row_id])
      },
      DatabaseRowEvent::Move {
        deleted_row_id,
        inserted_row,
      } => RowsChangesetPB::from_move(
        self.view_id.clone(),
        vec![deleted_row_id],
        vec![inserted_row.into()],
      ),
    };

    send_notification(&self.view_id, DatabaseNotification::DidUpdateViewRows)
      .payload(changeset)
      .send();
  }

  async fn mut_group_controller<F, T>(&self, f: F) -> Option<T>
  where
    F: FnOnce(&mut Box<dyn GroupController>, Arc<Field>) -> FlowyResult<T>,
  {
    let group_field_id = self.group_controller.read().await.field_id().to_owned();
    match self.delegate.get_field(&group_field_id).await {
      None => None,
      Some(field) => {
        let mut write_guard = self.group_controller.write().await;
        f(&mut write_guard, field).ok()
      },
    }
  }
}
