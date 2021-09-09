use crate::{
    entities::doc::*,
    errors::DocError,
    services::{doc_controller::DocController, file_manager::FileManager},
};
use flowy_dispatch::prelude::*;
use std::{convert::TryInto, path::Path};
use tokio::sync::RwLock;

#[tracing::instrument(skip(data, controller))]
pub async fn create_doc_handler(data: Data<CreateDocRequest>, controller: Unit<DocController>) -> DataResult<Doc, DocError> {
    let params: CreateDocParams = data.into_inner().try_into()?;
    let doc_desc = controller.create_doc(params).await?;
    data_result(doc_desc)
}

#[tracing::instrument(skip(data, controller))]
pub async fn read_doc_handler(data: Data<QueryDocRequest>, controller: Unit<DocController>) -> DataResult<Doc, DocError> {
    let params: QueryDocParams = data.into_inner().try_into()?;
    let doc_info = controller.read_doc(params).await?;
    data_result(doc_info)
}

#[tracing::instrument(skip(data, controller))]
pub async fn update_doc_handler(data: Data<UpdateDocRequest>, controller: Unit<DocController>) -> Result<(), DocError> {
    let mut params: UpdateDocParams = data.into_inner().try_into()?;
    let _ = controller.update_doc(params).await?;
    Ok(())
}

pub async fn delete_doc_handler(data: Data<QueryDocRequest>, controller: Unit<DocController>) -> Result<(), DocError> {
    let params: QueryDocParams = data.into_inner().try_into()?;
    let _ = controller.delete_doc(params).await?;
    Ok(())
}
