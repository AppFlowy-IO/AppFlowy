use crate::dart_notification::{send_dart_notification, GridDartNotification};
use crate::entities::*;
use crate::services::block_manager::GridBlockEvent;
use crate::services::filter::{FilterChangeset, FilterController, FilterTaskHandler, FilterType, UpdatedFilterType};
use crate::services::group::{
    default_group_configuration, find_group_field, make_group_controller, Group, GroupConfigurationReader,
    GroupController, MoveGroupRowContext,
};
use crate::services::row::GridBlockRowRevision;
use crate::services::sort::{SortChangeset, SortController, SortTaskHandler, SortType};
use crate::services::view_editor::changed_notifier::GridViewChangedNotifier;
use crate::services::view_editor::trait_impl::*;
use crate::services::view_editor::GridViewChangedReceiverRunner;
use flowy_database::ConnectionPool;
use flowy_error::FlowyResult;
use flowy_http_model::revision::Revision;
use flowy_revision::RevisionManager;
use flowy_sync::client_grid::{make_grid_view_operations, GridViewRevisionChangeset, GridViewRevisionPad};
use flowy_task::TaskDispatcher;
use grid_rev_model::{
    gen_grid_filter_id, gen_grid_sort_id, FieldRevision, FieldTypeRevision, FilterRevision, LayoutRevision,
    RowChangeset, RowRevision, SortRevision,
};
use lib_infra::async_trait::async_trait;
use lib_infra::future::Fut;
use lib_infra::ref_map::RefCountValue;
use nanoid::nanoid;
use std::borrow::Cow;
use std::future::Future;
use std::sync::Arc;
use tokio::sync::{broadcast, RwLock};

pub trait GridViewEditorDelegate: Send + Sync + 'static {
    /// If the field_ids is None, then it will return all the field revisions
    fn get_field_revs(&self, field_ids: Option<Vec<String>>) -> Fut<Vec<Arc<FieldRevision>>>;

    /// Returns the field with the field_id
    fn get_field_rev(&self, field_id: &str) -> Fut<Option<Arc<FieldRevision>>>;

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
    fn get_blocks(&self) -> Fut<Vec<GridBlockRowRevision>>;

    /// Returns a `TaskDispatcher` used to poll a `Task`
    fn get_task_scheduler(&self) -> Arc<RwLock<TaskDispatcher>>;
}

pub struct GridViewRevisionEditor {
    user_id: String,
    view_id: String,
    pad: Arc<RwLock<GridViewRevisionPad>>,
    rev_manager: Arc<RevisionManager<Arc<ConnectionPool>>>,
    delegate: Arc<dyn GridViewEditorDelegate>,
    group_controller: Arc<RwLock<Box<dyn GroupController>>>,
    filter_controller: Arc<RwLock<FilterController>>,
    sort_controller: Arc<RwLock<SortController>>,
    pub notifier: GridViewChangedNotifier,
}

impl GridViewRevisionEditor {
    #[tracing::instrument(level = "trace", skip_all, err)]
    pub async fn new(
        user_id: &str,
        token: &str,
        view_id: String,
        delegate: Arc<dyn GridViewEditorDelegate>,
        mut rev_manager: RevisionManager<Arc<ConnectionPool>>,
    ) -> FlowyResult<Self> {
        let (notifier, _) = broadcast::channel(100);
        tokio::spawn(GridViewChangedReceiverRunner(Some(notifier.subscribe())).run());
        let cloud = Arc::new(GridViewRevisionCloudService {
            token: token.to_owned(),
        });

        let view_rev_pad = match rev_manager.initialize::<GridViewRevisionSerde>(Some(cloud)).await {
            Ok(pad) => pad,
            Err(err) => {
                // It shouldn't be here, because the snapshot should come to recue.
                tracing::error!("Deserialize grid view revisions failed: {}", err);
                let view = GridViewRevisionPad::new(view_id.to_owned(), view_id.to_owned(), LayoutRevision::Table);
                let bytes = make_grid_view_operations(&view).json_bytes();
                let reset_revision = Revision::initial_revision(&view_id, bytes);
                let _ = rev_manager.reset_object(vec![reset_revision]).await;
                view
            }
        };

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

        let sort_controller = make_sort_controller(&view_id, delegate.clone(), view_rev_pad.clone()).await;

        let user_id = user_id.to_owned();
        let group_controller = Arc::new(RwLock::new(group_controller));
        let filter_controller =
            make_filter_controller(&view_id, delegate.clone(), notifier.clone(), view_rev_pad.clone()).await;
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

    #[tracing::instrument(name = "close grid view editor", level = "trace", skip_all)]
    pub async fn close(&self) {
        self.rev_manager.generate_snapshot().await;
        self.rev_manager.close().await;
        self.filter_controller.read().await.close().await;
        self.sort_controller.read().await.close().await;
    }

    pub async fn handle_block_event(&self, event: Cow<'_, GridBlockEvent>) {
        let changeset = match event.into_owned() {
            GridBlockEvent::InsertRow { block_id: _, row } => {
                //
                GridViewRowsChangesetPB::from_insert(self.view_id.clone(), vec![row])
            }
            GridBlockEvent::UpdateRow { block_id: _, row } => {
                //
                GridViewRowsChangesetPB::from_update(self.view_id.clone(), vec![row])
            }
            GridBlockEvent::DeleteRow { block_id: _, row_id } => {
                //
                GridViewRowsChangesetPB::from_delete(self.view_id.clone(), vec![row_id])
            }
            GridBlockEvent::Move {
                block_id: _,
                deleted_row_id,
                inserted_row,
            } => {
                //
                GridViewRowsChangesetPB::from_move(self.view_id.clone(), vec![deleted_row_id], vec![inserted_row])
            }
        };

        send_dart_notification(&self.view_id, GridDartNotification::DidUpdateGridViewRows)
            .payload(changeset)
            .send();
    }

    pub async fn sort_rows(&self, rows: &mut Vec<Arc<RowRevision>>) {
        self.sort_controller.read().await.sort_rows(rows)
    }

    pub async fn filter_rows(&self, _block_id: &str, mut rows: Vec<Arc<RowRevision>>) -> Vec<Arc<RowRevision>> {
        self.filter_controller.write().await.filter_row_revs(&mut rows).await;
        rows
    }

    pub async fn duplicate_view_data(&self) -> FlowyResult<String> {
        let json_str = self.pad.read().await.json_str()?;
        Ok(json_str)
    }

    pub async fn will_create_view_row(&self, row_rev: &mut RowRevision, params: &CreateRowParams) {
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

    pub async fn did_create_view_row(&self, row_pb: &RowPB, params: &CreateRowParams) {
        // Send the group notification if the current view has groups
        match params.group_id.as_ref() {
            None => {}
            Some(group_id) => {
                let index = match params.start_row_id {
                    None => Some(0),
                    Some(_) => None,
                };

                self.group_controller.write().await.did_create_row(row_pb, group_id);
                let inserted_row = InsertedRowPB {
                    row: row_pb.clone(),
                    index,
                    is_new: true,
                };
                let changeset = GroupRowsNotificationPB::insert(group_id.clone(), vec![inserted_row]);
                self.notify_did_update_group_rows(changeset).await;
            }
        }
    }

    #[tracing::instrument(level = "trace", skip_all)]
    pub async fn did_delete_view_row(&self, row_rev: &RowRevision) {
        // Send the group notification if the current view has groups;
        let changesets = self
            .mut_group_controller(|group_controller, field_rev| {
                group_controller.did_delete_delete_row(row_rev, &field_rev)
            })
            .await;

        tracing::trace!("Delete row in view changeset: {:?}", changesets);
        if let Some(changesets) = changesets {
            for changeset in changesets {
                self.notify_did_update_group_rows(changeset).await;
            }
        }
    }

    pub async fn did_update_view_cell(&self, row_rev: &RowRevision) {
        let changesets = self
            .mut_group_controller(|group_controller, field_rev| {
                group_controller.did_update_group_row(row_rev, &field_rev)
            })
            .await;

        if let Some(changesets) = changesets {
            for changeset in changesets {
                self.notify_did_update_group_rows(changeset).await;
            }
        }

        let filter_controller = self.filter_controller.clone();
        let row_id = row_rev.id.clone();
        tokio::spawn(async move {
            filter_controller.write().await.did_receive_row_changed(&row_id).await;
        });
    }

    pub async fn move_view_group_row(
        &self,
        row_rev: &RowRevision,
        row_changeset: &mut RowChangeset,
        to_group_id: &str,
        to_row_id: Option<String>,
    ) -> Vec<GroupRowsNotificationPB> {
        let changesets = self
            .mut_group_controller(|group_controller, field_rev| {
                let move_row_context = MoveGroupRowContext {
                    row_rev,
                    row_changeset,
                    field_rev: field_rev.as_ref(),
                    to_group_id,
                    to_row_id,
                };

                let changesets = group_controller.move_group_row(move_row_context)?;
                Ok(changesets)
            })
            .await;

        changesets.unwrap_or_default()
    }
    /// Only call once after grid view editor initialized
    #[tracing::instrument(level = "trace", skip(self))]
    pub async fn load_view_groups(&self) -> FlowyResult<Vec<GroupPB>> {
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

    #[tracing::instrument(level = "trace", skip(self), err)]
    pub async fn move_view_group(&self, params: MoveGroupParams) -> FlowyResult<()> {
        let _ = self
            .group_controller
            .write()
            .await
            .move_group(&params.from_group_id, &params.to_group_id)?;
        match self.group_controller.read().await.get_group(&params.from_group_id) {
            None => tracing::warn!("Can not find the group with id: {}", params.from_group_id),
            Some((index, group)) => {
                let inserted_group = InsertedGroupPB {
                    group: GroupPB::from(group),
                    index: index as i32,
                };

                let changeset = GroupViewChangesetPB {
                    view_id: self.view_id.clone(),
                    inserted_groups: vec![inserted_group],
                    deleted_groups: vec![params.from_group_id.clone()],
                    update_groups: vec![],
                    new_groups: vec![],
                };

                self.notify_did_update_view(changeset).await;
            }
        }
        Ok(())
    }

    pub async fn group_id(&self) -> String {
        self.group_controller.read().await.field_id().to_string()
    }

    pub async fn get_view_setting(&self) -> GridSettingPB {
        let field_revs = self.delegate.get_field_revs(None).await;
        let grid_setting = make_grid_setting(&*self.pad.read().await, &field_revs);
        grid_setting
    }

    pub async fn get_all_view_filters(&self) -> Vec<Arc<FilterRevision>> {
        let field_revs = self.delegate.get_field_revs(None).await;
        self.pad.read().await.get_all_filters(&field_revs)
    }

    pub async fn get_view_filters(&self, filter_type: &FilterType) -> Vec<Arc<FilterRevision>> {
        let field_type_rev: FieldTypeRevision = filter_type.field_type.clone().into();
        self.pad
            .read()
            .await
            .get_filters(&filter_type.field_id, &field_type_rev)
    }

    /// Initialize new group when grouping by a new field
    ///
    pub async fn initialize_new_group(&self, params: InsertGroupParams) -> FlowyResult<()> {
        if let Some(field_rev) = self.delegate.get_field_rev(&params.field_id).await {
            let _ = self
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
            let _ = self.group_by_view_field(&params.field_id).await?;
            self.notify_did_update_setting().await;
        }
        Ok(())
    }

    pub async fn delete_view_group(&self, params: DeleteGroupParams) -> FlowyResult<()> {
        self.modify(|pad| {
            let changeset = pad.delete_group(&params.group_id, &params.field_id, &params.field_type_rev)?;
            Ok(changeset)
        })
        .await
    }

    pub async fn insert_view_sort(&self, params: AlterSortParams) -> FlowyResult<()> {
        let sort_type = SortType::from(&params);
        let is_exist = params.sort_id.is_some();
        let sort_id = match params.sort_id {
            None => gen_grid_sort_id(),
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
            self.modify(|pad| {
                let changeset = pad.update_sort(&params.field_id, sort_rev)?;
                Ok(changeset)
            })
            .await?;
            sort_controller
                .did_receive_changes(SortChangeset::from_update(sort_type))
                .await
        } else {
            self.modify(|pad| {
                let changeset = pad.insert_sort(&params.field_id, sort_rev)?;
                Ok(changeset)
            })
            .await?;
            sort_controller
                .did_receive_changes(SortChangeset::from_insert(sort_type))
                .await
        };

        if let Some(changeset) = changeset {
            self.notify_did_update_sort(changeset).await;
        }
        Ok(())
    }

    pub async fn delete_view_sort(&self, params: DeleteSortParams) -> FlowyResult<()> {
        let sort_type = params.sort_type;
        let changeset = self
            .sort_controller
            .write()
            .await
            .did_receive_changes(SortChangeset::from_delete(sort_type.clone()))
            .await;

        let _ = self
            .modify(|pad| {
                let changeset = pad.delete_sort(&params.sort_id, &sort_type.field_id, sort_type.field_type)?;
                Ok(changeset)
            })
            .await?;

        if changeset.is_some() {
            self.notify_did_update_sort(changeset.unwrap()).await;
        }
        Ok(())
    }

    #[tracing::instrument(level = "trace", skip(self), err)]
    pub async fn insert_view_filter(&self, params: AlterFilterParams) -> FlowyResult<()> {
        let filter_type = FilterType::from(&params);
        let is_exist = params.filter_id.is_some();
        let filter_id = match params.filter_id {
            None => gen_grid_filter_id(),
            Some(filter_id) => filter_id,
        };
        let filter_rev = FilterRevision {
            id: filter_id.clone(),
            field_id: params.field_id.clone(),
            field_type: params.field_type,
            condition: params.condition,
            content: params.content,
        };
        let mut filter_controller = self.filter_controller.write().await;
        let changeset = if is_exist {
            let old_filter_type = self
                .delegate
                .get_field_rev(&params.field_id)
                .await
                .map(|field| FilterType::from(&field));
            self.modify(|pad| {
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
            self.modify(|pad| {
                let changeset = pad.insert_filter(&params.field_id, filter_rev)?;
                Ok(changeset)
            })
            .await?;
            filter_controller
                .did_receive_changes(FilterChangeset::from_insert(filter_type))
                .await
        };

        if let Some(changeset) = changeset {
            self.notify_did_update_filter(changeset).await;
        }
        Ok(())
    }

    #[tracing::instrument(level = "trace", skip(self), err)]
    pub async fn delete_view_filter(&self, params: DeleteFilterParams) -> FlowyResult<()> {
        let filter_type = params.filter_type;
        let changeset = self
            .filter_controller
            .write()
            .await
            .did_receive_changes(FilterChangeset::from_delete(filter_type.clone()))
            .await;

        let _ = self
            .modify(|pad| {
                let changeset = pad.delete_filter(&params.filter_id, &filter_type.field_id, filter_type.field_type)?;
                Ok(changeset)
            })
            .await?;

        if changeset.is_some() {
            self.notify_did_update_filter(changeset.unwrap()).await;
        }
        Ok(())
    }

    #[tracing::instrument(level = "trace", skip_all, err)]
    pub async fn did_update_view_field_type_option(
        &self,
        field_id: &str,
        old_field_rev: Option<Arc<FieldRevision>>,
    ) -> FlowyResult<()> {
        if let Some(field_rev) = self.delegate.get_field_rev(field_id).await {
            let old = old_field_rev.map(|old_field_rev| FilterType::from(&old_field_rev));
            let new = FilterType::from(&field_rev);
            let filter_type = UpdatedFilterType::new(old, new);
            let filter_changeset = FilterChangeset::from_update(filter_type);
            if let Some(changeset) = self
                .filter_controller
                .write()
                .await
                .did_receive_changes(filter_changeset)
                .await
            {
                self.notify_did_update_filter(changeset).await;
            }
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
    pub async fn group_by_view_field(&self, field_id: &str) -> FlowyResult<()> {
        if let Some(field_rev) = self.delegate.get_field_rev(field_id).await {
            let row_revs = self.delegate.get_row_revs(None).await;
            let new_group_controller = new_group_controller_with_field_rev(
                self.user_id.clone(),
                self.view_id.clone(),
                self.pad.clone(),
                self.rev_manager.clone(),
                field_rev,
                row_revs,
            )
            .await?;

            let new_groups = new_group_controller
                .groups()
                .into_iter()
                .map(|group| GroupPB::from(group.clone()))
                .collect();

            *self.group_controller.write().await = new_group_controller;
            let changeset = GroupViewChangesetPB {
                view_id: self.view_id.clone(),
                new_groups,
                ..Default::default()
            };

            debug_assert!(!changeset.is_empty());
            if !changeset.is_empty() {
                send_dart_notification(&changeset.view_id, GridDartNotification::DidGroupByNewField)
                    .payload(changeset)
                    .send();
            }
        }
        Ok(())
    }

    async fn notify_did_update_setting(&self) {
        let setting = self.get_view_setting().await;
        send_dart_notification(&self.view_id, GridDartNotification::DidUpdateGridSetting)
            .payload(setting)
            .send();
    }

    pub async fn notify_did_update_group_rows(&self, payload: GroupRowsNotificationPB) {
        send_dart_notification(&payload.group_id, GridDartNotification::DidUpdateGroup)
            .payload(payload)
            .send();
    }

    pub async fn notify_did_update_filter(&self, changeset: FilterChangesetNotificationPB) {
        send_dart_notification(&changeset.view_id, GridDartNotification::DidUpdateFilter)
            .payload(changeset)
            .send();
    }

    pub async fn notify_did_update_sort(&self, changeset: SortChangesetNotificationPB) {
        send_dart_notification(&changeset.view_id, GridDartNotification::DidUpdateSort)
            .payload(changeset)
            .send();
    }

    async fn notify_did_update_view(&self, changeset: GroupViewChangesetPB) {
        send_dart_notification(&self.view_id, GridDartNotification::DidUpdateGroupView)
            .payload(changeset)
            .send();
    }

    async fn modify<F>(&self, f: F) -> FlowyResult<()>
    where
        F: for<'a> FnOnce(&'a mut GridViewRevisionPad) -> FlowyResult<Option<GridViewRevisionChangeset>>,
    {
        let mut write_guard = self.pad.write().await;
        match f(&mut *write_guard)? {
            None => {}
            Some(change) => {
                let _ = apply_change(&self.user_id, self.rev_manager.clone(), change).await?;
            }
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
            }
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
            }
        }
    }
}

#[async_trait]
impl RefCountValue for GridViewRevisionEditor {
    async fn did_remove(&self) {
        self.close().await;
    }
}

async fn new_group_controller(
    user_id: String,
    view_id: String,
    view_rev_pad: Arc<RwLock<GridViewRevisionPad>>,
    rev_manager: Arc<RevisionManager<Arc<ConnectionPool>>>,
    delegate: Arc<dyn GridViewEditorDelegate>,
) -> FlowyResult<Box<dyn GroupController>> {
    let configuration_reader = GroupConfigurationReaderImpl(view_rev_pad.clone());
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
        .unwrap_or_else(|| find_group_field(&field_revs, &layout).unwrap());

    new_group_controller_with_field_rev(user_id, view_id, view_rev_pad, rev_manager, field_rev, row_revs).await
}

/// Returns a [GroupController]  
///
async fn new_group_controller_with_field_rev(
    user_id: String,
    view_id: String,
    view_rev_pad: Arc<RwLock<GridViewRevisionPad>>,
    rev_manager: Arc<RevisionManager<Arc<ConnectionPool>>>,
    field_rev: Arc<FieldRevision>,
    row_revs: Vec<Arc<RowRevision>>,
) -> FlowyResult<Box<dyn GroupController>> {
    let configuration_reader = GroupConfigurationReaderImpl(view_rev_pad.clone());
    let configuration_writer = GroupConfigurationWriterImpl {
        user_id,
        rev_manager,
        view_pad: view_rev_pad,
    };
    make_group_controller(view_id, field_rev, row_revs, configuration_reader, configuration_writer).await
}

async fn make_filter_controller(
    view_id: &str,
    delegate: Arc<dyn GridViewEditorDelegate>,
    notifier: GridViewChangedNotifier,
    pad: Arc<RwLock<GridViewRevisionPad>>,
) -> Arc<RwLock<FilterController>> {
    let field_revs = delegate.get_field_revs(None).await;
    let filter_revs = pad.read().await.get_all_filters(&field_revs);
    let task_scheduler = delegate.get_task_scheduler();
    let filter_delegate = GridViewFilterDelegateImpl {
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
        notifier,
    )
    .await;
    let filter_controller = Arc::new(RwLock::new(filter_controller));
    task_scheduler
        .write()
        .await
        .register_handler(FilterTaskHandler::new(handler_id, filter_controller.clone()));
    filter_controller
}

async fn make_sort_controller(
    view_id: &str,
    delegate: Arc<dyn GridViewEditorDelegate>,
    pad: Arc<RwLock<GridViewRevisionPad>>,
) -> Arc<RwLock<SortController>> {
    let handler_id = gen_handler_id();
    let sort_delegate = GridViewSortDelegateImpl {
        editor_delegate: delegate.clone(),
        view_revision_pad: pad,
    };
    let task_scheduler = delegate.get_task_scheduler();
    let sort_controller = Arc::new(RwLock::new(SortController::new(
        view_id,
        &handler_id,
        sort_delegate,
        task_scheduler.clone(),
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

#[cfg(test)]
mod tests {
    use flowy_sync::client_grid::GridOperations;

    #[test]
    fn test() {
        let s1 = r#"[{"insert":"{\"view_id\":\"fTURELffPr\",\"grid_id\":\"fTURELffPr\",\"layout\":0,\"filters\":[],\"groups\":[]}"}]"#;
        let _delta_1 = GridOperations::from_json(s1).unwrap();

        let s2 = r#"[{"retain":195},{"insert":"{\\\"group_id\\\":\\\"wD9i\\\",\\\"visible\\\":true},{\\\"group_id\\\":\\\"xZtv\\\",\\\"visible\\\":true},{\\\"group_id\\\":\\\"tFV2\\\",\\\"visible\\\":true}"},{"retain":10}]"#;
        let _delta_2 = GridOperations::from_json(s2).unwrap();
    }
}
