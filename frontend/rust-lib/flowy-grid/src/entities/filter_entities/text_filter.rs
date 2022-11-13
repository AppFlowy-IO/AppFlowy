use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_error::ErrorCode;
use grid_rev_model::FilterRevision;
use std::sync::Arc;

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct TextFilterPB {
    #[pb(index = 1)]
    pub condition: TextFilterCondition,

    #[pb(index = 2, one_of)]
    pub content: Option<String>,
}

#[derive(Debug, Clone, PartialEq, Eq, ProtoBuf_Enum)]
#[repr(u8)]
pub enum TextFilterCondition {
    Is = 0,
    IsNot = 1,
    Contains = 2,
    DoesNotContain = 3,
    StartsWith = 4,
    EndsWith = 5,
    TextIsEmpty = 6,
    TextIsNotEmpty = 7,
}

impl std::convert::From<TextFilterCondition> for u32 {
    fn from(value: TextFilterCondition) -> Self {
        value as u32
    }
}

impl std::default::Default for TextFilterCondition {
    fn default() -> Self {
        TextFilterCondition::Is
    }
}
impl std::convert::TryFrom<u8> for TextFilterCondition {
    type Error = ErrorCode;

    fn try_from(value: u8) -> Result<Self, Self::Error> {
        match value {
            0 => Ok(TextFilterCondition::Is),
            1 => Ok(TextFilterCondition::IsNot),
            2 => Ok(TextFilterCondition::Contains),
            3 => Ok(TextFilterCondition::DoesNotContain),
            4 => Ok(TextFilterCondition::StartsWith),
            5 => Ok(TextFilterCondition::EndsWith),
            6 => Ok(TextFilterCondition::TextIsEmpty),
            7 => Ok(TextFilterCondition::TextIsNotEmpty),
            _ => Err(ErrorCode::InvalidData),
        }
    }
}

impl std::convert::From<Arc<FilterRevision>> for TextFilterPB {
    fn from(rev: Arc<FilterRevision>) -> Self {
        TextFilterPB {
            condition: TextFilterCondition::try_from(rev.condition).unwrap_or(TextFilterCondition::Is),
            content: rev.content.clone(),
        }
    }
}
