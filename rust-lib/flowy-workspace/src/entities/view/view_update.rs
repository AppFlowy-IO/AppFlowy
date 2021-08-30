use crate::{
    entities::view::parser::{ViewId, *},
    errors::{ErrorBuilder, ErrorCode, WorkspaceError},
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

    #[pb(index = 5, one_of)]
    pub is_trash: Option<bool>,
}

#[derive(Default, ProtoBuf)]
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
        let view_id = ViewId::parse(self.view_id)
            .map_err(|e| ErrorBuilder::new(ErrorCode::ViewIdInvalid).msg(e).build())?
            .0;

        let name = match self.name {
            None => None,
            Some(name) => Some(
                ViewName::parse(name)
                    .map_err(|e| ErrorBuilder::new(ErrorCode::ViewNameInvalid).msg(e).build())?
                    .0,
            ),
        };

        let desc = match self.desc {
            None => None,
            Some(desc) => Some(
                ViewDesc::parse(desc)
                    .map_err(|e| ErrorBuilder::new(ErrorCode::ViewDescInvalid).msg(e).build())?
                    .0,
            ),
        };

        let thumbnail = match self.thumbnail {
            None => None,
            Some(thumbnail) => Some(
                ViewThumbnail::parse(thumbnail)
                    .map_err(|e| {
                        ErrorBuilder::new(ErrorCode::ViewThumbnailInvalid)
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
            is_trash: self.is_trash,
        })
    }
}
