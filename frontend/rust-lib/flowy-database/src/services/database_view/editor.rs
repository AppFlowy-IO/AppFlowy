use crate::entities::*;
use crate::notification::{send_notification, DatabaseNotification};
use crate::services::cell::{AtomicCellDataCache, TypeCellData};
use crate::services::database::DatabaseBlockEvent;
use crate::services::database_view::notifier::DatabaseViewChangedNotifier;
use crate::services::database_view::trait_impl::*;
use crate::services::database_view::DatabaseViewChangedReceiverRunner;
use crate::services::field::{RowSingleCellData, TypeOptionCellDataHandler};
use crate::services::filter::{
  FilterChangeset, FilterController, FilterTaskHandler, FilterType, UpdatedFilterType,
};
use crate::services::group::{
  default_group_configuration, find_grouping_field, make_group_controller, Group,
  GroupConfigurationReader, GroupController, MoveGroupRowContext,
};
use crate::services::row::DatabaseBlockRowRevision;
use crate::services::sort::{
  DeletedSortType, SortChangeset, SortController, SortTaskHandler, SortType,
};
use database_model::{
  gen_database_filter_id, gen_database_id, gen_database_sort_id, CalendarLayoutSetting,
  FieldRevision, FieldTypeRevision, FilterRevision, LayoutRevision, RowChangeset, RowRevision,
  SortRevision,
};
use flowy_client_sync::client_database::{
  make_database_view_operations, DatabaseViewRevisionChangeset, DatabaseViewRevisionPad,
};
use flowy_error::{FlowyError, FlowyResult};
use flowy_revision::RevisionManager;
use flowy_sqlite::ConnectionPool;
use flowy_task::TaskDispatcher;
use lib_infra::future::Fut;
use nanoid::nanoid;
use revision_model::Revision;
use std::borrow::Cow;
use std::collections::HashMap;
use std::future::Future;
use std::sync::Arc;
use tokio::sync::{broadcast, RwLock};

pub trait DatabaseViewData: Send + Sync + 'static {
  /// If the field_ids is None, then it will return all the field revisions
  fn get_field_revs(&self, field_ids: Option<Vec<String>>) -> Fut<Vec<Arc<FieldRevision>>>;

  /// Returns the field with the field_id
  fn get_field_rev(&self, field_id: &str) -> Fut<Option<Arc<FieldRevision>>>;

  fn get_primary_field_rev(&self) -> Fut<Option<Arc<FieldRevision>>>;

  /// Returns the index of the row with row_id
  fn index_of_row(&self, row_id: &str) -> Fut<Option<usize>>;

  /// Returns the `index` and `RowRevision` with row_id
  fn get_row_rev(&self, row_id: &str) -> Fut<Option<(usize, Arc<RowRevision>)>>;

  /// Returns all the rows that the block has. If the passed-in block_ids is None, then will return all the rows
  /// The relationship between the grid and the block is:
  ///     A grid has a list of blocks
  ///     A block has a list of rows
  ///     A row has a list of cells
  ///
  fn get_row_revs(&self, block_ids: Option<Vec<String>>) -> Fut<Vec<Arc<RowRevision>>>;

  /// Get all the blocks that the current Grid has.
  /// One grid has a list of blocks
  fn get_blocks(&self) -> Fut<Vec<DatabaseBlockRowRevision>>;

  /// Returns a `TaskDispatcher` used to poll a `Task`
  fn get_task_scheduler(&self) -> Arc<RwLock<TaskDispatcher>>;

  fn get_type_option_cell_handler(
    &self,
    field_rev: &FieldRevision,
    field_type: &FieldType,
  ) -> Option<Box<dyn TypeOptionCellDataHandler>>;
}

pub struct DatabaseViewEditor {
  user_id: String,
  pub view_id: String,
  pad: Arc<RwLock<DatabaseViewRevisionPad>>,
  rev_manager: Arc<RevisionManager<Arc<ConnectionPool>>>,
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
  pub async fn from_pad(
    user_id: &str,
    delegate: Arc<dyn DatabaseViewData>,
    cell_data_cache: AtomicCellDataCache,
    rev_manager: RevisionManager<Arc<ConnectionPool>>,
    view_rev_pad: DatabaseViewRevisionPad,
  ) -> FlowyResult<Self> {
    let view_id = view_rev_pad.view_id.clone();
    let (notifier, _) = broadcast::channel(100);
    tokio::spawn(DatabaseViewChangedReceiverRunner(Some(notifier.subscribe())).run());

    let view_rev_pad = Arc::new(RwLock::new(view_rev_pad));
    let rev_manager = Arc::new(rev_manager);
    let group_controller = new_group_controller(
      user_id.to_owned(),
      view_id.clone(),
      view_rev_pad.clone(),
      rev_manager.clone(),
      delegate.clone(),
    )
    .await?;

    let user_id = user_id.to_owned();
    let group_controller = Arc::new(RwLock::new(group_controller));
    let filter_controller = make_filter_controller(
      &view_id,
      delegate.clone(),
      notifier.clone(),
      cell_data_cache.clone(),
      view_rev_pad.clone(),
    )
    .await;

    let sort_controller = make_sort_controller(
      &view_id,
      delegate.clone(),
      notifier.clone(),
      filter_controller.clone(),
      view_rev_pad.clone(),
      cell_data_cache,
    )
    .await;
    Ok(Self {
      pad: view_rev_pad,
      user_id,
      view_id,
      rev_manager,
      delegate,
      group_controller,
      filter_controller,
      sort_controller,
      notifier,
    })
  }

  #[tracing::instrument(level = "trace", skip_all, err)]
  pub async fn new(
    user_id: &str,
    token: &str,
    view_id: String,
    delegate: Arc<dyn DatabaseViewData>,
    cell_data_cache: AtomicCellDataCache,
    mut rev_manager: RevisionManager<Arc<ConnectionPool>>,
  ) -> FlowyResult<Self> {
    let cloud = Arc::new(DatabaseViewRevisionCloudService {
      token: token.to_owned(),
    });

    let view_rev_pad = match rev_manager
      .initialize::<DatabaseViewRevisionSerde>(Some(cloud))
      .await
    {
      Ok(pad) => pad,
      Err(err) => {
        // It shouldn't be here, because the snapshot should come to recue.
        tracing::error!("Deserialize database view revisions failed: {}", err);
        let (view, reset_revision) = generate_restore_view(&view_id).await;
        let _ = rev_manager.reset_object(vec![reset_revision]).await;
        view
      },
    };

    Self::from_pad(
      user_id,
      delegate,
      cell_data_cache,
      rev_manager,
      view_rev_pad,
    )
    .await
  }

  #[tracing::instrument(name = "close database view editor", level = "trace", skip_all)]
  pub async fn close(&self) {
    self.rev_manager.generate_snapshot().await;
    self.rev_manager.close().await;
    self.sort_controller.write().await.close().await;
    self.filter_controller.close().await;
  }

  pub async fn handle_block_event(&self, event: Cow<'_, DatabaseBlockEvent>) {
    let changeset = match event.into_owned() {
      DatabaseBlockEvent::InsertRow { block_id: _, row } => {
        //
        RowsChangesetPB::from_insert(self.view_id.clone(), vec![row])
      },
      DatabaseBlockEvent::UpdateRow { block_id: _, row } => {
        //
        RowsChangesetPB::from_update(self.view_id.clone(), vec![row])
      },
      DatabaseBlockEvent::DeleteRow {
        block_id: _,
        row_id,
      } => {
        //
        RowsChangesetPB::from_delete(self.view_id.clone(), vec![row_id])
      },
      DatabaseBlockEvent::Move {
        block_id: _,
        deleted_row_id,
        inserted_row,
      } => {
        //
        RowsChangesetPB::from_move(
          self.view_id.clone(),
          vec![deleted_row_id],
          vec![inserted_row],
        )
      },
    };

    send_notification(&self.view_id, DatabaseNotification::DidUpdateViewRows)
      .payload(changeset)
      .send();
  }

  pub async fn v_sort_rows(&self, rows: &mut Vec<Arc<RowRevision>>) {
    self.sort_controller.write().await.sort_rows(rows).await
  }

  pub async fn v_filter_rows(&self, _block_id: &str, rows: &mut Vec<Arc<RowRevision>>) {
    self.filter_controller.filter_row_revs(rows).await;
  }

  pub async fn v_duplicate_database_view(&self) -> FlowyResult<String> {
    let json_str = self.pad.read().await.json_str()?;
    Ok(json_str)
  }

  pub async fn v_will_create_row(&self, row_rev: &mut RowRevision, params: &CreateRowParams) {
    if params.group_id.is_none() {
      return;
    }
    let group_id = params.group_id.as_ref().unwrap();
    let _ = self
      .mut_group_controller(|group_controller, field_rev| {
        group_controller.will_create_row(row_rev, &field_rev, group_id);
        Ok(())
      })
      .await;
  }

  pub async fn v_did_create_row(&self, row_pb: &RowPB, params: &CreateRowParams) {
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
          .did_create_row(row_pb, group_id);
        let inserted_row = InsertedRowPB {
          row: row_pb.clone(),
          index,
          is_new: true,
        };
        let changeset = GroupRowsNotificationPB::insert(group_id.clone(), vec![inserted_row]);
        self.notify_did_update_group_rows(changeset).await;
      },
    }
  }

  #[tracing::instrument(level = "trace", skip_all)]
  pub async fn v_did_delete_row(&self, row_rev: &RowRevision) {
    // Send the group notification if the current view has groups;
    let result = self
      .mut_group_controller(|group_controller, field_rev| {
        group_controller.did_delete_delete_row(row_rev, &field_rev)
      })
      .await;

    if let Some(result) = result {
      tracing::trace!("Delete row in view changeset: {:?}", result.row_changesets);
      for changeset in result.row_changesets {
        self.notify_did_update_group_rows(changeset).await;
      }
    }
  }

  pub async fn v_did_update_row(
    &self,
    old_row_rev: Option<Arc<RowRevision>>,
    row_rev: &RowRevision,
  ) {
    let result = self
      .mut_group_controller(|group_controller, field_rev| {
        Ok(group_controller.did_update_group_row(&old_row_rev, row_rev, &field_rev))
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
      self.notify_did_update_groups(changeset).await;

      tracing::trace!(
        "Group changesets after editing the row: {:?}",
        result.row_changesets
      );
      for changeset in result.row_changesets {
        self.notify_did_update_group_rows(changeset).await;
      }
    }

    let filter_controller = self.filter_controller.clone();
    let sort_controller = self.sort_controller.clone();
    let row_id = row_rev.id.clone();
    tokio::spawn(async move {
      filter_controller.did_receive_row_changed(&row_id).await;
      sort_controller
        .read()
        .await
        .did_receive_row_changed(&row_id)
        .await;
    });
  }

  pub async fn v_move_group_row(
    &self,
    row_rev: &RowRevision,
    row_changeset: &mut RowChangeset,
    to_group_id: &str,
    to_row_id: Option<String>,
  ) {
    let result = self
      .mut_group_controller(|group_controller, field_rev| {
        let move_row_context = MoveGroupRowContext {
          row_rev,
          row_changeset,
          field_rev: field_rev.as_ref(),
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
      self.notify_did_update_groups(changeset).await;

      for changeset in result.row_changesets {
        self.notify_did_update_group_rows(changeset).await;
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
      .cloned()
      .collect::<Vec<Group>>();
    tracing::trace!("Number of groups: {}", groups.len());
    Ok(groups.into_iter().map(GroupPB::from).collect())
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

        self.notify_did_update_groups(changeset).await;
      },
    }
    Ok(())
  }

  pub async fn group_id(&self) -> String {
    self.group_controller.read().await.field_id().to_string()
  }

  /// Initialize new group when grouping by a new field
  ///
  pub async fn v_initialize_new_group(&self, params: InsertGroupParams) -> FlowyResult<()> {
    if let Some(field_rev) = self.delegate.get_field_rev(&params.field_id).await {
      self
        .modify(|pad| {
          let configuration = default_group_configuration(&field_rev);
          let changeset = pad.insert_or_update_group_configuration(
            &params.field_id,
            &params.field_type_rev,
            configuration,
          )?;
          Ok(changeset)
        })
        .await?;
    }
    if self.group_controller.read().await.field_id() != params.field_id {
      self.v_update_group_setting(&params.field_id).await?;
      self.notify_did_update_setting().await;
    }
    Ok(())
  }

  pub async fn v_delete_group(&self, params: DeleteGroupParams) -> FlowyResult<()> {
    self
      .modify(|pad| {
        let changeset =
          pad.delete_group(&params.group_id, &params.field_id, &params.field_type_rev)?;
        Ok(changeset)
      })
      .await
  }

  pub async fn v_get_setting(&self) -> DatabaseViewSettingPB {
    let field_revs = self.delegate.get_field_revs(None).await;
    make_database_view_setting(&*self.pad.read().await, &field_revs)
  }

  pub async fn v_get_all_sorts(&self) -> Vec<Arc<SortRevision>> {
    let field_revs = self.delegate.get_field_revs(None).await;
    self.pad.read().await.get_all_sorts(&field_revs)
  }

  #[tracing::instrument(level = "trace", skip(self), err)]
  pub async fn v_insert_sort(&self, params: AlterSortParams) -> FlowyResult<SortRevision> {
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

  pub async fn v_get_all_filters(&self) -> Vec<Arc<FilterRevision>> {
    let field_revs = self.delegate.get_field_revs(None).await;
    self.pad.read().await.get_all_filters(&field_revs)
  }

  pub async fn v_get_filters(&self, filter_type: &FilterType) -> Vec<Arc<FilterRevision>> {
    let field_type_rev: FieldTypeRevision = filter_type.field_type.clone().into();
    self
      .pad
      .read()
      .await
      .get_filters(&filter_type.field_id, &field_type_rev)
  }

  #[tracing::instrument(level = "trace", skip(self), err)]
  pub async fn v_insert_filter(&self, params: AlterFilterParams) -> FlowyResult<()> {
    let filter_type = FilterType::from(&params);
    let is_exist = params.filter_id.is_some();
    let filter_id = match params.filter_id {
      None => gen_database_filter_id(),
      Some(filter_id) => filter_id,
    };
    let filter_rev = FilterRevision {
      id: filter_id.clone(),
      field_id: params.field_id.clone(),
      field_type: params.field_type,
      condition: params.condition,
      content: params.content,
    };
    let filter_controller = self.filter_controller.clone();
    let changeset = if is_exist {
      let old_filter_type = self
        .delegate
        .get_field_rev(&params.field_id)
        .await
        .map(|field| FilterType::from(&field));
      self
        .modify(|pad| {
          let changeset = pad.update_filter(&params.field_id, filter_rev)?;
          Ok(changeset)
        })
        .await?;
      filter_controller
        .did_receive_changes(FilterChangeset::from_update(UpdatedFilterType::new(
          old_filter_type,
          filter_type,
        )))
        .await
    } else {
      self
        .modify(|pad| {
          let changeset = pad.insert_filter(&params.field_id, filter_rev)?;
          Ok(changeset)
        })
        .await?;
      filter_controller
        .did_receive_changes(FilterChangeset::from_insert(filter_type))
        .await
    };
    drop(filter_controller);

    if let Some(changeset) = changeset {
      self.notify_did_update_filter(changeset).await;
    }
    Ok(())
  }

  #[tracing::instrument(level = "trace", skip(self), err)]
  pub async fn v_delete_filter(&self, params: DeleteFilterParams) -> FlowyResult<()> {
    let filter_type = params.filter_type;
    let changeset = self
      .filter_controller
      .did_receive_changes(FilterChangeset::from_delete(filter_type.clone()))
      .await;

    self
      .modify(|pad| {
        let changeset = pad.delete_filter(
          &params.filter_id,
          &filter_type.field_id,
          filter_type.field_type,
        )?;
        Ok(changeset)
      })
      .await?;

    if changeset.is_some() {
      self.notify_did_update_filter(changeset.unwrap()).await;
    }
    Ok(())
  }

  /// Returns the current calendar settings
  #[tracing::instrument(level = "debug", skip(self), err)]
  pub async fn v_get_layout_settings(
    &self,
    layout_ty: &LayoutRevision,
  ) -> FlowyResult<LayoutSettingParams> {
    let mut layout_setting = LayoutSettingParams::default();
    match layout_ty {
      LayoutRevision::Grid => {},
      LayoutRevision::Board => {},
      LayoutRevision::Calendar => {
        if let Some(calendar) = self
          .pad
          .read()
          .await
          .get_layout_setting::<CalendarLayoutSetting>(layout_ty)
        {
          // Check the field exist or not
          if let Some(field_rev) = self.delegate.get_field_rev(&calendar.layout_field_id).await {
            let field_type: FieldType = field_rev.ty.into();

            // Check the type of field is Datetime or not
            if field_type == FieldType::DateTime {
              layout_setting.calendar = Some(calendar);
            }
          }
        }
      },
    }

    tracing::debug!("{:?}", layout_setting);
    Ok(layout_setting)
  }

  /// Update the calendar settings and send the notification to refresh the UI
  pub async fn v_set_layout_settings(&self, params: LayoutSettingParams) -> FlowyResult<()> {
    // Maybe it needs no send notification to refresh the UI
    if let Some(new_calendar_setting) = params.calendar {
      if let Some(field_rev) = self
        .delegate
        .get_field_rev(&new_calendar_setting.layout_field_id)
        .await
      {
        let field_type: FieldType = field_rev.ty.into();
        if field_type != FieldType::DateTime {
          return Err(FlowyError::unexpect_calendar_field_type());
        }

        let layout_ty = LayoutRevision::Calendar;
        let old_calender_setting = self.v_get_layout_settings(&layout_ty).await?.calendar;
        self
          .modify(|pad| Ok(pad.set_layout_setting(&layout_ty, &new_calendar_setting)?))
          .await?;

        let new_field_id = new_calendar_setting.layout_field_id.clone();
        let layout_setting_pb: LayoutSettingPB = LayoutSettingParams {
          calendar: Some(new_calendar_setting),
        }
        .into();

        if let Some(old_calendar_setting) = old_calender_setting {
          // compare the new layout field id is equal to old layout field id
          // if not equal, send the  DidSetNewLayoutField notification
          // if equal, send the  DidUpdateLayoutSettings notification
          if old_calendar_setting.layout_field_id != new_field_id {
            send_notification(&self.view_id, DatabaseNotification::DidSetNewLayoutField)
              .payload(layout_setting_pb)
              .send();
          } else {
            send_notification(&self.view_id, DatabaseNotification::DidUpdateLayoutSettings)
              .payload(layout_setting_pb)
              .send();
          }
        } else {
          tracing::warn!("Calendar setting should not be empty")
        }
      }
    }

    Ok(())
  }

  #[tracing::instrument(level = "trace", skip_all, err)]
  pub async fn v_did_update_field_type_option(
    &self,
    field_id: &str,
    old_field_rev: Option<Arc<FieldRevision>>,
  ) -> FlowyResult<()> {
    if let Some(field_rev) = self.delegate.get_field_rev(field_id).await {
      let old = old_field_rev.map(|old_field_rev| FilterType::from(&old_field_rev));
      let new = FilterType::from(&field_rev);
      let filter_type = UpdatedFilterType::new(old, new);
      let filter_changeset = FilterChangeset::from_update(filter_type);

      self
        .sort_controller
        .read()
        .await
        .did_update_view_field_type_option(&field_rev)
        .await;

      let filter_controller = self.filter_controller.clone();
      let _ = tokio::spawn(async move {
        if let Some(notification) = filter_controller
          .did_receive_changes(filter_changeset)
          .await
        {
          send_notification(&notification.view_id, DatabaseNotification::DidUpdateFilter)
            .payload(notification)
            .send();
        }
      });
    }
    Ok(())
  }

  ///
  ///
  /// # Arguments
  ///
  /// * `field_id`:
  ///
  #[tracing::instrument(level = "debug", skip_all, err)]
  pub async fn v_update_group_setting(&self, field_id: &str) -> FlowyResult<()> {
    if let Some(field_rev) = self.delegate.get_field_rev(field_id).await {
      let row_revs = self.delegate.get_row_revs(None).await;
      let configuration_reader = GroupConfigurationReaderImpl {
        pad: self.pad.clone(),
        view_editor_delegate: self.delegate.clone(),
      };
      let new_group_controller = new_group_controller_with_field_rev(
        self.user_id.clone(),
        self.view_id.clone(),
        self.pad.clone(),
        self.rev_manager.clone(),
        field_rev,
        row_revs,
        configuration_reader,
      )
      .await?;

      let new_groups = new_group_controller
        .groups()
        .into_iter()
        .map(|group| GroupPB::from(group.clone()))
        .collect();

      *self.group_controller.write().await = new_group_controller;
      let changeset = GroupChangesetPB {
        view_id: self.view_id.clone(),
        initial_groups: new_groups,
        ..Default::default()
      };

      debug_assert!(!changeset.is_empty());
      if !changeset.is_empty() {
        send_notification(&changeset.view_id, DatabaseNotification::DidGroupByField)
          .payload(changeset)
          .send();
      }
    }
    Ok(())
  }

  pub(crate) async fn v_get_cells_for_field(
    &self,
    field_id: &str,
  ) -> FlowyResult<Vec<RowSingleCellData>> {
    get_cells_for_field(self.delegate.clone(), field_id).await
  }

  pub async fn v_get_calendar_event(&self, row_id: &str) -> Option<CalendarEventPB> {
    let layout_ty = LayoutRevision::Calendar;
    let calendar_setting = self
      .v_get_layout_settings(&layout_ty)
      .await
      .ok()?
      .calendar?;

    // Text
    let primary_field = self.delegate.get_primary_field_rev().await?;
    let text_cell = get_cell_for_row(self.delegate.clone(), &primary_field.id, row_id).await?;

    // Date
    let date_field = self
      .delegate
      .get_field_rev(&calendar_setting.layout_field_id)
      .await?;

    let date_cell = get_cell_for_row(self.delegate.clone(), &date_field.id, row_id).await?;
    let title = text_cell
      .into_text_field_cell_data()
      .unwrap_or_default()
      .into();

    let timestamp = date_cell
      .into_date_field_cell_data()
      .unwrap_or_default()
      .timestamp
      .unwrap_or_default();

    Some(CalendarEventPB {
      row_id: row_id.to_string(),
      title_field_id: primary_field.id.clone(),
      title,
      timestamp,
    })
  }

  pub async fn v_get_all_calendar_events(&self) -> Option<Vec<CalendarEventPB>> {
    let layout_ty = LayoutRevision::Calendar;
    let calendar_setting = self
      .v_get_layout_settings(&layout_ty)
      .await
      .ok()?
      .calendar?;

    // Text
    let primary_field = self.delegate.get_primary_field_rev().await?;
    let text_cells = self.v_get_cells_for_field(&primary_field.id).await.ok()?;

    // Date
    let timestamp_by_row_id = self
      .v_get_cells_for_field(&calendar_setting.layout_field_id)
      .await
      .ok()?
      .into_iter()
      .map(|date_cell| {
        let row_id = date_cell.row_id.clone();

        // timestamp
        let timestamp = date_cell
          .into_date_field_cell_data()
          .map(|date_cell_data| date_cell_data.timestamp.unwrap_or_default())
          .unwrap_or_default();

        (row_id, timestamp)
      })
      .collect::<HashMap<String, i64>>();

    let mut events: Vec<CalendarEventPB> = vec![];
    for text_cell in text_cells {
      let title_field_id = text_cell.field_id.clone();
      let row_id = text_cell.row_id.clone();
      let timestamp = timestamp_by_row_id
        .get(&row_id)
        .cloned()
        .unwrap_or_default();

      let title = text_cell
        .into_text_field_cell_data()
        .unwrap_or_default()
        .into();

      let event = CalendarEventPB {
        row_id,
        title_field_id,
        title,
        timestamp,
      };
      events.push(event);
    }

    Some(events)
  }

  async fn notify_did_update_setting(&self) {
    let setting = self.v_get_setting().await;
    send_notification(&self.view_id, DatabaseNotification::DidUpdateSettings)
      .payload(setting)
      .send();
  }

  pub async fn notify_did_update_group_rows(&self, payload: GroupRowsNotificationPB) {
    send_notification(&payload.group_id, DatabaseNotification::DidUpdateGroupRow)
      .payload(payload)
      .send();
  }

  pub async fn notify_did_update_filter(&self, notification: FilterChangesetNotificationPB) {
    send_notification(&notification.view_id, DatabaseNotification::DidUpdateFilter)
      .payload(notification)
      .send();
  }

  pub async fn notify_did_update_sort(&self, notification: SortChangesetNotificationPB) {
    if !notification.is_empty() {
      send_notification(&notification.view_id, DatabaseNotification::DidUpdateSort)
        .payload(notification)
        .send();
    }
  }

  async fn notify_did_update_groups(&self, changeset: GroupChangesetPB) {
    send_notification(&self.view_id, DatabaseNotification::DidUpdateGroups)
      .payload(changeset)
      .send();
  }

  async fn modify<F>(&self, f: F) -> FlowyResult<()>
  where
    F: for<'a> FnOnce(
      &'a mut DatabaseViewRevisionPad,
    ) -> FlowyResult<Option<DatabaseViewRevisionChangeset>>,
  {
    let mut write_guard = self.pad.write().await;
    match f(&mut write_guard)? {
      None => {},
      Some(change) => {
        apply_change(&self.user_id, self.rev_manager.clone(), change).await?;
      },
    }
    Ok(())
  }

  async fn mut_group_controller<F, T>(&self, f: F) -> Option<T>
  where
    F: FnOnce(&mut Box<dyn GroupController>, Arc<FieldRevision>) -> FlowyResult<T>,
  {
    let group_field_id = self.group_controller.read().await.field_id().to_owned();
    match self.delegate.get_field_rev(&group_field_id).await {
      None => None,
      Some(field_rev) => {
        let mut write_guard = self.group_controller.write().await;
        f(&mut write_guard, field_rev).ok()
      },
    }
  }

  #[allow(dead_code)]
  async fn async_mut_group_controller<F, O, T>(&self, f: F) -> Option<T>
  where
    F: FnOnce(Arc<RwLock<Box<dyn GroupController>>>, Arc<FieldRevision>) -> O,
    O: Future<Output = FlowyResult<T>> + Sync + 'static,
  {
    let group_field_id = self.group_controller.read().await.field_id().to_owned();
    match self.delegate.get_field_rev(&group_field_id).await {
      None => None,
      Some(field_rev) => {
        let _write_guard = self.group_controller.write().await;
        f(self.group_controller.clone(), field_rev).await.ok()
      },
    }
  }
}

pub(crate) async fn get_cell_for_row(
  delegate: Arc<dyn DatabaseViewData>,
  field_id: &str,
  row_id: &str,
) -> Option<RowSingleCellData> {
  let (_, row_rev) = delegate.get_row_rev(row_id).await?;
  let mut cells = get_cells_for_field_in_rows(delegate, field_id, vec![row_rev])
    .await
    .ok()?;
  if cells.is_empty() {
    None
  } else {
    assert_eq!(cells.len(), 1);
    Some(cells.remove(0))
  }
}

// Returns the list of cells corresponding to the given field.
pub(crate) async fn get_cells_for_field(
  delegate: Arc<dyn DatabaseViewData>,
  field_id: &str,
) -> FlowyResult<Vec<RowSingleCellData>> {
  let row_revs = delegate.get_row_revs(None).await;
  get_cells_for_field_in_rows(delegate, field_id, row_revs).await
}

pub(crate) async fn get_cells_for_field_in_rows(
  delegate: Arc<dyn DatabaseViewData>,
  field_id: &str,
  row_revs: Vec<Arc<RowRevision>>,
) -> FlowyResult<Vec<RowSingleCellData>> {
  let field_rev = delegate.get_field_rev(field_id).await.unwrap();
  let field_type: FieldType = field_rev.ty.into();
  let mut cells = vec![];
  if let Some(handler) = delegate.get_type_option_cell_handler(&field_rev, &field_type) {
    for row_rev in row_revs {
      if let Some(cell_rev) = row_rev.cells.get(field_id) {
        if let Ok(type_cell_data) = TypeCellData::try_from(cell_rev) {
          if let Ok(cell_data) =
            handler.get_cell_data(type_cell_data.cell_str, &field_type, &field_rev)
          {
            cells.push(RowSingleCellData {
              row_id: row_rev.id.clone(),
              field_id: field_rev.id.clone(),
              field_type: field_type.clone(),
              cell_data,
            })
          }
        }
      }
    }
  }
  Ok(cells)
}

async fn new_group_controller(
  user_id: String,
  view_id: String,
  view_rev_pad: Arc<RwLock<DatabaseViewRevisionPad>>,
  rev_manager: Arc<RevisionManager<Arc<ConnectionPool>>>,
  delegate: Arc<dyn DatabaseViewData>,
) -> FlowyResult<Box<dyn GroupController>> {
  let configuration_reader = GroupConfigurationReaderImpl {
    pad: view_rev_pad.clone(),
    view_editor_delegate: delegate.clone(),
  };
  let field_revs = delegate.get_field_revs(None).await;
  let row_revs = delegate.get_row_revs(None).await;
  let layout = view_rev_pad.read().await.layout();
  // Read the group field or find a new group field
  let field_rev = configuration_reader
    .get_configuration()
    .await
    .and_then(|configuration| {
      field_revs
        .iter()
        .find(|field_rev| field_rev.id == configuration.field_id)
        .cloned()
    })
    .unwrap_or_else(|| find_grouping_field(&field_revs, &layout).unwrap());

  new_group_controller_with_field_rev(
    user_id,
    view_id,
    view_rev_pad,
    rev_manager,
    field_rev,
    row_revs,
    configuration_reader,
  )
  .await
}

/// Returns a [GroupController]
///
async fn new_group_controller_with_field_rev(
  user_id: String,
  view_id: String,
  view_rev_pad: Arc<RwLock<DatabaseViewRevisionPad>>,
  rev_manager: Arc<RevisionManager<Arc<ConnectionPool>>>,
  grouping_field_rev: Arc<FieldRevision>,
  row_revs: Vec<Arc<RowRevision>>,
  configuration_reader: GroupConfigurationReaderImpl,
) -> FlowyResult<Box<dyn GroupController>> {
  let configuration_writer = GroupConfigurationWriterImpl {
    user_id,
    rev_manager,
    view_pad: view_rev_pad,
  };
  make_group_controller(
    view_id,
    grouping_field_rev,
    row_revs,
    configuration_reader,
    configuration_writer,
  )
  .await
}

async fn make_filter_controller(
  view_id: &str,
  delegate: Arc<dyn DatabaseViewData>,
  notifier: DatabaseViewChangedNotifier,
  cell_data_cache: AtomicCellDataCache,
  pad: Arc<RwLock<DatabaseViewRevisionPad>>,
) -> Arc<FilterController> {
  let field_revs = delegate.get_field_revs(None).await;
  let filter_revs = pad.read().await.get_all_filters(&field_revs);
  let task_scheduler = delegate.get_task_scheduler();
  let filter_delegate = DatabaseViewFilterDelegateImpl {
    editor_delegate: delegate.clone(),
    view_revision_pad: pad,
  };
  let handler_id = gen_handler_id();
  let filter_controller = FilterController::new(
    view_id,
    &handler_id,
    filter_delegate,
    task_scheduler.clone(),
    filter_revs,
    cell_data_cache,
    notifier,
  )
  .await;
  let filter_controller = Arc::new(filter_controller);
  task_scheduler
    .write()
    .await
    .register_handler(FilterTaskHandler::new(
      handler_id,
      filter_controller.clone(),
    ));
  filter_controller
}

async fn make_sort_controller(
  view_id: &str,
  delegate: Arc<dyn DatabaseViewData>,
  notifier: DatabaseViewChangedNotifier,
  filter_controller: Arc<FilterController>,
  pad: Arc<RwLock<DatabaseViewRevisionPad>>,
  cell_data_cache: AtomicCellDataCache,
) -> Arc<RwLock<SortController>> {
  let handler_id = gen_handler_id();
  let field_revs = delegate.get_field_revs(None).await;
  let sorts = pad.read().await.get_all_sorts(&field_revs);
  let sort_delegate = DatabaseViewSortDelegateImpl {
    editor_delegate: delegate.clone(),
    view_revision_pad: pad,
    filter_controller,
  };
  let task_scheduler = delegate.get_task_scheduler();
  let sort_controller = Arc::new(RwLock::new(SortController::new(
    view_id,
    &handler_id,
    sorts,
    sort_delegate,
    task_scheduler.clone(),
    cell_data_cache,
    notifier,
  )));
  task_scheduler
    .write()
    .await
    .register_handler(SortTaskHandler::new(handler_id, sort_controller.clone()));

  sort_controller
}

fn gen_handler_id() -> String {
  nanoid!(10)
}

async fn generate_restore_view(view_id: &str) -> (DatabaseViewRevisionPad, Revision) {
  let database_id = gen_database_id();
  let view = DatabaseViewRevisionPad::new(
    database_id,
    view_id.to_owned(),
    "".to_string(),
    LayoutRevision::Grid,
  );
  let bytes = make_database_view_operations(&view).json_bytes();
  let reset_revision = Revision::initial_revision(view_id, bytes);
  (view, reset_revision)
}

#[cfg(test)]
mod tests {
  use flowy_client_sync::client_database::DatabaseOperations;

  #[test]
  fn test() {
    let s1 = r#"[{"insert":"{\"view_id\":\"fTURELffPr\",\"grid_id\":\"fTURELffPr\",\"layout\":0,\"filters\":[],\"groups\":[]}"}]"#;
    let _delta_1 = DatabaseOperations::from_json(s1).unwrap();

    let s2 = r#"[{"retain":195},{"insert":"{\\\"group_id\\\":\\\"wD9i\\\",\\\"visible\\\":true},{\\\"group_id\\\":\\\"xZtv\\\",\\\"visible\\\":true},{\\\"group_id\\\":\\\"tFV2\\\",\\\"visible\\\":true}"},{"retain":10}]"#;
    let _delta_2 = DatabaseOperations::from_json(s2).unwrap();
  }
}
