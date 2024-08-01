use appflowy_local_ai::ai_ops::{LocalAITranslateItem, LocalAITranslateRowData};
use collab_integrate::collab_builder::AppFlowyCollabBuilder;
use collab_integrate::CollabKVDB;
use flowy_ai::ai_manager::AIManager;
use flowy_database2::{DatabaseManager, DatabaseUser};
use flowy_database_pub::cloud::{
  DatabaseAIService, DatabaseCloudService, SummaryRowContent, TranslateRowContent,
  TranslateRowResponse,
};
use flowy_error::FlowyError;
use flowy_user::services::authenticate_user::AuthenticateUser;
use lib_infra::async_trait::async_trait;
use lib_infra::priority_task::TaskDispatcher;
use std::sync::{Arc, Weak};
use tokio::sync::RwLock;

pub struct DatabaseDepsResolver();

impl DatabaseDepsResolver {
  pub async fn resolve(
    authenticate_user: Weak<AuthenticateUser>,
    task_scheduler: Arc<RwLock<TaskDispatcher>>,
    collab_builder: Arc<AppFlowyCollabBuilder>,
    cloud_service: Arc<dyn DatabaseCloudService>,
    ai_service: Arc<dyn DatabaseAIService>,
    ai_manager: Arc<AIManager>,
  ) -> Arc<DatabaseManager> {
    let user = Arc::new(DatabaseUserImpl(authenticate_user));
    Arc::new(DatabaseManager::new(
      user,
      task_scheduler,
      collab_builder,
      cloud_service,
      Arc::new(DatabaseAIServiceMiddleware {
        ai_manager,
        ai_service,
      }),
    ))
  }
}

struct DatabaseAIServiceMiddleware {
  ai_manager: Arc<AIManager>,
  ai_service: Arc<dyn DatabaseAIService>,
}
#[async_trait]
impl DatabaseAIService for DatabaseAIServiceMiddleware {
  async fn summary_database_row(
    &self,
    workspace_id: &str,
    object_id: &str,
    summary_row: SummaryRowContent,
  ) -> Result<String, FlowyError> {
    if self.ai_manager.local_ai_controller.is_running() {
      self
        .ai_manager
        .local_ai_controller
        .summary_database_row(summary_row)
        .await
        .map_err(|err| FlowyError::local_ai().with_context(err))
    } else {
      self
        .ai_service
        .summary_database_row(workspace_id, object_id, summary_row)
        .await
    }
  }

  async fn translate_database_row(
    &self,
    workspace_id: &str,
    translate_row: TranslateRowContent,
    language: &str,
  ) -> Result<TranslateRowResponse, FlowyError> {
    if self.ai_manager.local_ai_controller.is_running() {
      let data = LocalAITranslateRowData {
        cells: translate_row
          .into_iter()
          .map(|row| LocalAITranslateItem {
            title: row.title,
            content: row.content,
          })
          .collect(),
        language: language.to_string(),
        include_header: false,
      };
      let resp = self
        .ai_manager
        .local_ai_controller
        .translate_database_row(data)
        .await
        .map_err(|err| FlowyError::local_ai().with_context(err))?;

      Ok(TranslateRowResponse { items: resp.items })
    } else {
      self
        .ai_service
        .translate_database_row(workspace_id, translate_row, language)
        .await
    }
  }
}

struct DatabaseUserImpl(Weak<AuthenticateUser>);
impl DatabaseUserImpl {
  fn upgrade_user(&self) -> Result<Arc<AuthenticateUser>, FlowyError> {
    let user = self
      .0
      .upgrade()
      .ok_or(FlowyError::internal().with_context("Unexpected error: UserSession is None"))?;
    Ok(user)
  }
}

impl DatabaseUser for DatabaseUserImpl {
  fn user_id(&self) -> Result<i64, FlowyError> {
    self.upgrade_user()?.user_id()
  }

  fn collab_db(&self, uid: i64) -> Result<Weak<CollabKVDB>, FlowyError> {
    self.upgrade_user()?.get_collab_db(uid)
  }

  fn workspace_id(&self) -> Result<String, FlowyError> {
    self.upgrade_user()?.workspace_id()
  }

  fn workspace_database_object_id(&self) -> Result<String, FlowyError> {
    self.upgrade_user()?.workspace_database_object_id()
  }
}
