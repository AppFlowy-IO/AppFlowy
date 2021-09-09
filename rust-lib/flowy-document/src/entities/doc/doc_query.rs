use crate::{entities::doc::parser::DocId, errors::*};
use flowy_derive::ProtoBuf;
use std::convert::TryInto;

#[derive(Default, ProtoBuf)]
pub struct QueryDocRequest {
    #[pb(index = 1)]
    pub doc_id: String,
}

#[derive(ProtoBuf, Default, Debug, Clone)]
pub struct QueryDocParams {
    #[pb(index = 1)]
    pub doc_id: String,
}

impl TryInto<QueryDocParams> for QueryDocRequest {
    type Error = DocError;

    fn try_into(self) -> Result<QueryDocParams, Self::Error> {
        let doc_id = DocId::parse(self.doc_id)
            .map_err(|e| ErrorBuilder::new(ErrorCode::DocIdInvalid).msg(e).build())?
            .0;

        Ok(QueryDocParams { doc_id })
    }
}
