use crate::manager::{ViewDataProcessor, ViewDataProcessorMap};
use crate::{
    dart_notification::{send_dart_notification, FolderNotification},
    entities::{
        trash::{RepeatedTrashId, TrashType},
        view::{CreateViewParams, RepeatedView, UpdateViewParams, View, ViewId},
    },
    errors::{FlowyError, FlowyResult},
    event_map::{FolderCouldServiceV1, WorkspaceUser},
    services::{
        persistence::{FolderPersistence, FolderPersistenceTransaction, ViewChangeset},
        TrashController, TrashEvent,
    },
};
use bytes::Bytes;
use flowy_collaboration::entities::text_block_info::TextBlockId;
use flowy_database::kv::KV;
use flowy_folder_data_model::entities::view::ViewDataType;
use futures::{FutureExt, StreamExt};
use lib_infra::uuid;
use std::{collections::HashSet, sync::Arc};

const LATEST_VIEW_ID: &str = "latest_view_id";

pub(crate) struct ViewController {
    user: Arc<dyn WorkspaceUser>,
    cloud_service: Arc<dyn FolderCouldServiceV1>,
    persistence: Arc<FolderPersistence>,
    trash_controller: Arc<TrashController>,
    data_processors: ViewDataProcessorMap,
}

impl ViewController {
    pub(crate) fn new(
        user: Arc<dyn WorkspaceUser>,
        persistence: Arc<FolderPersistence>,
        cloud_service: Arc<dyn FolderCouldServiceV1>,
        trash_controller: Arc<TrashController>,
        data_processors: ViewDataProcessorMap,
    ) -> Self {
        Self {
            user,
            cloud_service,
            persistence,
            trash_controller,
            data_processors,
        }
    }

    pub(crate) fn initialize(&self) -> Result<(), FlowyError> {
        self.listen_trash_can_event();
        Ok(())
    }

    #[tracing::instrument(level = "trace", skip(self, params), fields(name = %params.name), err)]
    pub(crate) async fn create_view_from_params(&self, mut params: CreateViewParams) -> Result<View, FlowyError> {
        let processor = self.get_data_processor(&params.data_type)?;
        let user_id = self.user.user_id()?;
        if params.data.is_empty() {
            let view_data = processor.create_default_view(&user_id, &params.view_id).await?;
            params.data = view_data.to_vec();
        } else {
            let delta_data = processor
                .process_create_view_data(&user_id, &params.view_id, params.data.clone())
                .await?;
            let _ = self
                .create_view(&params.view_id, params.data_type.clone(), delta_data)
                .await?;
        };

        let view = self.create_view_on_server(params).await?;
        let _ = self.create_view_on_local(view.clone()).await?;
        Ok(view)
    }

    #[tracing::instrument(level = "debug", skip(self, view_id, delta_data), err)]
    pub(crate) async fn create_view(
        &self,
        view_id: &str,
        data_type: ViewDataType,
        delta_data: Bytes,
    ) -> Result<(), FlowyError> {
        if delta_data.is_empty() {
            return Err(FlowyError::internal().context("The content of the view should not be empty"));
        }
        let user_id = self.user.user_id()?;
        let processor = self.get_data_processor(&data_type)?;
        let _ = processor.create_container(&user_id, view_id, delta_data).await?;
        Ok(())
    }

    pub(crate) async fn create_view_on_local(&self, view: View) -> Result<(), FlowyError> {
        let trash_controller = self.trash_controller.clone();
        self.persistence
            .begin_transaction(|transaction| {
                let belong_to_id = view.belong_to_id.clone();
                let _ = transaction.create_view(view)?;
                let _ = notify_views_changed(&belong_to_id, trash_controller, &transaction)?;
                Ok(())
            })
            .await
    }

    #[tracing::instrument(skip(self, view_id), fields(view_id = %view_id.value), err)]
    pub(crate) async fn read_view(&self, view_id: ViewId) -> Result<View, FlowyError> {
        let view = self
            .persistence
            .begin_transaction(|transaction| {
                let view = transaction.read_view(&view_id.value)?;
                let trash_ids = self.trash_controller.read_trash_ids(&transaction)?;
                if trash_ids.contains(&view.id) {
                    return Err(FlowyError::record_not_found());
                }
                Ok(view)
            })
            .await?;
        let _ = self.read_view_on_server(view_id);
        Ok(view)
    }

    pub(crate) async fn read_local_views(&self, ids: Vec<String>) -> Result<Vec<View>, FlowyError> {
        self.persistence
            .begin_transaction(|transaction| {
                let mut views = vec![];
                for view_id in ids {
                    views.push(transaction.read_view(&view_id)?);
                }
                Ok(views)
            })
            .await
    }

    #[tracing::instrument(level = "debug", skip(self), err)]
    pub(crate) fn set_latest_view(&self, view_id: &str) -> Result<(), FlowyError> {
        KV::set_str(LATEST_VIEW_ID, view_id.to_owned());
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self), err)]
    pub(crate) async fn close_view(&self, view_id: &str) -> Result<(), FlowyError> {
        let processor = self.get_data_processor_from_view_id(view_id).await?;
        let _ = processor.close_container(view_id).await?;
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self,params), fields(doc_id = %params.value), err)]
    pub(crate) async fn delete_view(&self, params: TextBlockId) -> Result<(), FlowyError> {
        if let Some(view_id) = KV::get_str(LATEST_VIEW_ID) {
            if view_id == params.value {
                let _ = KV::remove(LATEST_VIEW_ID);
            }
        }
        let processor = self.get_data_processor_from_view_id(&params.value).await?;
        let _ = processor.close_container(&params.value).await?;
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self), err)]
    pub(crate) async fn duplicate_view(&self, view_id: &str) -> Result<(), FlowyError> {
        let view = self
            .persistence
            .begin_transaction(|transaction| transaction.read_view(view_id))
            .await?;

        let processor = self.get_data_processor(&view.data_type)?;
        let delta_bytes = processor.delta_bytes(view_id).await?;
        let duplicate_params = CreateViewParams {
            belong_to_id: view.belong_to_id.clone(),
            name: format!("{} (copy)", &view.name),
            desc: view.desc,
            thumbnail: view.thumbnail,
            data_type: view.data_type,
            data: delta_bytes.to_vec(),
            view_id: uuid(),
            plugin_type: view.plugin_type,
        };

        let _ = self.create_view_from_params(duplicate_params).await?;
        Ok(())
    }

    // belong_to_id will be the app_id or view_id.
    #[tracing::instrument(level = "debug", skip(self), err)]
    pub(crate) async fn read_views_belong_to(&self, belong_to_id: &str) -> Result<RepeatedView, FlowyError> {
        self.persistence
            .begin_transaction(|transaction| {
                read_belonging_views_on_local(belong_to_id, self.trash_controller.clone(), &transaction)
            })
            .await
    }

    #[tracing::instrument(level = "debug", skip(self, params), err)]
    pub(crate) async fn update_view(&self, params: UpdateViewParams) -> Result<View, FlowyError> {
        let changeset = ViewChangeset::new(params.clone());
        let view_id = changeset.id.clone();
        let view = self
            .persistence
            .begin_transaction(|transaction| {
                let _ = transaction.update_view(changeset)?;
                let view = transaction.read_view(&view_id)?;
                send_dart_notification(&view_id, FolderNotification::ViewUpdated)
                    .payload(view.clone())
                    .send();
                let _ = notify_views_changed(&view.belong_to_id, self.trash_controller.clone(), &transaction)?;
                Ok(view)
            })
            .await?;

        let _ = self.update_view_on_server(params);
        Ok(view)
    }

    pub(crate) async fn latest_visit_view(&self) -> FlowyResult<Option<View>> {
        match KV::get_str(LATEST_VIEW_ID) {
            None => Ok(None),
            Some(view_id) => {
                let view = self
                    .persistence
                    .begin_transaction(|transaction| transaction.read_view(&view_id))
                    .await?;
                Ok(Some(view))
            }
        }
    }
}

impl ViewController {
    #[tracing::instrument(skip(self), err)]
    async fn create_view_on_server(&self, params: CreateViewParams) -> Result<View, FlowyError> {
        let token = self.user.token()?;
        let view = self.cloud_service.create_view(&token, params).await?;
        Ok(view)
    }

    #[tracing::instrument(skip(self), err)]
    fn update_view_on_server(&self, params: UpdateViewParams) -> Result<(), FlowyError> {
        let token = self.user.token()?;
        let server = self.cloud_service.clone();
        tokio::spawn(async move {
            match server.update_view(&token, params).await {
                Ok(_) => {}
                Err(e) => {
                    // TODO: retry?
                    log::error!("Update view failed: {:?}", e);
                }
            }
        });
        Ok(())
    }

    #[tracing::instrument(skip(self), err)]
    fn read_view_on_server(&self, params: ViewId) -> Result<(), FlowyError> {
        let token = self.user.token()?;
        let server = self.cloud_service.clone();
        let persistence = self.persistence.clone();
        // TODO: Retry with RetryAction?
        tokio::spawn(async move {
            match server.read_view(&token, params).await {
                Ok(Some(view)) => {
                    match persistence
                        .begin_transaction(|transaction| transaction.create_view(view.clone()))
                        .await
                    {
                        Ok(_) => {
                            send_dart_notification(&view.id, FolderNotification::ViewUpdated)
                                .payload(view.clone())
                                .send();
                        }
                        Err(e) => log::error!("Save view failed: {:?}", e),
                    }
                }
                Ok(None) => {}
                Err(e) => log::error!("Read view failed: {:?}", e),
            }
        });
        Ok(())
    }

    fn listen_trash_can_event(&self) {
        let mut rx = self.trash_controller.subscribe();
        let persistence = self.persistence.clone();
        let data_processors = self.data_processors.clone();
        let trash_controller = self.trash_controller.clone();
        let _ = tokio::spawn(async move {
            loop {
                let mut stream = Box::pin(rx.recv().into_stream().filter_map(|result| async move {
                    match result {
                        Ok(event) => event.select(TrashType::TrashView),
                        Err(_e) => None,
                    }
                }));

                if let Some(event) = stream.next().await {
                    handle_trash_event(
                        persistence.clone(),
                        data_processors.clone(),
                        trash_controller.clone(),
                        event,
                    )
                    .await
                }
            }
        });
    }

    async fn get_data_processor_from_view_id(
        &self,
        view_id: &str,
    ) -> FlowyResult<Arc<dyn ViewDataProcessor + Send + Sync>> {
        let view = self
            .persistence
            .begin_transaction(|transaction| transaction.read_view(view_id))
            .await?;
        self.get_data_processor(&view.data_type)
    }

    #[inline]
    fn get_data_processor(&self, data_type: &ViewDataType) -> FlowyResult<Arc<dyn ViewDataProcessor + Send + Sync>> {
        match self.data_processors.get(data_type) {
            None => Err(FlowyError::internal().context(format!(
                "Get data processor failed. Unknown view data type: {:?}",
                data_type
            ))),
            Some(processor) => Ok(processor.clone()),
        }
    }
}

#[tracing::instrument(level = "trace", skip(persistence, data_processors, trash_can))]
async fn handle_trash_event(
    persistence: Arc<FolderPersistence>,
    data_processors: ViewDataProcessorMap,
    trash_can: Arc<TrashController>,
    event: TrashEvent,
) {
    match event {
        TrashEvent::NewTrash(identifiers, ret) => {
            let result = persistence
                .begin_transaction(|transaction| {
                    let views = read_local_views_with_transaction(identifiers, &transaction)?;
                    for view in views {
                        let _ = notify_views_changed(&view.belong_to_id, trash_can.clone(), &transaction)?;
                        notify_dart(view, FolderNotification::ViewDeleted);
                    }
                    Ok(())
                })
                .await;
            let _ = ret.send(result).await;
        }
        TrashEvent::Putback(identifiers, ret) => {
            let result = persistence
                .begin_transaction(|transaction| {
                    let views = read_local_views_with_transaction(identifiers, &transaction)?;
                    for view in views {
                        let _ = notify_views_changed(&view.belong_to_id, trash_can.clone(), &transaction)?;
                        notify_dart(view, FolderNotification::ViewRestored);
                    }
                    Ok(())
                })
                .await;
            let _ = ret.send(result).await;
        }
        TrashEvent::Delete(identifiers, ret) => {
            let result = || async {
                let views = persistence
                    .begin_transaction(|transaction| {
                        let mut notify_ids = HashSet::new();
                        let mut views = vec![];
                        for identifier in identifiers.items {
                            let view = transaction.read_view(&identifier.id)?;
                            let _ = transaction.delete_view(&view.id)?;
                            notify_ids.insert(view.belong_to_id.clone());
                            views.push(view);
                        }
                        for notify_id in notify_ids {
                            let _ = notify_views_changed(&notify_id, trash_can.clone(), &transaction)?;
                        }
                        Ok(views)
                    })
                    .await?;

                for view in views {
                    match get_data_processor(data_processors.clone(), &view.data_type) {
                        Ok(processor) => {
                            let _ = processor.close_container(&view.id).await?;
                        }
                        Err(e) => {
                            tracing::error!("{}", e)
                        }
                    }
                }
                Ok(())
            };
            let _ = ret.send(result().await).await;
        }
    }
}

fn get_data_processor(
    data_processors: ViewDataProcessorMap,
    data_type: &ViewDataType,
) -> FlowyResult<Arc<dyn ViewDataProcessor + Send + Sync>> {
    match data_processors.get(data_type) {
        None => Err(FlowyError::internal().context(format!(
            "Get data processor failed. Unknown view data type: {:?}",
            data_type
        ))),
        Some(processor) => Ok(processor.clone()),
    }
}

fn read_local_views_with_transaction<'a>(
    identifiers: RepeatedTrashId,
    transaction: &'a (dyn FolderPersistenceTransaction + 'a),
) -> Result<Vec<View>, FlowyError> {
    let mut views = vec![];
    for identifier in identifiers.items {
        let view = transaction.read_view(&identifier.id)?;
        views.push(view);
    }
    Ok(views)
}

fn notify_dart(view: View, notification: FolderNotification) {
    send_dart_notification(&view.id, notification).payload(view).send();
}

#[tracing::instrument(skip(belong_to_id, trash_controller, transaction), fields(view_count), err)]
fn notify_views_changed<'a>(
    belong_to_id: &str,
    trash_controller: Arc<TrashController>,
    transaction: &'a (dyn FolderPersistenceTransaction + 'a),
) -> FlowyResult<()> {
    let repeated_view = read_belonging_views_on_local(belong_to_id, trash_controller.clone(), transaction)?;
    tracing::Span::current().record("view_count", &format!("{}", repeated_view.len()).as_str());
    send_dart_notification(belong_to_id, FolderNotification::AppViewsChanged)
        .payload(repeated_view)
        .send();
    Ok(())
}

fn read_belonging_views_on_local<'a>(
    belong_to_id: &str,
    trash_controller: Arc<TrashController>,
    transaction: &'a (dyn FolderPersistenceTransaction + 'a),
) -> FlowyResult<RepeatedView> {
    let mut views = transaction.read_views(belong_to_id)?;
    let trash_ids = trash_controller.read_trash_ids(transaction)?;
    views.retain(|view_table| !trash_ids.contains(&view_table.id));

    Ok(RepeatedView { items: views })
}
