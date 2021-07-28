use crate::{
    entities::doc::*,
    errors::EditorError,
    services::{doc_controller::DocController, file_manager::FileManager},
};
use flowy_dispatch::prelude::*;
use std::{convert::TryInto, path::Path};
use tokio::sync::RwLock;

#[tracing::instrument(name = "create_doc", skip(data, controller, manager))]
pub async fn create_doc(
    data: Data<CreateDocRequest>,
    controller: Unit<DocController>,
    manager: Unit<RwLock<FileManager>>,
) -> ResponseResult<DocInfo, EditorError> {
    let params: CreateDocParams = data.into_inner().try_into()?;
    let dir = manager.read().await.user.user_doc_dir()?;
    let path = manager
        .write()
        .await
        .create_file(&params.id, &dir, &params.text)?;
    let doc_desc = controller
        .create_doc(params, path.to_str().unwrap())
        .await?;
    response_ok(doc_desc)
}

#[tracing::instrument(name = "read_doc", skip(data, controller, manager))]
pub async fn read_doc(
    data: Data<QueryDocRequest>,
    controller: Unit<DocController>,
    manager: Unit<RwLock<FileManager>>,
) -> ResponseResult<DocInfo, EditorError> {
    let params: QueryDocParams = data.into_inner().try_into()?;
    let doc_info = controller.read_doc(&params.doc_id).await?;
    let _ = manager
        .write()
        .await
        .open(Path::new(&doc_info.path), doc_info.id.clone())?;

    response_ok(doc_info)
}

#[tracing::instrument(name = "read_doc_data", skip(data, manager))]
pub async fn read_doc_data(
    data: Data<QueryDocDataRequest>,
    manager: Unit<RwLock<FileManager>>,
) -> ResponseResult<DocData, EditorError> {
    let params: QueryDocDataParams = data.into_inner().try_into()?;
    let text = manager
        .write()
        .await
        .open(Path::new(&params.path), params.doc_id)?;

    response_ok(DocData { text })
}

pub async fn update_doc(
    data: Data<UpdateDocRequest>,
    controller: Unit<DocController>,
    manager: Unit<RwLock<FileManager>>,
) -> Result<(), EditorError> {
    let mut params: UpdateDocParams = data.into_inner().try_into()?;

    if let Some(s) = params.text.take() {
        let doc_desc = controller.read_doc(&params.id).await?;
        manager
            .write()
            .await
            .save(Path::new(&doc_desc.path), &s, params.id.clone())
            .unwrap();
    }

    if params.name.is_some() || params.desc.is_some() {
        let _ = controller.update_doc(params).await?;
    }

    Ok(())
}
