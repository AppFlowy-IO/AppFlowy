use crate::entities::FieldType;
use crate::services::cell::{AnyCellData, CellBytes};
use crate::services::field::*;

use flowy_error::{ErrorCode, FlowyError, FlowyResult};
use flowy_grid_data_model::revision::{CellRevision, FieldRevision, FieldTypeRevision};

/// This trait is used when doing filter/search on the grid.
pub trait CellFilterOperation<T> {
    /// Return true if any_cell_data match the filter condition.
    fn apply_filter(&self, any_cell_data: AnyCellData, filter: &T) -> FlowyResult<bool>;
}

pub trait CellGroupOperation {
    fn apply_group(&self, any_cell_data: AnyCellData, group_content: &str) -> FlowyResult<bool>;
}

/// Return object that describes the cell.
pub trait CellDisplayable<CD> {
    fn display_data(
        &self,
        cell_data: CellData<CD>,
        decoded_field_type: &FieldType,
        field_rev: &FieldRevision,
    ) -> FlowyResult<CellBytes>;
}

// CD: Short for CellData. This type is the type return by apply_changeset function.
// CS: Short for Changeset. Parse the string into specific Changeset type.
pub trait CellDataOperation<CD, CS> {
    /// The cell_data is able to parse into the specific data if CD impl the FromCellData trait.
    /// For example:
    /// URLCellData, DateCellData. etc.
    fn decode_cell_data(
        &self,
        cell_data: CellData<CD>,
        decoded_field_type: &FieldType,
        field_rev: &FieldRevision,
    ) -> FlowyResult<CellBytes>;

    /// The changeset is able to parse into the specific data if CS impl the FromCellChangeset trait.
    /// For example:
    /// SelectOptionCellChangeset,DateCellChangeset. etc.  
    fn apply_changeset(&self, changeset: CellDataChangeset<CS>, cell_rev: Option<CellRevision>) -> FlowyResult<String>;
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
    let field_type = field_rev.field_type_rev.into();
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

    Ok(AnyCellData::new(s, field_type).json())
}

pub fn decode_any_cell_data<T: TryInto<AnyCellData>>(data: T, field_rev: &FieldRevision) -> CellBytes {
    if let Ok(any_cell_data) = data.try_into() {
        let AnyCellData { data, field_type } = any_cell_data;
        let to_field_type = field_rev.field_type_rev.into();
        match try_decode_cell_data(data.into(), field_rev, &field_type, &to_field_type) {
            Ok(cell_bytes) => cell_bytes,
            Err(e) => {
                tracing::error!("Decode cell data failed, {:?}", e);
                CellBytes::default()
            }
        }
    } else {
        tracing::error!("Decode type option data failed");
        CellBytes::default()
    }
}

pub fn try_decode_cell_data(
    cell_data: CellData<String>,
    field_rev: &FieldRevision,
    s_field_type: &FieldType,
    t_field_type: &FieldType,
) -> FlowyResult<CellBytes> {
    let cell_data = cell_data.try_into_inner()?;
    let get_cell_data = || {
        let field_type: FieldTypeRevision = t_field_type.into();
        let data = match t_field_type {
            FieldType::RichText => field_rev
                .get_type_option_entry::<RichTextTypeOptionPB>(field_type)?
                .decode_cell_data(cell_data.into(), s_field_type, field_rev),
            FieldType::Number => field_rev
                .get_type_option_entry::<NumberTypeOptionPB>(field_type)?
                .decode_cell_data(cell_data.into(), s_field_type, field_rev),
            FieldType::DateTime => field_rev
                .get_type_option_entry::<DateTypeOptionPB>(field_type)?
                .decode_cell_data(cell_data.into(), s_field_type, field_rev),
            FieldType::SingleSelect => field_rev
                .get_type_option_entry::<SingleSelectTypeOptionPB>(field_type)?
                .decode_cell_data(cell_data.into(), s_field_type, field_rev),
            FieldType::MultiSelect => field_rev
                .get_type_option_entry::<MultiSelectTypeOptionPB>(field_type)?
                .decode_cell_data(cell_data.into(), s_field_type, field_rev),
            FieldType::Checkbox => field_rev
                .get_type_option_entry::<CheckboxTypeOptionPB>(field_type)?
                .decode_cell_data(cell_data.into(), s_field_type, field_rev),
            FieldType::URL => field_rev
                .get_type_option_entry::<URLTypeOptionPB>(field_type)?
                .decode_cell_data(cell_data.into(), s_field_type, field_rev),
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

/// If the cell data is not String type, it should impl this trait.
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

pub struct CellDataChangeset<T>(pub Option<T>);

impl<T> CellDataChangeset<T> {
    pub fn try_into_inner(self) -> FlowyResult<T> {
        match self.0 {
            None => Err(ErrorCode::InvalidData.into()),
            Some(data) => Ok(data),
        }
    }
}

impl<T, C: ToString> std::convert::From<C> for CellDataChangeset<T>
where
    T: FromCellChangeset,
{
    fn from(changeset: C) -> Self {
        match T::from_changeset(changeset.to_string()) {
            Ok(data) => CellDataChangeset(Some(data)),
            Err(e) => {
                tracing::error!("Deserialize CellDataChangeset failed: {}", e);
                CellDataChangeset(None)
            }
        }
    }
}
impl std::convert::From<String> for CellDataChangeset<String> {
    fn from(s: String) -> Self {
        CellDataChangeset(Some(s))
    }
}
