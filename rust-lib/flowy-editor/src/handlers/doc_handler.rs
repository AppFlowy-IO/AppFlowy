use crate::{
    entities::doc::*,
    errors::EditorError,
    services::{doc_controller::DocController, file_manager::FileManager},
};
use flowy_dispatch::prelude::*;
use std::{
    convert::TryInto,
    path::Path,
    sync::{Arc, RwLock},
};

pub async fn create_doc(
    data: Data<CreateDocRequest>,
    controller: ModuleData<DocController>,
    manager: ModuleData<RwLock<FileManager>>,
) -> ResponseResult<DocDescription, EditorError> {
    let params: CreateDocParams = data.into_inner().try_into()?;
    let path = manager.read().unwrap().make_file_path(&params.id);
    let doc_desc = controller
        .create_doc(params, path.to_str().unwrap())
        .await?;
    response_ok(doc_desc)
}

pub async fn read_doc(
    data: Data<QueryDocRequest>,
    controller: ModuleData<DocController>,
    manager: ModuleData<RwLock<FileManager>>,
) -> ResponseResult<Doc, EditorError> {
    let params: QueryDocParams = data.into_inner().try_into()?;
    let desc = controller.read_doc(&params.doc_id).await?;

    let content = manager
        .write()
        .unwrap()
        .open(Path::new(&desc.path), desc.id.clone())?;

    let doc = Doc { desc, content };
    response_ok(doc)
}

pub async fn update_doc(
    data: Data<UpdateDocRequest>,
    controller: ModuleData<DocController>,
    manager: ModuleData<RwLock<FileManager>>,
) -> Result<(), EditorError> {
    let mut params: UpdateDocParams = data.into_inner().try_into()?;
    match params.content.take() {
        None => {},
        Some(s) => {
            let doc_desc = controller.read_doc(&params.id).await?;
            manager
                .write()
                .unwrap()
                .save(Path::new(&doc_desc.path), &s, params.id.clone());
        },
    }

    if params.name.is_some() || params.desc.is_some() {
        let _ = controller.update_doc(params).await?;
    }

    Ok(())
}
