use crate::{entities::doc::parser::DocId, errors::*};
use flowy_derive::ProtoBuf;
use std::convert::TryInto;

#[derive(Default, ProtoBuf)]
pub struct QueryDocRequest {
    #[pb(index = 1)]
    pub doc_id: String,

    #[pb(index = 2)]
    pub read_content: bool,
}

pub struct QueryDocParams {
    pub doc_id: String,
    pub read_content: bool,
}

impl TryInto<QueryDocParams> for QueryDocRequest {
    type Error = EditorError;

    fn try_into(self) -> Result<QueryDocParams, Self::Error> {
        let doc_id = DocId::parse(self.doc_id)
            .map_err(|e| {
                ErrorBuilder::new(EditorErrorCode::DocViewIdInvalid)
                    .msg(e)
                    .build()
            })?
            .0;

        Ok(QueryDocParams {
            doc_id,
            read_content: self.read_content,
        })
    }
}
