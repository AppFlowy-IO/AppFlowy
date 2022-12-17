use crate::entities::FieldType;
use crate::services::cell::{CellDataChangeset, CellDataDecoder, CellProtobufBlob, FromCellString};
use crate::services::field::{
    CheckboxTypeOptionPB, ChecklistTypeOptionPB, DateTypeOptionPB, MultiSelectTypeOptionPB, NumberTypeOptionPB,
    RichTextTypeOptionPB, SingleSelectTypeOptionPB, URLTypeOptionPB,
};
use bytes::Bytes;
use flowy_error::FlowyResult;
use grid_rev_model::FieldRevision;
use protobuf::ProtobufError;
use std::fmt::Debug;

pub trait TypeOption {
    type CellData: FromCellString + Default;
    type CellChangeset;
    type CellPBType: TryInto<Bytes, Error = ProtobufError> + Debug;
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
    ) -> FlowyResult<CellProtobufBlob>;

    fn stringify_cell_data(&self, cell_data: String, field_type: &FieldType, field_rev: &FieldRevision) -> String;
}

pub trait TypeOptionCellData: TypeOption {
    ///
    /// Convert the decoded cell data into corresponding `Protobuf struct`.
    /// For example:
    ///    FieldType::URL => URLCellDataPB
    ///    FieldType::Date=> DateCellDataPB
    fn convert_into_pb_type(&self, cell_data: <Self as TypeOption>::CellData) -> <Self as TypeOption>::CellPBType;

    /// Decodes the opaque cell data to corresponding data struct.
    // For example, the cell data is timestamp if its field type is `FieldType::Date`. This cell
    // data can not directly show to user. So it needs to be encode as the date string with custom
    // format setting. Encode `1647251762` to `"Mar 14,2022`
    fn decode_type_option_cell_data(&self, cell_data: String) -> FlowyResult<<Self as TypeOption>::CellData>;
}

impl<T> TypeOptionCellDataHandler for T
where
    T: TypeOption + CellDataDecoder + CellDataChangeset + TypeOptionCellData,
{
    fn handle_cell_data(
        &self,
        cell_data: String,
        field_type: &FieldType,
        field_rev: &FieldRevision,
    ) -> FlowyResult<CellProtobufBlob> {
        let cell_data = self.try_decode_cell_data(cell_data, field_type, field_rev)?;
        CellProtobufBlob::from(self.convert_into_pb_type(cell_data))
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
