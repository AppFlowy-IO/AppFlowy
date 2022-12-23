use crate::entities::FieldType;
use crate::services::cell::{
    AtomicCellDataCache, CellDataCache, CellDataCacheKeyCal, CellDataChangeset, CellDataDecoder, CellProtobufBlob,
    FromCellChangeset, FromCellString, TypeCellData,
};
use crate::services::field::{
    CheckboxTypeOptionPB, ChecklistTypeOptionPB, DateTypeOptionPB, MultiSelectTypeOptionPB, NumberTypeOptionPB,
    RichTextTypeOptionPB, SingleSelectTypeOptionPB, URLTypeOptionPB,
};
use bytes::Bytes;
use dashmap::DashMap;
use flowy_error::FlowyResult;
use grid_rev_model::{FieldRevision, TypeOptionDataDeserializer, TypeOptionDataSerializer};
use lazy_static::lazy_static;
use protobuf::ProtobufError;
use std::cmp::Ordering;
use std::fmt::Debug;
use std::sync::Arc;

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

pub trait TypeOptionCellDataComparable: TypeOption {
    fn apply_cmp(
        &self,
        cell_data: &<Self as TypeOption>::CellData,
        other_cell_data: &<Self as TypeOption>::CellData,
    ) -> Ordering;
}

pub trait TypeOptionConfiguration {
    type CellFilterConfiguration;
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

/// A helper trait that used to erase the `Self` of `TypeOption` trait to make it become a Object-safe trait.
pub trait TypeOptionTransformHandler {
    fn transform(&mut self, old_type_option_field_type: FieldType, old_type_option_data: String);

    fn json_str(&self) -> String;
}

impl<T> TypeOptionTransformHandler for T
where
    T: TypeOptionTransform + TypeOptionDataSerializer,
{
    fn transform(&mut self, old_type_option_field_type: FieldType, old_type_option_data: String) {
        if self.transformable() {
            self.transform_type_option(old_type_option_field_type, old_type_option_data)
        }
    }

    fn json_str(&self) -> String {
        self.json_str()
    }
}

/// A helper trait that used to erase the `Self` of `TypeOption` trait to make it become a Object-safe trait
/// Only object-safe traits can be made into trait objects.
/// > Object-safe traits are traits with methods that follow these two rules:
/// 1.the return type is not Self.
/// 2.there are no generic types parameters.
///
pub trait TypeOptionCellDataHandler {
    fn handle_cell_str(
        &self,
        cell_str: String,
        decoded_field_type: &FieldType,
        field_rev: &FieldRevision,
    ) -> FlowyResult<CellProtobufBlob>;

    fn handle_cell_changeset(
        &self,
        cell_changeset: String,
        old_type_cell_data: Option<TypeCellData>,
        field_rev: &FieldRevision,
    ) -> FlowyResult<String>;

    fn handle_cell_cmp(&self, left_cell_data: &str, right_cell_data: &str, field_rev: &FieldRevision) -> Ordering;

    /// Decode the cell_str to corresponding cell data, and then return the display string of the
    /// cell data.
    fn stringify_cell_str(&self, cell_str: String, field_type: &FieldType, field_rev: &FieldRevision) -> String;
}

struct TypeOptionCellDataHandlerImpl<T> {
    inner: T,
    cell_data_cache: Option<AtomicCellDataCache>,
}

impl<T> TypeOptionCellDataHandlerImpl<T> {
    pub fn new(inner: T, cell_data_cache: Option<AtomicCellDataCache>) -> Self {
        Self { inner, cell_data_cache }
    }
    // pub fn get_cache_cell_data(&self, field_rev: )
}

impl<T> TypeOptionCellDataHandlerImpl<T>
where
    T: TypeOption + CellDataDecoder,
{
    fn get_decoded_cell_data(
        &self,
        field_rev: &FieldRevision,
        decoded_field_type: &FieldType,
        cell_str: &str,
    ) -> FlowyResult<<Self as TypeOption>::CellData> {
        if let Some(cell_data_cache) = self.cell_data_cache.as_ref() {
            let key = CellDataCacheKeyCal::new(field_rev, decoded_field_type, cell_str);
            let read_guard = cell_data_cache.read();
            let cell_data = read_guard.get(&key).cloned();
            if cell_data.is_some() {
                return Ok(cell_data.unwrap());
            }
        }

        // self.decode_cell_data()
        todo!()
    }

    fn set_decoded_cell_data(&self, cell_data: <Self as TypeOption>::CellData, field_rev: &FieldRevision) {
        todo!()
    }
}

impl<T> std::ops::Deref for TypeOptionCellDataHandlerImpl<T> {
    type Target = T;

    fn deref(&self) -> &Self::Target {
        &self.inner
    }
}

impl<T> TypeOption for TypeOptionCellDataHandlerImpl<T>
where
    T: TypeOption,
{
    type CellData = T::CellData;
    type CellChangeset = T::CellChangeset;
    type CellProtobufType = T::CellProtobufType;
}

impl<T> TypeOptionCellDataHandler for TypeOptionCellDataHandlerImpl<T>
where
    T: TypeOption + CellDataDecoder + CellDataChangeset + TypeOptionCellData + TypeOptionTransform, // + TypeOptionCellDataComparable,
{
    fn handle_cell_str(
        &self,
        cell_str: String,
        decoded_field_type: &FieldType,
        field_rev: &FieldRevision,
    ) -> FlowyResult<CellProtobufBlob> {
        let cell_data = if self.transformable() {
            match self.transform_type_option_cell_str(&cell_str, decoded_field_type, field_rev) {
                None => self.decode_cell_str(cell_str, decoded_field_type, field_rev)?,
                Some(cell_data) => cell_data,
            }
        } else {
            self.decode_cell_str(cell_str, decoded_field_type, field_rev)?
        };
        CellProtobufBlob::from(self.convert_to_protobuf(cell_data))
    }

    fn handle_cell_changeset(
        &self,
        cell_changeset: String,
        old_type_cell_data: Option<TypeCellData>,
        field_rev: &FieldRevision,
    ) -> FlowyResult<String> {
        let changeset = <Self as TypeOption>::CellChangeset::from_changeset(cell_changeset)?;
        let cell_data = self.apply_changeset(changeset, old_type_cell_data)?;
        Ok(cell_data.to_string())
    }

    fn handle_cell_cmp(&self, left_cell_data: &str, right_cell_data: &str, field_rev: &FieldRevision) -> Ordering {
        if !TYPEOPTION_CELL_CACHE.contains_key(left_cell_data) {
            TYPEOPTION_CELL_CACHE
                .entry(left_cell_data.to_owned())
                .or_insert_with(|| {
                    let cell_data = self
                        .decode_cell_str(left_cell_data.to_owned(), &FieldType::RichText, field_rev)
                        .unwrap();
                    self.decode_cell_data_to_str(cell_data)
                });
        }

        if !TYPEOPTION_CELL_CACHE.contains_key(right_cell_data) {
            TYPEOPTION_CELL_CACHE
                .entry(right_cell_data.to_owned())
                .or_insert_with(|| {
                    let cell_data = self
                        .decode_cell_str(right_cell_data.to_owned(), &FieldType::RichText, field_rev)
                        .unwrap();
                    self.decode_cell_data_to_str(cell_data)
                });
        }
        let left = TYPEOPTION_CELL_CACHE.get(left_cell_data).unwrap();
        let right = TYPEOPTION_CELL_CACHE.get(left_cell_data).unwrap();
        // left.cmp(&right)
        todo!()
    }

    fn stringify_cell_str(&self, cell_str: String, field_type: &FieldType, field_rev: &FieldRevision) -> String {
        if self.transformable() {
            let cell_data = self.transform_type_option_cell_str(&cell_str, field_type, field_rev);
            if let Some(cell_data) = cell_data {
                return self.decode_cell_data_to_str(cell_data);
            }
        }
        match <Self as TypeOption>::CellData::from_cell_str(&cell_str) {
            Ok(cell_data) => self.decode_cell_data_to_str(cell_data),
            Err(_) => "".to_string(),
        }
    }
}

lazy_static! {
    pub(crate) static ref TYPEOPTION_CELL_CACHE: DashMap<String, String> = DashMap::new();
}

pub struct FieldRevisionExt<'a> {
    field_rev: &'a FieldRevision,
    cell_data_cache: Option<AtomicCellDataCache>,
}

impl<'a> FieldRevisionExt<'a> {
    pub fn new(field_rev: &'a FieldRevision, cell_data_cache: Option<AtomicCellDataCache>) -> Self {
        Self {
            field_rev,
            cell_data_cache,
        }
    }

    pub fn get_type_option_cell_data_handler(
        &self,
        field_type: &FieldType,
    ) -> Option<Box<dyn TypeOptionCellDataHandler>> {
        match field_type {
            FieldType::RichText => self
                .field_rev
                .get_type_option::<RichTextTypeOptionPB>(field_type.into())
                .map(|type_option| {
                    Box::new(TypeOptionCellDataHandlerImpl::new(
                        type_option,
                        self.cell_data_cache.clone(),
                    )) as Box<dyn TypeOptionCellDataHandler>
                }),
            FieldType::Number => self
                .field_rev
                .get_type_option::<NumberTypeOptionPB>(field_type.into())
                .map(|type_option| {
                    Box::new(TypeOptionCellDataHandlerImpl::new(
                        type_option,
                        self.cell_data_cache.clone(),
                    )) as Box<dyn TypeOptionCellDataHandler>
                }),
            FieldType::DateTime => self
                .field_rev
                .get_type_option::<DateTypeOptionPB>(field_type.into())
                .map(|type_option| {
                    Box::new(TypeOptionCellDataHandlerImpl::new(
                        type_option,
                        self.cell_data_cache.clone(),
                    )) as Box<dyn TypeOptionCellDataHandler>
                }),
            FieldType::SingleSelect => self
                .field_rev
                .get_type_option::<SingleSelectTypeOptionPB>(field_type.into())
                .map(|type_option| {
                    Box::new(TypeOptionCellDataHandlerImpl::new(
                        type_option,
                        self.cell_data_cache.clone(),
                    )) as Box<dyn TypeOptionCellDataHandler>
                }),
            FieldType::MultiSelect => self
                .field_rev
                .get_type_option::<MultiSelectTypeOptionPB>(field_type.into())
                .map(|type_option| {
                    Box::new(TypeOptionCellDataHandlerImpl::new(
                        type_option,
                        self.cell_data_cache.clone(),
                    )) as Box<dyn TypeOptionCellDataHandler>
                }),
            FieldType::Checkbox => self
                .field_rev
                .get_type_option::<CheckboxTypeOptionPB>(field_type.into())
                .map(|type_option| {
                    Box::new(TypeOptionCellDataHandlerImpl::new(
                        type_option,
                        self.cell_data_cache.clone(),
                    )) as Box<dyn TypeOptionCellDataHandler>
                }),
            FieldType::URL => self
                .field_rev
                .get_type_option::<URLTypeOptionPB>(field_type.into())
                .map(|type_option| {
                    Box::new(TypeOptionCellDataHandlerImpl::new(
                        type_option,
                        self.cell_data_cache.clone(),
                    )) as Box<dyn TypeOptionCellDataHandler>
                }),
            FieldType::Checklist => self
                .field_rev
                .get_type_option::<ChecklistTypeOptionPB>(field_type.into())
                .map(|type_option| {
                    Box::new(TypeOptionCellDataHandlerImpl::new(
                        type_option,
                        self.cell_data_cache.clone(),
                    )) as Box<dyn TypeOptionCellDataHandler>
                }),
        }
    }
}

pub fn transform_type_option(
    type_option_data: &str,
    new_field_type: &FieldType,
    old_type_option_data: Option<String>,
    old_field_type: FieldType,
) -> String {
    let mut transform_handler = get_type_option_transform_handler(type_option_data, new_field_type);
    if let Some(old_type_option_data) = old_type_option_data {
        transform_handler.transform(old_field_type, old_type_option_data);
    }
    transform_handler.json_str()
}

pub fn get_type_option_transform_handler(
    type_option_data: &str,
    field_type: &FieldType,
) -> Box<dyn TypeOptionTransformHandler> {
    match field_type {
        FieldType::RichText => {
            Box::new(RichTextTypeOptionPB::from_json_str(type_option_data)) as Box<dyn TypeOptionTransformHandler>
        }
        FieldType::Number => {
            Box::new(NumberTypeOptionPB::from_json_str(type_option_data)) as Box<dyn TypeOptionTransformHandler>
        }
        FieldType::DateTime => {
            Box::new(DateTypeOptionPB::from_json_str(type_option_data)) as Box<dyn TypeOptionTransformHandler>
        }
        FieldType::SingleSelect => {
            Box::new(SingleSelectTypeOptionPB::from_json_str(type_option_data)) as Box<dyn TypeOptionTransformHandler>
        }
        FieldType::MultiSelect => {
            Box::new(MultiSelectTypeOptionPB::from_json_str(type_option_data)) as Box<dyn TypeOptionTransformHandler>
        }
        FieldType::Checkbox => {
            Box::new(CheckboxTypeOptionPB::from_json_str(type_option_data)) as Box<dyn TypeOptionTransformHandler>
        }
        FieldType::URL => {
            Box::new(URLTypeOptionPB::from_json_str(type_option_data)) as Box<dyn TypeOptionTransformHandler>
        }
        FieldType::Checklist => {
            Box::new(ChecklistTypeOptionPB::from_json_str(type_option_data)) as Box<dyn TypeOptionTransformHandler>
        }
    }
}
