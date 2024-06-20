use crate::entities::icon::UpdateViewIconParams;
use crate::entities::{
  view_pb_with_child_views, view_pb_without_child_views, view_pb_without_child_views_from_arc,
  CreateViewParams, CreateWorkspaceParams, DeletedViewPB, FolderSnapshotPB, MoveNestedViewParams,
  RepeatedTrashPB, RepeatedViewIdPB, RepeatedViewPB, UpdateViewParams, ViewLayoutPB, ViewPB,
  ViewSectionPB, WorkspacePB, WorkspaceSettingPB,
};
use crate::manager_observer::{
  notify_child_views_changed, notify_did_update_workspace, notify_parent_view_did_change,
  ChildViewChangeReason,
};
use crate::notification::{
  send_notification, send_workspace_setting_notification, FolderNotification,
};
use crate::publish_util::{generate_publish_name, view_pb_to_publish_view};
use crate::share::ImportParams;
use crate::util::{
  folder_not_init_error, insert_parent_child_views, workspace_data_not_sync_error,
};
use crate::view_operation::{create_view, FolderOperationHandler, FolderOperationHandlers};
use collab::core::collab::{DataSource, MutexCollab};
use collab_entity::CollabType;
use collab_folder::error::FolderError;
use collab_folder::{
  Folder, FolderNotify, Section, SectionItem, TrashInfo, UserId, View, ViewLayout, ViewUpdate,
  Workspace,
};
use collab_integrate::collab_builder::{AppFlowyCollabBuilder, CollabBuilderConfig};
use collab_integrate::CollabKVDB;
use flowy_error::{ErrorCode, FlowyError, FlowyResult};
use flowy_folder_pub::cloud::{gen_view_id, FolderCloudService};
use flowy_folder_pub::entities::{
  PublishInfoResponse, PublishViewInfo, PublishViewMeta, PublishViewMetaData, PublishViewPayload,
};
use flowy_folder_pub::folder_builder::ParentChildViews;
use flowy_search_pub::entities::FolderIndexManager;
use flowy_sqlite::kv::StorePreferences;
use futures::future;
use parking_lot::RwLock;
use std::fmt::{Display, Formatter};
use std::ops::Deref;
use std::sync::{Arc, Weak};
use tracing::{error, info, instrument};

pub trait FolderUser: Send + Sync {
  fn user_id(&self) -> Result<i64, FlowyError>;
  fn workspace_id(&self) -> Result<String, FlowyError>;
  fn collab_db(&self, uid: i64) -> Result<Weak<CollabKVDB>, FlowyError>;
}

pub struct FolderManager {
  /// MutexFolder is the folder that is used to store the data.
  pub(crate) mutex_folder: Arc<MutexFolder>,
  pub(crate) collab_builder: Arc<AppFlowyCollabBuilder>,
  pub(crate) user: Arc<dyn FolderUser>,
  pub(crate) operation_handlers: FolderOperationHandlers,
  pub cloud_service: Arc<dyn FolderCloudService>,
  pub(crate) folder_indexer: Arc<dyn FolderIndexManager>,
  pub(crate) store_preferences: Arc<StorePreferences>,
}

impl FolderManager {
  pub fn new(
    user: Arc<dyn FolderUser>,
    collab_builder: Arc<AppFlowyCollabBuilder>,
    operation_handlers: FolderOperationHandlers,
    cloud_service: Arc<dyn FolderCloudService>,
    folder_indexer: Arc<dyn FolderIndexManager>,
    store_preferences: Arc<StorePreferences>,
  ) -> FlowyResult<Self> {
    let mutex_folder = Arc::new(MutexFolder::default());
    let manager = Self {
      user,
      mutex_folder,
      collab_builder,
      operation_handlers,
      cloud_service,
      folder_indexer,
      store_preferences,
    };

    Ok(manager)
  }

  #[instrument(level = "debug", skip(self), err)]
  pub async fn get_current_workspace(&self) -> FlowyResult<WorkspacePB> {
    let workspace_id = self.user.workspace_id()?;
    self.with_folder(
      || {
        let uid = self.user.user_id()?;
        Err(workspace_data_not_sync_error(uid, &workspace_id))
      },
      |folder| {
        let workspace_pb_from_workspace = |workspace: Workspace, folder: &Folder| {
          let views = get_workspace_public_view_pbs(&workspace_id, folder);
          let workspace: WorkspacePB = (workspace, views).into();
          Ok::<WorkspacePB, FlowyError>(workspace)
        };

        match folder.get_workspace_info(&workspace_id) {
          None => Err(FlowyError::record_not_found().with_context("Can not find the workspace")),
          Some(workspace) => workspace_pb_from_workspace(workspace, folder),
        }
      },
    )
  }

  /// Return a list of views of the current workspace.
  /// Only the first level of child views are included.
  pub async fn get_current_workspace_public_views(&self) -> FlowyResult<Vec<ViewPB>> {
    let views = self.get_workspace_public_views().await?;
    Ok(views)
  }

  pub async fn get_workspace_public_views(&self) -> FlowyResult<Vec<ViewPB>> {
    let workspace_id = self.user.workspace_id()?;
    Ok(self.with_folder(Vec::new, |folder| {
      get_workspace_public_view_pbs(&workspace_id, folder)
    }))
  }

  pub async fn get_workspace_private_views(&self) -> FlowyResult<Vec<ViewPB>> {
    let workspace_id = self.user.workspace_id()?;
    Ok(self.with_folder(Vec::new, |folder| {
      get_workspace_private_view_pbs(&workspace_id, folder)
    }))
  }

  #[instrument(level = "trace", skip_all, err)]
  pub(crate) async fn make_folder<T: Into<Option<FolderNotify>>>(
    &self,
    uid: i64,
    workspace_id: &str,
    collab_db: Weak<CollabKVDB>,
    doc_state: DataSource,
    folder_notifier: T,
  ) -> Result<Folder, FlowyError> {
    let folder_notifier = folder_notifier.into();
    // only need the check the workspace id when the doc state is not from the disk.
    let should_check_workspace_id = !matches!(doc_state, DataSource::Disk);
    let should_auto_initialize = !should_check_workspace_id;
    let config = CollabBuilderConfig::default()
      .sync_enable(true)
      .auto_initialize(should_auto_initialize);

    let object_id = workspace_id;
    let collab = self.collab_builder.build_with_config(
      workspace_id,
      uid,
      object_id,
      CollabType::Folder,
      collab_db,
      doc_state,
      config,
    )?;
    let (should_clear, err) = match Folder::open(UserId::from(uid), collab.clone(), folder_notifier)
    {
      Ok(folder) => {
        if should_check_workspace_id {
          // check the workspace id in the folder is matched with the workspace id. Just in case the folder
          // is overwritten by another workspace.
          let folder_workspace_id = folder.get_workspace_id();
          if folder_workspace_id != workspace_id {
            error!(
              "expect workspace_id: {}, actual workspace_id: {}",
              workspace_id, folder_workspace_id
            );
            return Err(FlowyError::workspace_data_not_match());
          }
          // Initialize the folder manually
          collab.lock().initialize();
        }
        return Ok(folder);
      },
      Err(err) => (matches!(err, FolderError::NoRequiredData(_)), err),
    };

    // If opening the folder fails due to missing required data (indicated by a `FolderError::NoRequiredData`),
    // the function logs an informational message and attempts to clear the folder data by deleting its
    // document from the collaborative database. It then returns the encountered error.
    if should_clear {
      info!("Clear the folder data and try to open the folder again");
      if let Some(db) = self.user.collab_db(uid).ok().and_then(|a| a.upgrade()) {
        let _ = db.delete_doc(uid, workspace_id).await;
      }
    }
    Err(err.into())
  }

  pub(crate) async fn create_empty_collab(
    &self,
    uid: i64,
    workspace_id: &str,
    collab_db: Weak<CollabKVDB>,
  ) -> Result<Arc<MutexCollab>, FlowyError> {
    let object_id = workspace_id;
    let collab = self.collab_builder.build_with_config(
      workspace_id,
      uid,
      object_id,
      CollabType::Folder,
      collab_db,
      DataSource::Disk,
      CollabBuilderConfig::default().sync_enable(true),
    )?;
    Ok(collab)
  }

  /// Initialize the folder with the given workspace id.
  /// Fetch the folder updates from the cloud service and initialize the folder.
  #[tracing::instrument(skip(self, user_id), err)]
  pub async fn initialize_with_workspace_id(&self, user_id: i64) -> FlowyResult<()> {
    let workspace_id = self.user.workspace_id()?;
    let object_id = &workspace_id;
    let folder_doc_state = self
      .cloud_service
      .get_folder_doc_state(&workspace_id, user_id, CollabType::Folder, object_id)
      .await?;
    if let Err(err) = self
      .initialize(
        user_id,
        &workspace_id,
        FolderInitDataSource::Cloud(folder_doc_state),
      )
      .await
    {
      // If failed to open folder with remote data, open from local disk. After open from the local
      // disk. the data will be synced to the remote server.
      error!("initialize folder with error {:?}, fallback local", err);
      self
        .initialize(
          user_id,
          &workspace_id,
          FolderInitDataSource::LocalDisk {
            create_if_not_exist: false,
          },
        )
        .await?;
    }
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
        .get_folder_doc_state(workspace_id, user_id, CollabType::Folder, workspace_id)
        .await
        .map_err(FlowyError::from);

      match result {
        Ok(folder_doc_state) => {
          info!(
            "Get folder updates via {}, doc state len: {}",
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
  pub async fn create_workspace(&self, params: CreateWorkspaceParams) -> FlowyResult<Workspace> {
    let uid = self.user.user_id()?;
    let new_workspace = self
      .cloud_service
      .create_workspace(uid, &params.name)
      .await?;
    Ok(new_workspace)
  }

  pub async fn get_workspace_setting_pb(&self) -> FlowyResult<WorkspaceSettingPB> {
    let workspace_id = self.user.workspace_id()?;
    let latest_view = self.get_current_view().await;
    Ok(WorkspaceSettingPB {
      workspace_id,
      latest_view,
    })
  }

  pub async fn insert_parent_child_views(
    &self,
    views: Vec<ParentChildViews>,
  ) -> Result<(), FlowyError> {
    self.with_folder(
      || Err(FlowyError::internal().with_context("The folder is not initialized")),
      |folder| {
        for view in views {
          insert_parent_child_views(folder, view);
        }
        Ok(())
      },
    )?;

    Ok(())
  }

  pub async fn get_workspace_pb(&self) -> FlowyResult<WorkspacePB> {
    let workspace_id = self.user.workspace_id()?;
    let guard = self.mutex_folder.read();
    let folder = guard
      .as_ref()
      .ok_or(FlowyError::internal().with_context("folder is not initialized"))?;
    let workspace = folder
      .get_workspace_info(&workspace_id)
      .ok_or_else(|| FlowyError::record_not_found().with_context("Can not find the workspace"))?;

    let views = folder
      .views
      .get_views_belong_to(&workspace.id)
      .into_iter()
      .map(|view| view_pb_without_child_views(view.as_ref().clone()))
      .collect::<Vec<ViewPB>>();
    drop(guard);

    Ok(WorkspacePB {
      id: workspace.id,
      name: workspace.name,
      views,
      create_time: workspace.created_at,
    })
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
    let folder = self.mutex_folder.read();
    match &*folder {
      None => none_callback(),
      Some(folder) => f2(folder),
    }
  }

  pub async fn create_view_with_params(&self, params: CreateViewParams) -> FlowyResult<View> {
    let workspace_id = self.user.workspace_id()?;
    let view_layout: ViewLayout = params.layout.clone().into();
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
    let section = params.section.clone().unwrap_or(ViewSectionPB::Public);
    let is_private = section == ViewSectionPB::Private;
    let view = create_view(self.user.user_id()?, params, view_layout);
    self.with_folder(
      || (),
      |folder| {
        folder.insert_view(view.clone(), index);
        if is_private {
          folder.add_private_view_ids(vec![view.id.clone()]);
        }
      },
    );

    let folder = &self.mutex_folder.read();
    if let Some(folder) = folder.as_ref() {
      notify_did_update_workspace(&workspace_id, folder);
    }

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
    // TODO(nathan): remove orphan view. Just use for create document in row
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

  /// Retrieves the view corresponding to the specified view ID.
  ///
  /// It is important to note that if the target view contains child views,
  /// this method only provides access to the first level of child views.
  ///
  /// Therefore, to access a nested child view within one of the initial child views, you must invoke this method
  /// again using the ID of the child view you wish to access.
  #[tracing::instrument(level = "debug", skip(self))]
  pub async fn get_view_pb(&self, view_id: &str) -> FlowyResult<ViewPB> {
    let view_id = view_id.to_string();

    let folder = self.mutex_folder.read();
    let folder = folder.as_ref().ok_or_else(folder_not_init_error)?;

    // trash views and other private views should not be accessed
    let view_ids_should_be_filtered = self.get_view_ids_should_be_filtered(folder);

    if view_ids_should_be_filtered.contains(&view_id) {
      return Err(FlowyError::new(
        ErrorCode::RecordNotFound,
        format!("View: {} is in trash or other private sections", view_id),
      ));
    }

    match folder.views.get_view(&view_id) {
      None => {
        error!("Can't find the view with id: {}", view_id);
        Err(FlowyError::record_not_found())
      },
      Some(view) => {
        let child_views = folder
          .views
          .get_views_belong_to(&view.id)
          .into_iter()
          .filter(|view| !view_ids_should_be_filtered.contains(&view.id))
          .collect::<Vec<_>>();
        let view_pb = view_pb_with_child_views(view, child_views);
        Ok(view_pb)
      },
    }
  }

  /// Retrieves all views.
  ///
  /// It is important to note that this will return a flat map of all views,
  /// excluding all child views themselves, as they are all at the same level in this
  /// map.
  ///
  #[tracing::instrument(level = "debug", skip(self))]
  pub async fn get_all_views_pb(&self) -> FlowyResult<Vec<ViewPB>> {
    let folder = self.mutex_folder.read();
    let folder = folder.as_ref().ok_or_else(folder_not_init_error)?;

    // trash views and other private views should not be accessed
    let view_ids_should_be_filtered = self.get_view_ids_should_be_filtered(folder);

    let all_views = folder.views.get_all_views();
    let views = all_views
      .into_iter()
      .filter(|view| !view_ids_should_be_filtered.contains(&view.id))
      .map(view_pb_without_child_views_from_arc)
      .collect::<Vec<_>>();

    Ok(views)
  }

  /// Retrieves the ancestors of the view corresponding to the specified view ID, including the view itself.
  ///
  /// For example, if the view hierarchy is as follows:
  ///   - View A
  ///    - View B
  ///     - View C
  ///
  /// If you invoke this method with the ID of View C, it will return a list of views: [View A, View B, View C].
  #[tracing::instrument(level = "debug", skip(self))]
  pub async fn get_view_ancestors_pb(&self, view_id: &str) -> FlowyResult<Vec<ViewPB>> {
    let mut ancestors = vec![];
    let mut parent_view_id = view_id.to_string();
    while let Some(view) =
      self.with_folder(|| None, |folder| folder.views.get_view(&parent_view_id))
    {
      // If the view is already in the ancestors list, then break the loop
      if ancestors.iter().any(|v: &ViewPB| v.id == view.id) {
        break;
      }
      ancestors.push(view_pb_without_child_views(view.as_ref().clone()));
      parent_view_id = view.parent_view_id.clone();
    }
    ancestors.reverse();
    Ok(ancestors)
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
          folder.add_trash_view_ids(vec![view_id.to_string()]);
          // notify the parent view that the view is moved to trash
          send_notification(view_id, FolderNotification::DidMoveViewToTrash)
            .payload(DeletedViewPB {
              view_id: view_id.to_string(),
              index: None,
            })
            .send();

          notify_child_views_changed(
            view_pb_without_child_views(view.as_ref().clone()),
            ChildViewChangeReason::Delete,
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
      .map(|view| view_pb_without_child_views(view.as_ref().clone()))
      .collect();

    if !favorite_descendant_views.is_empty() {
      folder.delete_favorite_view_ids(
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
  pub async fn move_nested_view(&self, params: MoveNestedViewParams) -> FlowyResult<()> {
    let workspace_id = self.user.workspace_id()?;
    let view_id = params.view_id;
    let new_parent_id = params.new_parent_id;
    let prev_view_id = params.prev_view_id;
    let from_section = params.from_section;
    let to_section = params.to_section;
    let view = self.get_view_pb(&view_id).await?;
    let old_parent_id = view.parent_view_id;
    self.with_folder(
      || (),
      |folder| {
        folder.move_nested_view(&view_id, &new_parent_id, prev_view_id);

        if from_section != to_section {
          if to_section == Some(ViewSectionPB::Private) {
            folder.add_private_view_ids(vec![view_id.clone()]);
          } else {
            folder.delete_private_view_ids(vec![view_id.clone()]);
          }
        }
      },
    );
    notify_parent_view_did_change(
      &workspace_id,
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
    let workspace_id = self.user.workspace_id()?;
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
          notify_parent_view_did_change(
            &workspace_id,
            self.mutex_folder.clone(),
            vec![parent_view_id],
          );
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
          .set_extra_if_not_none(params.extra)
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

    let is_private = self.with_folder(
      || false,
      |folder| folder.is_view_in_section(Section::Private, &view.id),
    );
    let section = if is_private {
      ViewSectionPB::Private
    } else {
      ViewSectionPB::Public
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
      section: Some(section),
    };

    self.create_view_with_params(duplicate_params).await?;
    Ok(())
  }

  #[tracing::instrument(level = "trace", skip(self), err)]
  pub(crate) async fn set_current_view(&self, view_id: &str) -> Result<(), FlowyError> {
    self.with_folder(
      || Err(FlowyError::record_not_found()),
      |folder| {
        folder.set_current_view(view_id);
        folder.add_recent_view_ids(vec![view_id.to_string()]);
        Ok(())
      },
    )?;

    let view = self.get_current_view().await;
    if let Some(view) = &view {
      let view_layout: ViewLayout = view.layout.clone().into();
      if let Some(handle) = self.operation_handlers.get(&view_layout) {
        info!("Open view: {}", view.id);
        if let Err(err) = handle.open_view(view_id).await {
          error!("Open view error: {:?}", err);
        }
      }
    }

    let workspace_id = self.user.workspace_id()?;
    send_workspace_setting_notification(workspace_id, view);
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
            folder.delete_favorite_view_ids(vec![view_id.to_string()]);
          } else {
            folder.add_favorite_view_ids(vec![view_id.to_string()]);
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

  /// Publish the view with the given view id.
  /// [publish_name] is one part of the URL of the published view. if it is None, the default publish name will be used. The default publish name is generated by the view id and view name.
  #[tracing::instrument(level = "debug", skip(self), err)]
  pub async fn publish_view(&self, view_id: &str, publish_name: Option<String>) -> FlowyResult<()> {
    let view = self
      .with_folder(|| None, |folder| folder.views.get_view(view_id))
      .ok_or_else(|| FlowyError::record_not_found().with_context("Can't find the view"))?;

    let layout = view.layout.clone();

    if layout != ViewLayout::Document {
      return Err(FlowyError::new(
        ErrorCode::NotSupportYet,
        "Only document view can be published".to_string(),
      ));
    }

    // Get the view payload and its child views recursively
    let payload = self
      .get_batch_publish_payload(view_id, publish_name)
      .await?;

    let workspace_id = self.user.workspace_id()?;
    self
      .cloud_service
      .publish_view(workspace_id.as_str(), payload)
      .await?;
    Ok(())
  }

  /// Unpublish the view with the given view id.
  #[tracing::instrument(level = "debug", skip(self), err)]
  pub async fn unpublish_views(&self, view_ids: Vec<String>) -> FlowyResult<()> {
    let workspace_id = self.user.workspace_id()?;
    self
      .cloud_service
      .unpublish_views(workspace_id.as_str(), view_ids)
      .await?;
    Ok(())
  }

  /// Get the publish info of the view with the given view id.
  /// The publish info contains the namespace and publish_name of the view.
  #[tracing::instrument(level = "debug", skip(self), err)]
  pub async fn get_publish_info(&self, view_id: &str) -> FlowyResult<PublishInfoResponse> {
    let publish_info = self.cloud_service.get_publish_info(view_id).await?;
    Ok(publish_info)
  }

  /// Get the namespace of the current workspace.
  /// The namespace is used to generate the URL of the published view.
  #[tracing::instrument(level = "debug", skip(self), err)]
  pub async fn set_publish_namespace(&self, namespace: String) -> FlowyResult<()> {
    let workspace_id = self.user.workspace_id()?;
    self
      .cloud_service
      .set_publish_namespace(workspace_id.as_str(), namespace.as_str())
      .await?;
    Ok(())
  }

  /// Get the namespace of the current workspace.
  #[tracing::instrument(level = "debug", skip(self), err)]
  pub async fn get_publish_namespace(&self) -> FlowyResult<String> {
    let workspace_id = self.user.workspace_id()?;
    let namespace = self
      .cloud_service
      .get_publish_namespace(workspace_id.as_str())
      .await?;
    Ok(namespace)
  }

  /// Get the publishing payload of the view with the given view id.
  /// The publishing payload contains the view data and its child views(not recursively).
  pub async fn get_batch_publish_payload(
    &self,
    view_id: &str,
    publish_name: Option<String>,
  ) -> FlowyResult<Vec<PublishViewPayload>> {
    let mut stack = vec![view_id.to_string()];
    let mut payloads = Vec::new();

    while let Some(current_view_id) = stack.pop() {
      let view = match self.get_view_pb(&current_view_id).await {
        Ok(view) => view,
        Err(_) => continue,
      };

      // Only document view can be published
      let layout = if view.layout == ViewLayoutPB::Document {
        ViewLayout::Document
      } else {
        continue;
      };

      // Only support set the publish_name for the current view, not for the child views
      let publish_name = if current_view_id == view_id {
        publish_name.clone()
      } else {
        None
      };

      let payload = self
        .get_publish_payload(&current_view_id, publish_name, layout)
        .await;

      if let Ok(payload) = payload {
        payloads.push(payload);
      }

      // Add the child views to the stack
      for child in &view.child_views {
        stack.push(child.id.clone());
      }
    }

    Ok(payloads)
  }

  async fn build_publish_views(&self, view_id: &str) -> Option<PublishViewInfo> {
    let view_pb = self.get_view_pb(view_id).await.ok()?;

    let mut child_views_futures = vec![];

    for child in &view_pb.child_views {
      let future = self.build_publish_views(&child.id);
      child_views_futures.push(future);
    }

    let child_views = future::join_all(child_views_futures)
      .await
      .into_iter()
      .flatten()
      .collect::<Vec<PublishViewInfo>>();

    let view_child_views = if child_views.is_empty() {
      None
    } else {
      Some(child_views)
    };

    let view = view_pb_to_publish_view(&view_pb);

    let view = PublishViewInfo {
      child_views: view_child_views,
      ..view
    };

    Some(view)
  }
  async fn get_publish_payload(
    &self,
    view_id: &str,
    publish_name: Option<String>,
    layout: ViewLayout,
  ) -> FlowyResult<PublishViewPayload> {
    let handler = self.get_handler(&layout)?;
    let encoded_collab = handler.encoded_collab_v1(view_id, layout).await?;
    let view = self
      .with_folder(|| None, |folder| folder.views.get_view(view_id))
      .ok_or_else(|| FlowyError::record_not_found().with_context("Can't find the view"))?;
    let publish_name = publish_name.unwrap_or_else(|| generate_publish_name(&view.id, &view.name));

    let child_views = self
      .build_publish_views(view_id)
      .await
      .map(|v| v.child_views.map_or(vec![], |c| c))
      .map_or(vec![], |c| c);

    let ancestor_views = self
      .get_view_ancestors_pb(view_id)
      .await?
      .iter()
      .map(view_pb_to_publish_view)
      .collect::<Vec<PublishViewInfo>>();

    let view_pb = self.get_view_pb(view_id).await?;
    let metadata = PublishViewMetaData {
      view: view_pb_to_publish_view(&view_pb),
      child_views,
      ancestor_views,
    };
    let meta = PublishViewMeta {
      view_id: view.id.clone(),
      publish_name,
      metadata,
    };

    let data = Vec::from(encoded_collab.doc_state);
    Ok(PublishViewPayload { meta, data })
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
    let recent_views = self.get_my_recent_sections().await;
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

  #[tracing::instrument(level = "debug", skip(self))]
  pub(crate) async fn get_my_recent_sections(&self) -> Vec<SectionItem> {
    self.get_sections(Section::Recent)
  }

  #[tracing::instrument(level = "trace", skip(self))]
  pub(crate) async fn get_my_trash_info(&self) -> Vec<TrashInfo> {
    self.with_folder(Vec::new, |folder| folder.get_my_trash_info())
  }

  #[tracing::instrument(level = "trace", skip(self))]
  pub(crate) async fn restore_all_trash(&self) {
    self.with_folder(
      || (),
      |folder| {
        folder.remove_all_my_trash_sections();
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
        folder.delete_trash_view_ids(vec![trash_id.to_string()]);
      },
    );
  }

  /// Delete all the trash permanently.
  #[tracing::instrument(level = "trace", skip(self))]
  pub(crate) async fn delete_my_trash(&self) {
    let deleted_trash = self.with_folder(Vec::new, |folder| folder.get_my_trash_info());
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
        folder.delete_trash_view_ids(vec![view_id.to_string()]);
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
    let workspace_id = self.user.workspace_id()?;
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
      section: None,
    };

    let view = create_view(self.user.user_id()?, params, import_data.view_layout);
    self.with_folder(
      || (),
      |folder| {
        folder.insert_view(view.clone(), None);
      },
    );
    notify_parent_view_did_change(
      &workspace_id,
      self.mutex_folder.clone(),
      vec![view.parent_view_id.clone()],
    );
    Ok(view)
  }

  /// Update the view with the provided view_id using the specified function.
  async fn update_view<F>(&self, view_id: &str, f: F) -> FlowyResult<()>
  where
    F: FnOnce(ViewUpdate) -> Option<View>,
  {
    let workspace_id = self.user.workspace_id()?;
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

      let folder = &self.mutex_folder.read();
      if let Some(folder) = folder.as_ref() {
        notify_did_update_workspace(&workspace_id, folder);
      }
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
    let workspace_id = self.user.workspace_id().ok()?;
    self.with_folder(
      || None,
      |folder| {
        let view = folder.views.get_view(view_id)?;
        match folder.views.get_view(&view.parent_view_id) {
          None => folder.get_workspace_info(&workspace_id).map(|workspace| {
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

  pub fn set_views_visibility(&self, view_ids: Vec<String>, is_public: bool) {
    self.with_folder(
      || (),
      |folder| {
        if is_public {
          folder.delete_private_view_ids(view_ids);
        } else {
          folder.add_private_view_ids(view_ids);
        }
      },
    );
  }

  /// Only support getting the Favorite and Recent sections.
  fn get_sections(&self, section_type: Section) -> Vec<SectionItem> {
    self.with_folder(Vec::new, |folder| {
      let views = match section_type {
        Section::Favorite => folder.get_my_favorite_sections(),
        Section::Recent => folder.get_my_recent_sections(),
        _ => vec![],
      };
      let view_ids_should_be_filtered = self.get_view_ids_should_be_filtered(folder);
      views
        .into_iter()
        .filter(|view| !view_ids_should_be_filtered.contains(&view.id))
        .collect()
    })
  }

  /// Get all the view that are in the trash, including the child views of the child views.
  /// For example, if A view which is in the trash has a child view B, this function will return
  /// both A and B.
  fn get_all_trash_ids(&self, folder: &Folder) -> Vec<String> {
    let trash_ids = folder
      .get_all_trash_sections()
      .into_iter()
      .map(|trash| trash.id)
      .collect::<Vec<String>>();
    let mut all_trash_ids = trash_ids.clone();
    for trash_id in trash_ids {
      all_trash_ids.extend(get_all_child_view_ids(folder, &trash_id));
    }
    all_trash_ids
  }

  /// Filter the views that are in the trash and belong to the other private sections.
  fn get_view_ids_should_be_filtered(&self, folder: &Folder) -> Vec<String> {
    let trash_ids = self.get_all_trash_ids(folder);
    let other_private_view_ids = self.get_other_private_view_ids(folder);
    [trash_ids, other_private_view_ids].concat()
  }

  fn get_other_private_view_ids(&self, folder: &Folder) -> Vec<String> {
    let my_private_view_ids = folder
      .get_my_private_sections()
      .into_iter()
      .map(|view| view.id)
      .collect::<Vec<String>>();

    let all_private_view_ids = folder
      .get_all_private_sections()
      .into_iter()
      .map(|view| view.id)
      .collect::<Vec<String>>();

    all_private_view_ids
      .into_iter()
      .filter(|id| !my_private_view_ids.contains(id))
      .collect()
  }

  pub fn remove_indices_for_workspace(&self, workspace_id: String) -> FlowyResult<()> {
    self
      .folder_indexer
      .remove_indices_for_workspace(workspace_id)?;

    Ok(())
  }
}

/// Return the views that belong to the workspace. The views are filtered by the trash and all the private views.
pub(crate) fn get_workspace_public_view_pbs(workspace_id: &str, folder: &Folder) -> Vec<ViewPB> {
  // get the trash ids
  let trash_ids = folder
    .get_all_trash_sections()
    .into_iter()
    .map(|trash| trash.id)
    .collect::<Vec<String>>();

  // get the private view ids
  let private_view_ids = folder
    .get_all_private_sections()
    .into_iter()
    .map(|view| view.id)
    .collect::<Vec<String>>();

  let mut views = folder.views.get_views_belong_to(workspace_id);
  // filter the views that are in the trash and all the private views
  views.retain(|view| !trash_ids.contains(&view.id) && !private_view_ids.contains(&view.id));

  views
    .into_iter()
    .map(|view| {
      // Get child views
      let mut child_views: Vec<Arc<View>> = folder
        .views
        .get_views_belong_to(&view.id)
        .into_iter()
        .collect();
      child_views.retain(|view| !trash_ids.contains(&view.id));
      view_pb_with_child_views(view, child_views)
    })
    .collect()
}

/// Get all the child views belong to the view id, including the child views of the child views.
fn get_all_child_view_ids(folder: &Folder, view_id: &str) -> Vec<String> {
  let child_view_ids = folder
    .views
    .get_views_belong_to(view_id)
    .into_iter()
    .map(|view| view.id.clone())
    .collect::<Vec<String>>();
  let mut all_child_view_ids = child_view_ids.clone();
  for child_view_id in child_view_ids {
    all_child_view_ids.extend(get_all_child_view_ids(folder, &child_view_id));
  }
  all_child_view_ids
}

/// Get the current private views of the user.
pub(crate) fn get_workspace_private_view_pbs(workspace_id: &str, folder: &Folder) -> Vec<ViewPB> {
  // get the trash ids
  let trash_ids = folder
    .get_all_trash_sections()
    .into_iter()
    .map(|trash| trash.id)
    .collect::<Vec<String>>();

  // get the private view ids
  let private_view_ids = folder
    .get_my_private_sections()
    .into_iter()
    .map(|view| view.id)
    .collect::<Vec<String>>();

  let mut views = folder.views.get_views_belong_to(workspace_id);
  // filter the views that are in the trash and not in the private view ids
  views.retain(|view| !trash_ids.contains(&view.id) && private_view_ids.contains(&view.id));

  views
    .into_iter()
    .map(|view| {
      // Get child views
      let mut child_views: Vec<Arc<View>> = folder
        .views
        .get_views_belong_to(&view.id)
        .into_iter()
        .collect();
      child_views.retain(|view| !trash_ids.contains(&view.id));
      view_pb_with_child_views(view, child_views)
    })
    .collect()
}

/// The MutexFolder is a wrapper of the [Folder] that is used to share the folder between different
/// threads.
#[derive(Clone, Default)]
pub struct MutexFolder(Arc<RwLock<Option<Folder>>>);
impl Deref for MutexFolder {
  type Target = Arc<RwLock<Option<Folder>>>;
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
  Cloud(Vec<u8>),
}

impl Display for FolderInitDataSource {
  fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
    match self {
      FolderInitDataSource::LocalDisk { .. } => f.write_fmt(format_args!("LocalDisk")),
      FolderInitDataSource::Cloud(_) => f.write_fmt(format_args!("Cloud")),
    }
  }
}
