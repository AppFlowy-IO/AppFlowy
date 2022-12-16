use crate::entities::FieldType;
use crate::services::cell::{CellBytes, CellDataChangeset, CellDataDecoder, FromCellString, TypeCellData};
use crate::services::field::{
    CheckboxTypeOptionPB, ChecklistTypeOptionPB, DateTypeOptionPB, MultiSelectTypeOptionPB, NumberTypeOptionPB,
    RichTextTypeOptionPB, SingleSelectTypeOptionPB, URLTypeOptionPB,
};
use flowy_error::FlowyResult;
use grid_rev_model::FieldRevision;

pub trait TypeOption {
    type CellData: FromCellString;
    type CellChangeset;
    type CellPBType;
}

pub trait TypeOptionConfiguration {
    type CellFilterConfiguration;
}

pub trait TypeOptionCellDataHandler {
    fn handle_cell_data(
        &self,
        cell_data: String,
        decoded_field_type: &FieldType,
        field_rev: &FieldRevision,
    ) -> FlowyResult<CellBytes>;

    fn stringify_cell_data(&self, cell_data: String, field_type: &FieldType, field_rev: &FieldRevision) -> String;
}

pub trait TypeOptionCellData: TypeOption {
    fn convert_into_pb_type(&self, cell_data: <Self as TypeOption>::CellData) -> <Self as TypeOption>::CellPBType {
        todo!()
    }

    fn decode_type_cell_data(&self, type_cell_data: TypeCellData) -> FlowyResult<<Self as TypeOption>::CellData> {
        self.decode_type_option_cell_data(type_cell_data.data)
    }

    fn decode_type_option_cell_data(&self, cell_data: String) -> FlowyResult<<Self as TypeOption>::CellData>;
}

impl<T> TypeOptionCellDataHandler for T
where
    T: TypeOption + CellDataDecoder + CellDataChangeset,
{
    fn handle_cell_data(
        &self,
        cell_data: String,
        field_type: &FieldType,
        field_rev: &FieldRevision,
    ) -> FlowyResult<CellBytes> {
        //
        self.try_decode_cell_data(cell_data, field_type, field_rev)
    }

    fn stringify_cell_data(
        &self,
        cell_data: String,
        decoded_field_type: &FieldType,
        field_rev: &FieldRevision,
    ) -> String {
        self.decode_cell_data_to_str(cell_data, decoded_field_type, field_rev)
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

    pub fn get_type_option_handler(&self, field_type: &FieldType) -> Option<Box<dyn TypeOptionCellDataHandler>> {
        match field_type {
            FieldType::RichText => self
                .field_rev
                .get_type_option::<RichTextTypeOptionPB>(field_type.into())
                .map(|type_option| Box::new(type_option) as Box<dyn TypeOptionCellDataHandler>),
            FieldType::Number => self
                .field_rev
                .get_type_option::<NumberTypeOptionPB>(field_type.into())
                .map(|type_option| Box::new(type_option) as Box<dyn TypeOptionCellDataHandler>),
            FieldType::DateTime => self
                .field_rev
                .get_type_option::<DateTypeOptionPB>(field_type.into())
                .map(|type_option| Box::new(type_option) as Box<dyn TypeOptionCellDataHandler>),
            FieldType::SingleSelect => self
                .field_rev
                .get_type_option::<SingleSelectTypeOptionPB>(field_type.into())
                .map(|type_option| Box::new(type_option) as Box<dyn TypeOptionCellDataHandler>),
            FieldType::MultiSelect => self
                .field_rev
                .get_type_option::<MultiSelectTypeOptionPB>(field_type.into())
                .map(|type_option| Box::new(type_option) as Box<dyn TypeOptionCellDataHandler>),
            FieldType::Checkbox => self
                .field_rev
                .get_type_option::<CheckboxTypeOptionPB>(field_type.into())
                .map(|type_option| Box::new(type_option) as Box<dyn TypeOptionCellDataHandler>),
            FieldType::URL => self
                .field_rev
                .get_type_option::<URLTypeOptionPB>(field_type.into())
                .map(|type_option| Box::new(type_option) as Box<dyn TypeOptionCellDataHandler>),
            FieldType::Checklist => self
                .field_rev
                .get_type_option::<ChecklistTypeOptionPB>(field_type.into())
                .map(|type_option| Box::new(type_option) as Box<dyn TypeOptionCellDataHandler>),
        }
    }
}
