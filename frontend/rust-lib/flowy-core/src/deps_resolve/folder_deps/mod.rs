mod folder_deps_chat_impl;
mod folder_deps_database_impl;
mod folder_deps_doc_impl;

use crate::server_layer::ServerProvider;
use collab_entity::{CollabType, EncodedCollab};
use collab_integrate::collab_builder::AppFlowyCollabBuilder;
use collab_integrate::CollabKVDB;
use flowy_ai::ai_manager::AIManager;
use flowy_database2::DatabaseManager;
use flowy_document::manager::DocumentManager;
use flowy_error::{internal_error, FlowyError, FlowyResult};
use flowy_folder::entities::UpdateViewParams;
use flowy_folder::manager::{FolderManager, FolderUser};
use flowy_folder::ViewLayout;
use flowy_search::folder::indexer::FolderIndexManagerImpl;
use flowy_sqlite::kv::KVStorePreferences;
use flowy_user::services::authenticate_user::AuthenticateUser;
use flowy_user::services::data_import::load_collab_by_object_id;
use std::sync::{Arc, Weak};

use crate::deps_resolve::folder_deps::folder_deps_chat_impl::ChatFolderOperation;
use crate::deps_resolve::folder_deps::folder_deps_database_impl::DatabaseFolderOperation;
use crate::deps_resolve::folder_deps::folder_deps_doc_impl::DocumentFolderOperation;
use collab_plugins::local_storage::kv::KVTransactionDB;
use flowy_folder_pub::query::{FolderQueryService, FolderService, FolderViewEdit, QueryCollab};
use lib_infra::async_trait::async_trait;

pub struct FolderDepsResolver();
#[allow(clippy::too_many_arguments)]
impl FolderDepsResolver {
  pub async fn resolve(
    authenticate_user: Weak<AuthenticateUser>,
    collab_builder: Arc<AppFlowyCollabBuilder>,
    server_provider: Arc<ServerProvider>,
    folder_indexer: Arc<FolderIndexManagerImpl>,
    store_preferences: Arc<KVStorePreferences>,
  ) -> Arc<FolderManager> {
    let user: Arc<dyn FolderUser> = Arc::new(FolderUserImpl {
      authenticate_user: authenticate_user.clone(),
    });

    Arc::new(
      FolderManager::new(
        user.clone(),
        collab_builder,
        server_provider.clone(),
        folder_indexer,
        store_preferences,
      )
      .unwrap(),
    )
  }
}

pub fn register_handlers(
  folder_manager: &Arc<FolderManager>,
  document_manager: Arc<DocumentManager>,
  database_manager: Arc<DatabaseManager>,
  chat_manager: Arc<AIManager>,
) {
  let document_folder_operation = Arc::new(DocumentFolderOperation(document_manager));
  folder_manager.register_operation_handler(ViewLayout::Document, document_folder_operation);

  let database_folder_operation = Arc::new(DatabaseFolderOperation(database_manager));
  let chat_folder_operation = Arc::new(ChatFolderOperation(chat_manager));
  folder_manager.register_operation_handler(ViewLayout::Board, database_folder_operation.clone());
  folder_manager.register_operation_handler(ViewLayout::Grid, database_folder_operation.clone());
  folder_manager.register_operation_handler(ViewLayout::Calendar, database_folder_operation);
  folder_manager.register_operation_handler(ViewLayout::Chat, chat_folder_operation);
}

struct FolderUserImpl {
  authenticate_user: Weak<AuthenticateUser>,
}

impl FolderUserImpl {
  fn upgrade_user(&self) -> Result<Arc<AuthenticateUser>, FlowyError> {
    let user = self
      .authenticate_user
      .upgrade()
      .ok_or(FlowyError::internal().with_context("Unexpected error: UserSession is None"))?;
    Ok(user)
  }
}

impl FolderUser for FolderUserImpl {
  fn user_id(&self) -> Result<i64, FlowyError> {
    self.upgrade_user()?.user_id()
  }

  fn workspace_id(&self) -> Result<String, FlowyError> {
    self.upgrade_user()?.workspace_id()
  }

  fn collab_db(&self, uid: i64) -> Result<Weak<CollabKVDB>, FlowyError> {
    self.upgrade_user()?.get_collab_db(uid)
  }

  fn is_folder_exist_on_disk(&self, uid: i64, workspace_id: &str) -> FlowyResult<bool> {
    self.upgrade_user()?.is_collab_on_disk(uid, workspace_id)
  }
}

#[derive(Clone)]
pub struct FolderServiceImpl {
  folder_manager: Weak<FolderManager>,
  user: Arc<dyn FolderUser>,
}
impl FolderService for FolderServiceImpl {}

impl FolderServiceImpl {
  pub fn new(
    folder_manager: Weak<FolderManager>,
    authenticate_user: Weak<AuthenticateUser>,
  ) -> Self {
    let user: Arc<dyn FolderUser> = Arc::new(FolderUserImpl { authenticate_user });
    Self {
      folder_manager,
      user,
    }
  }
}

#[async_trait]
impl FolderViewEdit for FolderServiceImpl {
  async fn set_view_title_if_empty(&self, view_id: &str, title: &str) -> FlowyResult<()> {
    if title.is_empty() {
      return Ok(());
    }

    if let Some(folder_manager) = self.folder_manager.upgrade() {
      if let Ok(view) = folder_manager.get_view(view_id).await {
        if view.name.is_empty() {
          let title = if title.len() > 50 {
            title.chars().take(50).collect()
          } else {
            title.to_string()
          };

          folder_manager
            .update_view_with_params(UpdateViewParams {
              view_id: view_id.to_string(),
              name: Some(title),
              desc: None,
              thumbnail: None,
              layout: None,
              is_favorite: None,
              extra: None,
            })
            .await?;
        }
      }
    }
    Ok(())
  }
}

#[async_trait]
impl FolderQueryService for FolderServiceImpl {
  async fn get_surrounding_view_ids_with_view_layout(
    &self,
    parent_view_id: &str,
    view_layout: ViewLayout,
  ) -> Vec<String> {
    let folder_manager = match self.folder_manager.upgrade() {
      Some(folder_manager) => folder_manager,
      None => return vec![],
    };

    if let Ok(view) = folder_manager.get_view(parent_view_id).await {
      if view.space_info().is_some() {
        return vec![];
      }
    }

    match folder_manager
      .get_untrashed_views_belong_to(parent_view_id)
      .await
    {
      Ok(views) => {
        let mut children = views
          .into_iter()
          .filter_map(|child| {
            if child.layout == view_layout {
              Some(child.id.clone())
            } else {
              None
            }
          })
          .collect::<Vec<_>>();
        children.push(parent_view_id.to_string());
        children
      },
      _ => vec![],
    }
  }

  async fn get_collab(&self, object_id: &str, collab_type: CollabType) -> Option<QueryCollab> {
    let encode_collab = get_encoded_collab_v1_from_disk(&self.user, object_id, collab_type.clone())
      .await
      .ok();

    encode_collab.map(|encoded_collab| QueryCollab {
      collab_type,
      encoded_collab,
    })
  }
}

#[inline]
async fn get_encoded_collab_v1_from_disk(
  user: &Arc<dyn FolderUser>,
  view_id: &str,
  collab_type: CollabType,
) -> Result<EncodedCollab, FlowyError> {
  let workspace_id = user.workspace_id()?;
  let uid = user
    .user_id()
    .map_err(|e| e.with_context("unable to get the uid: {}"))?;

  // get the collab db
  let collab_db = user
    .collab_db(uid)
    .map_err(|e| e.with_context("unable to get the collab"))?;
  let collab_db = collab_db.upgrade().ok_or_else(|| {
    FlowyError::internal().with_context(
      "The collab db has been dropped, indicating that the user has switched to a new account",
    )
  })?;
  let collab_read_txn = collab_db.read_txn();
  let collab =
    load_collab_by_object_id(uid, &collab_read_txn, &workspace_id, view_id).map_err(|e| {
      FlowyError::internal().with_context(format!("load document collab failed: {}", e))
    })?;

  tokio::task::spawn_blocking(move || {
    let data = collab
      .encode_collab_v1(|collab| collab_type.validate_require_data(collab))
      .map_err(|e| {
        FlowyError::internal().with_context(format!("encode document collab failed: {}", e))
      })?;
    Ok::<_, FlowyError>(data)
  })
  .await
  .map_err(internal_error)?
}
