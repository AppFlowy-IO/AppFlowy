use crate::{
    entities::trash::{Trash, TrashType},
    errors::ErrorCode,
    impl_def_and_def_mut,
    parser::{
        app::AppIdentify,
        view::{ViewDesc, ViewIdentify, ViewName, ViewThumbnail},
    },
};
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use serde::{Deserialize, Serialize};
use std::convert::TryInto;

#[derive(Eq, PartialEq, ProtoBuf, Default, Debug, Clone, Serialize, Deserialize)]
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

#[derive(Eq, PartialEq, Debug, Default, ProtoBuf, Clone, Serialize, Deserialize)]
#[serde(transparent)]
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
            ty: TrashType::TrashView,
        }
    }
}

#[derive(Eq, PartialEq, Debug, ProtoBuf_Enum, Clone, Serialize, Deserialize)]
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
        let view_data = "".to_string();
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

#[derive(Default, ProtoBuf)]
pub struct QueryViewRequest {
    #[pb(index = 1)]
    pub view_ids: Vec<String>,
}

#[derive(Default, ProtoBuf, Clone, Debug)]
pub struct ViewId {
    #[pb(index = 1)]
    pub view_id: String,
}

impl std::convert::From<String> for ViewId {
    fn from(view_id: String) -> Self {
        ViewId { view_id }
    }
}

impl TryInto<ViewId> for QueryViewRequest {
    type Error = ErrorCode;
    fn try_into(self) -> Result<ViewId, Self::Error> {
        debug_assert!(self.view_ids.len() == 1);
        if self.view_ids.len() != 1 {
            log::error!("The len of view_ids should be equal to 1");
            return Err(ErrorCode::ViewIdInvalid);
        }

        let view_id = self.view_ids.first().unwrap().clone();
        let view_id = ViewIdentify::parse(view_id)?.0;

        Ok(ViewId { view_id })
    }
}

#[derive(Default, ProtoBuf)]
pub struct RepeatedViewId {
    #[pb(index = 1)]
    pub items: Vec<String>,
}

impl TryInto<RepeatedViewId> for QueryViewRequest {
    type Error = ErrorCode;

    fn try_into(self) -> Result<RepeatedViewId, Self::Error> {
        let mut view_ids = vec![];
        for view_id in self.view_ids {
            let view_id = ViewIdentify::parse(view_id)?.0;

            view_ids.push(view_id);
        }

        Ok(RepeatedViewId { items: view_ids })
    }
}

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
        let view_id = ViewIdentify::parse(self.view_id)?.0;

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
