use crate::entities::FieldType;
use crate::services::cell::{CellBytes, TypeCellData};
use crate::services::field::*;
use std::fmt::Debug;

use flowy_error::{ErrorCode, FlowyError, FlowyResult};
use grid_rev_model::{CellRevision, FieldRevision, FieldTypeRevision};

/// This trait is used when doing filter/search on the grid.
pub trait CellFilterOperation<T> {
    /// Return true if any_cell_data match the filter condition.
    fn apply_filter(&self, any_cell_data: TypeCellData, filter: &T) -> FlowyResult<bool>;
}

pub trait CellGroupOperation {
    fn apply_group(&self, any_cell_data: TypeCellData, group_content: &str) -> FlowyResult<bool>;
}

/// Return object that describes the cell.
pub trait CellDisplayable<CD> {
    /// Serialize the cell data into `CellBytes` that will be posted to the `Dart` side. Using the
    /// corresponding protobuf struct implement in `Dart` to deserialize the data.
    ///
    /// Using `utf8` to encode the cell data if the cell data use `String` as its data container.
    /// Using `protobuf` to encode the cell data if the cell data use `Protobuf struct` as its data container.
    ///
    /// When switching the field type of the `FieldRevision` to another field type. The `field_type`
    /// of the `FieldRevision` is not equal to the `decoded_field_type`. The cell data is need to do
    /// some custom transformation.
    ///
    /// For example, the current field type of the `FieldRevision` is a checkbox. When switching the field
    /// type from the checkbox to single select, the `TypeOptionBuilder`'s transform method gets called.
    /// It will create two new options,`Yes` and `No`, if they don't exist. But the cell data didn't change,
    /// because we can't iterate all the rows to transform the cell data that can be parsed by the current
    /// field type. One approach is to transform the cell data when it get read. For the moment,
    /// the cell data is a string, `Yes` or `No`. It needs to compare with the option's name, if match
    /// return the id of the option. Otherwise, return a default value of `CellBytes`.
    ///
    /// # Arguments
    ///
    /// * `cell_data`: the generic annotation `CD` represents as the deserialize data type of the cell.
    /// * `decoded_field_type`: the field type of the cell_data when doing serialization
    ///
    /// returns: Result<CellBytes, FlowyError>
    ///
    fn displayed_cell_bytes(
        &self,
        cell_data: CellData<CD>,
        decoded_field_type: &FieldType,
        field_rev: &FieldRevision,
    ) -> FlowyResult<CellBytes>;

    /// Serialize the cell data into `String` that is readable
    ///
    /// The cell data is not readable which means it can't display the cell data directly to user.
    /// For example,
    /// 1. the cell data is timestamp if its field type is FieldType::Date that is not readable.
    /// It needs to be parsed as the date string.
    ///
    /// 2. the cell data is a commas separated id if its field type if FieldType::MultiSelect that is not readable.
    /// It needs to be parsed as a commas separated option name.
    ///
    fn displayed_cell_string(
        &self,
        cell_data: CellData<CD>,
        decoded_field_type: &FieldType,
        field_rev: &FieldRevision,
    ) -> FlowyResult<String>;
}

pub trait CellDataOperation<CD, CS> {
    /// The generic annotation `CD` represents as the deserialize data type of the cell data.
    /// The Serialize/Deserialize struct of the cell is base on the field type of the cell.
    ///
    /// For example:
    /// FieldType::URL => URLCellData
    /// FieldType::Date=> DateCellData
    ///
    /// Each cell data is a opaque data, it needs to deserialized to a concrete data struct
    ///
    /// `cell_data`: the opaque data of the cell.
    /// `decoded_field_type`: the field type of the cell data when doing serialization
    /// `field_rev`: the field of the cell data
    ///
    /// Returns the error if the cell data can't be parsed into `CD`.
    ///
    fn decode_cell_data(
        &self,
        cell_data: CellData<CD>,
        decoded_field_type: &FieldType,
        field_rev: &FieldRevision,
    ) -> FlowyResult<CellBytes>;

    /// The changeset is able to parse into the concrete data struct if CS implements  
    /// the `FromCellChangeset` trait.
    ///
    /// For example:
    /// SelectOptionCellChangeset,DateCellChangeset. etc.
    ///  
    fn apply_changeset(&self, changeset: AnyCellChangeset<CS>, cell_rev: Option<CellRevision>) -> FlowyResult<String>;
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
) -> Result<String, FlowyError> {
    let field_rev = field_rev.as_ref();
    let changeset = changeset.to_string();
    let field_type = field_rev.ty.into();
    let s = match field_type {
        FieldType::RichText => RichTextTypeOptionPB::from(field_rev).apply_changeset(changeset.into(), cell_rev),
        FieldType::Number => NumberTypeOptionPB::from(field_rev).apply_changeset(changeset.into(), cell_rev),
        FieldType::DateTime => DateTypeOptionPB::from(field_rev).apply_changeset(changeset.into(), cell_rev),
        FieldType::SingleSelect => {
            SingleSelectTypeOptionPB::from(field_rev).apply_changeset(changeset.into(), cell_rev)
        }
        FieldType::MultiSelect => MultiSelectTypeOptionPB::from(field_rev).apply_changeset(changeset.into(), cell_rev),
        FieldType::Checkbox => CheckboxTypeOptionPB::from(field_rev).apply_changeset(changeset.into(), cell_rev),
        FieldType::URL => URLTypeOptionPB::from(field_rev).apply_changeset(changeset.into(), cell_rev),
    }?;

    Ok(TypeCellData::new(s, field_type).to_json())
}

pub fn decode_any_cell_data<T: TryInto<TypeCellData, Error = FlowyError> + Debug>(
    data: T,
    field_rev: &FieldRevision,
) -> (FieldType, CellBytes) {
    let to_field_type = field_rev.ty.into();
    match data.try_into() {
        Ok(any_cell_data) => {
            let TypeCellData { data, field_type } = any_cell_data;
            match try_decode_cell_data(data.into(), &field_type, &to_field_type, field_rev) {
                Ok(cell_bytes) => (field_type, cell_bytes),
                Err(e) => {
                    tracing::error!("Decode cell data failed, {:?}", e);
                    (field_type, CellBytes::default())
                }
            }
        }
        Err(_err) => {
            // It's okay to ignore this error, because it's okay that the current cell can't
            // display the existing cell data. For example, the UI of the text cell will be blank if
            // the type of the data of cell is Number.

            (to_field_type, CellBytes::default())
        }
    }
}

pub fn decode_cell_data_to_string(
    cell_data: CellData<String>,
    from_field_type: &FieldType,
    to_field_type: &FieldType,
    field_rev: &FieldRevision,
) -> FlowyResult<String> {
    let cell_data = cell_data.try_into_inner()?;
    let get_cell_display_str = || {
        let field_type: FieldTypeRevision = to_field_type.into();
        let result = match to_field_type {
            FieldType::RichText => field_rev
                .get_type_option::<RichTextTypeOptionPB>(field_type)?
                .displayed_cell_string(cell_data.into(), from_field_type, field_rev),
            FieldType::Number => field_rev
                .get_type_option::<NumberTypeOptionPB>(field_type)?
                .displayed_cell_string(cell_data.into(), from_field_type, field_rev),
            FieldType::DateTime => field_rev
                .get_type_option::<DateTypeOptionPB>(field_type)?
                .displayed_cell_string(cell_data.into(), from_field_type, field_rev),
            FieldType::SingleSelect => field_rev
                .get_type_option::<SingleSelectTypeOptionPB>(field_type)?
                .displayed_cell_string(cell_data.into(), from_field_type, field_rev),
            FieldType::MultiSelect => field_rev
                .get_type_option::<MultiSelectTypeOptionPB>(field_type)?
                .displayed_cell_string(cell_data.into(), from_field_type, field_rev),
            FieldType::Checkbox => field_rev
                .get_type_option::<CheckboxTypeOptionPB>(field_type)?
                .displayed_cell_string(cell_data.into(), from_field_type, field_rev),
            FieldType::URL => field_rev
                .get_type_option::<URLTypeOptionPB>(field_type)?
                .displayed_cell_string(cell_data.into(), from_field_type, field_rev),
        };
        Some(result)
    };

    match get_cell_display_str() {
        Some(Ok(s)) => Ok(s),
        Some(Err(err)) => {
            tracing::error!("{:?}", err);
            Ok("".to_owned())
        }
        None => Ok("".to_owned()),
    }
}

/// Use the `to_field_type`'s TypeOption to parse the cell data into `from_field_type` type's data.
///
/// Each `FieldType` has its corresponding `TypeOption` that implements the `CellDisplayable`
/// and `CellDataOperation` traits.
///
pub fn try_decode_cell_data(
    cell_data: CellData<String>,
    from_field_type: &FieldType,
    to_field_type: &FieldType,
    field_rev: &FieldRevision,
) -> FlowyResult<CellBytes> {
    let cell_data = cell_data.try_into_inner()?;
    let get_cell_data = || {
        let field_type: FieldTypeRevision = to_field_type.into();
        let data = match to_field_type {
            FieldType::RichText => field_rev
                .get_type_option::<RichTextTypeOptionPB>(field_type)?
                .decode_cell_data(cell_data.into(), from_field_type, field_rev),
            FieldType::Number => field_rev
                .get_type_option::<NumberTypeOptionPB>(field_type)?
                .decode_cell_data(cell_data.into(), from_field_type, field_rev),
            FieldType::DateTime => field_rev
                .get_type_option::<DateTypeOptionPB>(field_type)?
                .decode_cell_data(cell_data.into(), from_field_type, field_rev),
            FieldType::SingleSelect => field_rev
                .get_type_option::<SingleSelectTypeOptionPB>(field_type)?
                .decode_cell_data(cell_data.into(), from_field_type, field_rev),
            FieldType::MultiSelect => field_rev
                .get_type_option::<MultiSelectTypeOptionPB>(field_type)?
                .decode_cell_data(cell_data.into(), from_field_type, field_rev),
            FieldType::Checkbox => field_rev
                .get_type_option::<CheckboxTypeOptionPB>(field_type)?
                .decode_cell_data(cell_data.into(), from_field_type, field_rev),
            FieldType::URL => field_rev
                .get_type_option::<URLTypeOptionPB>(field_type)?
                .decode_cell_data(cell_data.into(), from_field_type, field_rev),
        };
        Some(data)
    };

    match get_cell_data() {
        Some(Ok(data)) => Ok(data),
        Some(Err(err)) => {
            tracing::error!("{:?}", err);
            Ok(CellBytes::default())
        }
        None => Ok(CellBytes::default()),
    }
}

pub fn insert_text_cell(s: String, field_rev: &FieldRevision) -> CellRevision {
    let data = apply_cell_data_changeset(s, None, field_rev).unwrap();
    CellRevision::new(data)
}

pub fn insert_number_cell(num: i64, field_rev: &FieldRevision) -> CellRevision {
    let data = apply_cell_data_changeset(num, None, field_rev).unwrap();
    CellRevision::new(data)
}

pub fn insert_url_cell(url: String, field_rev: &FieldRevision) -> CellRevision {
    let data = apply_cell_data_changeset(url, None, field_rev).unwrap();
    CellRevision::new(data)
}

pub fn insert_checkbox_cell(is_check: bool, field_rev: &FieldRevision) -> CellRevision {
    let s = if is_check {
        CHECK.to_string()
    } else {
        UNCHECK.to_string()
    };
    let data = apply_cell_data_changeset(s, None, field_rev).unwrap();
    CellRevision::new(data)
}

pub fn insert_date_cell(timestamp: i64, field_rev: &FieldRevision) -> CellRevision {
    let cell_data = serde_json::to_string(&DateCellChangeset {
        date: Some(timestamp.to_string()),
        time: None,
        is_utc: true,
    })
    .unwrap();
    let data = apply_cell_data_changeset(cell_data, None, field_rev).unwrap();
    CellRevision::new(data)
}

pub fn insert_select_option_cell(option_ids: Vec<String>, field_rev: &FieldRevision) -> CellRevision {
    let cell_data = SelectOptionCellChangeset::from_insert_options(option_ids).to_str();
    let data = apply_cell_data_changeset(cell_data, None, field_rev).unwrap();
    CellRevision::new(data)
}

pub fn delete_select_option_cell(option_ids: Vec<String>, field_rev: &FieldRevision) -> CellRevision {
    let cell_data = SelectOptionCellChangeset::from_delete_options(option_ids).to_str();
    let data = apply_cell_data_changeset(cell_data, None, field_rev).unwrap();
    CellRevision::new(data)
}

/// Deserialize the String into cell specific data type.  
pub trait FromCellString {
    fn from_cell_str(s: &str) -> FlowyResult<Self>
    where
        Self: Sized;
}

/// CellData is a helper struct. String will be parser into Option<T> only if the T impl the FromCellString trait.
pub struct CellData<T>(pub Option<T>);
impl<T> CellData<T> {
    pub fn try_into_inner(self) -> FlowyResult<T> {
        match self.0 {
            None => Err(ErrorCode::InvalidData.into()),
            Some(data) => Ok(data),
        }
    }
}

impl<T> std::convert::From<String> for CellData<T>
where
    T: FromCellString,
{
    fn from(s: String) -> Self {
        match T::from_cell_str(&s) {
            Ok(inner) => CellData(Some(inner)),
            Err(e) => {
                tracing::error!("Deserialize Cell Data failed: {}", e);
                CellData(None)
            }
        }
    }
}

impl std::convert::From<usize> for CellData<String> {
    fn from(n: usize) -> Self {
        CellData(Some(n.to_string()))
    }
}

impl<T> std::convert::From<T> for CellData<T> {
    fn from(val: T) -> Self {
        CellData(Some(val))
    }
}

impl std::convert::From<CellData<String>> for String {
    fn from(p: CellData<String>) -> Self {
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
impl std::convert::From<String> for AnyCellChangeset<String> {
    fn from(s: String) -> Self {
        AnyCellChangeset(Some(s))
    }
}
