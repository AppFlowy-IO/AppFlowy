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
    pub name: String,

    #[pb(index = 3)]
    pub desc: String,

    #[pb(index = 4)]
    pub text: String,
}

pub struct CreateDocParams {
    pub id: String,
    pub name: String,
    pub desc: String,
    pub text: String,
}

impl TryInto<CreateDocParams> for CreateDocRequest {
    type Error = DocError;

    fn try_into(self) -> Result<CreateDocParams, Self::Error> {
        let name = DocName::parse(self.name)
            .map_err(|e| {
                ErrorBuilder::new(DocErrorCode::DocNameInvalid)
                    .msg(e)
                    .build()
            })?
            .0;

        let id = DocViewId::parse(self.id)
            .map_err(|e| {
                ErrorBuilder::new(DocErrorCode::DocViewIdInvalid)
                    .msg(e)
                    .build()
            })?
            .0;

        Ok(CreateDocParams {
            id,
            name,
            desc: self.desc,
            text: self.text,
        })
    }
}

#[derive(ProtoBuf, Default, Debug)]
pub struct DocInfo {
    #[pb(index = 1)]
    pub id: String,

    #[pb(index = 2)]
    pub name: String,

    #[pb(index = 3)]
    pub desc: String,

    #[pb(index = 4)]
    pub path: String,
}

#[derive(ProtoBuf, Default, Debug)]
pub struct DocData {
    #[pb(index = 1)]
    pub text: String,
}
