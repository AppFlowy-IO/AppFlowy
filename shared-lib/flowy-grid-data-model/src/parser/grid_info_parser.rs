use crate::entities::{ViewFilter, ViewGroup, ViewSort};
use crate::parser::NotEmptyStr;
use flowy_error_code::ErrorCode;

pub struct ViewFilterParser(pub ViewFilter);

impl ViewFilterParser {
    pub fn parse(value: ViewFilter) -> Result<ViewFilter, ErrorCode> {
        let field_id = match value.field_id {
            None => None,
            Some(field_id) => Some(NotEmptyStr::parse(field_id).map_err(|_| ErrorCode::FieldIdIsEmpty)?.0),
        };

        Ok(ViewFilter { field_id })
    }
}

pub struct ViewGroupParser(pub ViewGroup);

impl ViewGroupParser {
    pub fn parse(value: ViewGroup) -> Result<ViewGroup, ErrorCode> {
        let group_field_id = match value.group_field_id {
            None => None,
            Some(group_field_id) => Some(
                NotEmptyStr::parse(group_field_id)
                    .map_err(|_| ErrorCode::FieldIdIsEmpty)?
                    .0,
            ),
        };

        let sub_group_field_id = match value.sub_group_field_id {
            None => None,
            Some(sub_group_field_id) => Some(
                NotEmptyStr::parse(sub_group_field_id)
                    .map_err(|_| ErrorCode::FieldIdIsEmpty)?
                    .0,
            ),
        };

        Ok(ViewGroup {
            group_field_id,
            sub_group_field_id,
        })
    }
}

pub struct ViewSortParser(pub ViewSort);

impl ViewSortParser {
    pub fn parse(value: ViewSort) -> Result<ViewSort, ErrorCode> {
        let field_id = match value.field_id {
            None => None,
            Some(field_id) => Some(NotEmptyStr::parse(field_id).map_err(|_| ErrorCode::FieldIdIsEmpty)?.0),
        };

        Ok(ViewSort { field_id })
    }
}
