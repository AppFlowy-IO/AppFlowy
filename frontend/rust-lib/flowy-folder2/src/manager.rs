use crate::entities::{AppPB, CreateViewParams, CreateWorkspaceParams, UpdateViewParams};
use crate::notification::{send_notification, FolderNotification};
use crate::user_default::{gen_workspace_id, DefaultFolderBuilder};
use crate::view_ext::{
  gen_view_id, view_from_create_view_params, ViewDataProcessor, ViewDataProcessorMap,
};

use collab::plugin_impl::disk::CollabDiskPlugin;
use collab::preclude::CollabBuilder;
use collab_folder::core::{
  Folder as InnerFolder, FolderContext, TrashChange, TrashChangeReceiver, TrashInfo, TrashItem,
  View, ViewChange, ViewChangeReceiver, ViewLayout, Workspace,
};
use collab_persistence::CollabKV;
use flowy_error::{FlowyError, FlowyResult};
use lib_infra::util::timestamp;
use parking_lot::Mutex;
use std::collections::HashMap;
use std::ops::Deref;
use std::sync::Arc;

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
    let uid = user.user_id()?;
    // let db = user.kv_db()?;

    let folder_id = FolderId::new(uid);
    let collab = CollabBuilder::new(uid, folder_id)
      // .with_plugin(CollabDiskPlugin::new(db).unwrap())
      .build();

    let (view_tx, view_rx) = tokio::sync::broadcast::channel(100);
    let (trash_tx, trash_rx) = tokio::sync::broadcast::channel(100);
    let folder_context = FolderContext {
      view_change_tx: Some(view_tx),
      trash_change_tx: Some(trash_tx),
    };
    let folder = Folder(Arc::new(Mutex::new(InnerFolder::create(
      collab,
      folder_context,
    ))));
    listen_on_trash_change(trash_rx, folder.clone());
    listen_on_view_change(view_rx, folder.clone());
    let manager = Self {
      user,
      folder,
      view_processors,
    };

    Ok(manager)
  }

  /// Called immediately after the application launched with the user sign in/sign up.
  #[tracing::instrument(level = "trace", skip(self), err)]
  pub async fn initialize(&self, user_id: &str, build_default_folder: bool) -> FlowyResult<()> {
    let db = self.user.kv_db()?;
    let disk_plugin =
      Arc::new(CollabDiskPlugin::new(db).map_err(|err| FlowyError::internal().context(err))?);
    self.folder.lock().add_plugins(vec![disk_plugin]);

    if build_default_folder {
      DefaultFolderBuilder::build(self.folder.clone());
    }
    Ok(())
  }

  pub async fn get_current_workspace(&self) -> FlowyResult<Workspace> {
    match self.folder.lock().get_current_workspace() {
      None => Err(FlowyError::record_not_found().context("Can not find the workspace")),
      Some(workspace) => Ok(workspace),
    }
  }

  pub async fn get_current_workspace_views(&self) -> FlowyResult<Vec<View>> {
    let views = self.folder.lock().get_views_belong_to_current_workspace();
    Ok(views)
  }

  pub async fn get_workspace_views<F>(
    &self,
    workspace_id: &str,
    filter: F,
  ) -> FlowyResult<Vec<View>>
  where
    F: Fn(&ViewLayout) -> bool,
  {
    Ok(
      self
        .folder
        .lock()
        .views
        .get_views_belong_to(workspace_id)
        .into_iter()
        .filter(|view| filter(&view.layout))
        .collect::<Vec<_>>(),
    )
  }

  pub async fn initialize_with_new_user(&self, user_id: &str) -> FlowyResult<()> {
    self.initialize(user_id, true).await?;
    Ok(())
  }

  /// Called when the current user logout
  ///
  pub async fn clear(&self, user_id: &str) {
    todo!()
  }

  pub async fn create_workspace(&self, params: CreateWorkspaceParams) -> FlowyResult<Workspace> {
    let workspace = Workspace {
      id: gen_workspace_id(),
      name: params.name,
      belongings: Default::default(),
      created_at: timestamp(),
    };
    let folder = self.folder.lock();
    folder.workspaces.create_workspace(workspace.clone());
    folder.set_current_workspace(&workspace.id);
    Ok(workspace)
  }

  pub async fn open_workspace(&self, workspace_id: &str) -> FlowyResult<Workspace> {
    let folder = self.folder.lock();
    let workspace = folder
      .workspaces
      .get_workspace(workspace_id)
      .ok_or_else(|| FlowyError::record_not_found().context("Can't open not existing workspace"))?;
    folder.set_current_workspace(workspace_id);

    Ok(workspace)
  }

  pub async fn get_workspace(&self, workspace_id: &str) -> Option<Workspace> {
    self.folder.lock().workspaces.get_workspace(workspace_id)
  }

  pub async fn get_all_workspaces(&self) -> Vec<Workspace> {
    self.folder.lock().workspaces.get_all_workspaces()
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
    self.folder.lock().views.insert_view(view.clone());
    Ok(view)
  }

  #[tracing::instrument(level = "debug", skip(self), err)]
  pub(crate) async fn close_view(&self, view_id: &str) -> Result<(), FlowyError> {
    let view =
      self.folder.lock().views.get_view(view_id).ok_or(
        FlowyError::record_not_found().context("Can't find the view when closing the view"),
      )?;
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
  pub async fn get_view(&self, view_id: &str) -> FlowyResult<View> {
    match self.folder.lock().views.get_view(view_id) {
      None => Err(FlowyError::record_not_found()),
      Some(view) => Ok(view),
    }
  }

  #[tracing::instrument(level = "debug", skip(self, view_id), err)]
  pub async fn delete_view(&self, view_id: &str) -> FlowyResult<()> {
    self.folder.lock().views.delete_views(vec![view_id]);
    Ok(())
  }

  #[tracing::instrument(level = "debug", skip(self, view_id), err)]
  pub async fn move_view_to_trash(&self, view_id: &str) -> FlowyResult<()> {
    let folder = self.folder.lock();
    folder.trash.add_trash(TrashItem {
      id: view_id.to_string(),
      created_at: timestamp(),
    });

    if let Some(view) = folder.get_current_view() {
      if view == view_id {
        folder.set_current_view("");
      }
    }

    Ok(())
  }

  #[tracing::instrument(level = "debug", skip(self), err)]
  pub async fn move_view(&self, bid: &str, from: usize, to: usize) -> FlowyResult<()> {
    self
      .folder
      .lock()
      .belongings
      .move_belonging(bid, from as u32, to as u32);
    Ok(())
  }

  #[tracing::instrument(level = "debug", skip(self, bid), err)]
  pub async fn get_views_belong_to(&self, bid: &str) -> FlowyResult<Vec<View>> {
    let views = self.folder.lock().views.get_views_belong_to(bid);
    Ok(views)
  }

  #[tracing::instrument(level = "debug", skip(self, params), err)]
  pub async fn update_view_with_params(&self, params: UpdateViewParams) -> FlowyResult<View> {
    let view = self
      .folder
      .lock()
      .views
      .update_view(&params.view_id, |update| {
        update
          .set_name_if_not_none(params.name)
          .set_desc_if_not_none(params.desc)
          .done()
      });
    match view {
      None => Err(FlowyError::record_not_found()),
      Some(view) => Ok(view),
    }
  }

  #[tracing::instrument(level = "debug", skip(self), err)]
  pub(crate) async fn duplicate_view(&self, view_id: &str) -> Result<(), FlowyError> {
    let view = self
      .folder
      .lock()
      .views
      .get_view(view_id)
      .ok_or(FlowyError::record_not_found().context("Can't duplicate the view"))?;

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
    self.folder.lock().set_current_view(view_id);
    Ok(())
  }

  #[tracing::instrument(level = "trace", skip(self))]
  pub(crate) async fn get_current_view(&self) -> Option<View> {
    let view_id = self.folder.lock().get_current_view()?;
    self.folder.lock().views.get_view(&view_id)
  }

  #[tracing::instrument(level = "trace", skip(self))]
  pub(crate) async fn get_all_trash(&self) -> Vec<TrashInfo> {
    self.folder.lock().trash.get_all_trash()
  }

  #[tracing::instrument(level = "trace", skip(self))]
  pub(crate) async fn restore_all_trash(&self) {
    self.folder.lock().trash.clear();
  }

  #[tracing::instrument(level = "trace", skip(self))]
  pub(crate) async fn restore_trash(&self, trash_id: &str) {
    self.folder.lock().trash.delete_trash(trash_id);
  }

  #[tracing::instrument(level = "trace", skip(self))]
  pub(crate) async fn delete_trash(&self, trash_id: &str) {
    let folder = self.folder.lock();
    folder.trash.delete_trash(trash_id);
    folder.views.delete_views(vec![trash_id]);
  }

  #[tracing::instrument(level = "trace", skip(self))]
  pub(crate) async fn delete_all_trash(&self) {
    let folder = self.folder.lock();
    let trash = folder.trash.get_all_trash();
    folder.trash.clear();
    folder.views.delete_views(trash);
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

fn listen_on_view_change(mut rx: ViewChangeReceiver, folder: Folder) {
  tokio::spawn(async move {
    while let Ok(value) = rx.recv().await {
      match value {
        ViewChange::DidCreateView { view } => {
          let bid = view.bid.clone();
          notify_view_did_change(folder.clone(), &bid).await;
        },
        ViewChange::DidDeleteView { views } => {},
        ViewChange::DidUpdate { view } => {
          let bid = view.bid.clone();
          notify_view_did_change(folder.clone(), &bid).await;
        },
      };
    }
  });
}

fn listen_on_trash_change(mut rx: TrashChangeReceiver, folder: Folder) {
  tokio::spawn(async move {
    while let Ok(value) = rx.recv().await {
      match value {
        TrashChange::DidCreateTrash { ids } => {},
        TrashChange::DidDeleteTrash { ids } => {},
      }
    }
  });
}

async fn notify_view_did_change(folder: Folder, view_id: &str) {
  let folder = folder.lock();
  let trash_ids = folder
    .trash
    .get_all_trash()
    .into_iter()
    .map(|trash| trash.id)
    .collect::<Vec<String>>();

  let views = folder
    .views
    .get_views_belong_to(view_id)
    .into_iter()
    .filter(|view| !trash_ids.contains(&view.id))
    .collect::<Vec<View>>();
  drop(folder);

  let app = AppPB {
    id: view_id.to_string(),
    workspace_id: "".to_string(),
    name: "".to_string(),
    belongings: views.into(),
    create_time: 0,
  };

  send_notification(&view_id, FolderNotification::DidUpdateApp)
    .payload(app)
    .send();
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
#[derive(Clone)]
pub struct Folder(Arc<Mutex<InnerFolder>>);

impl Deref for Folder {
  type Target = Arc<Mutex<InnerFolder>>;
  fn deref(&self) -> &Self::Target {
    &self.0
  }
}

unsafe impl Sync for Folder {}

unsafe impl Send for Folder {}
