use crate::entities::{ViewFilter, ViewGroup, ViewSort};
use crate::errors::ErrorCode;
use crate::parser::view_info::ObjectId;

pub struct ViewFilterParser(pub ViewFilter);

impl ViewFilterParser {
    pub fn parse(value: ViewFilter) -> Result<ViewFilter, ErrorCode> {
        let object_id = ObjectId::parse(value.object_id)?.0;
        Ok(ViewFilter { object_id })
    }
}

pub struct ViewGroupParser(pub ViewGroup);

impl ViewGroupParser {
    pub fn parse(value: ViewGroup) -> Result<ViewGroup, ErrorCode> {
        let group_object_id = ObjectId::parse(value.group_object_id)?.0;

        let sub_group_object_id = match value.sub_group_object_id {
            None => None,
            Some(object_id) => Some(ObjectId::parse(object_id)?.0),
        };

        Ok(ViewGroup {
            group_object_id,
            sub_group_object_id,
        })
    }
}

pub struct ViewSortParser(pub ViewSort);

impl ViewSortParser {
    pub fn parse(value: ViewSort) -> Result<ViewSort, ErrorCode> {
        let object_id = ObjectId::parse(value.object_id)?.0;

        Ok(ViewSort { object_id })
    }
}
