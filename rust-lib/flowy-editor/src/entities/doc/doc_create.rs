use crate::{
    entities::doc::parser::*,
    errors::{ErrorBuilder, *},
};
use flowy_derive::ProtoBuf;
use std::convert::TryInto;

#[derive(ProtoBuf, Default)]
pub struct CreateDocRequest {
    #[pb(index = 1)]
    view_id: String,

    #[pb(index = 2)]
    pub name: String,
}

pub struct CreateDocParams {
    pub view_id: String,
    pub name: String,
}

impl TryInto<CreateDocParams> for CreateDocRequest {
    type Error = EditorError;

    fn try_into(self) -> Result<CreateDocParams, Self::Error> {
        let name = DocName::parse(self.name)
            .map_err(|e| {
                ErrorBuilder::new(EditorErrorCode::DocNameInvalid)
                    .msg(e)
                    .build()
            })?
            .0;

        let view_id = DocViewId::parse(self.view_id)
            .map_err(|e| {
                ErrorBuilder::new(EditorErrorCode::DocViewIdInvalid)
                    .msg(e)
                    .build()
            })?
            .0;

        Ok(CreateDocParams { view_id, name })
    }
}

#[derive(ProtoBuf, Default, Debug)]
pub struct Doc {
    #[pb(index = 1)]
    pub id: String,

    #[pb(index = 2)]
    pub name: String,

    #[pb(index = 3)]
    pub view_id: String,
}
