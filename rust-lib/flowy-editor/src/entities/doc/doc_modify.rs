use crate::{entities::doc::parser::*, errors::*};
use flowy_derive::ProtoBuf;
use std::convert::TryInto;

#[derive(ProtoBuf, Default)]
pub struct UpdateDocRequest {
    #[pb(index = 1)]
    pub id: String,

    #[pb(index = 2, one_of)]
    pub name: Option<String>,

    #[pb(index = 3, one_of)]
    pub desc: Option<String>,

    #[pb(index = 4, one_of)]
    pub content: Option<String>,
}

pub(crate) struct UpdateDocParams {
    pub(crate) id: String,
    pub(crate) name: Option<String>,
    pub(crate) desc: Option<String>,
    pub(crate) content: Option<String>,
}

impl TryInto<UpdateDocParams> for UpdateDocRequest {
    type Error = EditorError;

    fn try_into(self) -> Result<UpdateDocParams, Self::Error> {
        let id = DocId::parse(self.id)
            .map_err(|e| {
                ErrorBuilder::new(EditorErrorCode::DocViewIdInvalid)
                    .msg(e)
                    .build()
            })?
            .0;

        let name = match self.name {
            None => None,
            Some(name) => Some(
                DocName::parse(name)
                    .map_err(|e| {
                        ErrorBuilder::new(EditorErrorCode::DocNameInvalid)
                            .msg(e)
                            .build()
                    })?
                    .0,
            ),
        };

        let desc = match self.desc {
            None => None,
            Some(desc) => Some(
                DocDesc::parse(desc)
                    .map_err(|e| {
                        ErrorBuilder::new(EditorErrorCode::DocDescTooLong)
                            .msg(e)
                            .build()
                    })?
                    .0,
            ),
        };

        Ok(UpdateDocParams {
            id,
            name,
            desc,
            content: self.content,
        })
    }
}
