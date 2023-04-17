use std::collections::{HashMap, HashSet};
use std::ops::Deref;
use std::sync::Arc;

use collab::plugin_impl::disk::CollabDiskPlugin;
use collab::preclude::CollabBuilder;
use collab_folder::core::{
  Folder as InnerFolder, FolderContext, TrashChange, TrashChangeReceiver, TrashInfo, TrashRecord,
  View, ViewChange, ViewChangeReceiver, ViewLayout, Workspace,
};
use collab_persistence::CollabKV;
use parking_lot::Mutex;
use tracing::{event, Level};

use flowy_error::{FlowyError, FlowyResult};
use lib_infra::util::timestamp;

use crate::entities::{
  CreateViewParams, CreateWorkspaceParams, RepeatedTrashPB, RepeatedViewPB, RepeatedWorkspacePB,
  UpdateViewParams, ViewPB,
};
use crate::notification::{
  send_notification, send_workspace_notification, send_workspace_setting_notification,
  FolderNotification,
};
use crate::user_default::{gen_workspace_id, DefaultFolderBuilder};
use crate::view_ext::{
  gen_view_id, view_from_create_view_params, ViewDataProcessor, ViewDataProcessorMap,
};

pub trait FolderUser: Send + Sync {
  fn user_id(&self) -> Result<i64, FlowyError>;
  fn token(&self) -> Result<String, FlowyError>;
  fn kv_db(&self) -> Result<Arc<CollabKV>, FlowyError>;
}

pub struct Folder2Manager {
  folder: Folder,
  user: Arc<dyn FolderUser>,
  view_processors: ViewDataProcessorMap,
}

unsafe impl Send for Folder2Manager {}
unsafe impl Sync for Folder2Manager {}

impl Folder2Manager {
  pub async fn new(
    user: Arc<dyn FolderUser>,
    view_processors: ViewDataProcessorMap,
  ) -> FlowyResult<Self> {
    // let folder = make_user_folder(user.clone())?;
    let folder = Folder::default();
    let manager = Self {
      user,
      folder,
      view_processors,
    };

    Ok(manager)
  }

  pub async fn get_current_workspace(&self) -> FlowyResult<Workspace> {
    match self.with_folder(None, |folder| folder.get_current_workspace()) {
      None => Err(FlowyError::record_not_found().context("Can not find the workspace")),
      Some(workspace) => Ok(workspace),
    }
  }

  pub async fn get_current_workspace_views(&self) -> FlowyResult<Vec<ViewPB>> {
    let workspace_id = self
      .folder
      .lock()
      .as_ref()
      .map(|folder| folder.get_current_workspace_id());

    if let Some(Some(workspace_id)) = workspace_id {
      self.get_workspace_views(&workspace_id).await
    } else {
      Ok(vec![])
    }
  }

  pub async fn get_workspace_views(&self, workspace_id: &str) -> FlowyResult<Vec<ViewPB>> {
    let views = self.with_folder(vec![], |folder| {
      get_workspace_view_pbs(workspace_id, folder)
    });

    Ok(views)
  }

  /// Called immediately after the application launched fi the user already sign in/sign up.
  #[tracing::instrument(level = "trace", skip(self), err)]
  pub async fn initialize(&self, user_id: i64) -> FlowyResult<()> {
    if let Ok(uid) = self.user.user_id() {
      let folder_id = FolderId::new(uid);
      let mut collab = CollabBuilder::new(uid, folder_id).build();
      if let Ok(kv_db) = self.user.kv_db() {
        let disk_plugin = Arc::new(
          CollabDiskPlugin::new(uid, kv_db).map_err(|err| FlowyError::internal().context(err))?,
        );
        collab.add_plugin(disk_plugin);
        collab.initial();
      }

      let (view_tx, view_rx) = tokio::sync::broadcast::channel(100);
      let (trash_tx, trash_rx) = tokio::sync::broadcast::channel(100);
      let folder_context = FolderContext {
        view_change_tx: Some(view_tx),
        trash_change_tx: Some(trash_tx),
      };
      *self.folder.lock() = Some(InnerFolder::get_or_create(collab, folder_context));
      listen_on_trash_change(trash_rx, self.folder.clone());
      listen_on_view_change(view_rx, self.folder.clone());
    }

    Ok(())
  }

  /// Called after the user sign up / sign in
  pub async fn initialize_with_new_user(&self, user_id: i64, token: &str) -> FlowyResult<()> {
    self.initialize(user_id).await?;
    let (folder_data, workspace_pb) =
      DefaultFolderBuilder::build(self.user.user_id()?, &self.view_processors).await;
    self.with_folder((), |folder| {
      folder.create_with_data(folder_data);
    });

    send_notification(token, FolderNotification::DidCreateWorkspace)
      .payload(RepeatedWorkspacePB {
        items: vec![workspace_pb],
      })
      .send();
    Ok(())
  }

  /// Called when the current user logout
  ///
  pub async fn clear(&self, _user_id: i64) {
    todo!()
  }

  pub async fn create_workspace(&self, params: CreateWorkspaceParams) -> FlowyResult<Workspace> {
    let workspace = Workspace {
      id: gen_workspace_id(),
      name: params.name,
      belongings: Default::default(),
      created_at: timestamp(),
    };

    self.with_folder((), |folder| {
      folder.workspaces.create_workspace(workspace.clone());
      folder.set_current_workspace(&workspace.id);
    });

    let repeated_workspace = RepeatedWorkspacePB {
      items: vec![workspace.clone().into()],
    };
    send_workspace_notification(FolderNotification::DidCreateWorkspace, repeated_workspace);
    Ok(workspace)
  }

  pub async fn open_workspace(&self, workspace_id: &str) -> FlowyResult<Workspace> {
    self.with_folder(Err(FlowyError::internal()), |folder| {
      let workspace = folder
        .workspaces
        .get_workspace(workspace_id)
        .ok_or_else(|| {
          FlowyError::record_not_found().context("Can't open not existing workspace")
        })?;
      folder.set_current_workspace(workspace_id);
      Ok::<Workspace, FlowyError>(workspace)
    })
  }

  pub async fn get_workspace(&self, workspace_id: &str) -> Option<Workspace> {
    self.with_folder(None, |folder| folder.workspaces.get_workspace(workspace_id))
  }

  fn with_folder<F, Output>(&self, default_value: Output, f: F) -> Output
  where
    F: FnOnce(&InnerFolder) -> Output,
  {
    let folder = self.folder.lock();
    match &*folder {
      None => default_value,
      Some(folder) => f(folder),
    }
  }

  pub async fn get_all_workspaces(&self) -> Vec<Workspace> {
    self.with_folder(vec![], |folder| folder.workspaces.get_all_workspaces())
  }

  pub async fn create_view_with_params(&self, params: CreateViewParams) -> FlowyResult<View> {
    let view_layout: ViewLayout = params.layout.clone().into();
    let processor = self.get_data_processor(&view_layout)?;
    let user_id = self.user.user_id()?;
    let ext = params.ext.clone();
    match params.initial_data.is_empty() {
      true => {
        tracing::trace!("Create view with build-in data");
        processor
          .create_view_with_build_in_data(
            user_id,
            &params.view_id,
            &params.name,
            view_layout.clone(),
            ext,
          )
          .await?;
      },
      false => {
        tracing::trace!("Create view with view data");
        processor
          .create_view_with_custom_data(
            user_id,
            &params.view_id,
            &params.name,
            params.initial_data.clone(),
            view_layout.clone(),
            ext,
          )
          .await?;
      },
    }
    let view = view_from_create_view_params(params, view_layout);
    self.with_folder((), |folder| {
      folder.insert_view(view.clone());
    });

    notify_parent_view_did_change(self.folder.clone(), vec![view.bid.clone()]);
    Ok(view)
  }

  #[tracing::instrument(level = "debug", skip(self), err)]
  pub(crate) async fn close_view(&self, view_id: &str) -> Result<(), FlowyError> {
    let view = self
      .with_folder(None, |folder| folder.views.get_view(view_id))
      .ok_or_else(|| {
        FlowyError::record_not_found().context("Can't find the view when closing the view")
      })?;
    let processor = self.get_data_processor(&view.layout)?;
    processor.close_view(view_id).await?;
    Ok(())
  }

  pub async fn create_view_data(
    &self,
    view_id: &str,
    name: &str,
    view_layout: ViewLayout,
    data: Vec<u8>,
  ) -> FlowyResult<()> {
    let user_id = self.user.user_id()?;
    let processor = self.get_data_processor(&view_layout)?;
    processor
      .create_view_with_custom_data(
        user_id,
        view_id,
        name,
        data,
        view_layout,
        HashMap::default(),
      )
      .await?;
    Ok(())
  }

  #[tracing::instrument(level = "debug", skip(self, view_id), err)]
  pub async fn get_view(&self, view_id: &str) -> FlowyResult<ViewPB> {
    let view_id = view_id.to_string();
    let folder = self.folder.lock();
    let folder = folder.as_ref().ok_or_else(folder_not_init_error)?;
    let trash_ids = folder
      .trash
      .get_all_trash()
      .into_iter()
      .map(|trash| trash.id)
      .collect::<Vec<String>>();

    if trash_ids.contains(&view_id) {
      return Err(FlowyError::record_not_found());
    }

    match folder.views.get_view(&view_id) {
      None => Err(FlowyError::record_not_found()),
      Some(mut view) => {
        view.belongings.retain(|b| !trash_ids.contains(&b.id));
        let mut view_pb: ViewPB = view.into();
        view_pb.belongings = folder
          .views
          .get_views_belong_to(&view_pb.id)
          .into_iter()
          .filter(|view| !trash_ids.contains(&view.id))
          .map(|view| view.into())
          .collect::<Vec<ViewPB>>();
        Ok(view_pb)
      },
    }
  }

  #[tracing::instrument(level = "debug", skip(self, view_id), err)]
  pub async fn delete_view(&self, view_id: &str) -> FlowyResult<()> {
    self.with_folder((), |folder| folder.views.delete_views(vec![view_id]));
    Ok(())
  }

  #[tracing::instrument(level = "debug", skip(self), err)]
  pub async fn move_view_to_trash(&self, view_id: &str) -> FlowyResult<()> {
    self.with_folder((), |folder| {
      folder.trash.add_trash(vec![TrashRecord {
        id: view_id.to_string(),
        created_at: timestamp(),
      }]);

      if let Some(view) = folder.get_current_view() {
        if view == view_id {
          folder.set_current_view("");
        }
      }
    });

    Ok(())
  }

  #[tracing::instrument(level = "debug", skip(self), err)]
  pub async fn move_view(&self, view_id: &str, from: usize, to: usize) -> FlowyResult<()> {
    let view = self.with_folder(None, |folder| {
      folder.move_view(view_id, from as u32, to as u32)
    });

    match view {
      None => tracing::error!("Couldn't find the view. It should not be empty"),
      Some(view) => {
        notify_parent_view_did_change(self.folder.clone(), vec![view.bid]);
      },
    }
    Ok(())
  }

  #[tracing::instrument(level = "debug", skip(self, bid), err)]
  pub async fn get_views_belong_to(&self, bid: &str) -> FlowyResult<Vec<View>> {
    let views = self.with_folder(vec![], |folder| folder.views.get_views_belong_to(bid));
    Ok(views)
  }

  #[tracing::instrument(level = "trace", skip(self), err)]
  pub async fn update_view_with_params(&self, params: UpdateViewParams) -> FlowyResult<View> {
    let view = self
      .folder
      .lock()
      .as_ref()
      .ok_or_else(folder_not_init_error)?
      .views
      .update_view(&params.view_id, |update| {
        update
          .set_name_if_not_none(params.name)
          .set_desc_if_not_none(params.desc)
          .done()
      });

    match view {
      None => Err(FlowyError::record_not_found()),
      Some(view) => {
        let view_pb: ViewPB = view.clone().into();
        send_notification(&view.id, FolderNotification::DidUpdateView)
          .payload(view_pb)
          .send();

        notify_parent_view_did_change(self.folder.clone(), vec![view.bid.clone()]);
        Ok(view)
      },
    }
  }

  #[tracing::instrument(level = "debug", skip(self), err)]
  pub(crate) async fn duplicate_view(&self, view_id: &str) -> Result<(), FlowyError> {
    let view = self
      .with_folder(None, |folder| folder.views.get_view(view_id))
      .ok_or_else(|| FlowyError::record_not_found().context("Can't duplicate the view"))?;

    let processor = self.get_data_processor(&view.layout)?;
    let view_data = processor.get_view_data(&view.id).await?;
    let mut ext = HashMap::new();
    if let Some(database_id) = view.database_id {
      ext.insert("database_id".to_string(), database_id);
    }
    let duplicate_params = CreateViewParams {
      belong_to_id: view.bid.clone(),
      name: format!("{} (copy)", &view.name),
      desc: view.desc,
      layout: view.layout.into(),
      initial_data: view_data.to_vec(),
      view_id: gen_view_id(),
      ext,
    };

    let _ = self.create_view_with_params(duplicate_params).await?;
    Ok(())
  }

  #[tracing::instrument(level = "trace", skip(self), err)]
  pub(crate) async fn set_current_view(&self, view_id: &str) -> Result<(), FlowyError> {
    let folder = self.folder.lock();
    let folder = folder.as_ref().ok_or_else(folder_not_init_error)?;
    folder.set_current_view(view_id);

    let workspace = folder.get_current_workspace();
    let view = folder
      .get_current_view()
      .and_then(|view_id| folder.views.get_view(&view_id));
    send_workspace_setting_notification(workspace, view);
    Ok(())
  }

  #[tracing::instrument(level = "trace", skip(self))]
  pub(crate) async fn get_current_view(&self) -> Option<ViewPB> {
    let view_id = self.with_folder(None, |folder| folder.get_current_view())?;
    self.get_view(&view_id).await.ok()
  }

  #[tracing::instrument(level = "trace", skip(self))]
  pub(crate) async fn get_all_trash(&self) -> Vec<TrashInfo> {
    self.with_folder(vec![], |folder| folder.trash.get_all_trash())
  }

  #[tracing::instrument(level = "trace", skip(self))]
  pub(crate) async fn restore_all_trash(&self) {
    self.with_folder((), |folder| {
      folder.trash.clear();
    });

    send_notification("trash", FolderNotification::DidUpdateTrash)
      .payload(RepeatedTrashPB { items: vec![] })
      .send();
  }

  #[tracing::instrument(level = "trace", skip(self))]
  pub(crate) async fn restore_trash(&self, trash_id: &str) {
    self.with_folder((), |folder| {
      folder.trash.delete_trash(vec![trash_id]);
    });
  }

  #[tracing::instrument(level = "trace", skip(self))]
  pub(crate) async fn delete_trash(&self, trash_id: &str) {
    self.with_folder((), |folder| {
      folder.trash.delete_trash(vec![trash_id]);
      folder.views.delete_views(vec![trash_id]);
    })
  }

  #[tracing::instrument(level = "trace", skip(self))]
  pub(crate) async fn delete_all_trash(&self) {
    self.with_folder((), |folder| {
      let trash = folder.trash.get_all_trash();
      folder.trash.clear();
      folder.views.delete_views(trash);
    });

    send_notification("trash", FolderNotification::DidUpdateTrash)
      .payload(RepeatedTrashPB { items: vec![] })
      .send();
  }

  fn get_data_processor(
    &self,
    view_layout: &ViewLayout,
  ) -> FlowyResult<Arc<dyn ViewDataProcessor + Send + Sync>> {
    match self.view_processors.get(view_layout) {
      None => Err(FlowyError::internal().context(format!(
        "Get data processor failed. Unknown layout type: {:?}",
        view_layout
      ))),
      Some(processor) => Ok(processor.clone()),
    }
  }
}

/// Listen on the [ViewChange] after create/delete/update events happened
fn listen_on_view_change(mut rx: ViewChangeReceiver, folder: Folder) {
  tokio::spawn(async move {
    while let Ok(value) = rx.recv().await {
      match value {
        ViewChange::DidCreateView { view } => {
          notify_parent_view_did_change(folder.clone(), vec![view.bid]);
        },
        ViewChange::DidDeleteView { views: _ } => {},
        ViewChange::DidUpdate { view } => {
          notify_parent_view_did_change(folder.clone(), vec![view.bid]);
        },
      };
    }
  });
}

/// Listen on the [TrashChange]s and notify the frontend some views were changed.
fn listen_on_trash_change(mut rx: TrashChangeReceiver, folder: Folder) {
  tokio::spawn(async move {
    while let Ok(value) = rx.recv().await {
      let mut unique_ids = HashSet::new();
      tracing::trace!("Did receive trash change: {:?}", value);
      let ids = match value {
        TrashChange::DidCreateTrash { ids } => ids,
        TrashChange::DidDeleteTrash { ids } => ids,
      };

      if let Some(folder) = folder.lock().as_ref() {
        let views = folder.views.get_views(&ids);
        for view in views {
          unique_ids.insert(view.bid);
        }

        let repeated_trash: RepeatedTrashPB = folder.trash.get_all_trash().into();
        send_notification("trash", FolderNotification::DidUpdateTrash)
          .payload(repeated_trash)
          .send();
      }

      let parent_view_ids = unique_ids.into_iter().collect();
      notify_parent_view_did_change(folder.clone(), parent_view_ids);
    }
  });
}

fn get_workspace_view_pbs(workspace_id: &str, folder: &InnerFolder) -> Vec<ViewPB> {
  let trash_ids = folder
    .trash
    .get_all_trash()
    .into_iter()
    .map(|trash| trash.id)
    .collect::<Vec<String>>();

  let mut views = folder.get_workspace_views(workspace_id);
  views.retain(|view| !trash_ids.contains(&view.id));

  views
    .into_iter()
    .map(|view| {
      let mut parent_view: ViewPB = view.into();

      // Get child views
      parent_view.belongings = folder
        .views
        .get_views_belong_to(&parent_view.id)
        .into_iter()
        .map(|view| view.into())
        .collect();
      parent_view
    })
    .collect()
}

#[tracing::instrument(level = "debug", skip(folder, parent_view_ids))]
fn notify_parent_view_did_change<T: AsRef<str>>(
  folder: Folder,
  parent_view_ids: Vec<T>,
) -> Option<()> {
  let folder = folder.lock();
  let folder = folder.as_ref()?;
  let workspace_id = folder.get_current_workspace_id()?;
  let trash_ids = folder
    .trash
    .get_all_trash()
    .into_iter()
    .map(|trash| trash.id)
    .collect::<Vec<String>>();

  for parent_view_id in parent_view_ids {
    let parent_view_id = parent_view_id.as_ref();

    // if the view's bid is equal to workspace id. Then it will fetch the current
    // workspace views. Because the the workspace is not a view stored in the views map.
    if parent_view_id == workspace_id {
      let repeated_view: RepeatedViewPB = get_workspace_view_pbs(&workspace_id, folder).into();
      send_notification(&workspace_id, FolderNotification::DidUpdateWorkspaceViews)
        .payload(repeated_view)
        .send();
    } else {
      // Parent view can contain a list of child views. Currently, only get the first level
      // child views.
      let parent_view = folder.views.get_view(parent_view_id)?;
      let mut child_views = folder.views.get_views_belong_to(parent_view_id);
      child_views.retain(|view| !trash_ids.contains(&view.id));
      event!(Level::DEBUG, child_views_count = child_views.len());

      // Post the notification
      let mut parent_view_pb: ViewPB = parent_view.into();
      parent_view_pb.belongings = child_views
        .into_iter()
        .map(|child_view| child_view.into())
        .collect::<Vec<ViewPB>>();
      send_notification(parent_view_id, FolderNotification::DidUpdateChildViews)
        .payload(parent_view_pb)
        .send();
    }
  }

  None
}

fn folder_not_init_error() -> FlowyError {
  FlowyError::internal().context("Folder not initialized")
}

#[derive(Clone)]
pub struct FolderId(String);
impl FolderId {
  pub fn new(uid: i64) -> Self {
    Self(format!("{}:folder", uid))
  }
}

impl AsRef<str> for FolderId {
  fn as_ref(&self) -> &str {
    &self.0
  }
}
#[derive(Clone, Default)]
pub struct Folder(Arc<Mutex<Option<InnerFolder>>>);

impl Deref for Folder {
  type Target = Arc<Mutex<Option<InnerFolder>>>;
  fn deref(&self) -> &Self::Target {
    &self.0
  }
}

unsafe impl Sync for Folder {}

unsafe impl Send for Folder {}
