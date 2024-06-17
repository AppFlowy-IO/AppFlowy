use crate::entities::TranslateTypeOptionPB;
use crate::services::field::tag_type_option::tag::{TagOption, TagTypeOption};
use flowy_derive::ProtoBuf;
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct TagTypeOptionPB {
  #[pb(index = 1)]
  pub tags: Vec<TagItemPB>,
}

#[derive(ProtoBuf, Debug, Clone, Default)]
pub struct TagItemPB {
  #[pb(index = 1)]
  color: String,

  #[pb(index = 2)]
  text: String,
}

impl From<TagOption> for TagItemPB {
  fn from(value: TagOption) -> Self {
    Self {
      color: value.color,
      text: value.text,
    }
  }
}

impl From<TagItemPB> for TagOption {
  fn from(value: TagItemPB) -> Self {
    Self {
      color: value.color,
      text: value.text,
    }
  }
}

impl From<TagTypeOption> for TagTypeOptionPB {
  fn from(value: TagTypeOption) -> Self {
    Self {
      tags: value.tags.into_iter().map(TagItemPB::from).collect(),
    }
  }
}

impl From<TagTypeOptionPB> for TagTypeOption {
  fn from(value: TagTypeOptionPB) -> Self {
    Self {
      tags: value.tags.into_iter().map(TagOption::from).collect(),
    }
  }
}
