use crate::entities::{
    CheckboxCondition, DateFilterCondition, FieldType, NumberFilterCondition, SelectOptionCondition,
    TextFilterCondition,
};
use flowy_derive::ProtoBuf;
use flowy_error::ErrorCode;
use flowy_grid_data_model::parser::NotEmptyStr;
use flowy_grid_data_model::revision::{FieldRevision, GridFilterRevision};
use flowy_sync::entities::grid::{CreateGridFilterParams, DeleteFilterParams};
use std::convert::TryInto;
use std::sync::Arc;

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

impl std::convert::From<Vec<Arc<GridFilterRevision>>> for RepeatedGridFilter {
    fn from(revs: Vec<Arc<GridFilterRevision>>) -> Self {
        RepeatedGridFilter {
            items: revs.into_iter().map(|rev| rev.as_ref().into()).collect(),
        }
    }
}

impl std::convert::From<Vec<GridFilter>> for RepeatedGridFilter {
    fn from(items: Vec<GridFilter>) -> Self {
        Self { items }
    }
}

#[derive(ProtoBuf, Debug, Default, Clone)]
pub struct DeleteFilterPayload {
    #[pb(index = 1)]
    pub filter_id: String,

    #[pb(index = 2)]
    pub field_type: FieldType,
}

impl TryInto<DeleteFilterParams> for DeleteFilterPayload {
    type Error = ErrorCode;

    fn try_into(self) -> Result<DeleteFilterParams, Self::Error> {
        let filter_id = NotEmptyStr::parse(self.filter_id)
            .map_err(|_| ErrorCode::UnexpectedEmptyString)?
            .0;
        Ok(DeleteFilterParams {
            filter_id,
            field_type_rev: self.field_type.into(),
        })
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
            field_type: field_rev.field_type_rev.into(),
            condition: condition.into(),
            content,
        }
    }
}

impl TryInto<CreateGridFilterParams> for CreateGridFilterPayload {
    type Error = ErrorCode;

    fn try_into(self) -> Result<CreateGridFilterParams, Self::Error> {
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

        Ok(CreateGridFilterParams {
            field_id,
            field_type_rev: self.field_type.into(),
            condition,
            content: self.content,
        })
    }
}
