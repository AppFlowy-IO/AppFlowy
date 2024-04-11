use crate::entities::parser::view::ViewIdentify;
use collab_folder::{IconType, ViewIcon};
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_error::ErrorCode;

#[derive(ProtoBuf_Enum, Clone, Debug, PartialEq, Eq, Default)]
pub enum ViewIconTypePB {
  #[default]
  Emoji = 0,
  Url = 1,
  Icon = 2,
}

impl std::convert::From<ViewIconTypePB> for IconType {
  fn from(rev: ViewIconTypePB) -> Self {
    match rev {
      ViewIconTypePB::Emoji => IconType::Emoji,
      ViewIconTypePB::Url => IconType::Url,
      ViewIconTypePB::Icon => IconType::Icon,
    }
  }
}

impl From<IconType> for ViewIconTypePB {
  fn from(val: IconType) -> Self {
    match val {
      IconType::Emoji => ViewIconTypePB::Emoji,
      IconType::Url => ViewIconTypePB::Url,
      IconType::Icon => ViewIconTypePB::Icon,
    }
  }
}

#[derive(Default, ProtoBuf, Debug, Clone, PartialEq, Eq)]
pub struct ViewIconPB {
  #[pb(index = 1)]
  pub ty: ViewIconTypePB,
  #[pb(index = 2)]
  pub value: String,
}

impl std::convert::From<ViewIconPB> for ViewIcon {
  fn from(rev: ViewIconPB) -> Self {
    ViewIcon {
      ty: rev.ty.into(),
      value: rev.value,
    }
  }
}

impl From<ViewIcon> for ViewIconPB {
  fn from(val: ViewIcon) -> Self {
    ViewIconPB {
      ty: val.ty.into(),
      value: val.value,
    }
  }
}

#[derive(Default, ProtoBuf)]
pub struct UpdateViewIconPayloadPB {
  #[pb(index = 1)]
  pub view_id: String,

  #[pb(index = 2, one_of)]
  pub icon: Option<ViewIconPB>,
}

#[derive(Clone, Debug)]
pub struct UpdateViewIconParams {
  pub view_id: String,
  pub icon: Option<ViewIcon>,
}

impl TryInto<UpdateViewIconParams> for UpdateViewIconPayloadPB {
  type Error = ErrorCode;

  fn try_into(self) -> Result<UpdateViewIconParams, Self::Error> {
    let view_id = ViewIdentify::parse(self.view_id)?.0;

    let icon = self.icon.map(|icon| icon.into());

    Ok(UpdateViewIconParams { view_id, icon })
  }
}
