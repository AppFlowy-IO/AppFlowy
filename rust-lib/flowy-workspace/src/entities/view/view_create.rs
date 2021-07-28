use crate::{
    entities::{app::parser::BelongToId, view::parser::*},
    errors::{ErrorBuilder, WorkspaceError, WsErrCode},
    impl_def_and_def_mut,
    sql_tables::view::ViewTableType,
};
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use std::convert::TryInto;

#[derive(PartialEq, Debug, ProtoBuf_Enum)]
pub enum ViewType {
    Blank = 0,
    Doc   = 1,
}

impl std::default::Default for ViewType {
    fn default() -> Self { ViewType::Blank }
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

pub struct CreateViewParams {
    pub belong_to_id: String,
    pub name: String,
    pub desc: String,
    pub thumbnail: String,
    pub view_type: ViewTableType,
}

impl TryInto<CreateViewParams> for CreateViewRequest {
    type Error = WorkspaceError;

    fn try_into(self) -> Result<CreateViewParams, Self::Error> {
        let name = ViewName::parse(self.name)
            .map_err(|e| ErrorBuilder::new(WsErrCode::ViewNameInvalid).msg(e).build())?
            .0;

        let belong_to_id = BelongToId::parse(self.belong_to_id)
            .map_err(|e| ErrorBuilder::new(WsErrCode::AppIdInvalid).msg(e).build())?
            .0;

        let thumbnail = match self.thumbnail {
            None => "".to_string(),
            Some(thumbnail) => {
                ViewThumbnail::parse(thumbnail)
                    .map_err(|e| {
                        ErrorBuilder::new(WsErrCode::ViewThumbnailInvalid)
                            .msg(e)
                            .build()
                    })?
                    .0
            },
        };

        let view_type = ViewTypeCheck::parse(self.view_type).unwrap().0;
        Ok(CreateViewParams {
            belong_to_id,
            name,
            desc: self.desc,
            thumbnail,
            view_type,
        })
    }
}

#[derive(PartialEq, ProtoBuf, Default, Debug)]
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
}

#[derive(PartialEq, Debug, Default, ProtoBuf)]
pub struct RepeatedView {
    #[pb(index = 1)]
    pub items: Vec<View>,
}

impl_def_and_def_mut!(RepeatedView, View);
