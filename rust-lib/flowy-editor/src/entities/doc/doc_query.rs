use crate::{
    entities::doc::parser::{DocId, DocPath},
    errors::*,
};
use flowy_derive::ProtoBuf;
use std::convert::TryInto;

#[derive(Default, ProtoBuf)]
pub struct QueryDocRequest {
    #[pb(index = 1)]
    pub doc_id: String,
}

pub(crate) struct QueryDocParams {
    pub doc_id: String,
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

        Ok(QueryDocParams { doc_id })
    }
}

#[derive(Default, ProtoBuf)]
pub struct QueryDocDataRequest {
    #[pb(index = 1)]
    pub doc_id: String,

    #[pb(index = 2)]
    pub path: String,
}

pub(crate) struct QueryDocDataParams {
    pub doc_id: String,
    pub path: String,
}

impl TryInto<QueryDocDataParams> for QueryDocDataRequest {
    type Error = EditorError;

    fn try_into(self) -> Result<QueryDocDataParams, Self::Error> {
        let doc_id = DocId::parse(self.doc_id)
            .map_err(|e| {
                ErrorBuilder::new(EditorErrorCode::DocViewIdInvalid)
                    .msg(e)
                    .build()
            })?
            .0;

        let path = DocPath::parse(self.path)
            .map_err(|e| {
                ErrorBuilder::new(EditorErrorCode::DocFilePathInvalid)
                    .msg(e)
                    .build()
            })?
            .0;

        Ok(QueryDocDataParams { doc_id, path })
    }
}
