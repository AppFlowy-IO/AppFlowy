use crate::entities::{AppPB, CreateViewParams, UpdateViewParams, ViewDataFormatPB, WorkspacePB};
use crate::notification::{send_notification, FolderNotification};
use crate::view_ext::{
  gen_view_id, view_from_create_view_params, ViewDataProcessor, ViewDataProcessorMap,
};
use collab::plugin_impl::disk::CollabDiskPlugin;
use collab::preclude::CollabBuilder;
use collab_folder::core::{
  Folder, FolderContext, TrashChange, TrashChangeReceiver, TrashInfo, View, ViewChange,
  ViewChangeReceiver, ViewLayout,
};
use collab_persistence::CollabKV;
use flowy_error::{FlowyError, FlowyResult};
use std::collections::HashMap;
use std::fmt::Formatter;
use std::sync::Arc;
use tokio::sync::mpsc::Receiver;

pub trait FolderUser: Send + Sync {
  fn user_id(&self) -> Result<i64, FlowyError>;
  fn token(&self) -> Result<String, FlowyError>;
}

pub struct FolderManager {
  folder: Arc<Folder>,
  user: Arc<dyn FolderUser>,
  view_processors: ViewDataProcessorMap,
}

impl FolderManager {
  pub fn new(
    user: Arc<dyn FolderUser>,
    db: Arc<CollabKV>,
    view_processors: ViewDataProcessorMap,
  ) -> FlowyResult<Self> {
    let uid = user.user_id()?;
    let folder_id = FolderId::new(uid);
    let collab = CollabBuilder::new(uid, folder_id)
      .with_plugin(CollabDiskPlugin::new(db).unwrap())
      .build();

    let (view_tx, view_rx) = tokio::sync::broadcast::channel(100);
    let (trash_tx, trash_rx) = tokio::sync::broadcast::channel(100);
    let folder_context = FolderContext {
      view_change_tx: Some(view_tx),
      trash_change_tx: Some(trash_tx),
    };
    let folder = Arc::new(Folder::create(collab, folder_context));
    let manager = Self {
      user,
      folder,
      view_processors,
    };

    listen_on_trash_change(trash_rx, folder.clone());
    listen_on_view_change(view_rx, folder.clone());
    Ok(manager)
  }

  /// Called immediately after the application launched with the user sign in/sign up.
  #[tracing::instrument(level = "trace", skip(self), err)]
  pub async fn initialize(&self, user_id: &str, token: &str) -> FlowyResult<()> {
    todo!()
  }

  pub async fn get_current_workspace(&self) -> FlowyResult<WorkspacePB> {
    todo!()
  }

  pub async fn initialize_with_new_user(
    &self,
    user_id: &str,
    token: &str,
    view_data_format: ViewDataFormatPB,
  ) -> FlowyResult<()> {
    todo!()
  }

  /// Called when the current user logout
  ///
  pub async fn clear(&self, user_id: &str) {
    todo!()
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
    self.folder.views.insert_view(view.clone());
    Ok(view)
  }

  #[tracing::instrument(level = "debug", skip(self), err)]
  pub(crate) async fn close_view(&self, view_id: &str) -> Result<(), FlowyError> {
    let view = self
      .folder
      .views
      .get_view(view_id)
      .ok_or(Err(FlowyError::record_not_found()))?;
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
    match self.folder.views.get_view(view_id) {
      None => Err(FlowyError::record_not_found()),
      Some(view) => Ok(view),
    }
  }

  #[tracing::instrument(level = "debug", skip(self, view_id), err)]
  pub async fn delete_view(&self, view_id: &str) -> FlowyResult<()> {
    self.folder.views.delete_view(view_id);
    Ok(())
  }

  #[tracing::instrument(level = "debug", skip(self, view_id), err)]
  pub async fn move_view(&self, bid: &str, from: usize, to: usize) -> FlowyResult<()> {
    self
      .folder
      .belongings
      .move_belonging(bid, from as u32, to as u32);
    Ok(())
  }

  #[tracing::instrument(level = "debug", skip(self, bid), err)]
  pub async fn get_views_belong_to(&self, bid: &str) -> FlowyResult<Vec<View>> {
    let views = self.folder.views.get_views_belong_to(bid);
    Ok(views)
  }

  #[tracing::instrument(level = "debug", skip(self, params), err)]
  pub async fn update_view_with_params(&self, params: UpdateViewParams) -> FlowyResult<View> {
    let view = self.folder.views.update_view(&params.view_id, |update| {
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
      .views
      .get_view(view_id)
      .ok_or(Err(FlowyError::record_not_found()))?;

    let processor = self.get_data_processor(&view.layout)?;
    let view_data = processor.get_view_data(&view.id).await?;
    let duplicate_params = CreateViewParams {
      belong_to_id: view.bid.clone(),
      name: format!("{} (copy)", &view.name),
      desc: view.desc,
      layout: view.layout.into(),
      initial_data: view_data.to_vec(),
      view_id: gen_view_id(),
      ext: Default::default(),
    };

    let _ = self.create_view_with_params(duplicate_params).await?;
    Ok(())
  }

  #[tracing::instrument(level = "trace", skip(self), err)]
  pub(crate) fn set_latest_view(&self, view_id: &str) -> Result<(), FlowyError> {
    self.folder.set_current_view(view_id);
    Ok(())
  }

  #[tracing::instrument(level = "trace", skip(self), err)]
  pub(crate) fn get_latest_view(&self) -> Option<View> {
    let view_id = self.folder.get_current_view()?;
    self.folder.views.get_view(&view_id)
  }

  #[tracing::instrument(level = "trace", skip(self), err)]
  pub(crate) fn get_trash(&self) -> Vec<TrashInfo> {
    self.folder.trash.get_all_trash()
  }

  #[tracing::instrument(level = "trace", skip(self), err)]
  pub(crate) fn restore_all_trash(&self) {
    self.folder.trash.clear();
  }

  #[tracing::instrument(level = "trace", skip(self), err)]
  pub(crate) fn restore_trash(&self, trash_id: &str) {
    self.folder.trash.remove_trash(trash_id);
  }

  #[tracing::instrument(level = "trace", skip(self), err)]
  pub(crate) fn delete_trash(&self, trash_id: &str) {
    self.folder.trash.remove_trash(trash_id);
  }

  fn get_data_processor(
    &self,
    view_layout: &ViewLayout,
  ) -> FlowyResult<Arc<dyn ViewDataProcessor + Send + Sync>> {
    match self.view_processors.get(&view_layout) {
      None => Err(FlowyError::internal().context(format!(
        "Get data processor failed. Unknown layout type: {:?}",
        view_layout
      ))),
      Some(processor) => Ok(processor.clone()),
    }
  }
}

fn listen_on_view_change(mut rx: ViewChangeReceiver, folder: Arc<Folder>) {
  tokio::spawn(async move {
    while let Ok(value) = rx.recv().await {
      let view = match value {
        ViewChange::DidCreateView { view } => view,
        ViewChange::DidDeleteView { view } => view,
        ViewChange::DidUpdate { view } => view,
      };
      let bid = view.bid.clone();
      notify_view_did_change(folder.clone(), &bid);
    }
  });
}

fn listen_on_trash_change(mut rx: TrashChangeReceiver, folder: Arc<Folder>) {
  tokio::spawn(async move {
    while let Ok(value) = rx.recv().await {
      match value {
        TrashChange::DidCreateTrash { ids } => {},
        TrashChange::DidDeleteTrash { ids } => {},
      }
    }
  });
}

fn notify_view_did_change(folder: Arc<Folder>, view_id: &str) {
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

  let app = AppPB {
    id: view_id.to_string(),
    workspace_id: "".to_string(),
    name: "".to_string(),
    desc: "".to_string(),
    belongings: views.into(),
    version: 0,
    modified_time: 0,
    create_time: 0,
  };

  send_notification(&bid, FolderNotification::DidUpdateApp)
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
