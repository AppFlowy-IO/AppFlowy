use crate::services::field::*;
use std::fmt::Formatter;

use flowy_error::FlowyError;
use flowy_grid_data_model::entities::{CellMeta, FieldMeta, FieldType};
use serde::{Deserialize, Serialize};

pub trait CellDataOperation {
    fn decode_cell_data(&self, data: String, field_meta: &FieldMeta) -> String;
    fn apply_changeset<T: Into<CellDataChangeset>>(
        &self,
        changeset: T,
        cell_meta: Option<CellMeta>,
    ) -> Result<String, FlowyError>;
}

#[derive(Debug)]
pub struct CellDataChangeset(String);

impl std::fmt::Display for CellDataChangeset {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", &self.0)
    }
}

impl<T: AsRef<str>> std::convert::From<T> for CellDataChangeset {
    fn from(s: T) -> Self {
        let s = s.as_ref().to_owned();
        CellDataChangeset(s)
    }
}

impl std::ops::Deref for CellDataChangeset {
    type Target = str;

    fn deref(&self) -> &Self::Target {
        &self.0
    }
}

#[derive(Debug, Serialize, Deserialize)]
pub struct TypeOptionCellData {
    pub data: String,
    pub field_type: FieldType,
}

impl std::str::FromStr for TypeOptionCellData {
    type Err = FlowyError;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        let type_option_cell_data: TypeOptionCellData = serde_json::from_str(s)?;
        Ok(type_option_cell_data)
    }
}

impl TypeOptionCellData {
    pub fn new<T: ToString>(data: T, field_type: FieldType) -> Self {
        TypeOptionCellData {
            data: data.to_string(),
            field_type,
        }
    }

    pub fn json(&self) -> String {
        serde_json::to_string(self).unwrap_or_else(|_| "".to_owned())
    }

    pub fn is_number(&self) -> bool {
        self.field_type == FieldType::Number
    }

    pub fn is_text(&self) -> bool {
        self.field_type == FieldType::RichText
    }

    pub fn is_checkbox(&self) -> bool {
        self.field_type == FieldType::Checkbox
    }

    pub fn is_date(&self) -> bool {
        self.field_type == FieldType::DateTime
    }

    pub fn is_single_select(&self) -> bool {
        self.field_type == FieldType::SingleSelect
    }

    pub fn is_multi_select(&self) -> bool {
        self.field_type == FieldType::MultiSelect
    }
}

/// The changeset will be deserialized into specific data base on the FieldType.
/// For example, it's String on FieldType::RichText, and SelectOptionChangeset on FieldType::SingleSelect
pub fn apply_cell_data_changeset<T: Into<CellDataChangeset>>(
    changeset: T,
    cell_meta: Option<CellMeta>,
    field_meta: &FieldMeta,
) -> Result<String, FlowyError> {
    match field_meta.field_type {
        FieldType::RichText => RichTextTypeOption::from(field_meta).apply_changeset(changeset, cell_meta),
        FieldType::Number => NumberTypeOption::from(field_meta).apply_changeset(changeset, cell_meta),
        FieldType::DateTime => DateTypeOption::from(field_meta).apply_changeset(changeset, cell_meta),
        FieldType::SingleSelect => SingleSelectTypeOption::from(field_meta).apply_changeset(changeset, cell_meta),
        FieldType::MultiSelect => MultiSelectTypeOption::from(field_meta).apply_changeset(changeset, cell_meta),
        FieldType::Checkbox => CheckboxTypeOption::from(field_meta).apply_changeset(changeset, cell_meta),
    }
}
//
// #[tracing::instrument(level = "trace", skip(field_meta, data), fields(content), err)]
// pub fn decode_cell_data(data: String, field_meta: &FieldMeta, field_type: &FieldType) -> Result<String, FlowyError> {
//     let s = match field_meta.field_type {
//         FieldType::RichText => RichTextTypeOption::from(field_meta).decode_cell_data(data, field_meta),
//         FieldType::Number => NumberTypeOption::from(field_meta).decode_cell_data(data, field_meta),
//         FieldType::DateTime => DateTypeOption::from(field_meta).decode_cell_data(data, field_meta),
//         FieldType::SingleSelect => SingleSelectTypeOption::from(field_meta).decode_cell_data(data, field_meta),
//         FieldType::MultiSelect => MultiSelectTypeOption::from(field_meta).decode_cell_data(data, field_meta),
//         FieldType::Checkbox => CheckboxTypeOption::from(field_meta).decode_cell_data(data, field_meta),
//     };
//     tracing::Span::current().record("content", &format!("{:?}: {}", field_meta.field_type, s).as_str());
//     Ok(s)
// }

#[tracing::instrument(level = "trace", skip(field_meta, data), fields(content))]
pub fn decode_cell_data(data: String, field_meta: &FieldMeta, field_type: &FieldType) -> Option<String> {
    let s = match field_type {
        FieldType::RichText => field_meta
            .get_type_option_entry::<RichTextTypeOption>(field_type)?
            .decode_cell_data(data, field_meta),
        FieldType::Number => field_meta
            .get_type_option_entry::<NumberTypeOption>(field_type)?
            .decode_cell_data(data, field_meta),
        FieldType::DateTime => field_meta
            .get_type_option_entry::<DateTypeOption>(field_type)?
            .decode_cell_data(data, field_meta),
        FieldType::SingleSelect => field_meta
            .get_type_option_entry::<SingleSelectTypeOption>(field_type)?
            .decode_cell_data(data, field_meta),
        FieldType::MultiSelect => field_meta
            .get_type_option_entry::<MultiSelectTypeOption>(field_type)?
            .decode_cell_data(data, field_meta),
        FieldType::Checkbox => field_meta
            .get_type_option_entry::<CheckboxTypeOption>(field_type)?
            .decode_cell_data(data, field_meta),
    };
    tracing::Span::current().record("content", &format!("{:?}: {}", field_meta.field_type, s).as_str());
    Some(s)
}
