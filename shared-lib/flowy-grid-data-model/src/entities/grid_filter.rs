use crate::parser::NotEmptyStr;
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_error_code::ErrorCode;

use crate::entities::FieldType;
use crate::revision::{
    FilterInfoRevision, GridFilterRevision, NumberFilterConditionRevision, TextFilterConditionRevision,
};
use std::convert::TryInto;

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct GridFilter {
    #[pb(index = 1)]
    pub id: String,

    #[pb(index = 2)]
    pub field_id: String,

    #[pb(index = 3)]
    pub info: FilterInfo,
}

impl std::convert::From<GridFilterRevision> for GridFilter {
    fn from(rev: GridFilterRevision) -> Self {
        GridFilter {
            id: rev.id,
            field_id: rev.field_id,
            info: rev.info.into(),
        }
    }
}

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct FilterInfo {
    #[pb(index = 1, one_of)]
    pub condition: Option<String>,

    #[pb(index = 2, one_of)]
    pub content: Option<String>,
}

impl std::convert::From<FilterInfoRevision> for FilterInfo {
    fn from(rev: FilterInfoRevision) -> Self {
        FilterInfo {
            condition: rev.condition,
            content: rev.content,
        }
    }
}

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct RepeatedGridFilter {
    #[pb(index = 1)]
    pub items: Vec<GridFilter>,
}

impl std::convert::From<Vec<GridFilterRevision>> for RepeatedGridFilter {
    fn from(revs: Vec<GridFilterRevision>) -> Self {
        RepeatedGridFilter {
            items: revs.into_iter().map(|rev| rev.into()).collect(),
        }
    }
}

impl std::convert::From<Vec<GridFilter>> for RepeatedGridFilter {
    fn from(items: Vec<GridFilter>) -> Self {
        Self { items }
    }
}

#[derive(ProtoBuf, Debug, Default, Clone)]
pub struct CreateGridFilterPayload {
    #[pb(index = 1)]
    pub field_id: String,

    #[pb(index = 2)]
    pub field_type: FieldType,
}

pub struct CreateGridFilterParams {
    pub field_id: String,
    pub field_type: FieldType,
}

impl TryInto<CreateGridFilterParams> for CreateGridFilterPayload {
    type Error = ErrorCode;

    fn try_into(self) -> Result<CreateGridFilterParams, Self::Error> {
        let field_id = NotEmptyStr::parse(self.field_id)
            .map_err(|_| ErrorCode::FieldIdIsEmpty)?
            .0;

        Ok(CreateGridFilterParams {
            field_id,
            field_type: self.field_type,
        })
    }
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

impl std::convert::From<TextFilterConditionRevision> for TextFilterCondition {
    fn from(rev: TextFilterConditionRevision) -> Self {
        match rev {
            TextFilterConditionRevision::Is => TextFilterCondition::Is,
            TextFilterConditionRevision::IsNot => TextFilterCondition::IsNot,
            TextFilterConditionRevision::Contains => TextFilterCondition::Contains,
            TextFilterConditionRevision::DoesNotContain => TextFilterCondition::DoesNotContain,
            TextFilterConditionRevision::StartsWith => TextFilterCondition::StartsWith,
            TextFilterConditionRevision::EndsWith => TextFilterCondition::EndsWith,
            TextFilterConditionRevision::IsEmpty => TextFilterCondition::TextIsEmpty,
            TextFilterConditionRevision::IsNotEmpty => TextFilterCondition::TextIsNotEmpty,
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq, ProtoBuf_Enum)]
#[repr(u8)]
pub enum NumberFilterCondition {
    Equal = 0,
    NotEqual = 1,
    GreaterThan = 2,
    LessThan = 3,
    GreaterThanOrEqualTo = 4,
    LessThanOrEqualTo = 5,
    NumberIsEmpty = 6,
    NumberIsNotEmpty = 7,
}

impl std::convert::From<NumberFilterConditionRevision> for NumberFilterCondition {
    fn from(rev: NumberFilterConditionRevision) -> Self {
        match rev {
            NumberFilterConditionRevision::Equal => NumberFilterCondition::Equal,
            NumberFilterConditionRevision::NotEqual => NumberFilterCondition::NotEqual,
            NumberFilterConditionRevision::GreaterThan => NumberFilterCondition::GreaterThan,
            NumberFilterConditionRevision::LessThan => NumberFilterCondition::LessThan,
            NumberFilterConditionRevision::GreaterThanOrEqualTo => NumberFilterCondition::GreaterThan,
            NumberFilterConditionRevision::LessThanOrEqualTo => NumberFilterCondition::LessThanOrEqualTo,
            NumberFilterConditionRevision::IsEmpty => NumberFilterCondition::NumberIsEmpty,
            NumberFilterConditionRevision::IsNotEmpty => NumberFilterCondition::NumberIsNotEmpty,
        }
    }
}
