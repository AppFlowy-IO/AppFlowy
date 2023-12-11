use std::cmp::Ordering;
use std::fmt::Debug;

use bytes::Bytes;
use collab_database::fields::{Field, TypeOptionData};
use collab_database::rows::Cell;
use protobuf::ProtobufError;

use flowy_error::FlowyResult;

use crate::entities::{
  CheckboxTypeOptionPB, ChecklistTypeOptionPB, DateTypeOptionPB, FieldType,
  MultiSelectTypeOptionPB, NumberTypeOptionPB, RichTextTypeOptionPB, SingleSelectTypeOptionPB,
  TimestampTypeOptionPB, URLTypeOptionPB,
};
use crate::services::cell::{CellDataDecoder, FromCellChangeset, ToCellChangeset};
use crate::services::field::checklist_type_option::ChecklistTypeOption;
use crate::services::field::{
  CheckboxTypeOption, DateFormat, DateTypeOption, MultiSelectTypeOption, NumberTypeOption,
  RichTextTypeOption, SingleSelectTypeOption, TimeFormat, TimestampTypeOption, URLTypeOption,
};
use crate::services::filter::FromFilterString;
use crate::services::sort::SortCondition;

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
  type CellData: for<'a> From<&'a Cell>
    + TypeOptionCellData
    + ToString
    + Default
    + Send
    + Sync
    + Clone
    + Debug
    + 'static;

  /// Represents as the corresponding field type cell changeset.
  /// The changeset must implements the `FromCellChangesetString` and the `ToCellChangesetString` trait.
  /// These two traits are auto implemented for `String`.
  ///
  type CellChangeset: FromCellChangeset + ToCellChangeset;

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
/// This trait providing serialization and deserialization methods for cell data.
///
/// This trait ensures that a type which implements both `TypeOption` and `TypeOptionCellDataSerde` can
/// be converted to and from a corresponding `Protobuf struct`, and can be parsed from an opaque [Cell] structure.
pub trait TypeOptionCellDataSerde: TypeOption {
  /// Encode the cell data into corresponding `Protobuf struct`.
  /// For example:
  ///    FieldType::URL => URLCellDataPB
  ///    FieldType::Date=> DateCellDataPB
  fn protobuf_encode(
    &self,
    cell_data: <Self as TypeOption>::CellData,
  ) -> <Self as TypeOption>::CellProtobufType;

  /// Parse the opaque [Cell] to corresponding data struct.
  /// The [Cell] is a map that stores list of key/value data. Each [TypeOption::CellData]
  /// should implement the From<&Cell> trait to parse the [Cell] to corresponding data struct.
  fn parse_cell(&self, cell: &Cell) -> FlowyResult<<Self as TypeOption>::CellData>;
}

/// This trait that provides methods to extend the [TypeOption::CellData] functionalities.
///
pub trait TypeOptionCellData {
  /// Checks if the cell content is considered empty.
  ///
  /// Even if a cell is initialized, its content might still be considered empty
  /// based on certain criteria. e.g. empty text, date, select option, etc.
  fn is_cell_empty(&self) -> bool {
    false
  }
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
  fn transform_type_option(
    &mut self,
    _old_type_option_field_type: FieldType,
    _old_type_option_data: TypeOptionData,
  ) {
  }

  /// Transform the cell data from one field type to another
  ///
  /// # Arguments
  ///
  /// * `cell_str`: the cell string of the current field type
  /// * `transformed_field_type`: the cell will be transformed to the is field type's cell data.
  /// current `TypeOption` field type.
  ///
  fn transform_type_option_cell(
    &self,
    _cell: &Cell,
    _transformed_field_type: &FieldType,
    _field: &Field,
  ) -> Option<<Self as TypeOption>::CellData> {
    None
  }
}

pub trait TypeOptionCellDataFilter: TypeOption + CellDataDecoder {
  fn apply_filter(
    &self,
    filter: &<Self as TypeOption>::CellFilter,
    field_type: &FieldType,
    cell_data: &<Self as TypeOption>::CellData,
  ) -> bool;
}

#[inline(always)]
pub fn default_order() -> Ordering {
  Ordering::Equal
}

pub trait TypeOptionCellDataCompare: TypeOption {
  /// Compares the cell contents of two cells that are both not
  /// None. However, the cell contents might still be empty
  fn apply_cmp(
    &self,
    cell_data: &<Self as TypeOption>::CellData,
    other_cell_data: &<Self as TypeOption>::CellData,
    sort_condition: SortCondition,
  ) -> Ordering;

  /// Compares the two cells where one of the cells is None
  fn apply_cmp_with_uninitialized(
    &self,
    cell_data: Option<&<Self as TypeOption>::CellData>,
    other_cell_data: Option<&<Self as TypeOption>::CellData>,
    _sort_condition: SortCondition,
  ) -> Ordering {
    match (cell_data, other_cell_data) {
      (None, Some(cell_data)) if !cell_data.is_cell_empty() => Ordering::Greater,
      (Some(cell_data), None) if !cell_data.is_cell_empty() => Ordering::Less,
      _ => Ordering::Equal,
    }
  }
}

pub fn type_option_data_from_pb_or_default<T: Into<Bytes>>(
  bytes: T,
  field_type: &FieldType,
) -> TypeOptionData {
  let bytes = bytes.into();
  let result: Result<TypeOptionData, ProtobufError> = match field_type {
    FieldType::RichText => {
      RichTextTypeOptionPB::try_from(bytes).map(|pb| RichTextTypeOption::from(pb).into())
    },
    FieldType::Number => {
      NumberTypeOptionPB::try_from(bytes).map(|pb| NumberTypeOption::from(pb).into())
    },
    FieldType::DateTime => {
      DateTypeOptionPB::try_from(bytes).map(|pb| DateTypeOption::from(pb).into())
    },
    FieldType::LastEditedTime | FieldType::CreatedTime => {
      TimestampTypeOptionPB::try_from(bytes).map(|pb| TimestampTypeOption::from(pb).into())
    },
    FieldType::SingleSelect => {
      SingleSelectTypeOptionPB::try_from(bytes).map(|pb| SingleSelectTypeOption::from(pb).into())
    },
    FieldType::MultiSelect => {
      MultiSelectTypeOptionPB::try_from(bytes).map(|pb| MultiSelectTypeOption::from(pb).into())
    },
    FieldType::Checkbox => {
      CheckboxTypeOptionPB::try_from(bytes).map(|pb| CheckboxTypeOption::from(pb).into())
    },
    FieldType::URL => URLTypeOptionPB::try_from(bytes).map(|pb| URLTypeOption::from(pb).into()),
    FieldType::Checklist => {
      ChecklistTypeOptionPB::try_from(bytes).map(|pb| ChecklistTypeOption::from(pb).into())
    },
  };

  result.unwrap_or_else(|_| default_type_option_data_from_type(field_type))
}

pub fn type_option_to_pb(type_option: TypeOptionData, field_type: &FieldType) -> Bytes {
  match field_type {
    FieldType::RichText => {
      let rich_text_type_option: RichTextTypeOption = type_option.into();
      RichTextTypeOptionPB::from(rich_text_type_option)
        .try_into()
        .unwrap()
    },
    FieldType::Number => {
      let number_type_option: NumberTypeOption = type_option.into();
      NumberTypeOptionPB::from(number_type_option)
        .try_into()
        .unwrap()
    },
    FieldType::DateTime => {
      let date_type_option: DateTypeOption = type_option.into();
      DateTypeOptionPB::from(date_type_option).try_into().unwrap()
    },
    FieldType::LastEditedTime | FieldType::CreatedTime => {
      let timestamp_type_option: TimestampTypeOption = type_option.into();
      TimestampTypeOptionPB::from(timestamp_type_option)
        .try_into()
        .unwrap()
    },
    FieldType::SingleSelect => {
      let single_select_type_option: SingleSelectTypeOption = type_option.into();
      SingleSelectTypeOptionPB::from(single_select_type_option)
        .try_into()
        .unwrap()
    },
    FieldType::MultiSelect => {
      let multi_select_type_option: MultiSelectTypeOption = type_option.into();
      MultiSelectTypeOptionPB::from(multi_select_type_option)
        .try_into()
        .unwrap()
    },
    FieldType::Checkbox => {
      let checkbox_type_option: CheckboxTypeOption = type_option.into();
      CheckboxTypeOptionPB::from(checkbox_type_option)
        .try_into()
        .unwrap()
    },
    FieldType::URL => {
      let url_type_option: URLTypeOption = type_option.into();
      URLTypeOptionPB::from(url_type_option).try_into().unwrap()
    },
    FieldType::Checklist => {
      let checklist_type_option: ChecklistTypeOption = type_option.into();
      ChecklistTypeOptionPB::from(checklist_type_option)
        .try_into()
        .unwrap()
    },
  }
}

pub fn default_type_option_data_from_type(field_type: &FieldType) -> TypeOptionData {
  match field_type {
    FieldType::RichText => RichTextTypeOption::default().into(),
    FieldType::Number => NumberTypeOption::default().into(),
    FieldType::DateTime => DateTypeOption::default().into(),
    FieldType::LastEditedTime | FieldType::CreatedTime => TimestampTypeOption {
      field_type: *field_type,
      date_format: DateFormat::Friendly,
      time_format: TimeFormat::TwelveHour,
      include_time: true,
    }
    .into(),
    FieldType::SingleSelect => SingleSelectTypeOption::default().into(),
    FieldType::MultiSelect => MultiSelectTypeOption::default().into(),
    FieldType::Checkbox => CheckboxTypeOption::default().into(),
    FieldType::URL => URLTypeOption::default().into(),
    FieldType::Checklist => ChecklistTypeOption::default().into(),
  }
}
