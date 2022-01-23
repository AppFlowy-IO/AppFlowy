use crate::{
    entities::trash::{Trash, TrashType},
    errors::ErrorCode,
    impl_def_and_def_mut,
    parser::{
        app::AppIdentify,
        view::{ViewName, ViewThumbnail},
    },
};
use flowy_collaboration::document::default::initial_delta_string;
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use std::convert::TryInto;

#[derive(PartialEq, Debug, ProtoBuf_Enum, Clone)]
pub enum ViewType {
    Blank = 0,
    Doc = 1,
}

impl std::default::Default for ViewType {
    fn default() -> Self {
        ViewType::Blank
    }
}

impl std::convert::From<i32> for ViewType {
    fn from(val: i32) -> Self {
        match val {
            1 => ViewType::Doc,
            0 => ViewType::Blank,
            _ => {
                log::error!("Invalid view type: {}", val);
                ViewType::Blank
            }
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

#[derive(Default, ProtoBuf, Debug, Clone)]
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

    // ViewType::Doc -> Delta string
    #[pb(index = 6)]
    pub view_data: String,

    #[pb(index = 7)]
    pub view_id: String,
}

impl CreateViewParams {
    pub fn new(
        belong_to_id: String,
        name: String,
        desc: String,
        view_type: ViewType,
        thumbnail: String,
        view_data: String,
        view_id: String,
    ) -> Self {
        Self {
            belong_to_id,
            name,
            desc,
            thumbnail,
            view_type,
            view_data,
            view_id,
        }
    }
}

impl TryInto<CreateViewParams> for CreateViewRequest {
    type Error = ErrorCode;

    fn try_into(self) -> Result<CreateViewParams, Self::Error> {
        let name = ViewName::parse(self.name)?.0;
        let belong_to_id = AppIdentify::parse(self.belong_to_id)?.0;
        let view_data = initial_delta_string();
        let view_id = uuid::Uuid::new_v4().to_string();
        let thumbnail = match self.thumbnail {
            None => "".to_string(),
            Some(thumbnail) => ViewThumbnail::parse(thumbnail)?.0,
        };

        Ok(CreateViewParams::new(
            belong_to_id,
            name,
            self.desc,
            self.view_type,
            thumbnail,
            view_data,
            view_id,
        ))
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

impl std::convert::From<View> for Trash {
    fn from(view: View) -> Self {
        Trash {
            id: view.id,
            name: view.name,
            modified_time: view.modified_time,
            create_time: view.create_time,
            ty: TrashType::View,
        }
    }
}
