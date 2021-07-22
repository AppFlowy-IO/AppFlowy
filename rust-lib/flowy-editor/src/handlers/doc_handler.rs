use crate::{entities::doc::*, errors::EditorError};
use flowy_dispatch::prelude::*;
use std::{convert::TryInto, sync::Arc};

pub async fn create_doc(
    data: Data<CreateDocRequest>,
    // session: ModuleData<Arc<UserSession>>,
) -> ResponseResult<Doc, EditorError> {
    // let params: SignInParams = data.into_inner().try_into()?;
    // let user = session.sign_in(params).await?;
    // let user_detail = UserDetail::from(user);
    // response_ok(user_detail)

    panic!()
}
