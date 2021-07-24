use crate::{
    entities::view::parser::{ViewId, *},
    errors::{ErrorBuilder, WorkspaceError, WorkspaceErrorCode},
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

pub struct UpdateViewParams {
    pub view_id: String,
    pub name: Option<String>,
    pub desc: Option<String>,
    pub thumbnail: Option<String>,
}

impl TryInto<UpdateViewParams> for UpdateViewRequest {
    type Error = WorkspaceError;

    fn try_into(self) -> Result<UpdateViewParams, Self::Error> {
        let view_id = ViewId::parse(self.view_id)
            .map_err(|e| {
                ErrorBuilder::new(WorkspaceErrorCode::ViewIdInvalid)
                    .msg(e)
                    .build()
            })?
            .0;

        let name = match self.name {
            None => None,
            Some(name) => Some(
                ViewName::parse(name)
                    .map_err(|e| {
                        ErrorBuilder::new(WorkspaceErrorCode::ViewNameInvalid)
                            .msg(e)
                            .build()
                    })?
                    .0,
            ),
        };

        let desc = match self.desc {
            None => None,
            Some(desc) => Some(
                ViewDesc::parse(desc)
                    .map_err(|e| {
                        ErrorBuilder::new(WorkspaceErrorCode::ViewDescInvalid)
                            .msg(e)
                            .build()
                    })?
                    .0,
            ),
        };

        let thumbnail = match self.thumbnail {
            None => None,
            Some(thumbnail) => Some(
                ViewThumbnail::parse(thumbnail)
                    .map_err(|e| {
                        ErrorBuilder::new(WorkspaceErrorCode::ViewThumbnailInvalid)
                            .msg(e)
                            .build()
                    })?
                    .0,
            ),
        };

        Ok(UpdateViewParams {
            view_id,
            name,
            desc,
            thumbnail,
        })
    }
}
