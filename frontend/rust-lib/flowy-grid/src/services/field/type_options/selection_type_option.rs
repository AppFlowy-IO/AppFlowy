use crate::impl_type_option;
use crate::services::cell::{CellIdentifier, CellIdentifierPayload};
use crate::services::field::{BoxTypeOptionBuilder, TypeOptionBuilder};
use crate::services::row::{CellDataChangeset, CellDataOperation, TypeOptionCellData};
use crate::services::util::*;
use bytes::Bytes;
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_error::{ErrorCode, FlowyError, FlowyResult};
use flowy_grid_data_model::entities::{
    CellMeta, CellMetaChangeset, FieldMeta, FieldType, TypeOptionDataEntity, TypeOptionDataEntry,
};
use flowy_grid_data_model::parser::{NotEmptyStr, NotEmptyUuid};
use rayon::iter::{IntoParallelRefIterator, ParallelIterator};
use serde::{Deserialize, Serialize};
use std::str::FromStr;
use uuid::Uuid;

pub const SELECTION_IDS_SEPARATOR: &str = ",";

pub trait SelectOptionOperation: TypeOptionDataEntry + Send + Sync {
    fn insert_option(&mut self, new_option: SelectOption);
    fn delete_option(&mut self, delete_option: SelectOption);
    fn option_context(&self, cell_meta: &Option<CellMeta>) -> SelectOptionContext;
}

// Single select
#[derive(Clone, Debug, Default, Serialize, Deserialize, ProtoBuf)]
pub struct SingleSelectTypeOption {
    #[pb(index = 1)]
    pub options: Vec<SelectOption>,

    #[pb(index = 2)]
    pub disable_color: bool,
}
impl_type_option!(SingleSelectTypeOption, FieldType::SingleSelect);

impl SelectOptionOperation for SingleSelectTypeOption {
    fn insert_option(&mut self, new_option: SelectOption) {
        if let Some(index) = self.options.iter().position(|option| option.id == new_option.id) {
            self.options.remove(index);
            self.options.insert(index, new_option);
        } else {
            self.options.insert(0, new_option);
        }
    }

    fn delete_option(&mut self, delete_option: SelectOption) {
        if let Some(index) = self.options.iter().position(|option| option.id == delete_option.id) {
            self.options.remove(index);
        }
    }

    fn option_context(&self, cell_meta: &Option<CellMeta>) -> SelectOptionContext {
        let select_options = make_select_context_from(cell_meta, &self.options);
        SelectOptionContext {
            options: self.options.clone(),
            select_options,
        }
    }
}

impl CellDataOperation for SingleSelectTypeOption {
    fn decode_cell_data(&self, data: String, _field_meta: &FieldMeta) -> String {
        if let Ok(type_option_cell_data) = TypeOptionCellData::from_str(&data) {
            if !type_option_cell_data.is_single_select() {
                return String::new();
            }

            match select_option_ids(type_option_cell_data.data).pop() {
                None => String::new(),
                Some(option_id) => match self.options.iter().find(|option| option.id == option_id) {
                    None => String::new(),
                    Some(option) => option.name.clone(),
                },
            }
        } else {
            String::new()
        }
    }

    fn apply_changeset<T: Into<CellDataChangeset>>(
        &self,
        changeset: T,
        _cell_meta: Option<CellMeta>,
    ) -> Result<String, FlowyError> {
        let changeset = changeset.into();
        let select_option_changeset: SelectOptionCellChangeset = serde_json::from_str(&changeset)?;
        let new_cell_data: String;
        if let Some(insert_option_id) = select_option_changeset.insert_option_id {
            new_cell_data = insert_option_id;
        } else {
            new_cell_data = "".to_string()
        }

        return Ok(TypeOptionCellData::new(&new_cell_data, self.field_type()).json());
    }
}

#[derive(Default)]
pub struct SingleSelectTypeOptionBuilder(SingleSelectTypeOption);
impl_into_box_type_option_builder!(SingleSelectTypeOptionBuilder);
impl_builder_from_json_str_and_from_bytes!(SingleSelectTypeOptionBuilder, SingleSelectTypeOption);

impl SingleSelectTypeOptionBuilder {
    pub fn option(mut self, opt: SelectOption) -> Self {
        self.0.options.push(opt);
        self
    }
}

impl TypeOptionBuilder for SingleSelectTypeOptionBuilder {
    fn field_type(&self) -> FieldType {
        self.0.field_type()
    }

    fn entry(&self) -> &dyn TypeOptionDataEntry {
        &self.0
    }
}

// Multiple select
#[derive(Clone, Debug, Default, Serialize, Deserialize, ProtoBuf)]
pub struct MultiSelectTypeOption {
    #[pb(index = 1)]
    pub options: Vec<SelectOption>,

    #[pb(index = 2)]
    pub disable_color: bool,
}
impl_type_option!(MultiSelectTypeOption, FieldType::MultiSelect);

impl SelectOptionOperation for MultiSelectTypeOption {
    fn insert_option(&mut self, new_option: SelectOption) {
        if let Some(index) = self.options.iter().position(|option| option.id == new_option.id) {
            self.options.remove(index);
            self.options.insert(index, new_option);
        } else {
            self.options.insert(0, new_option);
        }
    }

    fn delete_option(&mut self, delete_option: SelectOption) {
        if let Some(index) = self.options.iter().position(|option| option.id == delete_option.id) {
            self.options.remove(index);
        }
    }

    fn option_context(&self, cell_meta: &Option<CellMeta>) -> SelectOptionContext {
        let select_options = make_select_context_from(cell_meta, &self.options);
        SelectOptionContext {
            options: self.options.clone(),
            select_options,
        }
    }
}

impl CellDataOperation for MultiSelectTypeOption {
    fn decode_cell_data(&self, data: String, _field_meta: &FieldMeta) -> String {
        if let Ok(type_option_cell_data) = TypeOptionCellData::from_str(&data) {
            if !type_option_cell_data.is_multi_select() {
                return String::new();
            }
            let option_ids = select_option_ids(type_option_cell_data.data);
            self.options
                .iter()
                .filter(|option| option_ids.contains(&option.id))
                .map(|option| option.name.clone())
                .collect::<Vec<String>>()
                .join(SELECTION_IDS_SEPARATOR)
        } else {
            String::new()
        }
    }

    fn apply_changeset<T: Into<CellDataChangeset>>(
        &self,
        changeset: T,
        cell_meta: Option<CellMeta>,
    ) -> Result<String, FlowyError> {
        let changeset = changeset.into();
        let select_option_changeset: SelectOptionCellChangeset = serde_json::from_str(&changeset)?;
        let new_cell_data: String;
        match cell_meta {
            None => {
                new_cell_data = select_option_changeset
                    .insert_option_id
                    .unwrap_or_else(|| "".to_owned());
            }
            Some(cell_meta) => {
                let mut selected_options = select_option_ids(cell_meta.data);
                if let Some(insert_option_id) = select_option_changeset.insert_option_id {
                    selected_options.push(insert_option_id);
                }

                if let Some(delete_option_id) = select_option_changeset.delete_option_id {
                    selected_options.retain(|id| id != &delete_option_id);
                }

                new_cell_data = selected_options.join(SELECTION_IDS_SEPARATOR);
            }
        }

        Ok(TypeOptionCellData::new(&new_cell_data, self.field_type()).json())
    }
}

#[derive(Default)]
pub struct MultiSelectTypeOptionBuilder(MultiSelectTypeOption);
impl_into_box_type_option_builder!(MultiSelectTypeOptionBuilder);
impl_builder_from_json_str_and_from_bytes!(MultiSelectTypeOptionBuilder, MultiSelectTypeOption);
impl MultiSelectTypeOptionBuilder {
    pub fn option(mut self, opt: SelectOption) -> Self {
        self.0.options.push(opt);
        self
    }
}

impl TypeOptionBuilder for MultiSelectTypeOptionBuilder {
    fn field_type(&self) -> FieldType {
        self.0.field_type()
    }

    fn entry(&self) -> &dyn TypeOptionDataEntry {
        &self.0
    }
}

fn select_option_ids(data: String) -> Vec<String> {
    data.split(SELECTION_IDS_SEPARATOR)
        .map(|id| id.to_string())
        .collect::<Vec<String>>()
}

#[derive(Clone, Debug, Default, Serialize, Deserialize, ProtoBuf)]
pub struct SelectOption {
    #[pb(index = 1)]
    pub id: String,

    #[pb(index = 2)]
    pub name: String,

    #[pb(index = 3)]
    pub color: SelectOptionColor,
}

impl SelectOption {
    pub fn new(name: &str) -> Self {
        SelectOption {
            id: uuid(),
            name: name.to_owned(),
            color: SelectOptionColor::default(),
        }
    }
}

#[derive(Clone, Debug, Default, ProtoBuf)]
pub struct SelectOptionChangesetPayload {
    #[pb(index = 1)]
    pub cell_identifier: CellIdentifierPayload,

    #[pb(index = 2, one_of)]
    pub insert_option: Option<SelectOption>,

    #[pb(index = 3, one_of)]
    pub delete_option: Option<SelectOption>,
}

pub struct SelectOptionChangeset {
    pub cell_identifier: CellIdentifier,
    pub insert_option: Option<SelectOption>,
    pub delete_option: Option<SelectOption>,
}

impl TryInto<SelectOptionChangeset> for SelectOptionChangesetPayload {
    type Error = ErrorCode;

    fn try_into(self) -> Result<SelectOptionChangeset, Self::Error> {
        let cell_identifier = self.cell_identifier.try_into()?;
        Ok(SelectOptionChangeset {
            cell_identifier,
            insert_option: self.insert_option,
            delete_option: self.delete_option,
        })
    }
}

#[derive(Clone, Debug, Default, ProtoBuf)]
pub struct SelectOptionCellChangesetPayload {
    #[pb(index = 1)]
    pub grid_id: String,

    #[pb(index = 2)]
    pub row_id: String,

    #[pb(index = 3)]
    pub field_id: String,

    #[pb(index = 4, one_of)]
    pub insert_option_id: Option<String>,

    #[pb(index = 5, one_of)]
    pub delete_option_id: Option<String>,
}

pub struct SelectOptionCellChangesetParams {
    pub grid_id: String,
    pub field_id: String,
    pub row_id: String,
    pub insert_option_id: Option<String>,
    pub delete_option_id: Option<String>,
}

#[derive(Clone, Serialize, Deserialize)]
pub struct SelectOptionCellChangeset {
    pub insert_option_id: Option<String>,
    pub delete_option_id: Option<String>,
}

impl SelectOptionCellChangeset {
    pub fn from_insert(option_id: &str) -> Self {
        SelectOptionCellChangeset {
            insert_option_id: Some(option_id.to_string()),
            delete_option_id: None,
        }
    }

    pub fn from_delete(option_id: &str) -> Self {
        SelectOptionCellChangeset {
            insert_option_id: None,
            delete_option_id: Some(option_id.to_string()),
        }
    }

    pub fn cell_data(&self) -> String {
        serde_json::to_string(self).unwrap()
    }
}

impl std::convert::From<SelectOptionCellChangesetParams> for CellMetaChangeset {
    fn from(params: SelectOptionCellChangesetParams) -> Self {
        let changeset = SelectOptionCellChangeset {
            insert_option_id: params.insert_option_id,
            delete_option_id: params.delete_option_id,
        };
        let s = serde_json::to_string(&changeset).unwrap();
        CellMetaChangeset {
            grid_id: params.grid_id,
            row_id: params.row_id,
            field_id: params.field_id,
            data: Some(s),
        }
    }
}

impl TryInto<SelectOptionCellChangesetParams> for SelectOptionCellChangesetPayload {
    type Error = ErrorCode;

    fn try_into(self) -> Result<SelectOptionCellChangesetParams, Self::Error> {
        let grid_id = NotEmptyUuid::parse(self.grid_id).map_err(|_| ErrorCode::GridIdIsEmpty)?;
        let row_id = NotEmptyUuid::parse(self.row_id).map_err(|_| ErrorCode::RowIdIsEmpty)?;
        let field_id = NotEmptyUuid::parse(self.field_id).map_err(|_| ErrorCode::FieldIdIsEmpty)?;
        let insert_option_id = match self.insert_option_id {
            None => None,
            Some(insert_option_id) => Some(
                NotEmptyUuid::parse(insert_option_id)
                    .map_err(|_| ErrorCode::OptionIdIsEmpty)?
                    .0,
            ),
        };

        let delete_option_id = match self.delete_option_id {
            None => None,
            Some(delete_option_id) => Some(
                NotEmptyUuid::parse(delete_option_id)
                    .map_err(|_| ErrorCode::OptionIdIsEmpty)?
                    .0,
            ),
        };

        Ok(SelectOptionCellChangesetParams {
            grid_id: grid_id.0,
            row_id: row_id.0,
            field_id: field_id.0,
            insert_option_id,
            delete_option_id,
        })
    }
}

#[derive(Clone, Debug, Default, Serialize, Deserialize, ProtoBuf)]
pub struct SelectOptionContext {
    #[pb(index = 1)]
    pub options: Vec<SelectOption>,

    #[pb(index = 2)]
    pub select_options: Vec<SelectOption>,
}

#[derive(ProtoBuf_Enum, Serialize, Deserialize, Debug, Clone)]
#[repr(u8)]
pub enum SelectOptionColor {
    Purple = 0,
    Pink = 1,
    LightPink = 2,
    Orange = 3,
    Yellow = 4,
    Lime = 5,
    Green = 6,
    Aqua = 7,
    Blue = 8,
}

impl std::default::Default for SelectOptionColor {
    fn default() -> Self {
        SelectOptionColor::Purple
    }
}

fn make_select_context_from(cell_meta: &Option<CellMeta>, options: &Vec<SelectOption>) -> Vec<SelectOption> {
    match cell_meta {
        None => vec![],
        Some(cell_meta) => {
            if let Ok(type_option_cell_data) = TypeOptionCellData::from_str(&cell_meta.data) {
                select_option_ids(type_option_cell_data.data)
                    .into_iter()
                    .flat_map(|option_id| options.iter().find(|option| option.id == option_id).cloned())
                    .collect()
            } else {
                vec![]
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use crate::services::field::{MultiSelectTypeOption, SingleSelectTypeOption};
    use crate::services::row::CellDataOperation;

    #[test]
    #[should_panic]
    fn selection_description_test() {
        let type_option = SingleSelectTypeOption::default();
        assert_eq!(type_option.apply_changeset("1,2,3").unwrap(), "1".to_owned());

        let type_option = MultiSelectTypeOption::default();
        assert_eq!(type_option.apply_changeset("1,2,3").unwrap(), "1,2,3".to_owned());
    }
}
