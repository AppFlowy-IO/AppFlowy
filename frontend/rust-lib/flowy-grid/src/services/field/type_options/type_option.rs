use crate::entities::FieldType;
use crate::services::cell::{CellBytes, CellDataChangeset, CellDataDecoder, FromCellString, IntoCellData};
use crate::services::field::{
    CheckboxTypeOptionPB, ChecklistTypeOptionPB, DateTypeOptionPB, MultiSelectTypeOptionPB, NumberTypeOptionPB,
    RichTextTypeOptionPB, SingleSelectTypeOptionPB, URLTypeOptionPB,
};
use flowy_error::FlowyResult;
use grid_rev_model::{FieldRevision, TypeOptionDataDeserializer};

pub trait TypeOption {
    type CellData: FromCellString;
    type CellChangeset;
}

pub trait TypeOptionHandler {
    fn handle_cell_data(
        &self,
        cell_data: String,
        decoded_field_type: &FieldType,
        field_rev: &FieldRevision,
    ) -> FlowyResult<CellBytes>;

    fn stringify_cell_data(&self, cell_data: String, field_type: &FieldType, field_rev: &FieldRevision) -> String;
}

impl<T> TypeOptionHandler for T
where
    T: TypeOption + CellDataDecoder + CellDataChangeset,
{
    fn handle_cell_data(
        &self,
        cell_data: String,
        field_type: &FieldType,
        field_rev: &FieldRevision,
    ) -> FlowyResult<CellBytes> {
        self.try_decode_cell_data(cell_data.into(), field_type, field_rev)
    }

    fn stringify_cell_data(
        &self,
        cell_data: String,
        decoded_field_type: &FieldType,
        field_rev: &FieldRevision,
    ) -> String {
        self.decode_cell_data_to_str(cell_data.into(), decoded_field_type, field_rev)
            .unwrap_or_default()
    }
}

pub struct FieldRevisionExt<'a> {
    field_rev: &'a FieldRevision,
}

impl<'a> FieldRevisionExt<'a> {
    pub fn new(field_rev: &'a FieldRevision) -> Self {
        Self { field_rev }
    }

    pub fn get_type_option_handler(&self, field_type: &FieldType) -> Option<Box<dyn TypeOptionHandler>> {
        match field_type {
            FieldType::RichText => self
                .field_rev
                .get_type_option::<RichTextTypeOptionPB>(field_type.into())
                .and_then(|type_option| Some(Box::new(type_option) as Box<dyn TypeOptionHandler>)),
            FieldType::Number => self
                .field_rev
                .get_type_option::<NumberTypeOptionPB>(field_type.into())
                .and_then(|type_option| Some(Box::new(type_option) as Box<dyn TypeOptionHandler>)),
            FieldType::DateTime => self
                .field_rev
                .get_type_option::<DateTypeOptionPB>(field_type.into())
                .and_then(|type_option| Some(Box::new(type_option) as Box<dyn TypeOptionHandler>)),
            FieldType::SingleSelect => self
                .field_rev
                .get_type_option::<SingleSelectTypeOptionPB>(field_type.into())
                .and_then(|type_option| Some(Box::new(type_option) as Box<dyn TypeOptionHandler>)),
            FieldType::MultiSelect => self
                .field_rev
                .get_type_option::<MultiSelectTypeOptionPB>(field_type.into())
                .and_then(|type_option| Some(Box::new(type_option) as Box<dyn TypeOptionHandler>)),
            FieldType::Checkbox => self
                .field_rev
                .get_type_option::<CheckboxTypeOptionPB>(field_type.into())
                .and_then(|type_option| Some(Box::new(type_option) as Box<dyn TypeOptionHandler>)),
            FieldType::URL => self
                .field_rev
                .get_type_option::<URLTypeOptionPB>(field_type.into())
                .and_then(|type_option| Some(Box::new(type_option) as Box<dyn TypeOptionHandler>)),
            FieldType::Checklist => self
                .field_rev
                .get_type_option::<ChecklistTypeOptionPB>(field_type.into())
                .and_then(|type_option| Some(Box::new(type_option) as Box<dyn TypeOptionHandler>)),
        }
    }
}
