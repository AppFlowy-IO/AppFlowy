use crate::entities::FieldType;
use crate::services::cell::{
    AtomicCellDataCache, AtomicCellFilterCache, CellDataChangeset, CellDataDecoder, CellProtobufBlob,
    FromCellChangesetString, FromCellString, TypeCellData,
};
use crate::services::field::{
    default_order, CheckboxTypeOptionPB, ChecklistTypeOptionPB, DateTypeOptionPB, MultiSelectTypeOptionPB,
    NumberTypeOptionPB, RichTextTypeOptionPB, SingleSelectTypeOptionPB, TypeOption, TypeOptionCellData,
    TypeOptionCellDataCompare, TypeOptionCellDataFilter, TypeOptionTransform, URLTypeOptionPB,
};
use crate::services::filter::FilterType;
use flowy_error::FlowyResult;
use grid_rev_model::{FieldRevision, TypeOptionDataDeserializer, TypeOptionDataSerializer};
use std::cmp::Ordering;
use std::collections::hash_map::DefaultHasher;
use std::hash::Hasher;

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

    fn handle_cell_compare(&self, left_cell_data: &str, right_cell_data: &str, field_rev: &FieldRevision) -> Ordering;

    fn handle_cell_filter(
        &self,
        filter_type: &FilterType,
        field_rev: &FieldRevision,
        type_cell_data: TypeCellData,
    ) -> bool;

    /// Decode the cell_str to corresponding cell data, and then return the display string of the
    /// cell data.
    fn stringify_cell_str(&self, cell_str: String, decoded_field_type: &FieldType, field_rev: &FieldRevision) -> String;
}

struct CellDataCacheKey(u64);
impl CellDataCacheKey {
    pub fn new(field_rev: &FieldRevision, decoded_field_type: FieldType, cell_str: &str) -> Self {
        let mut hasher = DefaultHasher::new();
        hasher.write(field_rev.id.as_bytes());
        hasher.write_u8(decoded_field_type as u8);
        hasher.write(cell_str.as_bytes());
        Self(hasher.finish())
    }
}

impl AsRef<u64> for CellDataCacheKey {
    fn as_ref(&self) -> &u64 {
        &self.0
    }
}

struct TypeOptionCellDataHandlerImpl<T> {
    inner: T,
    cell_data_cache: Option<AtomicCellDataCache>,
    cell_filter_cache: Option<AtomicCellFilterCache>,
}

impl<T> TypeOptionCellDataHandlerImpl<T>
where
    T: TypeOption
        + CellDataDecoder
        + CellDataChangeset
        + TypeOptionCellData
        + TypeOptionTransform
        + TypeOptionCellDataFilter
        + TypeOptionCellDataCompare
        + 'static,
{
    pub fn new_with_boxed(
        inner: T,
        cell_filter_cache: Option<AtomicCellFilterCache>,
        cell_data_cache: Option<AtomicCellDataCache>,
    ) -> Box<dyn TypeOptionCellDataHandler> {
        Box::new(Self {
            inner,
            cell_data_cache,
            cell_filter_cache,
        }) as Box<dyn TypeOptionCellDataHandler>
    }
}

impl<T> TypeOptionCellDataHandlerImpl<T>
where
    T: TypeOption + CellDataDecoder,
{
    fn get_decoded_cell_data(
        &self,
        cell_str: String,
        decoded_field_type: &FieldType,
        field_rev: &FieldRevision,
    ) -> FlowyResult<<Self as TypeOption>::CellData> {
        let key = CellDataCacheKey::new(field_rev, decoded_field_type.clone(), &cell_str);
        if let Some(cell_data_cache) = self.cell_data_cache.as_ref() {
            let read_guard = cell_data_cache.read();
            if let Some(cell_data) = read_guard.get(key.as_ref()).cloned() {
                tracing::trace!("Cell cache hit: {}:{}", decoded_field_type, cell_str);
                return Ok(cell_data);
            }
        }

        let cell_data = self.decode_cell_str(cell_str, decoded_field_type, field_rev)?;
        if let Some(cell_data_cache) = self.cell_data_cache.as_ref() {
            cell_data_cache.write().insert(key.as_ref(), cell_data.clone());
        }
        Ok(cell_data)
    }

    fn set_decoded_cell_data(&self, cell_data: <Self as TypeOption>::CellData, field_rev: &FieldRevision) {
        if let Some(cell_data_cache) = self.cell_data_cache.as_ref() {
            let field_type: FieldType = field_rev.ty.into();
            let cell_str = cell_data.to_string();
            tracing::trace!("Update cell cache {}:{}", field_type, cell_str);
            let key = CellDataCacheKey::new(field_rev, field_type, &cell_str);
            cell_data_cache.write().insert(key.as_ref(), cell_data);
        }
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
    type CellFilter = T::CellFilter;
}

impl<T> TypeOptionCellDataHandler for TypeOptionCellDataHandlerImpl<T>
where
    T: TypeOption
        + CellDataDecoder
        + CellDataChangeset
        + TypeOptionCellData
        + TypeOptionTransform
        + TypeOptionCellDataFilter
        + TypeOptionCellDataCompare,
{
    fn handle_cell_str(
        &self,
        cell_str: String,
        decoded_field_type: &FieldType,
        field_rev: &FieldRevision,
    ) -> FlowyResult<CellProtobufBlob> {
        let cell_data = if self.transformable() {
            match self.transform_type_option_cell_str(&cell_str, decoded_field_type, field_rev) {
                None => self.get_decoded_cell_data(cell_str, decoded_field_type, field_rev)?,
                Some(cell_data) => cell_data,
            }
        } else {
            self.get_decoded_cell_data(cell_str, decoded_field_type, field_rev)?
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
        self.set_decoded_cell_data(cell_data.clone(), field_rev);
        Ok(cell_data.to_string())
    }

    fn handle_cell_compare(&self, left_cell_data: &str, right_cell_data: &str, field_rev: &FieldRevision) -> Ordering {
        let field_type: FieldType = field_rev.ty.into();
        let left = self.get_decoded_cell_data(left_cell_data.to_owned(), &field_type, field_rev);
        let right = self.get_decoded_cell_data(right_cell_data.to_owned(), &field_type, field_rev);

        match (left, right) {
            (Ok(left), Ok(right)) => self.apply_cmp(&left, &right),
            (Ok(_), Err(_)) => Ordering::Greater,
            (Err(_), Ok(_)) => Ordering::Less,
            (Err(_), Err(_)) => default_order(),
        }
    }

    fn handle_cell_filter(
        &self,
        filter_type: &FilterType,
        field_rev: &FieldRevision,
        type_cell_data: TypeCellData,
    ) -> bool {
        let perform_filter = || {
            let filter_cache = self.cell_filter_cache.as_ref()?.read();
            let cell_filter = filter_cache.get::<<Self as TypeOption>::CellFilter>(filter_type)?;
            let cell_data = self
                .get_decoded_cell_data(type_cell_data.cell_str, &filter_type.field_type, field_rev)
                .ok()?;
            Some(self.apply_filter(cell_filter, &filter_type.field_type, &cell_data))
        };

        perform_filter().unwrap_or(true)
    }

    fn stringify_cell_str(&self, cell_str: String, decoded_field_type: &FieldType, field_rev: &FieldRevision) -> String {
        if self.transformable() {
            let cell_data = self.transform_type_option_cell_str(&cell_str, decoded_field_type, field_rev);
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

pub struct TypeOptionCellExt<'a> {
    field_rev: &'a FieldRevision,
    cell_data_cache: Option<AtomicCellDataCache>,
    cell_filter_cache: Option<AtomicCellFilterCache>,
}

impl<'a> TypeOptionCellExt<'a> {
    pub fn new_with_cell_data_cache(
        field_rev: &'a FieldRevision,
        cell_data_cache: Option<AtomicCellDataCache>,
    ) -> Self {
        Self {
            field_rev,
            cell_data_cache,
            cell_filter_cache: None,
        }
    }

    pub fn new(
        field_rev: &'a FieldRevision,
        cell_data_cache: Option<AtomicCellDataCache>,
        cell_filter_cache: Option<AtomicCellFilterCache>,
    ) -> Self {
        let mut this = Self::new_with_cell_data_cache(field_rev, cell_data_cache);
        this.cell_filter_cache = cell_filter_cache;
        this
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
                    TypeOptionCellDataHandlerImpl::new_with_boxed(
                        type_option,
                        self.cell_filter_cache.clone(),
                        self.cell_data_cache.clone(),
                    )
                }),
            FieldType::Number => self
                .field_rev
                .get_type_option::<NumberTypeOptionPB>(field_type.into())
                .map(|type_option| {
                    TypeOptionCellDataHandlerImpl::new_with_boxed(
                        type_option,
                        self.cell_filter_cache.clone(),
                        self.cell_data_cache.clone(),
                    )
                }),
            FieldType::DateTime => self
                .field_rev
                .get_type_option::<DateTypeOptionPB>(field_type.into())
                .map(|type_option| {
                    TypeOptionCellDataHandlerImpl::new_with_boxed(
                        type_option,
                        self.cell_filter_cache.clone(),
                        self.cell_data_cache.clone(),
                    )
                }),
            FieldType::SingleSelect => self
                .field_rev
                .get_type_option::<SingleSelectTypeOptionPB>(field_type.into())
                .map(|type_option| {
                    TypeOptionCellDataHandlerImpl::new_with_boxed(
                        type_option,
                        self.cell_filter_cache.clone(),
                        self.cell_data_cache.clone(),
                    )
                }),
            FieldType::MultiSelect => self
                .field_rev
                .get_type_option::<MultiSelectTypeOptionPB>(field_type.into())
                .map(|type_option| {
                    TypeOptionCellDataHandlerImpl::new_with_boxed(
                        type_option,
                        self.cell_filter_cache.clone(),
                        self.cell_data_cache.clone(),
                    )
                }),
            FieldType::Checkbox => self
                .field_rev
                .get_type_option::<CheckboxTypeOptionPB>(field_type.into())
                .map(|type_option| {
                    TypeOptionCellDataHandlerImpl::new_with_boxed(
                        type_option,
                        self.cell_filter_cache.clone(),
                        self.cell_data_cache.clone(),
                    )
                }),
            FieldType::URL => self
                .field_rev
                .get_type_option::<URLTypeOptionPB>(field_type.into())
                .map(|type_option| {
                    TypeOptionCellDataHandlerImpl::new_with_boxed(
                        type_option,
                        self.cell_filter_cache.clone(),
                        self.cell_data_cache.clone(),
                    )
                }),
            FieldType::Checklist => self
                .field_rev
                .get_type_option::<ChecklistTypeOptionPB>(field_type.into())
                .map(|type_option| {
                    TypeOptionCellDataHandlerImpl::new_with_boxed(
                        type_option,
                        self.cell_filter_cache.clone(),
                        self.cell_data_cache.clone(),
                    )
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
fn get_type_option_transform_handler(
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
