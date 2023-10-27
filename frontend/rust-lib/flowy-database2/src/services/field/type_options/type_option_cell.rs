use std::cmp::Ordering;
use std::collections::hash_map::DefaultHasher;
use std::hash::{Hash, Hasher};

use collab_database::fields::{Field, TypeOptionData};
use collab_database::rows::{Cell, RowId};

use flowy_error::FlowyResult;
use lib_infra::box_any::BoxAny;

use crate::entities::FieldType;
use crate::services::cell::{
  CellCache, CellDataChangeset, CellDataDecoder, CellFilterCache, CellProtobufBlob,
  FromCellChangeset,
};
use crate::services::field::checklist_type_option::ChecklistTypeOption;
use crate::services::field::{
  CheckboxTypeOption, DateTypeOption, MultiSelectTypeOption, NumberTypeOption, RichTextTypeOption,
  SingleSelectTypeOption, TimestampTypeOption, TypeOption, TypeOptionCellDataCompare,
  TypeOptionCellDataFilter, TypeOptionCellDataSerde, TypeOptionTransform, URLTypeOption,
};
use crate::services::sort::SortCondition;

pub const CELL_DATA: &str = "data";

/// Each [FieldType] has its own [TypeOptionCellDataHandler].
/// A helper trait that used to erase the `Self` of `TypeOption` trait to make it become a Object-safe trait
/// Only object-safe traits can be made into trait objects.
/// > Object-safe traits are traits with methods that follow these two rules:
/// 1.the return type is not Self.
/// 2.there are no generic types parameters.
///
pub trait TypeOptionCellDataHandler: Send + Sync + 'static {
  fn handle_cell_str(
    &self,
    cell: &Cell,
    decoded_field_type: &FieldType,
    field_rev: &Field,
  ) -> FlowyResult<CellProtobufBlob>;

  // TODO(nathan): replace cell_changeset with BoxAny to get rid of the serde process.
  fn handle_cell_changeset(
    &self,
    cell_changeset: String,
    old_cell: Option<Cell>,
    field: &Field,
  ) -> FlowyResult<Cell>;

  fn handle_cell_compare(
    &self,
    left_cell: Option<&Cell>,
    right_cell: Option<&Cell>,
    field: &Field,
    sort_condition: SortCondition,
  ) -> Ordering;

  fn handle_cell_filter(&self, field_type: &FieldType, field: &Field, cell: &Cell) -> bool;

  /// Format the cell to string using the passed-in [FieldType] and [Field].
  /// The [Cell] is generic, so we need to know the [FieldType] and [Field] to format the cell.
  ///
  /// For example, the field type of the [TypeOptionCellDataHandler] is [FieldType::Date], and
  /// the if field_type is [FieldType::RichText], then the string would be something like "Mar 14, 2022".
  ///
  fn stringify_cell_str(&self, cell: &Cell, field_type: &FieldType, field: &Field) -> String;

  /// Format the cell to [BoxCellData] using the passed-in [FieldType] and [Field].
  /// The caller can get the cell data by calling [BoxCellData::unbox_or_none].
  fn get_cell_data(
    &self,
    cell: &Cell,
    field_type: &FieldType,
    field: &Field,
  ) -> FlowyResult<BoxCellData>;
}

struct CellDataCacheKey(u64);
impl CellDataCacheKey {
  pub fn new(field_rev: &Field, decoded_field_type: FieldType, cell: &Cell) -> Self {
    let mut hasher = DefaultHasher::new();
    if let Some(type_option_data) = field_rev.get_any_type_option(&decoded_field_type) {
      type_option_data.hash(&mut hasher);
    }
    hasher.write(field_rev.id.as_bytes());
    hasher.write_u8(decoded_field_type as u8);
    cell.hash(&mut hasher);
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
  cell_data_cache: Option<CellCache>,
  cell_filter_cache: Option<CellFilterCache>,
}

impl<T> TypeOptionCellDataHandlerImpl<T>
where
  T: TypeOption
    + CellDataDecoder
    + CellDataChangeset
    + TypeOptionCellDataSerde
    + TypeOptionTransform
    + TypeOptionCellDataFilter
    + TypeOptionCellDataCompare
    + Send
    + Sync
    + 'static,
{
  pub fn into_boxed(self) -> Box<dyn TypeOptionCellDataHandler> {
    Box::new(self) as Box<dyn TypeOptionCellDataHandler>
  }

  pub fn new_with_boxed(
    inner: T,
    cell_filter_cache: Option<CellFilterCache>,
    cell_data_cache: Option<CellCache>,
  ) -> Box<dyn TypeOptionCellDataHandler> {
    Self {
      inner,
      cell_data_cache,
      cell_filter_cache,
    }
    .into_boxed()
  }
}

impl<T> TypeOptionCellDataHandlerImpl<T>
where
  T: TypeOption + CellDataDecoder + Send + Sync,
{
  fn get_decoded_cell_data(
    &self,
    cell: &Cell,
    decoded_field_type: &FieldType,
    field: &Field,
  ) -> FlowyResult<<Self as TypeOption>::CellData> {
    let key = CellDataCacheKey::new(field, decoded_field_type.clone(), cell);
    if let Some(cell_data_cache) = self.cell_data_cache.as_ref() {
      let read_guard = cell_data_cache.read();
      if let Some(cell_data) = read_guard.get(key.as_ref()).cloned() {
        // tracing::trace!(
        //   "Cell cache hit: field_type:{}, cell: {:?}, cell_data: {:?}",
        //   decoded_field_type,
        //   cell,
        //   cell_data
        // );
        return Ok(cell_data);
      }
    }

    let cell_data = self.decode_cell(cell, decoded_field_type, field)?;
    if let Some(cell_data_cache) = self.cell_data_cache.as_ref() {
      // tracing::trace!(
      //   "Cell cache update: field_type:{}, cell: {:?}, cell_data: {:?}",
      //   decoded_field_type,
      //   cell,
      //   cell_data
      // );
      cell_data_cache
        .write()
        .insert(key.as_ref(), cell_data.clone());
    }
    Ok(cell_data)
  }

  fn set_decoded_cell_data(
    &self,
    cell: &Cell,
    cell_data: <Self as TypeOption>::CellData,
    field: &Field,
  ) {
    if let Some(cell_data_cache) = self.cell_data_cache.as_ref() {
      let field_type = FieldType::from(field.field_type);
      let key = CellDataCacheKey::new(field, field_type, cell);
      // tracing::trace!(
      //   "Cell cache update: field_type:{}, cell: {:?}, cell_data: {:?}",
      //   field_type,
      //   cell,
      //   cell_data
      // );
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
  T: TypeOption + Send + Sync,
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
    + TypeOptionCellDataSerde
    + TypeOptionTransform
    + TypeOptionCellDataFilter
    + TypeOptionCellDataCompare
    + Send
    + Sync
    + 'static,
{
  fn handle_cell_str(
    &self,
    cell: &Cell,
    decoded_field_type: &FieldType,
    field_rev: &Field,
  ) -> FlowyResult<CellProtobufBlob> {
    let cell_data = self
      .get_cell_data(cell, decoded_field_type, field_rev)?
      .unbox_or_default::<<Self as TypeOption>::CellData>();

    CellProtobufBlob::from(self.protobuf_encode(cell_data))
  }

  fn handle_cell_changeset(
    &self,
    cell_changeset: String,
    old_cell: Option<Cell>,
    field: &Field,
  ) -> FlowyResult<Cell> {
    let changeset = <Self as TypeOption>::CellChangeset::from_changeset(cell_changeset)?;
    let (cell, cell_data) = self.apply_changeset(changeset, old_cell)?;
    self.set_decoded_cell_data(&cell, cell_data, field);
    Ok(cell)
  }

  /// Compares two cell data values given their optional references, field information, and sorting condition.
  ///
  /// This function is designed to handle the comparison of cells that might not be initialized. The cells are
  /// first decoded based on the provided field type, and then compared according to the specified sort condition.
  ///
  /// # Parameters
  /// - `left_cell`: An optional reference to the left cell's data.
  /// - `right_cell`: An optional reference to the right cell's data.
  /// - `field`: A reference to the field information, which includes details about the field type.
  /// - `sort_condition`: The condition that dictates the sort order based on the results of the comparison.
  ///
  /// # Returns
  /// An `Ordering` indicating:
  /// - `Ordering::Equal` if both cells are `None` or if their decoded values are equal.
  /// - `Ordering::Less` or `Ordering::Greater` based on the `apply_cmp_with_uninitialized` or `apply_cmp`
  ///   method results and the specified `sort_condition`.
  ///
  /// # Note
  /// - If only one of the cells is `None`, the other cell is decoded, and the comparison is made using
  ///   the `apply_cmp_with_uninitialized` method.
  /// - If both cells are present, they are decoded, and the comparison is made using the `apply_cmp` method.
  fn handle_cell_compare(
    &self,
    left_cell: Option<&Cell>,
    right_cell: Option<&Cell>,
    field: &Field,
    sort_condition: SortCondition,
  ) -> Ordering {
    let field_type = FieldType::from(field.field_type);

    match (left_cell, right_cell) {
      (None, None) => Ordering::Equal,
      (None, Some(right_cell)) => {
        let right_cell_data = self
          .get_decoded_cell_data(right_cell, &field_type, field)
          .unwrap_or_default();

        self.apply_cmp_with_uninitialized(None, Some(right_cell_data).as_ref(), sort_condition)
      },
      (Some(left_cell), None) => {
        let left_cell_data = self
          .get_decoded_cell_data(left_cell, &field_type, field)
          .unwrap_or_default();

        self.apply_cmp_with_uninitialized(Some(left_cell_data).as_ref(), None, sort_condition)
      },
      (Some(left_cell), Some(right_cell)) => {
        let left_cell_data: <T as TypeOption>::CellData = self
          .get_decoded_cell_data(left_cell, &field_type, field)
          .unwrap_or_default();
        let right_cell_data = self
          .get_decoded_cell_data(right_cell, &field_type, field)
          .unwrap_or_default();

        self.apply_cmp(&left_cell_data, &right_cell_data, sort_condition)
      },
    }
  }

  fn handle_cell_filter(&self, field_type: &FieldType, field: &Field, cell: &Cell) -> bool {
    let perform_filter = || {
      let filter_cache = self.cell_filter_cache.as_ref()?.read();
      let cell_filter = filter_cache.get::<<Self as TypeOption>::CellFilter>(&field.id)?;
      let cell_data = self.get_decoded_cell_data(cell, field_type, field).ok()?;
      Some(self.apply_filter(cell_filter, field_type, &cell_data))
    };

    perform_filter().unwrap_or(true)
  }

  /// Stringify [Cell] to string
  /// if the [TypeOptionCellDataHandler] supports transform, it will try to transform the [Cell] to
  /// the passed-in field type [Cell].
  /// For example, the field type of the [TypeOptionCellDataHandler] is [FieldType::MultiSelect], the field_type
  /// is [FieldType::RichText], then the string will be transformed to a string that separated by comma with the
  /// option's name.
  ///
  fn stringify_cell_str(&self, cell: &Cell, field_type: &FieldType, field: &Field) -> String {
    if self.transformable() {
      let cell_data = self.transform_type_option_cell(cell, field_type, field);
      if let Some(cell_data) = cell_data {
        return self.stringify_cell_data(cell_data);
      }
    }
    self.stringify_cell(cell)
  }

  fn get_cell_data(
    &self,
    cell: &Cell,
    field_type: &FieldType,
    field: &Field,
  ) -> FlowyResult<BoxCellData> {
    // tracing::debug!("get_cell_data: {:?}", std::any::type_name::<Self>());
    let cell_data = if self.transformable() {
      match self.transform_type_option_cell(cell, field_type, field) {
        None => self.get_decoded_cell_data(cell, field_type, field)?,
        Some(cell_data) => cell_data,
      }
    } else {
      self.get_decoded_cell_data(cell, field_type, field)?
    };
    Ok(BoxCellData::new(cell_data))
  }
}

pub struct TypeOptionCellExt<'a> {
  field: &'a Field,
  cell_data_cache: Option<CellCache>,
  cell_filter_cache: Option<CellFilterCache>,
}

impl<'a> TypeOptionCellExt<'a> {
  pub fn new_with_cell_data_cache(field: &'a Field, cell_data_cache: Option<CellCache>) -> Self {
    Self {
      field,
      cell_data_cache,
      cell_filter_cache: None,
    }
  }

  pub fn new(
    field: &'a Field,
    cell_data_cache: Option<CellCache>,
    cell_filter_cache: Option<CellFilterCache>,
  ) -> Self {
    let mut this = Self::new_with_cell_data_cache(field, cell_data_cache);
    this.cell_filter_cache = cell_filter_cache;
    this
  }

  pub fn get_cells<T>(&self) -> Vec<T> {
    let field_type = FieldType::from(self.field.field_type);
    match self.get_type_option_cell_data_handler(&field_type) {
      None => vec![],
      Some(_handler) => {
        todo!()
      },
    }
  }

  pub fn get_type_option_cell_data_handler(
    &self,
    field_type: &FieldType,
  ) -> Option<Box<dyn TypeOptionCellDataHandler>> {
    match field_type {
      FieldType::RichText => self
        .field
        .get_type_option::<RichTextTypeOption>(field_type)
        .map(|type_option| {
          TypeOptionCellDataHandlerImpl::new_with_boxed(
            type_option,
            self.cell_filter_cache.clone(),
            self.cell_data_cache.clone(),
          )
        }),
      FieldType::Number => self
        .field
        .get_type_option::<NumberTypeOption>(field_type)
        .map(|type_option| {
          TypeOptionCellDataHandlerImpl::new_with_boxed(
            type_option,
            self.cell_filter_cache.clone(),
            self.cell_data_cache.clone(),
          )
        }),
      FieldType::DateTime => self
        .field
        .get_type_option::<DateTypeOption>(field_type)
        .map(|type_option| {
          TypeOptionCellDataHandlerImpl::new_with_boxed(
            type_option,
            self.cell_filter_cache.clone(),
            self.cell_data_cache.clone(),
          )
        }),
      FieldType::LastEditedTime | FieldType::CreatedTime => self
        .field
        .get_type_option::<TimestampTypeOption>(field_type)
        .map(|type_option| {
          TypeOptionCellDataHandlerImpl::new_with_boxed(
            type_option,
            self.cell_filter_cache.clone(),
            self.cell_data_cache.clone(),
          )
        }),
      FieldType::SingleSelect => self
        .field
        .get_type_option::<SingleSelectTypeOption>(field_type)
        .map(|type_option| {
          TypeOptionCellDataHandlerImpl::new_with_boxed(
            type_option,
            self.cell_filter_cache.clone(),
            self.cell_data_cache.clone(),
          )
        }),
      FieldType::MultiSelect => self
        .field
        .get_type_option::<MultiSelectTypeOption>(field_type)
        .map(|type_option| {
          TypeOptionCellDataHandlerImpl::new_with_boxed(
            type_option,
            self.cell_filter_cache.clone(),
            self.cell_data_cache.clone(),
          )
        }),
      FieldType::Checkbox => self
        .field
        .get_type_option::<CheckboxTypeOption>(field_type)
        .map(|type_option| {
          TypeOptionCellDataHandlerImpl::new_with_boxed(
            type_option,
            self.cell_filter_cache.clone(),
            self.cell_data_cache.clone(),
          )
        }),
      FieldType::URL => {
        self
          .field
          .get_type_option::<URLTypeOption>(field_type)
          .map(|type_option| {
            TypeOptionCellDataHandlerImpl::new_with_boxed(
              type_option,
              self.cell_filter_cache.clone(),
              self.cell_data_cache.clone(),
            )
          })
      },
      FieldType::Checklist => self
        .field
        .get_type_option::<ChecklistTypeOption>(field_type)
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
  type_option_data: &TypeOptionData,
  new_field_type: &FieldType,
  old_type_option_data: Option<TypeOptionData>,
  old_field_type: FieldType,
) -> TypeOptionData {
  let mut transform_handler = get_type_option_transform_handler(type_option_data, new_field_type);
  if let Some(old_type_option_data) = old_type_option_data {
    transform_handler.transform(old_field_type, old_type_option_data);
  }
  transform_handler.to_type_option_data()
}

/// A helper trait that used to erase the `Self` of `TypeOption` trait to make it become a Object-safe trait.
pub trait TypeOptionTransformHandler {
  fn transform(
    &mut self,
    old_type_option_field_type: FieldType,
    old_type_option_data: TypeOptionData,
  );

  fn to_type_option_data(&self) -> TypeOptionData;
}

impl<T> TypeOptionTransformHandler for T
where
  T: TypeOptionTransform + Into<TypeOptionData> + Clone,
{
  fn transform(
    &mut self,
    old_type_option_field_type: FieldType,
    old_type_option_data: TypeOptionData,
  ) {
    if self.transformable() {
      self.transform_type_option(old_type_option_field_type, old_type_option_data)
    }
  }

  fn to_type_option_data(&self) -> TypeOptionData {
    self.clone().into()
  }
}
fn get_type_option_transform_handler(
  type_option_data: &TypeOptionData,
  field_type: &FieldType,
) -> Box<dyn TypeOptionTransformHandler> {
  let type_option_data = type_option_data.clone();
  match field_type {
    FieldType::RichText => {
      Box::new(RichTextTypeOption::from(type_option_data)) as Box<dyn TypeOptionTransformHandler>
    },
    FieldType::Number => {
      Box::new(NumberTypeOption::from(type_option_data)) as Box<dyn TypeOptionTransformHandler>
    },
    FieldType::DateTime => {
      Box::new(DateTypeOption::from(type_option_data)) as Box<dyn TypeOptionTransformHandler>
    },
    FieldType::LastEditedTime | FieldType::CreatedTime => {
      Box::new(TimestampTypeOption::from(type_option_data)) as Box<dyn TypeOptionTransformHandler>
    },
    FieldType::SingleSelect => Box::new(SingleSelectTypeOption::from(type_option_data))
      as Box<dyn TypeOptionTransformHandler>,
    FieldType::MultiSelect => {
      Box::new(MultiSelectTypeOption::from(type_option_data)) as Box<dyn TypeOptionTransformHandler>
    },
    FieldType::Checkbox => {
      Box::new(CheckboxTypeOption::from(type_option_data)) as Box<dyn TypeOptionTransformHandler>
    },
    FieldType::URL => {
      Box::new(URLTypeOption::from(type_option_data)) as Box<dyn TypeOptionTransformHandler>
    },
    FieldType::Checklist => {
      Box::new(ChecklistTypeOption::from(type_option_data)) as Box<dyn TypeOptionTransformHandler>
    },
  }
}

pub type BoxCellData = BoxAny;

pub struct RowSingleCellData {
  pub row_id: RowId,
  pub field_id: String,
  pub field_type: FieldType,
  pub cell_data: Option<BoxCellData>,
}

macro_rules! into_cell_data {
  ($func_name:ident,$return_ty:ty) => {
    #[allow(dead_code)]
    pub fn $func_name(self) -> Option<$return_ty> {
      self.cell_data?.unbox_or_none()
    }
  };
}

impl RowSingleCellData {
  into_cell_data!(
    into_text_field_cell_data,
    <RichTextTypeOption as TypeOption>::CellData
  );
  into_cell_data!(
    into_number_field_cell_data,
    <NumberTypeOption as TypeOption>::CellData
  );
  into_cell_data!(
    into_url_field_cell_data,
    <URLTypeOption as TypeOption>::CellData
  );
  into_cell_data!(
    into_single_select_field_cell_data,
    <SingleSelectTypeOption as TypeOption>::CellData
  );
  into_cell_data!(
    into_multi_select_field_cell_data,
    <MultiSelectTypeOption as TypeOption>::CellData
  );
  into_cell_data!(
    into_date_field_cell_data,
    <DateTypeOption as TypeOption>::CellData
  );
  into_cell_data!(
    into_timestamp_field_cell_data,
    <TimestampTypeOption as TypeOption>::CellData
  );
  into_cell_data!(
    into_check_list_field_cell_data,
    <CheckboxTypeOption as TypeOption>::CellData
  );
}
