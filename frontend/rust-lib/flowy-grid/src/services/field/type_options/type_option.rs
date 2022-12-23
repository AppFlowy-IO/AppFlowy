use crate::entities::FieldType;
use crate::services::cell::{
    AnyTypeCache, AtomicCellDataCache, CellDataChangeset, CellDataDecoder, CellProtobufBlob, FromCellChangeset,
    FromCellString, TypeCellData,
};

use crate::services::filter::FromFilterString;
use bytes::Bytes;

use flowy_error::FlowyResult;
use grid_rev_model::FieldRevision;

use protobuf::ProtobufError;
use std::cmp::Ordering;
use std::fmt::Debug;

pub trait TypeOption {
    /// `CellData` represents as the decoded model for current type option. Each of them impl the
    /// `FromCellString` and `Default` trait. If the cell string can not be decoded into the specified
    /// cell data type then the default value will be returned.
    /// For example:
    ///     FieldType::Checkbox => CheckboxCellData
    ///     FieldType::Date => DateCellData
    ///     FieldType::URL => URLCellData
    ///
    /// Uses `StrCellData` for any `TypeOption` if their cell data is pure `String`.
    ///
    type CellData: FromCellString + ToString + Default + Send + Sync + Clone + 'static;

    /// Represents as the corresponding field type cell changeset.
    /// The changeset must implements the `FromCellChangeset` trait. The `CellChangeset` is implemented
    /// for `String`.
    ///  
    type CellChangeset: FromCellChangeset;

    ///  For the moment, the protobuf type only be used in the FFI of `Dart`. If the decoded cell
    /// struct is just a `String`, then use the `StrCellData` as its `CellProtobufType`.
    /// Otherwise, providing a custom protobuf type as its `CellProtobufType`.
    /// For example:
    ///     FieldType::Date => DateCellDataPB
    ///     FieldType::URL => URLCellDataPB
    ///
    type CellProtobufType: TryInto<Bytes, Error = ProtobufError> + Debug;

    /// Represents as the filter configuration for this type option.
    type CellFilter: FromFilterString + Send + Sync + 'static;
}

pub trait TypeOptionCellData: TypeOption {
    /// Convert the decoded cell data into corresponding `Protobuf struct`.
    /// For example:
    ///    FieldType::URL => URLCellDataPB
    ///    FieldType::Date=> DateCellDataPB
    fn convert_to_protobuf(&self, cell_data: <Self as TypeOption>::CellData) -> <Self as TypeOption>::CellProtobufType;

    /// Decodes the opaque cell string to corresponding data struct.
    // For example, the cell data is timestamp if its field type is `FieldType::Date`. This cell
    // data can not directly show to user. So it needs to be encode as the date string with custom
    // format setting. Encode `1647251762` to `"Mar 14,2022`
    fn decode_type_option_cell_str(&self, cell_str: String) -> FlowyResult<<Self as TypeOption>::CellData>;
}

pub trait TypeOptionTransform: TypeOption {
    /// Returns true if the current `TypeOption` provides custom type option transformation
    fn transformable(&self) -> bool {
        false
    }

    /// Transform the TypeOption from one field type to another
    /// For example, when switching from `checkbox` type-option to `single-select`
    /// type-option, adding the `Yes` option if the `single-select` type-option doesn't contain it.
    /// But the cell content is a string, `Yes`, it's need to do the cell content transform.
    /// The `Yes` string will be transformed to the `Yes` option id.
    ///
    /// # Arguments
    ///
    /// * `old_type_option_field_type`: the FieldType of the passed-in TypeOption
    /// * `old_type_option_data`: the data that can be parsed into corresponding `TypeOption`.
    ///
    ///
    fn transform_type_option(&mut self, _old_type_option_field_type: FieldType, _old_type_option_data: String) {}

    /// Transform the cell data from one field type to another
    ///
    /// # Arguments
    ///
    /// * `cell_str`: the cell string of the current field type
    /// * `decoded_field_type`: the field type of the cell data that's going to be transformed into
    /// current `TypeOption` field type.
    ///
    fn transform_type_option_cell_str(
        &self,
        _cell_str: &str,
        _decoded_field_type: &FieldType,
        _field_rev: &FieldRevision,
    ) -> Option<<Self as TypeOption>::CellData> {
        None
    }
}

pub trait TypeOptionCellDataFilter: TypeOption + CellDataDecoder {
    fn apply_filter2(
        &self,
        filter: &<Self as TypeOption>::CellFilter,
        field_type: &FieldType,
        cell_data: &<Self as TypeOption>::CellData,
    ) -> bool;
}

pub trait TypeOptionCellDataComparable: TypeOption {
    fn apply_cmp(
        &self,
        cell_data: &<Self as TypeOption>::CellData,
        other_cell_data: &<Self as TypeOption>::CellData,
    ) -> Ordering;
}
