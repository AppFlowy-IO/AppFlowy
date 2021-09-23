use crate::{
    entities::view::parser::{ViewId, *},
    errors::WorkspaceError,
};
use flowy_derive::ProtoBuf;
use flowy_document::entities::doc::{DocDelta, UpdateDocParams};
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

    #[pb(index = 5, one_of)]
    pub is_trash: Option<bool>,
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

    #[pb(index = 5, one_of)]
    pub is_trash: Option<bool>,
}

impl UpdateViewParams {
    pub fn new(view_id: &str) -> Self {
        Self {
            view_id: view_id.to_owned(),
            ..Default::default()
        }
    }

    pub fn trash(mut self) -> Self {
        self.is_trash = Some(true);
        self
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
    type Error = WorkspaceError;

    fn try_into(self) -> Result<UpdateViewParams, Self::Error> {
        let view_id = ViewId::parse(self.view_id).map_err(|e| WorkspaceError::view_id().context(e))?.0;

        let name = match self.name {
            None => None,
            Some(name) => Some(ViewName::parse(name).map_err(|e| WorkspaceError::view_name().context(e))?.0),
        };

        let desc = match self.desc {
            None => None,
            Some(desc) => Some(ViewDesc::parse(desc).map_err(|e| WorkspaceError::view_desc().context(e))?.0),
        };

        let thumbnail = match self.thumbnail {
            None => None,
            Some(thumbnail) => Some(
                ViewThumbnail::parse(thumbnail)
                    .map_err(|e| WorkspaceError::view_thumbnail().context(e))?
                    .0,
            ),
        };

        Ok(UpdateViewParams {
            view_id,
            name,
            desc,
            thumbnail,
            is_trash: self.is_trash,
        })
    }
}

#[derive(Default, ProtoBuf)]
pub struct SaveViewDataRequest {
    #[pb(index = 1)]
    pub view_id: String,

    #[pb(index = 2)]
    pub data: Vec<u8>,
}

impl TryInto<UpdateDocParams> for SaveViewDataRequest {
    type Error = WorkspaceError;

    fn try_into(self) -> Result<UpdateDocParams, Self::Error> {
        let view_id = ViewId::parse(self.view_id).map_err(|e| WorkspaceError::view_id().context(e))?.0;

        // Opti: Vec<u8> -> Delta -> Vec<u8>
        let data = DeltaData::parse(self.data).map_err(|e| WorkspaceError::view_data().context(e))?.0;

        Ok(UpdateDocParams { doc_id: view_id, data })
    }
}

#[derive(Default, ProtoBuf)]
pub struct ApplyChangesetRequest {
    #[pb(index = 1)]
    pub view_id: String,

    #[pb(index = 2)]
    pub data: Vec<u8>,
}

impl TryInto<DocDelta> for ApplyChangesetRequest {
    type Error = WorkspaceError;

    fn try_into(self) -> Result<DocDelta, Self::Error> {
        let view_id = ViewId::parse(self.view_id).map_err(|e| WorkspaceError::view_id().context(e))?.0;

        // Opti: Vec<u8> -> Delta -> Vec<u8>
        let data = DeltaData::parse(self.data).map_err(|e| WorkspaceError::view_data().context(e))?.0;

        Ok(DocDelta { doc_id: view_id, data })
    }
}
