use std::collections::HashSet;
use std::fmt::{Display, Formatter};
use std::ops::Deref;
use std::sync::{Arc, Weak};

use collab::core::collab::{CollabRawData, MutexCollab};
use collab::core::collab_state::SyncState;
use collab_entity::CollabType;
use collab_folder::{
  Folder, FolderData, FolderNotify, Section, SectionItem, TrashChange, TrashChangeReceiver,
  TrashInfo, UserId, View, ViewChange, ViewChangeReceiver, ViewLayout, ViewUpdate, Workspace,
};
use parking_lot::{Mutex, RwLock};
use tokio_stream::wrappers::WatchStream;
use tokio_stream::StreamExt;
use tracing::{event, info, instrument, Level};

use collab_integrate::collab_builder::AppFlowyCollabBuilder;
use collab_integrate::{CollabPersistenceConfig, RocksCollabDB, YrsDocAction};
use flowy_error::{ErrorCode, FlowyError, FlowyResult};
use flowy_folder_deps::cloud::{gen_view_id, FolderCloudService};
use lib_dispatch::prelude::af_spawn;

use crate::entities::icon::UpdateViewIconParams;
use crate::entities::{
  view_pb_with_child_views, view_pb_without_child_views, ChildViewUpdatePB, CreateViewParams,
  CreateWorkspaceParams, DeletedViewPB, FolderSnapshotPB, FolderSnapshotStatePB, FolderSyncStatePB,
  RepeatedTrashPB, RepeatedViewIdPB, RepeatedViewPB, UpdateViewParams, UserFolderPB, ViewPB,
  WorkspacePB, WorkspaceSettingPB,
};
use crate::notification::{
  send_notification, send_workspace_setting_notification, FolderNotification,
};
use crate::share::ImportParams;
use crate::user_default::DefaultFolderBuilder;
use crate::view_operation::{create_view, FolderOperationHandler, FolderOperationHandlers};

/// [FolderUser] represents the user for folder.
pub trait FolderUser: Send + Sync {
  fn user_id(&self) -> Result<i64, FlowyError>;
  fn token(&self) -> Result<Option<String>, FlowyError>;
  fn collab_db(&self, uid: i64) -> Result<Weak<RocksCollabDB>, FlowyError>;
}

pub struct FolderManager {
  workspace_id: RwLock<Option<String>>,
  mutex_folder: Arc<MutexFolder>,
  collab_builder: Arc<AppFlowyCollabBuilder>,
  user: Arc<dyn FolderUser>,
  operation_handlers: FolderOperationHandlers,
  pub cloud_service: Arc<dyn FolderCloudService>,
}

unsafe impl Send for FolderManager {}
unsafe impl Sync for FolderManager {}

impl FolderManager {
  pub async fn new(
    user: Arc<dyn FolderUser>,
    collab_builder: Arc<AppFlowyCollabBuilder>,
    operation_handlers: FolderOperationHandlers,
    cloud_service: Arc<dyn FolderCloudService>,
  ) -> FlowyResult<Self> {
    let mutex_folder = Arc::new(MutexFolder::default());
    let manager = Self {
      user,
      mutex_folder,
      collab_builder,
      operation_handlers,
      cloud_service,
      workspace_id: Default::default(),
    };

    Ok(manager)
  }

  #[instrument(level = "debug", skip(self), err)]
  pub async fn get_current_workspace(&self) -> FlowyResult<WorkspacePB> {
    self.with_folder(
      || {
        let uid = self.user.user_id()?;
        let workspace_id = self.workspace_id.read().as_ref().cloned().ok_or(
          FlowyError::from(ErrorCode::WorkspaceIdInvalid)
            .with_context("Unexpected empty workspace id"),
        )?;
        Err(workspace_data_not_sync_error(uid, &workspace_id))
      },
      |folder| {
        let workspace_pb_from_workspace = |workspace: Workspace, folder: &Folder| {
          let views = get_workspace_view_pbs(&workspace.id, folder);
          let workspace: WorkspacePB = (workspace, views).into();
          Ok::<WorkspacePB, FlowyError>(workspace)
        };

        match folder.get_current_workspace() {
          None => Err(FlowyError::record_not_found().with_context("Can not find the workspace")),
          Some(workspace) => workspace_pb_from_workspace(workspace, folder),
        }
      },
    )
  }

  /// Return a list of views of the current workspace.
  /// Only the first level of child views are included.
  pub async fn get_current_workspace_views(&self) -> FlowyResult<Vec<ViewPB>> {
    let workspace_id = self
      .mutex_folder
      .lock()
      .as_ref()
      .map(|folder| folder.get_workspace_id());

    if let Some(workspace_id) = workspace_id {
      self.get_workspace_views(&workspace_id).await
    } else {
      tracing::warn!("Can't get current workspace views");
      Ok(vec![])
    }
  }

  pub async fn get_workspace_views(&self, workspace_id: &str) -> FlowyResult<Vec<ViewPB>> {
    let views = self.with_folder(Vec::new, |folder| {
      get_workspace_view_pbs(workspace_id, folder)
    });

    Ok(views)
  }

  /// Called immediately after the application launched if the user already sign in/sign up.
  #[tracing::instrument(level = "info", skip(self, initial_data), err)]
  pub async fn initialize(
    &self,
    uid: i64,
    workspace_id: &str,
    initial_data: FolderInitDataSource,
  ) -> FlowyResult<()> {
    // Update the workspace id
    event!(
      Level::INFO,
      "Init workspace: {} from: {}",
      workspace_id,
      initial_data
    );
    *self.workspace_id.write() = Some(workspace_id.to_string());
    let workspace_id = workspace_id.to_string();

    // Get the collab db for the user with given user id.
    let collab_db = self.user.collab_db(uid)?;

    let (view_tx, view_rx) = tokio::sync::broadcast::channel(100);
    let (trash_tx, trash_rx) = tokio::sync::broadcast::channel(100);
    let folder_notifier = FolderNotify {
      view_change_tx: view_tx,
      trash_change_tx: trash_tx,
    };

    let folder = match initial_data {
      FolderInitDataSource::LocalDisk {
        create_if_not_exist,
      } => {
        let is_exist = is_exist_in_local_disk(&self.user, &workspace_id).unwrap_or(false);
        if is_exist {
          event!(Level::INFO, "Init folder from local disk");
          let collab = self
            .collab_for_folder(uid, &workspace_id, collab_db, vec![])
            .await?;
          Folder::open(UserId::from(uid), collab, Some(folder_notifier))?
        } else if create_if_not_exist {
          // Currently, this branch is only used when the server type is supabase. For appflowy cloud,
          // the default workspace is already created when the user sign up.
          event!(Level::INFO, "Create folder with default folder builder");
          let folder_data =
            DefaultFolderBuilder::build(uid, workspace_id.to_string(), &self.operation_handlers)
              .await;

          let collab = self
            .collab_for_folder(uid, &workspace_id, collab_db, vec![])
            .await?;
          Folder::create(
            UserId::from(uid),
            collab,
            Some(folder_notifier),
            folder_data,
          )
        } else {
          return Err(FlowyError::new(
            ErrorCode::RecordNotFound,
            "Can't find any workspace data",
          ));
        }
      },
      FolderInitDataSource::Cloud(raw_data) => {
        event!(Level::INFO, "Restore folder from cloud service");
        if raw_data.is_empty() {
          return Err(workspace_data_not_sync_error(uid, &workspace_id));
        }
        let collab = self
          .collab_for_folder(uid, &workspace_id, collab_db, raw_data)
          .await?;
        Folder::open(UserId::from(uid), collab, Some(folder_notifier))?
      },
      FolderInitDataSource::FolderData(folder_data) => {
        event!(Level::INFO, "Restore folder with passed-in folder data");
        let collab = self
          .collab_for_folder(uid, &workspace_id, collab_db, vec![])
          .await?;
        Folder::create(
          UserId::from(uid),
          collab,
          Some(folder_notifier),
          folder_data,
        )
      },
    };

    let folder_state_rx = folder.subscribe_sync_state();
    *self.mutex_folder.lock() = Some(folder);

    let weak_mutex_folder = Arc::downgrade(&self.mutex_folder);
    subscribe_folder_sync_state_changed(workspace_id.clone(), folder_state_rx, &weak_mutex_folder);
    subscribe_folder_snapshot_state_changed(workspace_id, &weak_mutex_folder);
    subscribe_folder_trash_changed(trash_rx, &weak_mutex_folder);
    subscribe_folder_view_changed(view_rx, &weak_mutex_folder);
    Ok(())
  }

  async fn collab_for_folder(
    &self,
    uid: i64,
    workspace_id: &str,
    collab_db: Weak<RocksCollabDB>,
    raw_data: CollabRawData,
  ) -> Result<Arc<MutexCollab>, FlowyError> {
    let collab = self
      .collab_builder
      .build_with_config(
        uid,
        workspace_id,
        CollabType::Folder,
        collab_db,
        raw_data,
        &CollabPersistenceConfig::new().enable_snapshot(true),
      )
      .await?;
    Ok(collab)
  }

  /// Initialize the folder with the given workspace id.
  /// Fetch the folder updates from the cloud service and initialize the folder.
  #[tracing::instrument(skip(self, user_id), err)]
  pub async fn initialize_with_workspace_id(
    &self,
    user_id: i64,
    workspace_id: &str,
  ) -> FlowyResult<()> {
    let folder_doc_state = self
      .cloud_service
      .get_folder_doc_state(workspace_id, user_id)
      .await?;

    event!(
      Level::INFO,
      "Get folder updates via {}, number of updates: {}",
      self.cloud_service.service_name(),
      folder_doc_state.len()
    );

    self
      .initialize(
        user_id,
        workspace_id,
        FolderInitDataSource::Cloud(folder_doc_state),
      )
      .await?;
    Ok(())
  }

  /// Initialize the folder for the new user.
  /// Using the [DefaultFolderBuilder] to create the default workspace for the new user.
  #[instrument(level = "info", skip_all, err)]
  pub async fn initialize_with_new_user(
    &self,
    user_id: i64,
    _token: &str,
    is_new: bool,
    data_source: FolderInitDataSource,
    workspace_id: &str,
  ) -> FlowyResult<()> {
    // Create the default workspace if the user is new
    info!("initialize_when_sign_up: is_new: {}", is_new);
    if is_new {
      self.initialize(user_id, workspace_id, data_source).await?;
    } else {
      // The folder updates should not be empty, as the folder data is stored
      // when the user signs up for the first time.
      let result = self
        .cloud_service
        .get_folder_doc_state(workspace_id, user_id)
        .await
        .map_err(FlowyError::from);

      match result {
        Ok(folder_updates) => {
          info!(
            "Get folder updates via {}, number of updates: {}",
            self.cloud_service.service_name(),
            folder_updates.len()
          );
          self
            .initialize(
              user_id,
              workspace_id,
              FolderInitDataSource::Cloud(folder_updates),
            )
            .await?;
        },
        Err(err) => {
          if err.is_record_not_found() {
            self.initialize(user_id, workspace_id, data_source).await?;
          } else {
            return Err(err);
          }
        },
      }
    }
    Ok(())
  }

  /// Called when the current user logout
  ///
  pub async fn clear(&self, _user_id: i64) {}

  #[tracing::instrument(level = "info", skip_all, err)]
  pub async fn create_workspace(&self, _params: CreateWorkspaceParams) -> FlowyResult<Workspace> {
    Err(FlowyError::not_support())
  }

  #[tracing::instrument(level = "info", skip_all, err)]
  pub async fn open_workspace(&self, _workspace_id: &str) -> FlowyResult<Workspace> {
    self.with_folder(
      || Err(FlowyError::internal()),
      |folder| {
        let workspace = folder.get_current_workspace().ok_or_else(|| {
          FlowyError::record_not_found().with_context("Can't open not existing workspace")
        })?;
        Ok::<Workspace, FlowyError>(workspace)
      },
    )
  }

  pub async fn get_workspace(&self, _workspace_id: &str) -> Option<Workspace> {
    self.with_folder(|| None, |folder| folder.get_current_workspace())
  }

  pub async fn get_workspace_setting_pb(&self) -> FlowyResult<WorkspaceSettingPB> {
    let workspace_id = self.get_current_workspace_id().await?;
    let latest_view = self.get_current_view().await;
    Ok(WorkspaceSettingPB {
      workspace_id,
      latest_view,
    })
  }

  pub async fn get_workspace_pb(&self) -> FlowyResult<WorkspacePB> {
    let workspace_pb = {
      let guard = self.mutex_folder.lock();
      let folder = guard
        .as_ref()
        .ok_or(FlowyError::internal().with_context("folder is not initialized"))?;
      let workspace = folder.get_current_workspace().ok_or(
        FlowyError::record_not_found().with_context("Can't find the current workspace id "),
      )?;

      let views = folder
        .views
        .get_views_belong_to(&workspace.id)
        .into_iter()
        .map(view_pb_without_child_views)
        .collect::<Vec<ViewPB>>();

      WorkspacePB {
        id: workspace.id,
        name: workspace.name,
        views,
        create_time: workspace.created_at,
      }
    };

    Ok(workspace_pb)
  }

  async fn get_current_workspace_id(&self) -> FlowyResult<String> {
    self
      .mutex_folder
      .lock()
      .as_ref()
      .map(|folder| folder.get_workspace_id())
      .ok_or(FlowyError::internal().with_context("Unexpected empty workspace id"))
  }

  /// This function acquires a lock on the `mutex_folder` and checks its state.
  /// If the folder is `None`, it invokes the `none_callback`, otherwise, it passes the folder to the `f2` callback.
  ///
  /// # Parameters
  ///
  /// * `none_callback`: A callback function that is invoked when `mutex_folder` contains `None`.
  /// * `f2`: A callback function that is invoked when `mutex_folder` contains a `Some` value. The contained folder is passed as an argument to this callback.
  fn with_folder<F1, F2, Output>(&self, none_callback: F1, f2: F2) -> Output
  where
    F1: FnOnce() -> Output,
    F2: FnOnce(&Folder) -> Output,
  {
    let folder = self.mutex_folder.lock();
    match &*folder {
      None => none_callback(),
      Some(folder) => f2(folder),
    }
  }

  pub async fn get_all_workspaces(&self) -> Vec<Workspace> {
    self.with_folder(Vec::new, |folder| {
      let mut workspaces = vec![];
      if let Some(workspace) = folder.get_current_workspace() {
        workspaces.push(workspace);
      }
      workspaces
    })
  }

  pub async fn create_view_with_params(&self, params: CreateViewParams) -> FlowyResult<View> {
    let view_layout: ViewLayout = params.layout.clone().into();
    let _workspace_id = self.get_current_workspace_id().await?;
    let handler = self.get_handler(&view_layout)?;
    let user_id = self.user.user_id()?;
    let meta = params.meta.clone();

    if meta.is_empty() && params.initial_data.is_empty() {
      tracing::trace!("Create view with build-in data");
      handler
        .create_built_in_view(user_id, &params.view_id, &params.name, view_layout.clone())
        .await?;
    } else {
      tracing::trace!("Create view with view data");
      handler
        .create_view_with_view_data(
          user_id,
          &params.view_id,
          &params.name,
          params.initial_data.clone(),
          view_layout.clone(),
          meta,
        )
        .await?;
    }

    let index = params.index;
    let view = create_view(self.user.user_id()?, params, view_layout);
    self.with_folder(
      || (),
      |folder| {
        folder.insert_view(view.clone(), index);
      },
    );

    Ok(view)
  }

  /// The orphan view is meant to be a view that is not attached to any parent view. By default, this
  /// view will not be shown in the view list unless it is attached to a parent view that is shown in
  /// the view list.
  pub async fn create_orphan_view_with_params(
    &self,
    params: CreateViewParams,
  ) -> FlowyResult<View> {
    let view_layout: ViewLayout = params.layout.clone().into();
    let handler = self.get_handler(&view_layout)?;
    let user_id = self.user.user_id()?;
    handler
      .create_built_in_view(user_id, &params.view_id, &params.name, view_layout.clone())
      .await?;
    let view = create_view(self.user.user_id()?, params, view_layout);
    self.with_folder(
      || (),
      |folder| {
        folder.insert_view(view.clone(), None);
      },
    );
    Ok(view)
  }

  #[tracing::instrument(level = "debug", skip(self), err)]
  pub(crate) async fn close_view(&self, view_id: &str) -> Result<(), FlowyError> {
    if let Some(view) = self.with_folder(|| None, |folder| folder.views.get_view(view_id)) {
      let handler = self.get_handler(&view.layout)?;
      handler.close_view(view_id).await?;
    }
    Ok(())
  }

  /// Returns the view with the given view id.
  /// The child views of the view will only access the first. So if you want to get the child view's
  /// child view, you need to call this method again.
  #[tracing::instrument(level = "debug", skip(self, view_id), err)]
  pub async fn get_view_pb(&self, view_id: &str) -> FlowyResult<ViewPB> {
    let view_id = view_id.to_string();
    let folder = self.mutex_folder.lock();
    let folder = folder.as_ref().ok_or_else(folder_not_init_error)?;
    let trash_ids = folder
      .get_all_trash()
      .into_iter()
      .map(|trash| trash.id)
      .collect::<Vec<String>>();

    if trash_ids.contains(&view_id) {
      return Err(FlowyError::record_not_found());
    }

    match folder.views.get_view(&view_id) {
      None => Err(FlowyError::record_not_found()),
      Some(view) => {
        let child_views = folder
          .views
          .get_views_belong_to(&view.id)
          .into_iter()
          .filter(|view| !trash_ids.contains(&view.id))
          .collect::<Vec<_>>();
        let view_pb = view_pb_with_child_views(view, child_views);
        Ok(view_pb)
      },
    }
  }

  /// Move the view to trash. If the view is the current view, then set the current view to empty.
  /// When the view is moved to trash, all the child views will be moved to trash as well.
  /// All the favorite views being trashed will be unfavorited first to remove it from favorites list as well. The process of unfavoriting concerned view is handled by `unfavorite_view_and_decendants()`
  #[tracing::instrument(level = "debug", skip(self), err)]
  pub async fn move_view_to_trash(&self, view_id: &str) -> FlowyResult<()> {
    self.with_folder(
      || (),
      |folder| {
        if let Some(view) = folder.views.get_view(view_id) {
          self.unfavorite_view_and_decendants(view.clone(), folder);
          folder.add_trash(vec![view_id.to_string()]);
          // notify the parent view that the view is moved to trash
          send_notification(view_id, FolderNotification::DidMoveViewToTrash)
            .payload(DeletedViewPB {
              view_id: view_id.to_string(),
              index: None,
            })
            .send();

          notify_child_views_changed(
            view_pb_without_child_views(view),
            ChildViewChangeReason::DidDeleteView,
          );
        }
      },
    );

    Ok(())
  }

  fn unfavorite_view_and_decendants(&self, view: Arc<View>, folder: &Folder) {
    let mut all_descendant_views: Vec<Arc<View>> = vec![view.clone()];
    all_descendant_views.extend(folder.views.get_views_belong_to(&view.id));

    let favorite_descendant_views: Vec<ViewPB> = all_descendant_views
      .iter()
      .filter(|view| view.is_favorite)
      .map(|view| view_pb_without_child_views(view.clone()))
      .collect();

    if !favorite_descendant_views.is_empty() {
      folder.delete_favorites(
        favorite_descendant_views
          .iter()
          .map(|v| v.id.clone())
          .collect(),
      );
      send_notification("favorite", FolderNotification::DidUnfavoriteView)
        .payload(RepeatedViewPB {
          items: favorite_descendant_views,
        })
        .send();
    }
  }

  /// Moves a nested view to a new location in the hierarchy.
  ///
  /// This function takes the `view_id` of the view to be moved,
  /// `new_parent_id` of the view under which the `view_id` should be moved,
  /// and an optional `prev_view_id` to position the `view_id` right after
  /// this specific view.
  ///
  /// If `prev_view_id` is provided, the moved view will be placed right after
  /// the view corresponding to `prev_view_id` under the `new_parent_id`.
  /// If `prev_view_id` is `None`, the moved view will become the first child of the new parent.
  ///
  /// # Arguments
  ///
  /// * `view_id` - A string slice that holds the id of the view to be moved.
  /// * `new_parent_id` - A string slice that holds the id of the new parent view.
  /// * `prev_view_id` - An `Option<String>` that holds the id of the view after which the `view_id` should be positioned.
  ///
  #[tracing::instrument(level = "trace", skip(self), err)]
  pub async fn move_nested_view(
    &self,
    view_id: String,
    new_parent_id: String,
    prev_view_id: Option<String>,
  ) -> FlowyResult<()> {
    let view = self.get_view_pb(&view_id).await?;
    let old_parent_id = view.parent_view_id;
    self.with_folder(
      || (),
      |folder| {
        folder.move_nested_view(&view_id, &new_parent_id, prev_view_id);
      },
    );
    notify_parent_view_did_change(
      self.mutex_folder.clone(),
      vec![new_parent_id, old_parent_id],
    );
    Ok(())
  }

  /// Move the view with given id from one position to another position.
  /// The view will be moved to the new position in the same parent view.
  /// The passed in index is the index of the view that displayed in the UI.
  /// We need to convert the index to the real index of the view in the parent view.
  #[tracing::instrument(level = "trace", skip(self), err)]
  pub async fn move_view(&self, view_id: &str, from: usize, to: usize) -> FlowyResult<()> {
    if let Some((is_workspace, parent_view_id, child_views)) = self.get_view_relation(view_id).await
    {
      // The display parent view is the view that is displayed in the UI
      let display_views = if is_workspace {
        self
          .get_current_workspace()
          .await?
          .views
          .into_iter()
          .map(|view| view.id)
          .collect::<Vec<_>>()
      } else {
        self
          .get_view_pb(&parent_view_id)
          .await?
          .child_views
          .into_iter()
          .map(|view| view.id)
          .collect::<Vec<_>>()
      };

      if display_views.len() > to {
        let to_view_id = display_views[to].clone();

        // Find the actual index of the view in the parent view
        let actual_from_index = child_views.iter().position(|id| id == view_id);
        let actual_to_index = child_views.iter().position(|id| id == &to_view_id);
        if let (Some(actual_from_index), Some(actual_to_index)) =
          (actual_from_index, actual_to_index)
        {
          self.with_folder(
            || (),
            |folder| {
              folder.move_view(view_id, actual_from_index as u32, actual_to_index as u32);
            },
          );
          notify_parent_view_did_change(self.mutex_folder.clone(), vec![parent_view_id]);
        }
      }
    }
    Ok(())
  }

  /// Return a list of views that belong to the given parent view id.
  #[tracing::instrument(level = "debug", skip(self, parent_view_id), err)]
  pub async fn get_views_belong_to(&self, parent_view_id: &str) -> FlowyResult<Vec<Arc<View>>> {
    let views = self.with_folder(Vec::new, |folder| {
      folder.views.get_views_belong_to(parent_view_id)
    });
    Ok(views)
  }

  /// Update the view with the given params.
  #[tracing::instrument(level = "trace", skip(self), err)]
  pub async fn update_view_with_params(&self, params: UpdateViewParams) -> FlowyResult<()> {
    self
      .update_view(&params.view_id, |update| {
        update
          .set_name_if_not_none(params.name)
          .set_desc_if_not_none(params.desc)
          .set_layout_if_not_none(params.layout)
          .set_favorite_if_not_none(params.is_favorite)
          .done()
      })
      .await
  }

  /// Update the icon of the view with the given params.
  #[tracing::instrument(level = "trace", skip(self), err)]
  pub async fn update_view_icon_with_params(
    &self,
    params: UpdateViewIconParams,
  ) -> FlowyResult<()> {
    self
      .update_view(&params.view_id, |update| {
        update.set_icon(params.icon).done()
      })
      .await
  }

  /// Duplicate the view with the given view id.
  #[tracing::instrument(level = "debug", skip(self), err)]
  pub(crate) async fn duplicate_view(&self, view_id: &str) -> Result<(), FlowyError> {
    let view = self
      .with_folder(|| None, |folder| folder.views.get_view(view_id))
      .ok_or_else(|| FlowyError::record_not_found().with_context("Can't duplicate the view"))?;

    let handler = self.get_handler(&view.layout)?;
    let view_data = handler.duplicate_view(&view.id).await?;

    // get the current view index in the parent view, because we need to insert the duplicated view below the current view.
    let index = if let Some((_, __, views)) = self.get_view_relation(&view.parent_view_id).await {
      views.iter().position(|id| id == view_id).map(|i| i as u32)
    } else {
      None
    };

    let duplicate_params = CreateViewParams {
      parent_view_id: view.parent_view_id.clone(),
      name: format!("{} (copy)", &view.name),
      desc: view.desc.clone(),
      layout: view.layout.clone().into(),
      initial_data: view_data.to_vec(),
      view_id: gen_view_id().to_string(),
      meta: Default::default(),
      set_as_current: true,
      index,
    };

    self.create_view_with_params(duplicate_params).await?;
    Ok(())
  }

  #[tracing::instrument(level = "trace", skip(self), err)]
  pub(crate) async fn set_current_view(&self, view_id: &str) -> Result<(), FlowyError> {
    let workspace_id = self.with_folder(
      || Err(FlowyError::record_not_found()),
      |folder| {
        folder.set_current_view(view_id);
        folder.add_recent_view_ids(vec![view_id.to_string()]);
        Ok(folder.get_workspace_id())
      },
    )?;

    send_workspace_setting_notification(workspace_id, self.get_current_view().await);
    Ok(())
  }

  #[tracing::instrument(level = "trace", skip(self))]
  pub(crate) async fn get_current_view(&self) -> Option<ViewPB> {
    let view_id = self.with_folder(|| None, |folder| folder.get_current_view())?;
    self.get_view_pb(&view_id).await.ok()
  }

  /// Toggles the favorite status of a view identified by `view_id`If the view is not a favorite, it will be added to the favorites list; otherwise, it will be removed from the list.
  #[tracing::instrument(level = "debug", skip(self), err)]
  pub async fn toggle_favorites(&self, view_id: &str) -> FlowyResult<()> {
    self.with_folder(
      || (),
      |folder| {
        if let Some(old_view) = folder.views.get_view(view_id) {
          if old_view.is_favorite {
            folder.delete_favorites(vec![view_id.to_string()]);
          } else {
            folder.add_favorites(vec![view_id.to_string()]);
          }
        }
      },
    );
    self.send_toggle_favorite_notification(view_id).await;
    Ok(())
  }

  /// Add the view to the recent view list / history.
  #[tracing::instrument(level = "debug", skip(self), err)]
  pub async fn add_recent_views(&self, view_ids: Vec<String>) -> FlowyResult<()> {
    self.with_folder(
      || (),
      |folder| {
        folder.add_recent_view_ids(view_ids);
      },
    );
    self.send_update_recent_views_notification().await;
    Ok(())
  }

  /// Add the view to the recent view list / history.
  #[tracing::instrument(level = "debug", skip(self), err)]
  pub async fn remove_recent_views(&self, view_ids: Vec<String>) -> FlowyResult<()> {
    self.with_folder(
      || (),
      |folder| {
        folder.delete_recent_view_ids(view_ids);
      },
    );
    self.send_update_recent_views_notification().await;
    Ok(())
  }

  // Used by toggle_favorites to send notification to frontend, after the favorite status of view has been changed.It sends two distinct notifications: one to correctly update the concerned view's is_favorite status, and another to update the list of favorites that is to be displayed.
  async fn send_toggle_favorite_notification(&self, view_id: &str) {
    if let Ok(view) = self.get_view_pb(view_id).await {
      let notification_type = if view.is_favorite {
        FolderNotification::DidFavoriteView
      } else {
        FolderNotification::DidUnfavoriteView
      };
      send_notification("favorite", notification_type)
        .payload(RepeatedViewPB {
          items: vec![view.clone()],
        })
        .send();

      send_notification(&view.id, FolderNotification::DidUpdateView)
        .payload(view)
        .send()
    }
  }

  async fn send_update_recent_views_notification(&self) {
    let recent_views = self.get_all_recent_sections().await;
    send_notification("recent_views", FolderNotification::DidUpdateRecentViews)
      .payload(RepeatedViewIdPB {
        items: recent_views.into_iter().map(|item| item.id).collect(),
      })
      .send();
  }

  #[tracing::instrument(level = "trace", skip(self))]
  pub(crate) async fn get_all_favorites(&self) -> Vec<SectionItem> {
    self.get_sections(Section::Favorite)
  }

  #[tracing::instrument(level = "trace", skip(self))]
  pub(crate) async fn get_all_recent_sections(&self) -> Vec<SectionItem> {
    self.get_sections(Section::Recent)
  }

  #[tracing::instrument(level = "trace", skip(self))]
  pub(crate) async fn get_all_trash(&self) -> Vec<TrashInfo> {
    self.with_folder(Vec::new, |folder| folder.get_all_trash())
  }

  #[tracing::instrument(level = "trace", skip(self))]
  pub(crate) async fn restore_all_trash(&self) {
    self.with_folder(
      || (),
      |folder| {
        folder.remote_all_trash();
      },
    );
    send_notification("trash", FolderNotification::DidUpdateTrash)
      .payload(RepeatedTrashPB { items: vec![] })
      .send();
  }

  #[tracing::instrument(level = "trace", skip(self))]
  pub(crate) async fn restore_trash(&self, trash_id: &str) {
    self.with_folder(
      || (),
      |folder| {
        folder.delete_trash(vec![trash_id.to_string()]);
      },
    );
  }

  /// Delete all the trash permanently.
  #[tracing::instrument(level = "trace", skip(self))]
  pub(crate) async fn delete_all_trash(&self) {
    let deleted_trash = self.with_folder(Vec::new, |folder| folder.get_all_trash());
    for trash in deleted_trash {
      let _ = self.delete_trash(&trash.id).await;
    }
    send_notification("trash", FolderNotification::DidUpdateTrash)
      .payload(RepeatedTrashPB { items: vec![] })
      .send();
  }

  /// Delete the trash permanently.
  /// Delete the view will delete all the resources that the view holds. For example, if the view
  /// is a database view. Then the database will be deleted as well.
  #[tracing::instrument(level = "debug", skip(self, view_id), err)]
  pub async fn delete_trash(&self, view_id: &str) -> FlowyResult<()> {
    let view = self.with_folder(|| None, |folder| folder.views.get_view(view_id));
    self.with_folder(
      || (),
      |folder| {
        folder.delete_trash(vec![view_id.to_string()]);
        folder.views.delete_views(vec![view_id]);
      },
    );
    if let Some(view) = view {
      if let Ok(handler) = self.get_handler(&view.layout) {
        handler.delete_view(view_id).await?;
      }
    }
    Ok(())
  }

  pub(crate) async fn import(&self, import_data: ImportParams) -> FlowyResult<View> {
    if import_data.data.is_none() && import_data.file_path.is_none() {
      return Err(FlowyError::new(
        ErrorCode::InvalidParams,
        "data or file_path is required",
      ));
    }

    let handler = self.get_handler(&import_data.view_layout)?;
    let view_id = gen_view_id().to_string();
    let uid = self.user.user_id()?;
    if let Some(data) = import_data.data {
      handler
        .import_from_bytes(
          uid,
          &view_id,
          &import_data.name,
          import_data.import_type,
          data,
        )
        .await?;
    }

    if let Some(file_path) = import_data.file_path {
      handler
        .import_from_file_path(&view_id, &import_data.name, file_path)
        .await?;
    }

    let params = CreateViewParams {
      parent_view_id: import_data.parent_view_id,
      name: import_data.name,
      desc: "".to_string(),
      layout: import_data.view_layout.clone().into(),
      initial_data: vec![],
      view_id,
      meta: Default::default(),
      set_as_current: false,
      index: None,
    };

    let view = create_view(self.user.user_id()?, params, import_data.view_layout);
    self.with_folder(
      || (),
      |folder| {
        folder.insert_view(view.clone(), None);
      },
    );
    notify_parent_view_did_change(self.mutex_folder.clone(), vec![view.parent_view_id.clone()]);
    Ok(view)
  }

  /// Update the view with the provided view_id using the specified function.
  async fn update_view<F>(&self, view_id: &str, f: F) -> FlowyResult<()>
  where
    F: FnOnce(ViewUpdate) -> Option<View>,
  {
    let value = self.with_folder(
      || None,
      |folder| {
        let old_view = folder.views.get_view(view_id);
        let new_view = folder.views.update_view(view_id, f);

        Some((old_view, new_view))
      },
    );

    if let Some((Some(old_view), Some(new_view))) = value {
      if let Ok(handler) = self.get_handler(&old_view.layout) {
        handler.did_update_view(&old_view, &new_view).await?;
      }
    }

    if let Ok(view_pb) = self.get_view_pb(view_id).await {
      send_notification(&view_pb.id, FolderNotification::DidUpdateView)
        .payload(view_pb)
        .send();
    }
    Ok(())
  }

  /// Returns a handler that implements the [FolderOperationHandler] trait
  fn get_handler(
    &self,
    view_layout: &ViewLayout,
  ) -> FlowyResult<Arc<dyn FolderOperationHandler + Send + Sync>> {
    match self.operation_handlers.get(view_layout) {
      None => Err(FlowyError::internal().with_context(format!(
        "Get data processor failed. Unknown layout type: {:?}",
        view_layout
      ))),
      Some(processor) => Ok(processor.clone()),
    }
  }

  /// Returns the relation of the view. The relation is a tuple of (is_workspace, parent_view_id,
  /// child_view_ids). If the view is a workspace, then the parent_view_id is the workspace id.
  /// Otherwise, the parent_view_id is the parent view id of the view. The child_view_ids is the
  /// child view ids of the view.
  async fn get_view_relation(&self, view_id: &str) -> Option<(bool, String, Vec<String>)> {
    self.with_folder(
      || None,
      |folder| {
        let view = folder.views.get_view(view_id)?;
        match folder.views.get_view(&view.parent_view_id) {
          None => folder.get_current_workspace().map(|workspace| {
            (
              true,
              workspace.id,
              workspace
                .child_views
                .items
                .into_iter()
                .map(|view| view.id)
                .collect::<Vec<String>>(),
            )
          }),
          Some(parent_view) => Some((
            false,
            parent_view.id.clone(),
            parent_view
              .children
              .items
              .clone()
              .into_iter()
              .map(|view| view.id)
              .collect::<Vec<String>>(),
          )),
        }
      },
    )
  }

  pub async fn get_folder_snapshots(
    &self,
    workspace_id: &str,
    limit: usize,
  ) -> FlowyResult<Vec<FolderSnapshotPB>> {
    let snapshots = self
      .cloud_service
      .get_folder_snapshots(workspace_id, limit)
      .await?
      .into_iter()
      .map(|snapshot| FolderSnapshotPB {
        snapshot_id: snapshot.snapshot_id,
        snapshot_desc: "".to_string(),
        created_at: snapshot.created_at,
        data: snapshot.data,
      })
      .collect::<Vec<_>>();

    Ok(snapshots)
  }

  /// Only expose this method for testing
  #[cfg(debug_assertions)]
  pub fn get_mutex_folder(&self) -> &Arc<MutexFolder> {
    &self.mutex_folder
  }

  /// Only expose this method for testing
  #[cfg(debug_assertions)]
  pub fn get_cloud_service(&self) -> &Arc<dyn FolderCloudService> {
    &self.cloud_service
  }

  fn get_sections(&self, section_type: Section) -> Vec<SectionItem> {
    self.with_folder(Vec::new, |folder| {
      let trash_ids = folder
        .get_all_trash()
        .into_iter()
        .map(|trash| trash.id)
        .collect::<Vec<String>>();

      let mut views = match section_type {
        Section::Favorite => folder.get_all_favorites(),
        Section::Recent => folder.get_all_recent_sections(),
        _ => vec![],
      };

      // filter the views that are in the trash
      views.retain(|view| !trash_ids.contains(&view.id));
      views
    })
  }
}

/// Listen on the [ViewChange] after create/delete/update events happened
fn subscribe_folder_view_changed(
  mut rx: ViewChangeReceiver,
  weak_mutex_folder: &Weak<MutexFolder>,
) {
  let weak_mutex_folder = weak_mutex_folder.clone();
  af_spawn(async move {
    while let Ok(value) = rx.recv().await {
      if let Some(folder) = weak_mutex_folder.upgrade() {
        tracing::trace!("Did receive view change: {:?}", value);
        match value {
          ViewChange::DidCreateView { view } => {
            notify_child_views_changed(
              view_pb_without_child_views(Arc::new(view.clone())),
              ChildViewChangeReason::DidCreateView,
            );
            notify_parent_view_did_change(folder.clone(), vec![view.parent_view_id]);
          },
          ViewChange::DidDeleteView { views } => {
            for view in views {
              notify_child_views_changed(
                view_pb_without_child_views(view),
                ChildViewChangeReason::DidDeleteView,
              );
            }
          },
          ViewChange::DidUpdate { view } => {
            notify_child_views_changed(
              view_pb_without_child_views(Arc::new(view.clone())),
              ChildViewChangeReason::DidUpdateView,
            );
            notify_parent_view_did_change(folder.clone(), vec![view.parent_view_id]);
          },
        };
      }
    }
  });
}

fn subscribe_folder_snapshot_state_changed(
  workspace_id: String,
  weak_mutex_folder: &Weak<MutexFolder>,
) {
  let weak_mutex_folder = weak_mutex_folder.clone();
  af_spawn(async move {
    if let Some(mutex_folder) = weak_mutex_folder.upgrade() {
      let stream = mutex_folder
        .lock()
        .as_ref()
        .map(|folder| folder.subscribe_snapshot_state());
      if let Some(mut state_stream) = stream {
        while let Some(snapshot_state) = state_stream.next().await {
          if let Some(new_snapshot_id) = snapshot_state.snapshot_id() {
            tracing::debug!("Did create folder remote snapshot: {}", new_snapshot_id);
            send_notification(
              &workspace_id,
              FolderNotification::DidUpdateFolderSnapshotState,
            )
            .payload(FolderSnapshotStatePB { new_snapshot_id })
            .send();
          }
        }
      }
    }
  });
}

fn subscribe_folder_sync_state_changed(
  workspace_id: String,
  mut folder_sync_state_rx: WatchStream<SyncState>,
  _weak_mutex_folder: &Weak<MutexFolder>,
) {
  af_spawn(async move {
    while let Some(state) = folder_sync_state_rx.next().await {
      send_notification(&workspace_id, FolderNotification::DidUpdateFolderSyncUpdate)
        .payload(FolderSyncStatePB::from(state))
        .send();
    }
  });
}

/// Listen on the [TrashChange]s and notify the frontend some views were changed.
fn subscribe_folder_trash_changed(
  mut rx: TrashChangeReceiver,
  weak_mutex_folder: &Weak<MutexFolder>,
) {
  let weak_mutex_folder = weak_mutex_folder.clone();
  af_spawn(async move {
    while let Ok(value) = rx.recv().await {
      if let Some(folder) = weak_mutex_folder.upgrade() {
        let mut unique_ids = HashSet::new();
        tracing::trace!("Did receive trash change: {:?}", value);
        let ids = match value {
          TrashChange::DidCreateTrash { ids } => ids,
          TrashChange::DidDeleteTrash { ids } => ids,
        };

        if let Some(folder) = folder.lock().as_ref() {
          let views = folder.views.get_views(&ids);
          for view in views {
            unique_ids.insert(view.parent_view_id.clone());
          }

          let repeated_trash: RepeatedTrashPB = folder.get_all_trash().into();
          send_notification("trash", FolderNotification::DidUpdateTrash)
            .payload(repeated_trash)
            .send();
        }

        let parent_view_ids = unique_ids.into_iter().collect();
        notify_parent_view_did_change(folder.clone(), parent_view_ids);
      }
    }
  });
}

/// Return the views that belong to the workspace. The views are filtered by the trash.
fn get_workspace_view_pbs(_workspace_id: &str, folder: &Folder) -> Vec<ViewPB> {
  let trash_ids = folder
    .get_all_trash()
    .into_iter()
    .map(|trash| trash.id)
    .collect::<Vec<String>>();

  let mut views = folder.get_workspace_views();
  views.retain(|view| !trash_ids.contains(&view.id));

  views
    .into_iter()
    .map(|view| {
      // Get child views
      let child_views = folder
        .views
        .get_views_belong_to(&view.id)
        .into_iter()
        .collect();
      view_pb_with_child_views(view, child_views)
    })
    .collect()
}

fn notify_did_update_workspace(workspace_id: &str, folder: &Folder) {
  let repeated_view: RepeatedViewPB = get_workspace_view_pbs(workspace_id, folder).into();
  tracing::trace!("Did update workspace views: {:?}", repeated_view);
  send_notification(workspace_id, FolderNotification::DidUpdateWorkspaceViews)
    .payload(repeated_view)
    .send();
}

/// Notify the the list of parent view ids that its child views were changed.
#[tracing::instrument(level = "debug", skip(folder, parent_view_ids))]
fn notify_parent_view_did_change<T: AsRef<str>>(
  folder: Arc<MutexFolder>,
  parent_view_ids: Vec<T>,
) -> Option<()> {
  let folder = folder.lock();
  let folder = folder.as_ref()?;
  let workspace_id = folder.get_workspace_id();
  let trash_ids = folder
    .get_all_trash()
    .into_iter()
    .map(|trash| trash.id)
    .collect::<Vec<String>>();

  for parent_view_id in parent_view_ids {
    let parent_view_id = parent_view_id.as_ref();

    // if the view's parent id equal to workspace id. Then it will fetch the current
    // workspace views. Because the the workspace is not a view stored in the views map.
    if parent_view_id == workspace_id {
      notify_did_update_workspace(&workspace_id, folder)
    } else {
      // Parent view can contain a list of child views. Currently, only get the first level
      // child views.
      let parent_view = folder.views.get_view(parent_view_id)?;
      let mut child_views = folder.views.get_views_belong_to(parent_view_id);
      child_views.retain(|view| !trash_ids.contains(&view.id));
      event!(Level::DEBUG, child_views_count = child_views.len());

      // Post the notification
      let parent_view_pb = view_pb_with_child_views(parent_view, child_views);
      send_notification(parent_view_id, FolderNotification::DidUpdateView)
        .payload(parent_view_pb)
        .send();
    }
  }

  None
}

pub enum ChildViewChangeReason {
  DidCreateView,
  DidDeleteView,
  DidUpdateView,
}

/// Notify the the list of parent view ids that its child views were changed.
#[tracing::instrument(level = "debug", skip_all)]
fn notify_child_views_changed(view_pb: ViewPB, reason: ChildViewChangeReason) {
  let parent_view_id = view_pb.parent_view_id.clone();
  let mut payload = ChildViewUpdatePB {
    parent_view_id: view_pb.parent_view_id.clone(),
    ..Default::default()
  };

  match reason {
    ChildViewChangeReason::DidCreateView => {
      payload.create_child_views.push(view_pb);
    },
    ChildViewChangeReason::DidDeleteView => {
      payload.delete_child_views.push(view_pb.id);
    },
    ChildViewChangeReason::DidUpdateView => {
      payload.update_child_views.push(view_pb);
    },
  }

  send_notification(&parent_view_id, FolderNotification::DidUpdateChildViews)
    .payload(payload)
    .send();
}

fn folder_not_init_error() -> FlowyError {
  FlowyError::internal().with_context("Folder not initialized")
}

#[derive(Clone, Default)]
pub struct MutexFolder(Arc<Mutex<Option<Folder>>>);
impl Deref for MutexFolder {
  type Target = Arc<Mutex<Option<Folder>>>;
  fn deref(&self) -> &Self::Target {
    &self.0
  }
}
unsafe impl Sync for MutexFolder {}
unsafe impl Send for MutexFolder {}

#[allow(clippy::large_enum_variant)]
pub enum FolderInitDataSource {
  /// It means using the data stored on local disk to initialize the folder
  LocalDisk { create_if_not_exist: bool },
  /// If there is no data stored on local disk, we will use the data from the server to initialize the folder
  Cloud(CollabRawData),
  /// If the user is new, we use the [DefaultFolderBuilder] to create the default folder.
  FolderData(FolderData),
}

impl Display for FolderInitDataSource {
  fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
    match self {
      FolderInitDataSource::LocalDisk { .. } => f.write_fmt(format_args!("LocalDisk")),
      FolderInitDataSource::Cloud(_) => f.write_fmt(format_args!("Cloud")),
      FolderInitDataSource::FolderData(_) => f.write_fmt(format_args!("Custom FolderData")),
    }
  }
}

fn is_exist_in_local_disk(user: &Arc<dyn FolderUser>, doc_id: &str) -> FlowyResult<bool> {
  let uid = user.user_id()?;
  if let Some(collab_db) = user.collab_db(uid)?.upgrade() {
    let read_txn = collab_db.read_txn();
    Ok(read_txn.is_exist(uid, doc_id))
  } else {
    Ok(false)
  }
}

fn workspace_data_not_sync_error(uid: i64, workspace_id: &str) -> FlowyError {
  FlowyError::from(ErrorCode::WorkspaceDataNotSync).with_payload(UserFolderPB {
    uid,
    workspace_id: workspace_id.to_string(),
  })
}
