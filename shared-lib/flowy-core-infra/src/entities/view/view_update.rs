use crate::{
    errors::ErrorCode,
    parser::view::{ViewDesc, ViewId, ViewName, ViewThumbnail},
};
use flowy_derive::ProtoBuf;
use std::convert::TryInto;

#[derive(Default, ProtoBuf)]
pub struct UpdateViewRequest {
    #[pb(index = 1)]
    pub view_id: String,

    #[pb(index = 2, one_of)]
    pub name: Option<String>,

    #[pb(index = 3, one_of)]
    pub desc: Option<String>,

    #[pb(index = 4, one_of)]
    pub thumbnail: Option<String>,
}

#[derive(Default, ProtoBuf, Clone, Debug)]
pub struct UpdateViewParams {
    #[pb(index = 1)]
    pub view_id: String,

    #[pb(index = 2, one_of)]
    pub name: Option<String>,

    #[pb(index = 3, one_of)]
    pub desc: Option<String>,

    #[pb(index = 4, one_of)]
    pub thumbnail: Option<String>,
}

impl UpdateViewParams {
    pub fn new(view_id: &str) -> Self {
        Self {
            view_id: view_id.to_owned(),
            ..Default::default()
        }
    }

    pub fn name(mut self, name: &str) -> Self {
        self.name = Some(name.to_owned());
        self
    }

    pub fn desc(mut self, desc: &str) -> Self {
        self.desc = Some(desc.to_owned());
        self
    }
}

impl TryInto<UpdateViewParams> for UpdateViewRequest {
    type Error = ErrorCode;

    fn try_into(self) -> Result<UpdateViewParams, Self::Error> {
        let view_id = ViewId::parse(self.view_id)?.0;

        let name = match self.name {
            None => None,
            Some(name) => Some(ViewName::parse(name)?.0),
        };

        let desc = match self.desc {
            None => None,
            Some(desc) => Some(ViewDesc::parse(desc)?.0),
        };

        let thumbnail = match self.thumbnail {
            None => None,
            Some(thumbnail) => Some(ViewThumbnail::parse(thumbnail)?.0),
        };

        Ok(UpdateViewParams {
            view_id,
            name,
            desc,
            thumbnail,
        })
    }
}
// #[derive(Default, ProtoBuf)]
// pub struct DocDeltaRequest {
//     #[pb(index = 1)]
//     pub view_id: String,
//
//     #[pb(index = 2)]
//     pub data: String,
// }
//
// impl TryInto<DocDelta> for DocDeltaRequest {
//     type Error = FlowyError;
//
//     fn try_into(self) -> Result<DocDelta, Self::Error> {
//         let view_id = ViewId::parse(self.view_id)
//             .map_err(|e| FlowyError::view_id().context(e))?
//             .0;
//
//         Ok(DocDelta { doc_id: view_id, data: self.data })
//     }
// }
