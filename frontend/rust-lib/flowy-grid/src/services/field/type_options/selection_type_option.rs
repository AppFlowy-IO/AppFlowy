use crate::impl_type_option;
use crate::services::field::{BoxTypeOptionBuilder, TypeOptionBuilder};
use crate::services::row::{CellDataOperation, TypeOptionCellData};
use crate::services::util::*;
use bytes::Bytes;
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_error::{ErrorCode, FlowyError, FlowyResult};
use flowy_grid_data_model::entities::{FieldMeta, FieldType, TypeOptionDataEntity, TypeOptionDataEntry};
use flowy_grid_data_model::parser::{NotEmptyStr, NotEmptyUuid};
use rayon::iter::{IntoParallelRefIterator, ParallelIterator};
use serde::{Deserialize, Serialize};
use std::str::FromStr;
use uuid::Uuid;

pub const SELECTION_IDS_SEPARATOR: &str = ",";

// Single select
#[derive(Clone, Debug, Default, Serialize, Deserialize, ProtoBuf)]
pub struct SingleSelectTypeOption {
    #[pb(index = 1)]
    pub options: Vec<SelectOption>,

    #[pb(index = 2)]
    pub disable_color: bool,
}
impl_type_option!(SingleSelectTypeOption, FieldType::SingleSelect);

impl CellDataOperation for SingleSelectTypeOption {
    fn deserialize_cell_data(&self, data: String, _field_meta: &FieldMeta) -> String {
        if let Ok(type_option_cell_data) = TypeOptionCellData::from_str(&data) {
            if !type_option_cell_data.is_single_select() || !type_option_cell_data.is_multi_select() {
                return String::new();
            }

            let option_id = type_option_cell_data.data;
            match self.options.iter().find(|option| option.id == option_id) {
                None => String::new(),
                Some(option) => option.name.clone(),
            }
        } else {
            String::new()
        }
    }

    fn serialize_cell_data(&self, data: &str) -> Result<String, FlowyError> {
        let data = single_select_option_id_from_data(data.to_owned())?;
        Ok(TypeOptionCellData::new(&data, self.field_type()).json())
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

impl CellDataOperation for MultiSelectTypeOption {
    fn deserialize_cell_data(&self, data: String, _field_meta: &FieldMeta) -> String {
        if let Ok(type_option_cell_data) = TypeOptionCellData::from_str(&data) {
            if !type_option_cell_data.is_single_select() || !type_option_cell_data.is_multi_select() {
                return String::new();
            }

            match select_option_ids(type_option_cell_data.data) {
                Ok(option_ids) => {
                    //
                    self.options
                        .iter()
                        .filter(|option| option_ids.contains(&option.id))
                        .map(|option| option.name.clone())
                        .collect::<Vec<String>>()
                        .join(SELECTION_IDS_SEPARATOR)
                }
                Err(_) => String::new(),
            }
        } else {
            String::new()
        }
    }

    fn serialize_cell_data(&self, data: &str) -> Result<String, FlowyError> {
        let data = multi_select_option_id_from_data(data.to_owned())?;
        Ok(TypeOptionCellData::new(&data, self.field_type()).json())
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

fn single_select_option_id_from_data(data: String) -> FlowyResult<String> {
    let select_option_ids = select_option_ids(data)?;
    if select_option_ids.is_empty() {
        return Ok("".to_owned());
    }

    Ok(select_option_ids.split_first().unwrap().0.to_string())
}

fn multi_select_option_id_from_data(data: String) -> FlowyResult<String> {
    let select_option_ids = select_option_ids(data)?;
    Ok(select_option_ids.join(SELECTION_IDS_SEPARATOR))
}

fn select_option_ids(mut data: String) -> FlowyResult<Vec<String>> {
    data.retain(|c| !c.is_whitespace());
    let select_option_ids = data.split(SELECTION_IDS_SEPARATOR).collect::<Vec<&str>>();
    if select_option_ids
        .par_iter()
        .find_first(|option_id| match Uuid::parse_str(option_id) {
            Ok(_) => false,
            Err(e) => {
                tracing::error!("{}", e);
                true
            }
        })
        .is_some()
    {
        let msg = format!(
            "Invalid selection id string: {}. It should consist of the uuid string and separated by comma",
            data
        );
        return Err(FlowyError::internal().context(msg));
    }
    Ok(select_option_ids.iter().map(|id| id.to_string()).collect::<Vec<_>>())
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

#[derive(Clone)]
pub struct SelectOptionChangesetParams {
    pub grid_id: String,
    pub field_id: String,
    pub row_id: String,
    pub insert_option_id: Option<String>,
    pub delete_option_id: Option<String>,
}

impl TryInto<SelectOptionChangesetParams> for SelectOptionChangesetPayload {
    type Error = ErrorCode;

    fn try_into(self) -> Result<SelectOptionChangesetParams, Self::Error> {
        let grid_id = NotEmptyUuid::parse(self.grid_id).map_err(|_| ErrorCode::GridIdIsEmpty)?;
        let row_id = NotEmptyUuid::parse(self.row_id).map_err(|_| ErrorCode::RowIdIsEmpty)?;
        let field_id = NotEmptyUuid::parse(self.field_id).map_err(|_| ErrorCode::FieldIdIsEmpty)?;
        let insert_option_id = match self.insert_option_id {
            None => None,
            Some(insert_option_id) => Some(
                NotEmptyStr::parse(insert_option_id)
                    .map_err(|_| ErrorCode::OptionIdIsEmpty)?
                    .0,
            ),
        };

        let delete_option_id = match self.delete_option_id {
            None => None,
            Some(delete_option_id) => Some(
                NotEmptyStr::parse(delete_option_id)
                    .map_err(|_| ErrorCode::OptionIdIsEmpty)?
                    .0,
            ),
        };

        Ok(SelectOptionChangesetParams {
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

#[cfg(test)]
mod tests {
    use crate::services::field::{MultiSelectTypeOption, SingleSelectTypeOption};
    use crate::services::row::CellDataOperation;

    #[test]
    #[should_panic]
    fn selection_description_test() {
        let type_option = SingleSelectTypeOption::default();
        assert_eq!(type_option.serialize_cell_data("1,2,3").unwrap(), "1".to_owned());

        let type_option = MultiSelectTypeOption::default();
        assert_eq!(type_option.serialize_cell_data("1,2,3").unwrap(), "1,2,3".to_owned());
    }
}
