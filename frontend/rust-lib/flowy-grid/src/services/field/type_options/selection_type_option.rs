use crate::impl_from_and_to_type_option;
use crate::services::field::{BoxTypeOptionBuilder, TypeOptionBuilder};
use crate::services::row::CellDataSerde;
use crate::services::util::*;
use bytes::Bytes;
use flowy_derive::ProtoBuf;
use flowy_error::{FlowyError, FlowyResult};
use flowy_grid_data_model::entities::{FieldMeta, FieldType};
use rayon::iter::{IntoParallelRefIterator, ParallelIterator};
use serde::{Deserialize, Serialize};
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
impl_from_and_to_type_option!(SingleSelectTypeOption, FieldType::SingleSelect);

impl CellDataSerde for SingleSelectTypeOption {
    fn deserialize_cell_data(&self, data: String) -> String {
        data
    }

    fn serialize_cell_data(&self, data: &str) -> Result<String, FlowyError> {
        single_select_option_id_from_data(data.to_owned())
    }
}

#[derive(Default)]
pub struct SingleSelectTypeOptionBuilder(SingleSelectTypeOption);
impl_into_box_type_option_builder!(SingleSelectTypeOptionBuilder);
impl_from_json_str_and_from_bytes!(SingleSelectTypeOptionBuilder, SingleSelectTypeOption);

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

    fn build_type_option_str(&self) -> String {
        self.0.clone().into()
    }

    fn build_type_option_data(&self) -> Bytes {
        self.0.clone().try_into().unwrap()
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
impl_from_and_to_type_option!(MultiSelectTypeOption, FieldType::MultiSelect);

impl CellDataSerde for MultiSelectTypeOption {
    fn deserialize_cell_data(&self, data: String) -> String {
        data
    }

    fn serialize_cell_data(&self, data: &str) -> Result<String, FlowyError> {
        multi_select_option_id_from_data(data.to_owned())
    }
}

#[derive(Default)]
pub struct MultiSelectTypeOptionBuilder(MultiSelectTypeOption);
impl_into_box_type_option_builder!(MultiSelectTypeOptionBuilder);
impl_from_json_str_and_from_bytes!(MultiSelectTypeOptionBuilder, MultiSelectTypeOption);
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

    fn build_type_option_str(&self) -> String {
        self.0.clone().into()
    }

    fn build_type_option_data(&self) -> Bytes {
        self.0.clone().try_into().unwrap()
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
    pub color: String,
}

impl SelectOption {
    pub fn new(name: &str) -> Self {
        SelectOption {
            id: uuid(),
            name: name.to_owned(),
            color: "".to_string(),
        }
    }
}

#[cfg(test)]
mod tests {
    use crate::services::cell::{MultiSelectDescription, SingleSelectTypeOption};
    use crate::services::row::CellDataSerde;

    #[test]
    #[should_panic]
    fn selection_description_test() {
        let type_option = SingleSelectTypeOption::default();
        assert_eq!(description.serialize_cell_data("1,2,3").unwrap(), "1".to_owned());

        let type_option = MultiSelectDescription::default();
        assert_eq!(description.serialize_cell_data("1,2,3").unwrap(), "1,2,3".to_owned());
    }
}
