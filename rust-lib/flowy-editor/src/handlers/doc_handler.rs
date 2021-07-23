use crate::{entities::doc::*, errors::EditorError, services::file_manager::FileManager};
use flowy_dispatch::prelude::*;
use std::{
    convert::TryInto,
    sync::{Arc, RwLock},
};

pub async fn create_doc(
    data: Data<CreateDocRequest>,
    manager: ModuleData<RwLock<FileManager>>,
) -> ResponseResult<Doc, EditorError> {
    let params: CreateDocParams = data.into_inner().try_into()?;
    // let user = session.sign_in(params).await?;
    // let user_detail = UserDetail::from(user);
    // response_ok(user_detail)

    panic!()
}
