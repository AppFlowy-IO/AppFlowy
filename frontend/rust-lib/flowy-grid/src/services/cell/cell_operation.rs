use flowy_error::{ErrorCode, FlowyError, FlowyResult};
use flowy_grid_data_model::revision::{CellRevision, FieldRevision, FieldTypeRevision};

use crate::entities::FieldType;
use crate::services::cell::{AnyCellData, DecodedCellData};
use crate::services::field::*;

pub trait CellFilterOperation<T> {
    /// Return true if any_cell_data match the filter condition.
    fn apply_filter(&self, any_cell_data: AnyCellData, filter: &T) -> FlowyResult<bool>;
}

pub trait CellDataOperation<D, C> {
    /// The cell_data is able to parse into the specific data that was impl the FromCellData trait.
    /// For example:
    /// URLCellData, DateCellData. etc.
    fn decode_cell_data(
        &self,
        cell_data: CellData<D>,
        decoded_field_type: &FieldType,
        field_rev: &FieldRevision,
    ) -> FlowyResult<DecodedCellData>;

    /// The changeset is able to parse into the specific data that was impl the FromCellChangeset trait.
    /// For example:
    /// SelectOptionCellChangeset,DateCellChangeset. etc.  
    fn apply_changeset(&self, changeset: CellDataChangeset<C>, cell_rev: Option<CellRevision>) -> FlowyResult<String>;
}
/// The changeset will be deserialized into specific data base on the FieldType.
/// For example, it's String on FieldType::RichText, and SelectOptionChangeset on FieldType::SingleSelect
pub fn apply_cell_data_changeset<C: ToString, T: AsRef<FieldRevision>>(
    changeset: C,
    cell_rev: Option<CellRevision>,
    field_rev: T,
) -> Result<String, FlowyError> {
    let field_rev = field_rev.as_ref();
    let changeset = changeset.to_string();
    let field_type = field_rev.field_type_rev.into();
    let s = match field_type {
        FieldType::RichText => RichTextTypeOption::from(field_rev).apply_changeset(changeset.into(), cell_rev),
        FieldType::Number => NumberTypeOption::from(field_rev).apply_changeset(changeset.into(), cell_rev),
        FieldType::DateTime => DateTypeOption::from(field_rev).apply_changeset(changeset.into(), cell_rev),
        FieldType::SingleSelect => SingleSelectTypeOption::from(field_rev).apply_changeset(changeset.into(), cell_rev),
        FieldType::MultiSelect => MultiSelectTypeOption::from(field_rev).apply_changeset(changeset.into(), cell_rev),
        FieldType::Checkbox => CheckboxTypeOption::from(field_rev).apply_changeset(changeset.into(), cell_rev),
        FieldType::URL => URLTypeOption::from(field_rev).apply_changeset(changeset.into(), cell_rev),
    }?;

    Ok(AnyCellData::new(s, field_type).json())
}

pub fn decode_any_cell_data<T: TryInto<AnyCellData>>(data: T, field_rev: &FieldRevision) -> DecodedCellData {
    if let Ok(any_cell_data) = data.try_into() {
        let AnyCellData { cell_data, field_type } = any_cell_data;
        let to_field_type = field_rev.field_type_rev.into();
        match try_decode_cell_data(CellData(Some(cell_data)), field_rev, &field_type, &to_field_type) {
            Ok(cell_data) => cell_data,
            Err(e) => {
                tracing::error!("Decode cell data failed, {:?}", e);
                DecodedCellData::default()
            }
        }
    } else {
        tracing::error!("Decode type option data failed");
        DecodedCellData::default()
    }
}

pub fn try_decode_cell_data(
    cell_data: CellData<String>,
    field_rev: &FieldRevision,
    s_field_type: &FieldType,
    t_field_type: &FieldType,
) -> FlowyResult<DecodedCellData> {
    let cell_data = cell_data.try_into_inner()?;
    let get_cell_data = || {
        let field_type: FieldTypeRevision = t_field_type.into();
        let data = match t_field_type {
            FieldType::RichText => field_rev
                .get_type_option_entry::<RichTextTypeOption>(field_type)?
                .decode_cell_data(cell_data.into(), s_field_type, field_rev),
            FieldType::Number => field_rev
                .get_type_option_entry::<NumberTypeOption>(field_type)?
                .decode_cell_data(cell_data.into(), s_field_type, field_rev),
            FieldType::DateTime => field_rev
                .get_type_option_entry::<DateTypeOption>(field_type)?
                .decode_cell_data(cell_data.into(), s_field_type, field_rev),
            FieldType::SingleSelect => field_rev
                .get_type_option_entry::<SingleSelectTypeOption>(field_type)?
                .decode_cell_data(cell_data.into(), s_field_type, field_rev),
            FieldType::MultiSelect => field_rev
                .get_type_option_entry::<MultiSelectTypeOption>(field_type)?
                .decode_cell_data(cell_data.into(), s_field_type, field_rev),
            FieldType::Checkbox => field_rev
                .get_type_option_entry::<CheckboxTypeOption>(field_type)?
                .decode_cell_data(cell_data.into(), s_field_type, field_rev),
            FieldType::URL => field_rev
                .get_type_option_entry::<URLTypeOption>(field_type)?
                .decode_cell_data(cell_data.into(), s_field_type, field_rev),
        };
        Some(data)
    };

    match get_cell_data() {
        Some(Ok(data)) => Ok(data),
        Some(Err(err)) => {
            tracing::error!("{:?}", err);
            Ok(DecodedCellData::default())
        }
        None => Ok(DecodedCellData::default()),
    }
}

pub trait FromCellString {
    fn from_cell_str(s: &str) -> FlowyResult<Self>
    where
        Self: Sized;
}

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

impl std::convert::From<String> for CellData<String> {
    fn from(s: String) -> Self {
        CellData(Some(s))
    }
}

impl std::convert::From<CellData<String>> for String {
    fn from(p: CellData<String>) -> Self {
        p.try_into_inner().unwrap_or_else(|_| String::new())
    }
}

// CellChangeset
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
