use crate::{
    entities::{app::parser::AppId, view::parser::*},
    errors::{ErrorBuilder, ErrorCode, WorkspaceError},
    impl_def_and_def_mut,
};
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use std::convert::TryInto;

#[derive(PartialEq, Debug, ProtoBuf_Enum, Clone)]
pub enum ViewType {
    Blank = 0,
    Doc   = 1,
}

impl std::default::Default for ViewType {
    fn default() -> Self { ViewType::Blank }
}

impl std::convert::From<i32> for ViewType {
    fn from(val: i32) -> Self {
        match val {
            1 => ViewType::Doc,
            0 => ViewType::Blank,
            _ => {
                log::error!("Invalid view type: {}", val);
                ViewType::Blank
            },
        }
    }
}

#[derive(Default, ProtoBuf)]
pub struct CreateViewRequest {
    #[pb(index = 1)]
    pub belong_to_id: String,

    #[pb(index = 2)]
    pub name: String,

    #[pb(index = 3)]
    pub desc: String,

    #[pb(index = 4, one_of)]
    pub thumbnail: Option<String>,

    #[pb(index = 5)]
    pub view_type: ViewType,
}

#[derive(Default, ProtoBuf, Debug)]
pub struct CreateViewParams {
    #[pb(index = 1)]
    pub belong_to_id: String,

    #[pb(index = 2)]
    pub name: String,

    #[pb(index = 3)]
    pub desc: String,

    #[pb(index = 4)]
    pub thumbnail: String,

    #[pb(index = 5)]
    pub view_type: ViewType,
}

impl TryInto<CreateViewParams> for CreateViewRequest {
    type Error = WorkspaceError;

    fn try_into(self) -> Result<CreateViewParams, Self::Error> {
        let name = ViewName::parse(self.name)
            .map_err(|e| ErrorBuilder::new(ErrorCode::ViewNameInvalid).msg(e).build())?
            .0;

        let belong_to_id = AppId::parse(self.belong_to_id)
            .map_err(|e| ErrorBuilder::new(ErrorCode::AppIdInvalid).msg(e).build())?
            .0;

        let thumbnail = match self.thumbnail {
            None => "".to_string(),
            Some(thumbnail) => {
                ViewThumbnail::parse(thumbnail)
                    .map_err(|e| ErrorBuilder::new(ErrorCode::ViewThumbnailInvalid).msg(e).build())?
                    .0
            },
        };

        Ok(CreateViewParams {
            belong_to_id,
            name,
            desc: self.desc,
            thumbnail,
            view_type: self.view_type,
        })
    }
}

#[derive(PartialEq, ProtoBuf, Default, Debug, Clone)]
pub struct View {
    #[pb(index = 1)]
    pub id: String,

    #[pb(index = 2)]
    pub belong_to_id: String,

    #[pb(index = 3)]
    pub name: String,

    #[pb(index = 4)]
    pub desc: String,

    #[pb(index = 5)]
    pub view_type: ViewType,

    #[pb(index = 6)]
    pub version: i64,

    #[pb(index = 7)]
    pub belongings: RepeatedView,

    #[pb(index = 8)]
    pub modified_time: i64,

    #[pb(index = 9)]
    pub create_time: i64,
}

#[derive(PartialEq, Debug, Default, ProtoBuf, Clone)]
pub struct RepeatedView {
    #[pb(index = 1)]
    pub items: Vec<View>,
}

impl_def_and_def_mut!(RepeatedView, View);
