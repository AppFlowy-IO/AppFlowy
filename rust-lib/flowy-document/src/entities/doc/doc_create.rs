use crate::{
    entities::doc::parser::*,
    errors::{ErrorBuilder, *},
};
use flowy_derive::ProtoBuf;
use std::convert::TryInto;

#[derive(ProtoBuf, Default)]
pub struct CreateDocRequest {
    #[pb(index = 1)]
    pub id: String,

    #[pb(index = 2)]
    pub data: String,
}

#[derive(ProtoBuf, Default, Debug, Clone)]
pub struct CreateDocParams {
    #[pb(index = 1)]
    pub id: String,

    #[pb(index = 2)]
    pub data: String,
}

impl TryInto<CreateDocParams> for CreateDocRequest {
    type Error = DocError;

    fn try_into(self) -> Result<CreateDocParams, Self::Error> {
        let id = DocId::parse(self.id)
            .map_err(|e| ErrorBuilder::new(ErrorCode::DocIdInvalid).msg(e).build())?
            .0;

        Ok(CreateDocParams { id, data: self.data })
    }
}

#[derive(ProtoBuf, Default, Debug, Clone)]
pub struct Doc {
    #[pb(index = 1)]
    pub id: String,

    #[pb(index = 2)]
    pub data: String,
}
