use crate::entities::FieldType;
use crate::services::cell::{AtomicCellDataCache, CellDataCache, CellProtobufBlob, TypeCellData};
use crate::services::field::*;
use flowy_error::{ErrorCode, FlowyError, FlowyResult};
use grid_rev_model::{CellRevision, FieldRevision};
use std::cmp::Ordering;
use std::fmt::Debug;
use std::sync::Arc;

/// This trait is used when doing filter/search on the grid.
pub trait CellFilterable: TypeOptionConfiguration {
    /// Return true if type_cell_data match the filter condition.
    fn apply_filter(
        &self,
        type_cell_data: TypeCellData,
        filter: &<Self as TypeOptionConfiguration>::CellFilterConfiguration,
    ) -> FlowyResult<bool>;
}

pub trait CellComparable {
    type CellData;
    fn apply_cmp(&self, cell_data: &Self::CellData, other_cell_data: &Self::CellData) -> Ordering;
}

/// Decode the opaque cell data into readable format content
pub trait CellDataDecoder: TypeOption {
    ///
    /// Tries to decode the opaque cell string to `decoded_field_type`'s cell data. Sometimes, the `field_type`
    /// of the `FieldRevision` is not equal to the `decoded_field_type`(This happened When switching
    /// the field type of the `FieldRevision` to another field type). So the cell data is need to do
    /// some transformation.
    ///
    /// For example, the current field type of the `FieldRevision` is a checkbox. When switching the field
    /// type from the checkbox to single select, it will create two new options,`Yes` and `No`, if they don't exist.
    /// But the data of the cell doesn't change. We can't iterate all the rows to transform the cell
    /// data that can be parsed by the current field type. One approach is to transform the cell data
    /// when it get read. For the moment, the cell data is a string, `Yes` or `No`. It needs to compare
    /// with the option's name, if match return the id of the option.
    fn decode_cell_str(
        &self,
        cell_str: String,
        decoded_field_type: &FieldType,
        field_rev: &FieldRevision,
    ) -> FlowyResult<<Self as TypeOption>::CellData>;

    /// Same as `decode_cell_data` does but Decode the cell data to readable `String`
    /// For example, The string of the Multi-Select cell will be a list of the option's name
    /// separated by a comma.
    fn decode_cell_data_to_str(&self, cell_data: <Self as TypeOption>::CellData) -> String;
}

pub trait CellDataChangeset: TypeOption {
    /// The changeset is able to parse into the concrete data struct if `TypeOption::CellChangeset`
    /// implements the `FromCellChangeset` trait.
    /// For example,the SelectOptionCellChangeset,DateCellChangeset. etc.
    ///  
    fn apply_changeset(
        &self,
        changeset: <Self as TypeOption>::CellChangeset,
        type_cell_data: Option<TypeCellData>,
    ) -> FlowyResult<<Self as TypeOption>::CellData>;
}

/// changeset: It will be deserialized into specific data base on the FieldType.
///     For example,
///         FieldType::RichText => String
///         FieldType::SingleSelect => SelectOptionChangeset
///
/// cell_rev: It will be None if the cell does not contain any data.
pub fn apply_cell_data_changeset<C: ToString, T: AsRef<FieldRevision>>(
    changeset: C,
    cell_rev: Option<CellRevision>,
    field_rev: T,
    cell_data_cache: Option<AtomicCellDataCache>,
) -> Result<String, FlowyError> {
    let field_rev = field_rev.as_ref();
    let changeset = changeset.to_string();
    let field_type: FieldType = field_rev.ty.into();

    let type_cell_data = cell_rev.and_then(|cell_rev| match TypeCellData::try_from(cell_rev) {
        Ok(type_cell_data) => Some(type_cell_data),
        Err(_) => None,
    });

    let cell_data =
        match TypeOptionCellDataExt::new(field_rev, cell_data_cache).get_type_option_cell_data_handler(&field_type) {
            None => "".to_string(),
            Some(handler) => handler.handle_cell_changeset(changeset, type_cell_data, field_rev)?,
        };
    Ok(TypeCellData::new(cell_data, field_type).to_json())
}

pub fn decode_type_cell_data<T: TryInto<TypeCellData, Error = FlowyError> + Debug>(
    data: T,
    field_rev: &FieldRevision,
    cell_data_cache: Option<AtomicCellDataCache>,
) -> (FieldType, CellProtobufBlob) {
    let to_field_type = field_rev.ty.into();
    match data.try_into() {
        Ok(type_cell_data) => {
            let TypeCellData { cell_str, field_type } = type_cell_data;
            match try_decode_cell_str(cell_str, &field_type, &to_field_type, field_rev, cell_data_cache) {
                Ok(cell_bytes) => (field_type, cell_bytes),
                Err(e) => {
                    tracing::error!("Decode cell data failed, {:?}", e);
                    (field_type, CellProtobufBlob::default())
                }
            }
        }
        Err(_err) => {
            // It's okay to ignore this error, because it's okay that the current cell can't
            // display the existing cell data. For example, the UI of the text cell will be blank if
            // the type of the data of cell is Number.

            (to_field_type, CellProtobufBlob::default())
        }
    }
}

/// Decode the opaque cell data from one field type to another using the corresponding `TypeOption`
///
/// The cell data might become an empty string depends on the to_field_type's `TypeOption`   
/// support transform the from_field_type's cell data or not.
///
/// # Arguments
///
/// * `cell_str`: the opaque cell string
/// * `from_field_type`: the original field type of the passed-in cell data. Check the `TypeCellData`
/// that is used to save the origin field type of the cell data.
/// * `to_field_type`: decode the passed-in cell data to this field type. It will use the to_field_type's
/// TypeOption to decode this cell data.
/// * `field_rev`: used to get the corresponding TypeOption for the specified field type.
///
/// returns: CellBytes
///
pub fn try_decode_cell_str(
    cell_str: String,
    from_field_type: &FieldType,
    to_field_type: &FieldType,
    field_rev: &FieldRevision,
    cell_data_cache: Option<AtomicCellDataCache>,
) -> FlowyResult<CellProtobufBlob> {
    match TypeOptionCellDataExt::new(field_rev, cell_data_cache).get_type_option_cell_data_handler(to_field_type) {
        None => Ok(CellProtobufBlob::default()),
        Some(handler) => handler.handle_cell_str(cell_str, from_field_type, field_rev),
    }
}

/// Returns a string that represents the current field_type's cell data.
/// If the cell data of the `FieldType` doesn't support displaying in String then will return an
/// empty string. For example, The string of the Multi-Select cell will be a list of the option's name
/// separated by a comma.
pub fn stringify_cell_data(
    cell_data: String,
    from_field_type: &FieldType,
    to_field_type: &FieldType,
    field_rev: &FieldRevision,
) -> String {
    match TypeOptionCellDataExt::new(field_rev, None).get_type_option_cell_data_handler(to_field_type) {
        None => "".to_string(),
        Some(handler) => handler.stringify_cell_str(cell_data, from_field_type, field_rev),
    }
}

pub fn insert_text_cell(s: String, field_rev: &FieldRevision) -> CellRevision {
    let data = apply_cell_data_changeset(s, None, field_rev, None).unwrap();
    CellRevision::new(data)
}

pub fn insert_number_cell(num: i64, field_rev: &FieldRevision) -> CellRevision {
    let data = apply_cell_data_changeset(num, None, field_rev, None).unwrap();
    CellRevision::new(data)
}

pub fn insert_url_cell(url: String, field_rev: &FieldRevision) -> CellRevision {
    let data = apply_cell_data_changeset(url, None, field_rev, None).unwrap();
    CellRevision::new(data)
}

pub fn insert_checkbox_cell(is_check: bool, field_rev: &FieldRevision) -> CellRevision {
    let s = if is_check {
        CHECK.to_string()
    } else {
        UNCHECK.to_string()
    };
    let data = apply_cell_data_changeset(s, None, field_rev, None).unwrap();
    CellRevision::new(data)
}

pub fn insert_date_cell(timestamp: i64, field_rev: &FieldRevision) -> CellRevision {
    let cell_data = serde_json::to_string(&DateCellChangeset {
        date: Some(timestamp.to_string()),
        time: None,
        is_utc: true,
    })
    .unwrap();
    let data = apply_cell_data_changeset(cell_data, None, field_rev, None).unwrap();
    CellRevision::new(data)
}

pub fn insert_select_option_cell(option_ids: Vec<String>, field_rev: &FieldRevision) -> CellRevision {
    let cell_data = SelectOptionCellChangeset::from_insert_options(option_ids).to_str();
    let data = apply_cell_data_changeset(cell_data, None, field_rev, None).unwrap();
    CellRevision::new(data)
}

pub fn delete_select_option_cell(option_ids: Vec<String>, field_rev: &FieldRevision) -> CellRevision {
    let cell_data = SelectOptionCellChangeset::from_delete_options(option_ids).to_str();
    let data = apply_cell_data_changeset(cell_data, None, field_rev, None).unwrap();
    CellRevision::new(data)
}

/// Deserialize the String into cell specific data type.  
pub trait FromCellString {
    fn from_cell_str(s: &str) -> FlowyResult<Self>
    where
        Self: Sized;
}

/// IntoCellData is a helper struct used to deserialize string into a specific data type that implements
/// the `FromCellString` trait.
///
pub struct IntoCellData<T>(pub Option<T>);
impl<T> IntoCellData<T> {
    pub fn try_into_inner(self) -> FlowyResult<T> {
        match self.0 {
            None => Err(ErrorCode::InvalidData.into()),
            Some(data) => Ok(data),
        }
    }
}

impl<T> std::convert::From<String> for IntoCellData<T>
where
    T: FromCellString,
{
    fn from(s: String) -> Self {
        match T::from_cell_str(&s) {
            Ok(inner) => IntoCellData(Some(inner)),
            Err(e) => {
                tracing::error!("Deserialize Cell Data failed: {}", e);
                IntoCellData(None)
            }
        }
    }
}

impl<T> std::convert::From<T> for IntoCellData<T> {
    fn from(val: T) -> Self {
        IntoCellData(Some(val))
    }
}

impl std::convert::From<usize> for IntoCellData<String> {
    fn from(n: usize) -> Self {
        IntoCellData(Some(n.to_string()))
    }
}

impl std::convert::From<IntoCellData<String>> for String {
    fn from(p: IntoCellData<String>) -> Self {
        p.try_into_inner().unwrap_or_else(|_| String::new())
    }
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
            }
        }
    }
}
// impl std::convert::From<String> for AnyCellChangeset<String> {
//     fn from(s: String) -> Self {
//         AnyCellChangeset(Some(s))
//     }
// }
