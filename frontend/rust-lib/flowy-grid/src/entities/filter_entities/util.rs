use crate::entities::parser::NotEmptyStr;
use crate::entities::{
    CheckboxCondition, DateFilterCondition, FieldType, NumberFilterCondition, SelectOptionCondition,
    TextFilterCondition,
};
use flowy_derive::ProtoBuf;
use flowy_error::ErrorCode;
use grid_rev_model::{FieldRevision, FieldTypeRevision, FilterConfigurationRevision};
use std::convert::TryInto;
use std::sync::Arc;

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct GridFilterConfigurationPB {
    #[pb(index = 1)]
    pub id: String,
}

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct RepeatedGridFilterConfigurationPB {
    #[pb(index = 1)]
    pub items: Vec<GridFilterConfigurationPB>,
}

impl std::convert::From<&FilterConfigurationRevision> for GridFilterConfigurationPB {
    fn from(rev: &FilterConfigurationRevision) -> Self {
        Self { id: rev.id.clone() }
    }
}

impl std::convert::From<Vec<Arc<FilterConfigurationRevision>>> for RepeatedGridFilterConfigurationPB {
    fn from(revs: Vec<Arc<FilterConfigurationRevision>>) -> Self {
        RepeatedGridFilterConfigurationPB {
            items: revs.into_iter().map(|rev| rev.as_ref().into()).collect(),
        }
    }
}

impl std::convert::From<Vec<GridFilterConfigurationPB>> for RepeatedGridFilterConfigurationPB {
    fn from(items: Vec<GridFilterConfigurationPB>) -> Self {
        Self { items }
    }
}

#[derive(ProtoBuf, Debug, Default, Clone)]
pub struct DeleteFilterPayloadPB {
    #[pb(index = 1)]
    pub field_id: String,

    #[pb(index = 2)]
    pub filter_id: String,

    #[pb(index = 3)]
    pub field_type: FieldType,
}

impl TryInto<DeleteFilterParams> for DeleteFilterPayloadPB {
    type Error = ErrorCode;

    fn try_into(self) -> Result<DeleteFilterParams, Self::Error> {
        let field_id = NotEmptyStr::parse(self.field_id)
            .map_err(|_| ErrorCode::FieldIdIsEmpty)?
            .0;
        let filter_id = NotEmptyStr::parse(self.filter_id)
            .map_err(|_| ErrorCode::UnexpectedEmptyString)?
            .0;
        Ok(DeleteFilterParams {
            field_id,
            filter_id,
            field_type_rev: self.field_type.into(),
        })
    }
}

pub struct DeleteFilterParams {
    pub field_id: String,
    pub filter_id: String,
    pub field_type_rev: FieldTypeRevision,
}

#[derive(ProtoBuf, Debug, Default, Clone)]
pub struct InsertFilterPayloadPB {
    #[pb(index = 1)]
    pub field_id: String,

    #[pb(index = 2)]
    pub field_type: FieldType,

    #[pb(index = 3)]
    pub condition: i32,

    #[pb(index = 4, one_of)]
    pub content: Option<String>,
}

impl InsertFilterPayloadPB {
    #[allow(dead_code)]
    pub fn new<T: Into<i32>>(field_rev: &FieldRevision, condition: T, content: Option<String>) -> Self {
        Self {
            field_id: field_rev.id.clone(),
            field_type: field_rev.ty.into(),
            condition: condition.into(),
            content,
        }
    }
}

impl TryInto<InsertFilterParams> for InsertFilterPayloadPB {
    type Error = ErrorCode;

    fn try_into(self) -> Result<InsertFilterParams, Self::Error> {
        let field_id = NotEmptyStr::parse(self.field_id)
            .map_err(|_| ErrorCode::FieldIdIsEmpty)?
            .0;
        let condition = self.condition as u8;
        match self.field_type {
            FieldType::RichText | FieldType::URL => {
                let _ = TextFilterCondition::try_from(condition)?;
            }
            FieldType::Checkbox => {
                let _ = CheckboxCondition::try_from(condition)?;
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

        Ok(InsertFilterParams {
            field_id,
            field_type_rev: self.field_type.into(),
            condition,
            content: self.content,
        })
    }
}

pub struct InsertFilterParams {
    pub field_id: String,
    pub field_type_rev: FieldTypeRevision,
    pub condition: u8,
    pub content: Option<String>,
}
