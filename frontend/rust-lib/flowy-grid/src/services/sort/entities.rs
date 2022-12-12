use crate::entities::FieldType;
use grid_rev_model::FieldTypeRevision;

#[derive(Hash, Eq, PartialEq, Debug, Clone)]
pub struct SortType {
    pub field_id: String,
    pub field_type: FieldType,
}

impl Into<FieldTypeRevision> for SortType {
    fn into(self) -> FieldTypeRevision {
        self.field_type.into()
    }
}
