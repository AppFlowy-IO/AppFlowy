pub use crate::entities::view::ViewDataTypePB;
use crate::entities::ViewInfoPB;
use crate::manager::{ViewDataProcessor, ViewDataProcessorMap};
use crate::{
    dart_notification::{send_dart_notification, FolderNotification},
    entities::{
        trash::{RepeatedTrashIdPB, TrashType},
        view::{CreateViewParams, RepeatedViewPB, UpdateViewParams, ViewIdPB, ViewPB},
    },
    errors::{FlowyError, FlowyResult},
    event_map::{FolderCouldServiceV1, WorkspaceUser},
    services::{
        persistence::{FolderPersistence, FolderPersistenceTransaction, ViewChangeset},
        TrashController, TrashEvent,
    },
};
use bytes::Bytes;
use flowy_database::kv::KV;
use flowy_folder_data_model::revision::{gen_view_id, ViewRevision};
use flowy_sync::entities::text_block::TextBlockIdPB;
use futures::{FutureExt, StreamExt};
use lib_infra::util::timestamp;
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
    pub(crate) async fn create_view_from_params(
        &self,
        mut params: CreateViewParams,
    ) -> Result<ViewRevision, FlowyError> {
        let processor = self.get_data_processor(params.data_type.clone())?;
        let user_id = self.user.user_id()?;
        if params.view_content_data.is_empty() {
            let view_data = processor
                .create_default_view(&user_id, &params.view_id, params.layout.clone())
                .await?;
            params.view_content_data = view_data.to_vec();
        } else {
            let delta_data = processor
                .create_view_from_delta_data(&user_id, &params.view_id, params.view_content_data.clone())
                .await?;
            let _ = self
                .create_view(&params.view_id, params.data_type.clone(), delta_data)
                .await?;
        };

        let view_rev = self.create_view_on_server(params).await?;
        let _ = self.create_view_on_local(view_rev.clone()).await?;
        Ok(view_rev)
    }

    #[tracing::instrument(level = "debug", skip(self, view_id, delta_data), err)]
    pub(crate) async fn create_view(
        &self,
        view_id: &str,
        data_type: ViewDataTypePB,
        delta_data: Bytes,
    ) -> Result<(), FlowyError> {
        if delta_data.is_empty() {
            return Err(FlowyError::internal().context("The content of the view should not be empty"));
        }
        let user_id = self.user.user_id()?;
        let processor = self.get_data_processor(data_type)?;
        let _ = processor.create_container(&user_id, view_id, delta_data).await?;
        Ok(())
    }

    pub(crate) async fn create_view_on_local(&self, view_rev: ViewRevision) -> Result<(), FlowyError> {
        let trash_controller = self.trash_controller.clone();
        self.persistence
            .begin_transaction(|transaction| {
                let belong_to_id = view_rev.app_id.clone();
                let _ = transaction.create_view(view_rev)?;
                let _ = notify_views_changed(&belong_to_id, trash_controller, &transaction)?;
                Ok(())
            })
            .await
    }

    #[tracing::instrument(level = "debug", skip(self, view_id), fields(view_id = %view_id.value), err)]
    pub(crate) async fn read_view(&self, view_id: ViewIdPB) -> Result<ViewRevision, FlowyError> {
        let view_rev = self
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
        Ok(view_rev)
    }

    #[tracing::instrument(level = "debug", skip(self, view_id), fields(view_id = %view_id.value), err)]
    pub(crate) async fn read_view_info(&self, view_id: ViewIdPB) -> Result<ViewInfoPB, FlowyError> {
        let view_info = self
            .persistence
            .begin_transaction(|transaction| {
                let view_rev = transaction.read_view(&view_id.value)?;

                let items: Vec<ViewPB> = view_rev
                    .belongings
                    .into_iter()
                    .map(|view_rev| view_rev.into())
                    .collect();

                let view_info = ViewInfoPB {
                    id: view_rev.id,
                    belong_to_id: view_rev.app_id,
                    name: view_rev.name,
                    desc: view_rev.desc,
                    data_type: view_rev.data_type.into(),
                    belongings: RepeatedViewPB { items },
                    ext_data: view_rev.ext_data,
                };
                Ok(view_info)
            })
            .await?;

        Ok(view_info)
    }

    pub(crate) async fn read_local_views(&self, ids: Vec<String>) -> Result<Vec<ViewRevision>, FlowyError> {
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

    #[tracing::instrument(level = "trace", skip(self), err)]
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
    pub(crate) async fn delete_view(&self, params: TextBlockIdPB) -> Result<(), FlowyError> {
        if let Some(view_id) = KV::get_str(LATEST_VIEW_ID) {
            if view_id == params.value {
                let _ = KV::remove(LATEST_VIEW_ID);
            }
        }
        let processor = self.get_data_processor_from_view_id(&params.value).await?;
        let _ = processor.delete_container(&params.value).await?;
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self), err)]
    pub(crate) async fn move_view(&self, view_id: &str, from: usize, to: usize) -> Result<(), FlowyError> {
        let _ = self
            .persistence
            .begin_transaction(|transaction| {
                let _ = transaction.move_view(view_id, from, to)?;
                let view = transaction.read_view(view_id)?;
                let _ = notify_views_changed(&view.app_id, self.trash_controller.clone(), &transaction)?;
                Ok(())
            })
            .await?;
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self), err)]
    pub(crate) async fn duplicate_view(&self, view_id: &str) -> Result<(), FlowyError> {
        let view_rev = self
            .persistence
            .begin_transaction(|transaction| transaction.read_view(view_id))
            .await?;

        let processor = self.get_data_processor(view_rev.data_type.clone())?;
        let delta_bytes = processor.get_delta_data(view_id).await?;
        let duplicate_params = CreateViewParams {
            belong_to_id: view_rev.app_id.clone(),
            name: format!("{} (copy)", &view_rev.name),
            desc: view_rev.desc,
            thumbnail: view_rev.thumbnail,
            data_type: view_rev.data_type.into(),
            layout: view_rev.layout.into(),
            view_content_data: delta_bytes.to_vec(),
            view_id: gen_view_id(),
        };

        let _ = self.create_view_from_params(duplicate_params).await?;
        Ok(())
    }

    // belong_to_id will be the app_id or view_id.
    #[tracing::instrument(level = "trace", skip(self), err)]
    pub(crate) async fn read_views_belong_to(&self, belong_to_id: &str) -> Result<Vec<ViewRevision>, FlowyError> {
        self.persistence
            .begin_transaction(|transaction| {
                read_belonging_views_on_local(belong_to_id, self.trash_controller.clone(), &transaction)
            })
            .await
    }

    #[tracing::instrument(level = "debug", skip(self, params), err)]
    pub(crate) async fn update_view(&self, params: UpdateViewParams) -> Result<ViewRevision, FlowyError> {
        let changeset = ViewChangeset::new(params.clone());
        let view_id = changeset.id.clone();
        let view_rev = self
            .persistence
            .begin_transaction(|transaction| {
                let _ = transaction.update_view(changeset)?;
                let view_rev = transaction.read_view(&view_id)?;
                let view: ViewPB = view_rev.clone().into();
                send_dart_notification(&view_id, FolderNotification::ViewUpdated)
                    .payload(view)
                    .send();
                let _ = notify_views_changed(&view_rev.app_id, self.trash_controller.clone(), &transaction)?;
                Ok(view_rev)
            })
            .await?;

        let _ = self.update_view_on_server(params);
        Ok(view_rev)
    }

    pub(crate) async fn latest_visit_view(&self) -> FlowyResult<Option<ViewRevision>> {
        match KV::get_str(LATEST_VIEW_ID) {
            None => Ok(None),
            Some(view_id) => {
                let view_rev = self
                    .persistence
                    .begin_transaction(|transaction| transaction.read_view(&view_id))
                    .await?;
                Ok(Some(view_rev))
            }
        }
    }
}

impl ViewController {
    #[tracing::instrument(level = "debug", skip(self, params), err)]
    async fn create_view_on_server(&self, params: CreateViewParams) -> Result<ViewRevision, FlowyError> {
        let token = self.user.token()?;
        let view_rev = self.cloud_service.create_view(&token, params).await?;
        Ok(view_rev)
    }

    #[tracing::instrument(level = "debug", skip(self), err)]
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

    #[tracing::instrument(level = "debug", skip(self), err)]
    fn read_view_on_server(&self, params: ViewIdPB) -> Result<(), FlowyError> {
        let token = self.user.token()?;
        let server = self.cloud_service.clone();
        let persistence = self.persistence.clone();
        // TODO: Retry with RetryAction?
        tokio::spawn(async move {
            match server.read_view(&token, params).await {
                Ok(Some(view_rev)) => {
                    match persistence
                        .begin_transaction(|transaction| transaction.create_view(view_rev.clone()))
                        .await
                    {
                        Ok(_) => {
                            let view: ViewPB = view_rev.into();
                            send_dart_notification(&view.id, FolderNotification::ViewUpdated)
                                .payload(view)
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
        self.get_data_processor(view.data_type)
    }

    #[inline]
    fn get_data_processor<T: Into<ViewDataTypePB>>(
        &self,
        data_type: T,
    ) -> FlowyResult<Arc<dyn ViewDataProcessor + Send + Sync>> {
        let data_type = data_type.into();
        match self.data_processors.get(&data_type) {
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
                    let view_revs = read_local_views_with_transaction(identifiers, &transaction)?;
                    for view_rev in view_revs {
                        let _ = notify_views_changed(&view_rev.app_id, trash_can.clone(), &transaction)?;
                        notify_dart(view_rev.into(), FolderNotification::ViewDeleted);
                    }
                    Ok(())
                })
                .await;
            let _ = ret.send(result).await;
        }
        TrashEvent::Putback(identifiers, ret) => {
            let result = persistence
                .begin_transaction(|transaction| {
                    let view_revs = read_local_views_with_transaction(identifiers, &transaction)?;
                    for view_rev in view_revs {
                        let _ = notify_views_changed(&view_rev.app_id, trash_can.clone(), &transaction)?;
                        notify_dart(view_rev.into(), FolderNotification::ViewRestored);
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
                            notify_ids.insert(view.app_id.clone());
                            views.push(view);
                        }
                        for notify_id in notify_ids {
                            let _ = notify_views_changed(&notify_id, trash_can.clone(), &transaction)?;
                        }
                        Ok(views)
                    })
                    .await?;

                for view in views {
                    let data_type = view.data_type.clone().into();
                    match get_data_processor(data_processors.clone(), &data_type) {
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

fn make_view_rev_from(params: CreateViewParams) -> ViewRevision {
    let time = timestamp();
    ViewRevision {
        id: params.view_id,
        app_id: params.belong_to_id,
        name: params.name,
        desc: params.desc,
        data_type: params.data_type.into(),
        version: 0,
        belongings: vec![],
        modified_time: time,
        create_time: time,
        ext_data: "".to_string(),
        thumbnail: params.thumbnail,
        layout: params.layout.into(),
    }
}

fn get_data_processor(
    data_processors: ViewDataProcessorMap,
    data_type: &ViewDataTypePB,
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
    identifiers: RepeatedTrashIdPB,
    transaction: &'a (dyn FolderPersistenceTransaction + 'a),
) -> Result<Vec<ViewRevision>, FlowyError> {
    let mut view_revs = vec![];
    for identifier in identifiers.items {
        view_revs.push(transaction.read_view(&identifier.id)?);
    }
    Ok(view_revs)
}

fn notify_dart(view: ViewPB, notification: FolderNotification) {
    send_dart_notification(&view.id, notification).payload(view).send();
}

#[tracing::instrument(
    level = "debug",
    skip(belong_to_id, trash_controller, transaction),
    fields(view_count),
    err
)]
fn notify_views_changed<'a>(
    belong_to_id: &str,
    trash_controller: Arc<TrashController>,
    transaction: &'a (dyn FolderPersistenceTransaction + 'a),
) -> FlowyResult<()> {
    let items: Vec<ViewPB> = read_belonging_views_on_local(belong_to_id, trash_controller.clone(), transaction)?
        .into_iter()
        .map(|view_rev| view_rev.into())
        .collect();
    tracing::Span::current().record("view_count", &format!("{}", items.len()).as_str());

    let repeated_view = RepeatedViewPB { items };
    send_dart_notification(belong_to_id, FolderNotification::AppViewsChanged)
        .payload(repeated_view)
        .send();
    Ok(())
}

fn read_belonging_views_on_local<'a>(
    belong_to_id: &str,
    trash_controller: Arc<TrashController>,
    transaction: &'a (dyn FolderPersistenceTransaction + 'a),
) -> FlowyResult<Vec<ViewRevision>> {
    let mut view_revs = transaction.read_views(belong_to_id)?;
    let trash_ids = trash_controller.read_trash_ids(transaction)?;
    view_revs.retain(|view_table| !trash_ids.contains(&view_table.id));

    Ok(view_revs)
}
