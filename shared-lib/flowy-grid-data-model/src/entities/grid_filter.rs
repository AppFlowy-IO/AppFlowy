use crate::parser::NotEmptyStr;
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_error_code::ErrorCode;

use crate::entities::FieldType;
use crate::revision::{FieldRevision, GridFilterRevision};
use std::convert::TryInto;

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct GridFilter {
    #[pb(index = 1)]
    pub id: String,
}

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct RepeatedGridFilter {
    #[pb(index = 1)]
    pub items: Vec<GridFilter>,
}

impl std::convert::From<&GridFilterRevision> for GridFilter {
    fn from(rev: &GridFilterRevision) -> Self {
        Self { id: rev.id.clone() }
    }
}

impl std::convert::From<&Vec<GridFilterRevision>> for RepeatedGridFilter {
    fn from(revs: &Vec<GridFilterRevision>) -> Self {
        RepeatedGridFilter {
            items: revs.iter().map(|rev| rev.into()).collect(),
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

    #[pb(index = 3)]
    pub condition: i32,

    #[pb(index = 4, one_of)]
    pub content: Option<String>,
}

impl CreateGridFilterPayload {
    #[allow(dead_code)]
    pub fn new<T: Into<i32>>(field_rev: &FieldRevision, condition: T, content: Option<String>) -> Self {
        Self {
            field_id: field_rev.id.clone(),
            field_type: field_rev.field_type.clone(),
            condition: condition.into(),
            content,
        }
    }
}

pub struct CreateGridFilterParams {
    pub field_id: String,
    pub field_type: FieldType,
    pub condition: u8,
    pub content: Option<String>,
}

impl TryInto<CreateGridFilterParams> for CreateGridFilterPayload {
    type Error = ErrorCode;

    fn try_into(self) -> Result<CreateGridFilterParams, Self::Error> {
        let field_id = NotEmptyStr::parse(self.field_id)
            .map_err(|_| ErrorCode::FieldIdIsEmpty)?
            .0;
        let condition = self.condition as u8;
        match self.field_type {
            FieldType::RichText | FieldType::Checkbox | FieldType::URL => {
                let _ = TextFilterCondition::try_from(condition)?;
            }
            FieldType::Number => {
                let _ = NumberFilterCondition::try_from(condition)?;
            }
            FieldType::DateTime => {
                let _ = DateFilterCondition::try_from(condition)?;
            }
            FieldType::SingleSelect | FieldType::MultiSelect => {
                let _ = SelectOptionCondition::try_from(condition)?;
            }
        }

        Ok(CreateGridFilterParams {
            field_id,
            field_type: self.field_type,
            condition,
            content: self.content,
        })
    }
}

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct GridTextFilter {
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
impl std::convert::Into<i32> for TextFilterCondition {
    fn into(self) -> i32 {
        self as i32
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

impl std::convert::From<GridFilterRevision> for GridTextFilter {
    fn from(rev: GridFilterRevision) -> Self {
        GridTextFilter {
            condition: TextFilterCondition::try_from(rev.condition).unwrap_or(TextFilterCondition::Is),
            content: rev.content,
        }
    }
}

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct GridNumberFilter {
    #[pb(index = 1)]
    pub condition: NumberFilterCondition,

    #[pb(index = 2, one_of)]
    pub content: Option<String>,
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
impl std::default::Default for NumberFilterCondition {
    fn default() -> Self {
        NumberFilterCondition::Equal
    }
}

impl std::convert::Into<i32> for NumberFilterCondition {
    fn into(self) -> i32 {
        self as i32
    }
}
impl std::convert::TryFrom<u8> for NumberFilterCondition {
    type Error = ErrorCode;

    fn try_from(n: u8) -> Result<Self, Self::Error> {
        match n {
            0 => Ok(NumberFilterCondition::Equal),
            1 => Ok(NumberFilterCondition::NotEqual),
            2 => Ok(NumberFilterCondition::GreaterThan),
            3 => Ok(NumberFilterCondition::LessThan),
            4 => Ok(NumberFilterCondition::GreaterThanOrEqualTo),
            5 => Ok(NumberFilterCondition::LessThanOrEqualTo),
            6 => Ok(NumberFilterCondition::NumberIsEmpty),
            7 => Ok(NumberFilterCondition::NumberIsNotEmpty),
            _ => Err(ErrorCode::InvalidData),
        }
    }
}

impl std::convert::From<GridFilterRevision> for GridNumberFilter {
    fn from(rev: GridFilterRevision) -> Self {
        GridNumberFilter {
            condition: NumberFilterCondition::try_from(rev.condition).unwrap_or(NumberFilterCondition::Equal),
            content: rev.content,
        }
    }
}

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct GridSelectOptionFilter {
    #[pb(index = 1)]
    pub condition: SelectOptionCondition,

    #[pb(index = 2, one_of)]
    pub content: Option<String>,
}

#[derive(Debug, Clone, PartialEq, Eq, ProtoBuf_Enum)]
#[repr(u8)]
pub enum SelectOptionCondition {
    OptionIs = 0,
    OptionIsNot = 1,
    OptionIsEmpty = 2,
    OptionIsNotEmpty = 3,
}

impl std::convert::Into<i32> for SelectOptionCondition {
    fn into(self) -> i32 {
        self as i32
    }
}

impl std::default::Default for SelectOptionCondition {
    fn default() -> Self {
        SelectOptionCondition::OptionIs
    }
}

impl std::convert::TryFrom<u8> for SelectOptionCondition {
    type Error = ErrorCode;

    fn try_from(value: u8) -> Result<Self, Self::Error> {
        match value {
            0 => Ok(SelectOptionCondition::OptionIs),
            1 => Ok(SelectOptionCondition::OptionIsNot),
            2 => Ok(SelectOptionCondition::OptionIsEmpty),
            3 => Ok(SelectOptionCondition::OptionIsNotEmpty),
            _ => Err(ErrorCode::InvalidData),
        }
    }
}

impl std::convert::From<GridFilterRevision> for GridSelectOptionFilter {
    fn from(rev: GridFilterRevision) -> Self {
        GridSelectOptionFilter {
            condition: SelectOptionCondition::try_from(rev.condition).unwrap_or(SelectOptionCondition::OptionIs),
            content: rev.content,
        }
    }
}

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct GridDateFilter {
    #[pb(index = 1)]
    pub condition: DateFilterCondition,

    #[pb(index = 2, one_of)]
    pub content: Option<String>,
}

#[derive(Debug, Clone, PartialEq, Eq, ProtoBuf_Enum)]
#[repr(u8)]
pub enum DateFilterCondition {
    DateIs = 0,
    DateBefore = 1,
    DateAfter = 2,
    DateOnOrBefore = 3,
    DateOnOrAfter = 4,
    DateWithIn = 5,
    DateIsEmpty = 6,
}

impl std::default::Default for DateFilterCondition {
    fn default() -> Self {
        DateFilterCondition::DateIs
    }
}

impl std::convert::TryFrom<u8> for DateFilterCondition {
    type Error = ErrorCode;

    fn try_from(value: u8) -> Result<Self, Self::Error> {
        match value {
            0 => Ok(DateFilterCondition::DateIs),
            1 => Ok(DateFilterCondition::DateBefore),
            2 => Ok(DateFilterCondition::DateAfter),
            3 => Ok(DateFilterCondition::DateOnOrBefore),
            4 => Ok(DateFilterCondition::DateOnOrAfter),
            5 => Ok(DateFilterCondition::DateWithIn),
            6 => Ok(DateFilterCondition::DateIsEmpty),
            _ => Err(ErrorCode::InvalidData),
        }
    }
}
impl std::convert::From<GridFilterRevision> for GridDateFilter {
    fn from(rev: GridFilterRevision) -> Self {
        GridDateFilter {
            condition: DateFilterCondition::try_from(rev.condition).unwrap_or(DateFilterCondition::DateIs),
            content: rev.content,
        }
    }
}
