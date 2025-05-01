use crate::app_life_cycle::AppLifeCycleImpl;
use crate::full_indexed_data_provider::FullIndexedDataProvider;
use crate::indexed_data_consumer::{
  get_or_init_document_tantivy_state, EmbeddingsInstantConsumerImpl, SearchFullIndexConsumer,
  SearchInstantIndexImpl,
};
use flowy_folder::manager::FolderManager;
use flowy_user::services::entities::{UserConfig, UserPaths};
use flowy_user_pub::entities::WorkspaceType;
use std::sync::{Arc, Weak};
use std::time::Duration;
use tokio::time::timeout;
use tracing::{error, info, instrument, warn};
use uuid::Uuid;

impl AppLifeCycleImpl {
  async fn wait_for_folder_ready(folder_manager: &Weak<FolderManager>) -> bool {
    let mut folder_ready_notify = match folder_manager.upgrade() {
      Some(folder) => folder.subscribe_folder_ready_notifier(),
      None => {
        warn!("[Indexing] No folder manager available, skipping indexed data provider");
        return false;
      },
    };

    // Check if the folder is already ready
    if *folder_ready_notify.borrow() {
      tokio::time::sleep(Duration::from_secs(5)).await;
      return true;
    }

    // Wait for the folder to become ready with timeout
    match timeout(Duration::from_secs(20), folder_ready_notify.changed()).await {
      Err(_) => {
        warn!("[Indexing] Timeout waiting for folder ready");
        false
      },
      Ok(_) => {
        let is_ready = *folder_ready_notify.borrow();
        if is_ready {
          // We don't want to start indexing immediately after the folder is ready
          tokio::time::sleep(Duration::from_secs(5)).await;
        }

        is_ready
      },
    }
  }

  #[instrument(skip_all)]
  pub(crate) async fn start_instant_indexed_data_provider(
    &self,
    user_id: i64,
    workspace_id: &Uuid,
    workspace_type: &WorkspaceType,
    _user_config: &UserConfig,
    user_paths: &UserPaths,
  ) {
    let instant_indexed_data_provider = self.instant_indexed_data_provider.clone();
    let runtime = self.runtime.clone();
    let workspace_id_cloned = *workspace_id;
    let workspace_type_cloned = *workspace_type;
    let user_paths = user_paths.clone();
    let folder_manager = self.folder_manager.clone();
    let weak_logged_user = Arc::downgrade(&self.logged_user);

    self.runtime.spawn(async move {
      if !Self::wait_for_folder_ready(&folder_manager).await {
        return;
      }

      info!(
        "[Indexing] Starting instant indexed data provider for workspace: {:?}",
        workspace_id_cloned
      );

      if let Some(instant_indexed_data_provider) = instant_indexed_data_provider {
        instant_indexed_data_provider.clear_consumers().await;

        // Add embedding consumer when workspace type is local
        #[cfg(any(target_os = "linux", target_os = "macos", target_os = "windows"))]
        {
          if workspace_type_cloned.is_local() {
            instant_indexed_data_provider
              .register_consumer(Box::new(EmbeddingsInstantConsumerImpl::new()))
              .await;
          }
        }

        match SearchInstantIndexImpl::new(
          &workspace_id_cloned,
          user_paths.tanvity_index_path(user_id),
          folder_manager,
          weak_logged_user,
        )
        .await
        {
          Ok(consumer) => {
            consumer.refresh_search_index();
            instant_indexed_data_provider
              .register_consumer(Box::new(consumer))
              .await;
          },
          Err(err) => error!(
            "[Indexing] Failed to create SearchInstantIndexImpl: {:?}",
            err
          ),
        }

        if instant_indexed_data_provider.num_consumers().await > 0 {
          info!(
            "[Indexing] instant indexed data provider with {} consumers for workspace: {:?}",
            instant_indexed_data_provider.num_consumers().await,
            workspace_id_cloned
          );
          if let Err(err) = instant_indexed_data_provider
            .spawn_instant_indexed_provider(&runtime.inner)
            .await
          {
            error!(
              "[Indexing] Failed to spawn instant indexed data provider: {:?}",
              err
            );
          }
        }
      } else {
        info!("[Indexing] No instant indexed data provider to start");
      }
    });
  }

  pub(crate) async fn create_thanvity_state_if_not_exists(
    &self,
    uid: i64,
    workspace_id: &Uuid,
    user_paths: &UserPaths,
  ) {
    let data_path = user_paths.tanvity_index_path(uid);
    let _ = get_or_init_document_tantivy_state(*workspace_id, data_path);
  }

  #[instrument(skip(self, _user_config, user_paths))]
  pub(crate) async fn start_full_indexed_data_provider(
    &self,
    uid: i64,
    workspace_id: &Uuid,
    workspace_type: &WorkspaceType,
    _user_config: &UserConfig,
    user_paths: &UserPaths,
  ) {
    let folder_manager = self.folder_manager.clone();
    let logged_user = self.logged_user.clone();
    let full_indexed_data_provider = self.full_indexed_data_provider.clone();
    let workspace_id_cloned = *workspace_id;
    let workspace_type_cloned = *workspace_type;
    let user_paths = user_paths.clone();
    let full_indexed_finish_sender = self.full_indexed_finish_sender.clone();
    full_indexed_finish_sender.send_replace(false);

    self.runtime.spawn(async move {
      if !Self::wait_for_folder_ready(&folder_manager).await {
        return;
      }

      info!(
        "[Indexing] Starting full indexed data provider for workspace: {:?}",
        workspace_id_cloned
      );

      let new_provider = FullIndexedDataProvider::new(
        workspace_id_cloned,
        folder_manager,
        Arc::downgrade(&logged_user),
      );
      #[cfg(any(target_os = "linux", target_os = "macos", target_os = "windows"))]
      {
        if workspace_type_cloned.is_local() {
          new_provider
            .register_full_indexed_consumer(Box::new(
              crate::indexed_data_consumer::EmbeddingFullIndexConsumer,
            ))
            .await;
        }
      }

      match SearchFullIndexConsumer::new(&workspace_id_cloned, user_paths.tanvity_index_path(uid)) {
        Ok(consumer) => {
          new_provider
            .register_full_indexed_consumer(Box::new(consumer))
            .await;
        },
        Err(err) => error!(
          "[Indexing] Failed to create SearchFullIndexConsumer: {:?}",
          err
        ),
      }

      if new_provider.num_consumers().await > 0 {
        info!(
          "[Indexing] full indexed data provider with {} consumers for workspace: {:?}",
          new_provider.num_consumers().await,
          workspace_id_cloned
        );
        match new_provider.full_index_unindexed_documents().await {
          Ok(()) => {
            info!("[Indexing] full index succeeded");
          },
          Err(err) => {
            error!("[Indexing] full index failed {:?}", err);
          },
        }
        full_indexed_finish_sender.send_replace(true);
        info!("[Indexing] full indexed data provider stopped");
      }

      if let Some(provider) = full_indexed_data_provider.upgrade() {
        let old = provider.write().await.replace(new_provider);
        if let Some(old) = old {
          old.cancel_indexing();
        }
      } else {
        info!("[Indexing] No full indexed data provider to start");
      }
    });
  }
}
