use crate::entities::parser::NotEmptyStr;
use crate::entities::{
    CheckboxFilterCondition, DateFilterCondition, FieldType, NumberFilterCondition, SelectOptionCondition,
    TextFilterCondition,
};
use crate::services::filter::FilterType;
use flowy_derive::ProtoBuf;
use flowy_error::ErrorCode;
use grid_rev_model::{FieldRevision, FieldTypeRevision, FilterRevision};
use std::convert::TryInto;
use std::sync::Arc;

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct FilterPB {
    #[pb(index = 1)]
    pub id: String,
}

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct RepeatedGridFilterConfigurationPB {
    #[pb(index = 1)]
    pub items: Vec<FilterPB>,
}

impl std::convert::From<&FilterRevision> for FilterPB {
    fn from(rev: &FilterRevision) -> Self {
        Self { id: rev.id.clone() }
    }
}

impl std::convert::From<Vec<Arc<FilterRevision>>> for RepeatedGridFilterConfigurationPB {
    fn from(revs: Vec<Arc<FilterRevision>>) -> Self {
        RepeatedGridFilterConfigurationPB {
            items: revs.into_iter().map(|rev| rev.as_ref().into()).collect(),
        }
    }
}

impl std::convert::From<Vec<FilterPB>> for RepeatedGridFilterConfigurationPB {
    fn from(items: Vec<FilterPB>) -> Self {
        Self { items }
    }
}

#[derive(ProtoBuf, Debug, Default, Clone)]
pub struct DeleteFilterPayloadPB {
    #[pb(index = 1)]
    pub field_id: String,

    #[pb(index = 2)]
    pub field_type: FieldType,

    #[pb(index = 3)]
    pub filter_id: String,
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

        let filter_type = FilterType {
            field_id,
            field_type: self.field_type,
        };

        Ok(DeleteFilterParams { filter_id, filter_type })
    }
}

pub struct DeleteFilterParams {
    pub filter_type: FilterType,
    pub filter_id: String,
}

#[derive(ProtoBuf, Debug, Default, Clone)]
pub struct CreateFilterPayloadPB {
    #[pb(index = 1)]
    pub field_id: String,

    #[pb(index = 2)]
    pub field_type: FieldType,

    #[pb(index = 3)]
    pub condition: u32,

    #[pb(index = 4)]
    pub content: String,
}

impl CreateFilterPayloadPB {
    #[allow(dead_code)]
    pub fn new<T: Into<u32>>(field_rev: &FieldRevision, condition: T, content: String) -> Self {
        Self {
            field_id: field_rev.id.clone(),
            field_type: field_rev.ty.into(),
            condition: condition.into(),
            content,
        }
    }
}

impl TryInto<CreateFilterParams> for CreateFilterPayloadPB {
    type Error = ErrorCode;

    fn try_into(self) -> Result<CreateFilterParams, Self::Error> {
        let field_id = NotEmptyStr::parse(self.field_id)
            .map_err(|_| ErrorCode::FieldIdIsEmpty)?
            .0;
        let condition = self.condition as u8;
        match self.field_type {
            FieldType::RichText | FieldType::URL => {
                let _ = TextFilterCondition::try_from(condition)?;
            }
            FieldType::Checkbox => {
                let _ = CheckboxFilterCondition::try_from(condition)?;
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

        Ok(CreateFilterParams {
            field_id,
            field_type_rev: self.field_type.into(),
            condition,
            content: self.content,
        })
    }
}

pub struct CreateFilterParams {
    pub field_id: String,
    pub field_type_rev: FieldTypeRevision,
    pub condition: u8,
    pub content: String,
}
