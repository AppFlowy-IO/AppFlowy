use std::collections::HashMap;
use std::fmt::Debug;

use collab_database::fields::Field;
use collab_database::rows::{get_field_type_from_cell, Cell, Cells};

use flowy_error::{ErrorCode, FlowyError, FlowyResult};

use crate::entities::FieldType;
use crate::services::cell::{CellCache, CellProtobufBlob};
use crate::services::field::checklist_type_option::ChecklistCellChangeset;
use crate::services::field::*;
use crate::services::group::make_no_status_group;

/// Decode the opaque cell data into readable format content
pub trait CellDataDecoder: TypeOption {
  ///
  /// Tries to decode the [Cell] to `decoded_field_type`'s cell data. Sometimes, the `field_type`
  /// of the `Field` is not equal to the `decoded_field_type`(This happened When switching
  /// the field type of the `Field` to another field type). So the cell data is need to do
  /// some transformation.
  ///
  /// For example, the current field type of the `Field` is a checkbox. When switching the field
  /// type from the checkbox to single select, it will create two new options,`Yes` and `No`, if they don't exist.
  /// But the data of the cell doesn't change. We can't iterate all the rows to transform the cell
  /// data that can be parsed by the current field type. One approach is to transform the cell data
  /// when reading.
  fn decode_cell(
    &self,
    cell: &Cell,
    decoded_field_type: &FieldType,
    field: &Field,
  ) -> FlowyResult<<Self as TypeOption>::CellData>;

  /// Decode the cell data to readable `String`
  /// For example, The string of the Multi-Select cell will be a list of the option's name
  /// separated by a comma.
  fn stringify_cell_data(&self, cell_data: <Self as TypeOption>::CellData) -> String;

  /// Same as [CellDataDecoder::stringify_cell_data] but the input parameter is the [Cell]
  fn stringify_cell(&self, cell: &Cell) -> String;
}

pub trait CellDataChangeset: TypeOption {
  /// The changeset is able to parse into the concrete data struct if `TypeOption::CellChangeset`
  /// implements the `FromCellChangesetString` trait.
  /// For example,the SelectOptionCellChangeset,DateCellChangeset. etc.
  /// # Arguments
  ///
  /// * `changeset`: the cell changeset that represents the changes of the cell.
  /// * `cell`: the data of the cell. It will be None if the cell does not contain any data.
  fn apply_changeset(
    &self,
    changeset: <Self as TypeOption>::CellChangeset,
    cell: Option<Cell>,
  ) -> FlowyResult<(Cell, <Self as TypeOption>::CellData)>;
}

/// changeset: It will be deserialized into specific data base on the FieldType.
///     For example,
///         FieldType::RichText => String
///         FieldType::SingleSelect => SelectOptionChangeset
///
/// cell_rev: It will be None if the cell does not contain any data.
pub fn apply_cell_changeset<C: ToCellChangeset>(
  changeset: C,
  cell: Option<Cell>,
  field: &Field,
  cell_data_cache: Option<CellCache>,
) -> Result<Cell, FlowyError> {
  let changeset = changeset.to_cell_changeset_str();
  let field_type = FieldType::from(field.field_type);
  match TypeOptionCellExt::new_with_cell_data_cache(field, cell_data_cache)
    .get_type_option_cell_data_handler(&field_type)
  {
    None => Ok(Cell::default()),
    Some(handler) => Ok(handler.handle_cell_changeset(changeset, cell, field)?),
  }
}

pub fn get_cell_protobuf(
  cell: &Cell,
  field: &Field,
  cell_cache: Option<CellCache>,
) -> CellProtobufBlob {
  let from_field_type = get_field_type_from_cell(cell);
  if from_field_type.is_none() {
    return CellProtobufBlob::default();
  }

  let from_field_type = from_field_type.unwrap();
  let to_field_type = FieldType::from(field.field_type);
  match try_decode_cell_str_to_cell_protobuf(
    cell,
    &from_field_type,
    &to_field_type,
    field,
    cell_cache,
  ) {
    Ok(cell_bytes) => cell_bytes,
    Err(e) => {
      tracing::error!("Decode cell data failed, {:?}", e);
      CellProtobufBlob::default()
    },
  }
}

/// Decode the opaque cell data from one field type to another using the corresponding `TypeOption`
///
/// The cell data might become an empty string depends on the to_field_type's `TypeOption`
/// support transform the from_field_type's cell data or not.
///
/// # Arguments
///
/// * `cell`: the opaque cell string that can be decoded by corresponding structs.
/// * `from_field_type`: the original field type of the passed-in cell data. Check the `TypeCellData`
/// that is used to save the origin field type of the cell data.
/// * `to_field_type`: decode the passed-in cell data to this field type. It will use the to_field_type's
/// TypeOption to decode this cell data.
/// * `field`: used to get the corresponding TypeOption for the specified field type.
///
/// returns: CellBytes
///
pub fn try_decode_cell_str_to_cell_protobuf(
  cell: &Cell,
  from_field_type: &FieldType,
  to_field_type: &FieldType,
  field: &Field,
  cell_data_cache: Option<CellCache>,
) -> FlowyResult<CellProtobufBlob> {
  match TypeOptionCellExt::new_with_cell_data_cache(field, cell_data_cache)
    .get_type_option_cell_data_handler(to_field_type)
  {
    None => Ok(CellProtobufBlob::default()),
    Some(handler) => handler.handle_cell_str(cell, from_field_type, field),
  }
}

pub fn try_decode_cell_to_cell_data<T: Default + 'static>(
  cell: &Cell,
  from_field_type: &FieldType,
  to_field_type: &FieldType,
  field: &Field,
  cell_data_cache: Option<CellCache>,
) -> Option<T> {
  let handler = TypeOptionCellExt::new_with_cell_data_cache(field, cell_data_cache)
    .get_type_option_cell_data_handler(to_field_type)?;
  handler
    .get_cell_data(cell, from_field_type, field)
    .ok()?
    .unbox_or_none::<T>()
}
/// Returns a string that represents the current field_type's cell data.
/// For example, The string of the Multi-Select cell will be a list of the option's name
/// separated by a comma.
///
/// # Arguments
///
/// * `cell`: the opaque cell string that can be decoded by corresponding structs
/// * `to_field_type`: the cell will be decoded to this field type's cell data.
/// * `from_field_type`: the original field type of the passed-in cell data.
/// * `field`: used to get the corresponding TypeOption for the specified field type.
///
/// returns: String
pub fn stringify_cell_data(
  cell: &Cell,
  to_field_type: &FieldType,
  from_field_type: &FieldType,
  field: &Field,
) -> String {
  match TypeOptionCellExt::new_with_cell_data_cache(field, None)
    .get_type_option_cell_data_handler(from_field_type)
  {
    None => "".to_string(),
    Some(handler) => handler.stringify_cell_str(cell, to_field_type, field),
  }
}

pub fn insert_text_cell(s: String, field: &Field) -> Cell {
  apply_cell_changeset(s, None, field, None).unwrap()
}

pub fn insert_number_cell(num: i64, field: &Field) -> Cell {
  apply_cell_changeset(num.to_string(), None, field, None).unwrap()
}

pub fn insert_url_cell(url: String, field: &Field) -> Cell {
  // checking if url is equal to group id of no status group because everywhere
  // except group of rows with empty url the group id is equal to the url
  // so then on the case that url is equal to empty url group id we should change
  // the url to empty string
  let _no_status_group_id = make_no_status_group(field).id;
  let url = match url {
    a if a == _no_status_group_id => "".to_owned(),
    _ => url,
  };

  apply_cell_changeset(url, None, field, None).unwrap()
}

pub fn insert_checkbox_cell(is_check: bool, field: &Field) -> Cell {
  let s = if is_check {
    CHECK.to_string()
  } else {
    UNCHECK.to_string()
  };
  apply_cell_changeset(s, None, field, None).unwrap()
}

pub fn insert_date_cell(timestamp: i64, include_time: Option<bool>, field: &Field) -> Cell {
  let cell_data = serde_json::to_string(&DateCellChangeset {
    date: Some(timestamp.to_string()),
    time: None,
    include_time,
  })
  .unwrap();
  apply_cell_changeset(cell_data, None, field, None).unwrap()
}

pub fn insert_select_option_cell(option_ids: Vec<String>, field: &Field) -> Cell {
  let changeset =
    SelectOptionCellChangeset::from_insert_options(option_ids).to_cell_changeset_str();
  apply_cell_changeset(changeset, None, field, None).unwrap()
}

pub fn insert_checklist_cell(insert_options: Vec<String>, field: &Field) -> Cell {
  let changeset = ChecklistCellChangeset {
    insert_options,
    ..Default::default()
  }
  .to_cell_changeset_str();
  apply_cell_changeset(changeset, None, field, None).unwrap()
}

pub fn delete_select_option_cell(option_ids: Vec<String>, field: &Field) -> Cell {
  let changeset =
    SelectOptionCellChangeset::from_delete_options(option_ids).to_cell_changeset_str();
  apply_cell_changeset(changeset, None, field, None).unwrap()
}

/// Deserialize the String into cell specific data type.
pub trait FromCellString {
  fn from_cell_str(s: &str) -> FlowyResult<Self>
  where
    Self: Sized;
}

/// If the changeset applying to the cell is not String type, it should impl this trait.
/// Deserialize the string into cell specific changeset.
pub trait FromCellChangeset {
  fn from_changeset(changeset: String) -> FlowyResult<Self>
  where
    Self: Sized;
}

impl FromCellChangeset for String {
  fn from_changeset(changeset: String) -> FlowyResult<Self>
  where
    Self: Sized,
  {
    Ok(changeset)
  }
}

pub trait ToCellChangeset: Debug {
  fn to_cell_changeset_str(&self) -> String;
}

impl ToCellChangeset for String {
  fn to_cell_changeset_str(&self) -> String {
    self.clone()
  }
}

pub struct AnyCellChangeset<T>(pub Option<T>);

impl<T> AnyCellChangeset<T> {
  pub fn try_into_inner(self) -> FlowyResult<T> {
    match self.0 {
      None => Err(ErrorCode::InvalidData.into()),
      Some(data) => Ok(data),
    }
  }
}

impl<T, C: ToString> std::convert::From<C> for AnyCellChangeset<T>
where
  T: FromCellChangeset,
{
  fn from(changeset: C) -> Self {
    match T::from_changeset(changeset.to_string()) {
      Ok(data) => AnyCellChangeset(Some(data)),
      Err(e) => {
        tracing::error!("Deserialize CellDataChangeset failed: {}", e);
        AnyCellChangeset(None)
      },
    }
  }
}

pub struct CellBuilder<'a> {
  cells: Cells,
  field_maps: HashMap<String, &'a Field>,
}

impl<'a> CellBuilder<'a> {
  /// Build list of Cells from HashMap of cell string by field id.
  pub fn with_cells(cell_by_field_id: HashMap<String, String>, fields: &'a [Field]) -> Self {
    let field_maps = fields
      .iter()
      .map(|field| (field.id.clone(), field))
      .collect::<HashMap<String, &Field>>();

    let mut cells = Cells::new();
    for (field_id, cell_str) in cell_by_field_id {
      if let Some(field) = field_maps.get(&field_id) {
        let field_type = FieldType::from(field.field_type);
        match field_type {
          FieldType::RichText => {
            cells.insert(field_id, insert_text_cell(cell_str, field));
          },
          FieldType::Number => {
            if let Ok(num) = cell_str.parse::<i64>() {
              cells.insert(field_id, insert_number_cell(num, field));
            }
          },
          FieldType::DateTime => {
            if let Ok(timestamp) = cell_str.parse::<i64>() {
              cells.insert(field_id, insert_date_cell(timestamp, Some(false), field));
            }
          },
          FieldType::LastEditedTime | FieldType::CreatedTime => {
            tracing::warn!("Shouldn't insert cell data to cell whose field type is LastEditedTime or CreatedTime");
          },
          FieldType::SingleSelect | FieldType::MultiSelect => {
            if let Ok(ids) = SelectOptionIds::from_cell_str(&cell_str) {
              cells.insert(field_id, insert_select_option_cell(ids.into_inner(), field));
            }
          },
          FieldType::Checkbox => {
            if let Ok(value) = CheckboxCellData::from_cell_str(&cell_str) {
              cells.insert(field_id, insert_checkbox_cell(value.into_inner(), field));
            }
          },
          FieldType::URL => {
            cells.insert(field_id, insert_url_cell(cell_str, field));
          },
          FieldType::Checklist => {
            if let Ok(ids) = SelectOptionIds::from_cell_str(&cell_str) {
              cells.insert(field_id, insert_select_option_cell(ids.into_inner(), field));
            }
          },
        }
      }
    }

    CellBuilder { cells, field_maps }
  }

  pub fn build(self) -> Cells {
    self.cells
  }

  pub fn insert_text_cell(&mut self, field_id: &str, data: String) {
    match self.field_maps.get(&field_id.to_owned()) {
      None => tracing::warn!("Can't find the text field with id: {}", field_id),
      Some(field) => {
        self
          .cells
          .insert(field_id.to_owned(), insert_text_cell(data, field));
      },
    }
  }

  pub fn insert_url_cell(&mut self, field_id: &str, data: String) {
    match self.field_maps.get(&field_id.to_owned()) {
      None => tracing::warn!("Can't find the url field with id: {}", field_id),
      Some(field) => {
        self
          .cells
          .insert(field_id.to_owned(), insert_url_cell(data, field));
      },
    }
  }

  pub fn insert_number_cell(&mut self, field_id: &str, num: i64) {
    match self.field_maps.get(&field_id.to_owned()) {
      None => tracing::warn!("Can't find the number field with id: {}", field_id),
      Some(field) => {
        self
          .cells
          .insert(field_id.to_owned(), insert_number_cell(num, field));
      },
    }
  }

  pub fn insert_checkbox_cell(&mut self, field_id: &str, is_check: bool) {
    match self.field_maps.get(&field_id.to_owned()) {
      None => tracing::warn!("Can't find the checkbox field with id: {}", field_id),
      Some(field) => {
        self
          .cells
          .insert(field_id.to_owned(), insert_checkbox_cell(is_check, field));
      },
    }
  }

  pub fn insert_date_cell(&mut self, field_id: &str, timestamp: i64) {
    match self.field_maps.get(&field_id.to_owned()) {
      None => tracing::warn!("Can't find the date field with id: {}", field_id),
      Some(field) => {
        self.cells.insert(
          field_id.to_owned(),
          insert_date_cell(timestamp, Some(false), field),
        );
      },
    }
  }

  pub fn insert_select_option_cell(&mut self, field_id: &str, option_ids: Vec<String>) {
    match self.field_maps.get(&field_id.to_owned()) {
      None => tracing::warn!("Can't find the select option field with id: {}", field_id),
      Some(field) => {
        self.cells.insert(
          field_id.to_owned(),
          insert_select_option_cell(option_ids, field),
        );
      },
    }
  }
  pub fn insert_checklist_cell(&mut self, field_id: &str, option_names: Vec<String>) {
    match self.field_maps.get(&field_id.to_owned()) {
      None => tracing::warn!("Can't find the field with id: {}", field_id),
      Some(field) => {
        self.cells.insert(
          field_id.to_owned(),
          insert_checklist_cell(option_names, field),
        );
      },
    }
  }
}
