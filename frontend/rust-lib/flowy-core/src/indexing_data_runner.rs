use crate::app_life_cycle::AppLifeCycleImpl;
use crate::full_indexed_data_provider::FullIndexedDataProvider;
use crate::indexed_data_consumer::{
  EmbeddingsInstantConsumerImpl, SearchFullIndexConsumer, SearchInstantIndexImpl,
};
use flowy_user::services::entities::{UserConfig, UserPaths};
use flowy_user_pub::entities::WorkspaceType;
use std::sync::Arc;
use std::time::Duration;
use tokio::time::interval;
use tracing::{error, info, instrument};
use uuid::Uuid;

impl AppLifeCycleImpl {
  #[instrument(skip(self, _user_config, user_paths))]
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

    self.runtime.spawn(async move {
      if let Some(instant_indexed_data_provider) = instant_indexed_data_provider {
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
        ) {
          Ok(consumer) => {
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
       "[Indexing] Starting instant indexed data provider with {} consumers for workspace: {:?}",
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
    let runtime = self.runtime.clone();
    let workspace_id_cloned = *workspace_id;
    let workspace_type_cloned = *workspace_type;
    let user_paths = user_paths.clone();

    self.runtime.spawn(async move {
      let new_provider = FullIndexedDataProvider::new(folder_manager, Arc::downgrade(&logged_user));

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
          "[Indexing] Starting full indexed data provider with {} consumers for workspace: {:?}",
          new_provider.num_consumers().await,
          workspace_id_cloned
        );
        let cloned_new_provider = new_provider.clone();
        let interval_dur = Duration::from_secs(30);
        let mut ticker = interval(interval_dur);

        runtime.spawn(async move {
          ticker.tick().await;

          const MAX_ATTEMPTS: usize = 3;
          let mut attempt = 0;
          loop {
            attempt += 1;
            match cloned_new_provider.full_index_unindexed_documents().await {
              Ok(()) => {
                info!("[Indexing] full index succeeded on attempt {}", attempt);
                break;
              },
              Err(err) if attempt < MAX_ATTEMPTS => {
                error!(
                  "[Indexing] Attempt {}/{} to index documents failed: {:?}. retrying in 5s…",
                  attempt, MAX_ATTEMPTS, err
                );
                tokio::time::sleep(Duration::from_secs(5)).await;
              },
              Err(err) => {
                error!(
                  "[Indexing] Indexing failed after {} attempts: {:?}. giving up.",
                  attempt, err
                );
                break;
              },
            }
          }
        });
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
