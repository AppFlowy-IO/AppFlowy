use crate::entities::{GridFilter, GridGroup, GridSort};
use crate::parser::NotEmptyStr;
use flowy_error_code::ErrorCode;

pub struct ViewFilterParser(pub GridFilter);

impl ViewFilterParser {
    pub fn parse(value: GridFilter) -> Result<GridFilter, ErrorCode> {
        let field_id = match value.field_id {
            None => None,
            Some(field_id) => Some(NotEmptyStr::parse(field_id).map_err(|_| ErrorCode::FieldIdIsEmpty)?.0),
        };

        Ok(GridFilter { field_id })
    }
}

pub struct ViewGroupParser(pub GridGroup);

impl ViewGroupParser {
    pub fn parse(value: GridGroup) -> Result<GridGroup, ErrorCode> {
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

        Ok(GridGroup {
            group_field_id,
            sub_group_field_id,
        })
    }
}

pub struct ViewSortParser(pub GridSort);

impl ViewSortParser {
    pub fn parse(value: GridSort) -> Result<GridSort, ErrorCode> {
        let field_id = match value.field_id {
            None => None,
            Some(field_id) => Some(NotEmptyStr::parse(field_id).map_err(|_| ErrorCode::FieldIdIsEmpty)?.0),
        };

        Ok(GridSort { field_id })
    }
}
