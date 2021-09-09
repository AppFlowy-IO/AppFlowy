use crate::{entities::doc::parser::*, errors::*};
use flowy_derive::ProtoBuf;
use std::convert::TryInto;

#[derive(ProtoBuf, Default)]
pub struct UpdateDocRequest {
    #[pb(index = 1)]
    pub id: String,

    #[pb(index = 2, one_of)]
    pub data: Option<String>,
}

#[derive(ProtoBuf, Default, Debug, Clone)]
pub struct UpdateDocParams {
    #[pb(index = 1)]
    pub(crate) id: String,

    #[pb(index = 2, one_of)]
    pub(crate) data: Option<String>,
}

impl TryInto<UpdateDocParams> for UpdateDocRequest {
    type Error = DocError;

    fn try_into(self) -> Result<UpdateDocParams, Self::Error> {
        let id = DocId::parse(self.id)
            .map_err(|e| ErrorBuilder::new(ErrorCode::DocIdInvalid).msg(e).build())?
            .0;

        Ok(UpdateDocParams { id, data: self.data })
    }
}
