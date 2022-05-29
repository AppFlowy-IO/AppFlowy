use crate::entities::{CellIdentifier, CellIdentifierPayload};
use crate::impl_type_option;
use crate::services::field::type_options::util::get_cell_data;
use crate::services::field::{BoxTypeOptionBuilder, TypeOptionBuilder};
use crate::services::row::{CellContentChangeset, CellDataOperation, DecodedCellData, TypeOptionCellData};
use bytes::Bytes;
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_error::{ErrorCode, FlowyError, FlowyResult};
use flowy_grid_data_model::entities::{
    CellChangeset, CellMeta, FieldMeta, FieldType, TypeOptionDataDeserializer, TypeOptionDataEntry,
};
use flowy_grid_data_model::parser::NotEmptyStr;
use nanoid::nanoid;
use serde::{Deserialize, Serialize};
use std::str::FromStr;

pub const SELECTION_IDS_SEPARATOR: &str = ",";

pub trait SelectOptionOperation: TypeOptionDataEntry + Send + Sync {
    fn insert_option(&mut self, new_option: SelectOption) {
        let options = self.mut_options();
        if let Some(index) = options
            .iter()
            .position(|option| option.id == new_option.id || option.name == new_option.name)
        {
            options.remove(index);
            options.insert(index, new_option);
        } else {
            options.insert(0, new_option);
        }
    }

    fn delete_option(&mut self, delete_option: SelectOption) {
        let options = self.mut_options();
        if let Some(index) = options.iter().position(|option| option.id == delete_option.id) {
            options.remove(index);
        }
    }

    fn create_option(&self, name: &str) -> SelectOption {
        let color = select_option_color_from_index(self.options().len());
        SelectOption::with_color(name, color)
    }

    fn select_option_cell_data(&self, cell_meta: &Option<CellMeta>) -> SelectOptionCellData;

    fn options(&self) -> &Vec<SelectOption>;

    fn mut_options(&mut self) -> &mut Vec<SelectOption>;
}

pub fn select_option_operation(field_meta: &FieldMeta) -> FlowyResult<Box<dyn SelectOptionOperation>> {
    match &field_meta.field_type {
        FieldType::SingleSelect => {
            let type_option = SingleSelectTypeOption::from(field_meta);
            Ok(Box::new(type_option))
        }
        FieldType::MultiSelect => {
            let type_option = MultiSelectTypeOption::from(field_meta);
            Ok(Box::new(type_option))
        }
        ty => {
            tracing::error!("Unsupported field type: {:?} for this handler", ty);
            Err(ErrorCode::FieldInvalidOperation.into())
        }
    }
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
    fn select_option_cell_data(&self, cell_meta: &Option<CellMeta>) -> SelectOptionCellData {
        let select_options = make_select_context_from(cell_meta, &self.options);
        SelectOptionCellData {
            options: self.options.clone(),
            select_options,
        }
    }

    fn options(&self) -> &Vec<SelectOption> {
        &self.options
    }

    fn mut_options(&mut self) -> &mut Vec<SelectOption> {
        &mut self.options
    }
}

impl CellDataOperation<String, String> for SingleSelectTypeOption {
    fn decode_cell_data<T>(
        &self,
        encoded_data: T,
        decoded_field_type: &FieldType,
        _field_meta: &FieldMeta,
    ) -> FlowyResult<DecodedCellData>
    where
        T: Into<String>,
    {
        if !decoded_field_type.is_select_option() {
            return Ok(DecodedCellData::default());
        }

        let encoded_data = encoded_data.into();
        let mut cell_data = SelectOptionCellData {
            options: self.options.clone(),
            select_options: vec![],
        };
        if let Some(option_id) = select_option_ids(encoded_data).first() {
            if let Some(option) = self.options.iter().find(|option| &option.id == option_id) {
                cell_data.select_options.push(option.clone());
            }
        }

        DecodedCellData::try_from_bytes(cell_data)
    }

    fn apply_changeset<C>(&self, changeset: C, _cell_meta: Option<CellMeta>) -> Result<String, FlowyError>
    where
        C: Into<CellContentChangeset>,
    {
        let changeset = changeset.into();
        let select_option_changeset: SelectOptionCellContentChangeset = serde_json::from_str(&changeset)?;
        let new_cell_data: String;
        if let Some(insert_option_id) = select_option_changeset.insert_option_id {
            tracing::trace!("Insert single select option: {}", &insert_option_id);
            new_cell_data = insert_option_id;
        } else {
            tracing::trace!("Delete single select option");
            new_cell_data = "".to_string()
        }

        Ok(new_cell_data)
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
    fn select_option_cell_data(&self, cell_meta: &Option<CellMeta>) -> SelectOptionCellData {
        let select_options = make_select_context_from(cell_meta, &self.options);
        SelectOptionCellData {
            options: self.options.clone(),
            select_options,
        }
    }

    fn options(&self) -> &Vec<SelectOption> {
        &self.options
    }

    fn mut_options(&mut self) -> &mut Vec<SelectOption> {
        &mut self.options
    }
}

impl CellDataOperation<String, String> for MultiSelectTypeOption {
    fn decode_cell_data<T>(
        &self,
        encoded_data: T,
        decoded_field_type: &FieldType,
        _field_meta: &FieldMeta,
    ) -> FlowyResult<DecodedCellData>
    where
        T: Into<String>,
    {
        if !decoded_field_type.is_select_option() {
            return Ok(DecodedCellData::default());
        }

        let encoded_data = encoded_data.into();
        let select_options = select_option_ids(encoded_data)
            .into_iter()
            .flat_map(|option_id| self.options.iter().find(|option| option.id == option_id).cloned())
            .collect::<Vec<SelectOption>>();

        let cell_data = SelectOptionCellData {
            options: self.options.clone(),
            select_options,
        };

        DecodedCellData::try_from_bytes(cell_data)
    }

    fn apply_changeset<T>(&self, changeset: T, cell_meta: Option<CellMeta>) -> Result<String, FlowyError>
    where
        T: Into<CellContentChangeset>,
    {
        let content_changeset: SelectOptionCellContentChangeset = serde_json::from_str(&changeset.into())?;
        let new_cell_data: String;
        match cell_meta {
            None => {
                new_cell_data = content_changeset.insert_option_id.unwrap_or_else(|| "".to_owned());
            }
            Some(cell_meta) => {
                let cell_data = get_cell_data(&cell_meta);
                let mut selected_options = select_option_ids(cell_data);
                if let Some(insert_option_id) = content_changeset.insert_option_id {
                    tracing::trace!("Insert multi select option: {}", &insert_option_id);
                    if selected_options.contains(&insert_option_id) {
                        selected_options.retain(|id| id != &insert_option_id);
                    } else {
                        selected_options.push(insert_option_id);
                    }
                }

                if let Some(delete_option_id) = content_changeset.delete_option_id {
                    tracing::trace!("Delete multi select option: {}", &delete_option_id);
                    selected_options.retain(|id| id != &delete_option_id);
                }

                new_cell_data = selected_options.join(SELECTION_IDS_SEPARATOR);
                tracing::trace!("Multi select cell data: {}", &new_cell_data);
            }
        }

        Ok(new_cell_data)
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

#[derive(Clone, Debug, Default, PartialEq, Eq, Serialize, Deserialize, ProtoBuf)]
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
            id: nanoid!(4),
            name: name.to_owned(),
            color: SelectOptionColor::default(),
        }
    }

    pub fn with_color(name: &str, color: SelectOptionColor) -> Self {
        SelectOption {
            id: nanoid!(4),
            name: name.to_owned(),
            color,
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
    pub update_option: Option<SelectOption>,

    #[pb(index = 4, one_of)]
    pub delete_option: Option<SelectOption>,
}

pub struct SelectOptionChangeset {
    pub cell_identifier: CellIdentifier,
    pub insert_option: Option<SelectOption>,
    pub update_option: Option<SelectOption>,
    pub delete_option: Option<SelectOption>,
}

impl TryInto<SelectOptionChangeset> for SelectOptionChangesetPayload {
    type Error = ErrorCode;

    fn try_into(self) -> Result<SelectOptionChangeset, Self::Error> {
        let cell_identifier = self.cell_identifier.try_into()?;
        Ok(SelectOptionChangeset {
            cell_identifier,
            insert_option: self.insert_option,
            update_option: self.update_option,
            delete_option: self.delete_option,
        })
    }
}

#[derive(Clone, Debug, Default, ProtoBuf)]
pub struct SelectOptionCellChangesetPayload {
    #[pb(index = 1)]
    pub cell_identifier: CellIdentifierPayload,

    #[pb(index = 2, one_of)]
    pub insert_option_id: Option<String>,

    #[pb(index = 3, one_of)]
    pub delete_option_id: Option<String>,
}

pub struct SelectOptionCellChangesetParams {
    pub cell_identifier: CellIdentifier,
    pub insert_option_id: Option<String>,
    pub delete_option_id: Option<String>,
}

impl std::convert::From<SelectOptionCellChangesetParams> for CellChangeset {
    fn from(params: SelectOptionCellChangesetParams) -> Self {
        let changeset = SelectOptionCellContentChangeset {
            insert_option_id: params.insert_option_id,
            delete_option_id: params.delete_option_id,
        };
        let s = serde_json::to_string(&changeset).unwrap();
        CellChangeset {
            grid_id: params.cell_identifier.grid_id,
            row_id: params.cell_identifier.row_id,
            field_id: params.cell_identifier.field_id,
            cell_content_changeset: Some(s),
        }
    }
}

impl TryInto<SelectOptionCellChangesetParams> for SelectOptionCellChangesetPayload {
    type Error = ErrorCode;

    fn try_into(self) -> Result<SelectOptionCellChangesetParams, Self::Error> {
        let cell_identifier: CellIdentifier = self.cell_identifier.try_into()?;
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

        Ok(SelectOptionCellChangesetParams {
            cell_identifier,
            insert_option_id,
            delete_option_id,
        })
    }
}

#[derive(Clone, Serialize, Deserialize)]
pub struct SelectOptionCellContentChangeset {
    pub insert_option_id: Option<String>,
    pub delete_option_id: Option<String>,
}

impl SelectOptionCellContentChangeset {
    pub fn from_insert(option_id: &str) -> Self {
        SelectOptionCellContentChangeset {
            insert_option_id: Some(option_id.to_string()),
            delete_option_id: None,
        }
    }

    pub fn from_delete(option_id: &str) -> Self {
        SelectOptionCellContentChangeset {
            insert_option_id: None,
            delete_option_id: Some(option_id.to_string()),
        }
    }

    pub fn to_str(&self) -> String {
        serde_json::to_string(self).unwrap()
    }
}

#[derive(Clone, Debug, Default, Serialize, Deserialize, ProtoBuf)]
pub struct SelectOptionCellData {
    #[pb(index = 1)]
    pub options: Vec<SelectOption>,

    #[pb(index = 2)]
    pub select_options: Vec<SelectOption>,
}

#[derive(ProtoBuf_Enum, PartialEq, Eq, Serialize, Deserialize, Debug, Clone)]
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

pub fn select_option_color_from_index(index: usize) -> SelectOptionColor {
    match index % 8 {
        0 => SelectOptionColor::Purple,
        1 => SelectOptionColor::Pink,
        2 => SelectOptionColor::LightPink,
        3 => SelectOptionColor::Orange,
        4 => SelectOptionColor::Yellow,
        5 => SelectOptionColor::Lime,
        6 => SelectOptionColor::Green,
        7 => SelectOptionColor::Aqua,
        8 => SelectOptionColor::Blue,
        _ => SelectOptionColor::Purple,
    }
}

impl std::default::Default for SelectOptionColor {
    fn default() -> Self {
        SelectOptionColor::Purple
    }
}

fn make_select_context_from(cell_meta: &Option<CellMeta>, options: &[SelectOption]) -> Vec<SelectOption> {
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
    use crate::services::field::FieldBuilder;
    use crate::services::field::{
        MultiSelectTypeOption, MultiSelectTypeOptionBuilder, SelectOption, SelectOptionCellContentChangeset,
        SelectOptionCellData, SingleSelectTypeOption, SingleSelectTypeOptionBuilder, SELECTION_IDS_SEPARATOR,
    };
    use crate::services::row::CellDataOperation;
    use flowy_grid_data_model::entities::FieldMeta;

    #[test]
    fn single_select_test() {
        let google_option = SelectOption::new("Google");
        let facebook_option = SelectOption::new("Facebook");
        let twitter_option = SelectOption::new("Twitter");
        let single_select = SingleSelectTypeOptionBuilder::default()
            .option(google_option.clone())
            .option(facebook_option.clone())
            .option(twitter_option);

        let field_meta = FieldBuilder::new(single_select)
            .name("Platform")
            .visibility(true)
            .build();

        let type_option = SingleSelectTypeOption::from(&field_meta);

        let option_ids = vec![google_option.id.clone(), facebook_option.id].join(SELECTION_IDS_SEPARATOR);
        let data = SelectOptionCellContentChangeset::from_insert(&option_ids).to_str();
        let cell_data = type_option.apply_changeset(data, None).unwrap();
        assert_single_select_options(cell_data, &type_option, &field_meta, vec![google_option.clone()]);

        let data = SelectOptionCellContentChangeset::from_insert(&google_option.id).to_str();
        let cell_data = type_option.apply_changeset(data, None).unwrap();
        assert_single_select_options(cell_data, &type_option, &field_meta, vec![google_option]);

        // Invalid option id
        let cell_data = type_option
            .apply_changeset(SelectOptionCellContentChangeset::from_insert("").to_str(), None)
            .unwrap();
        assert_single_select_options(cell_data, &type_option, &field_meta, vec![]);

        // Invalid option id
        let cell_data = type_option
            .apply_changeset(SelectOptionCellContentChangeset::from_insert("123").to_str(), None)
            .unwrap();

        assert_single_select_options(cell_data, &type_option, &field_meta, vec![]);

        // Invalid changeset
        assert!(type_option.apply_changeset("123", None).is_err());
    }

    #[test]
    fn multi_select_test() {
        let google_option = SelectOption::new("Google");
        let facebook_option = SelectOption::new("Facebook");
        let twitter_option = SelectOption::new("Twitter");
        let multi_select = MultiSelectTypeOptionBuilder::default()
            .option(google_option.clone())
            .option(facebook_option.clone())
            .option(twitter_option);

        let field_meta = FieldBuilder::new(multi_select)
            .name("Platform")
            .visibility(true)
            .build();

        let type_option = MultiSelectTypeOption::from(&field_meta);

        let option_ids = vec![google_option.id.clone(), facebook_option.id.clone()].join(SELECTION_IDS_SEPARATOR);
        let data = SelectOptionCellContentChangeset::from_insert(&option_ids).to_str();
        let cell_data = type_option.apply_changeset(data, None).unwrap();
        assert_multi_select_options(
            cell_data,
            &type_option,
            &field_meta,
            vec![google_option.clone(), facebook_option],
        );

        let data = SelectOptionCellContentChangeset::from_insert(&google_option.id).to_str();
        let cell_data = type_option.apply_changeset(data, None).unwrap();
        assert_multi_select_options(cell_data, &type_option, &field_meta, vec![google_option]);

        // Invalid option id
        let cell_data = type_option
            .apply_changeset(SelectOptionCellContentChangeset::from_insert("").to_str(), None)
            .unwrap();
        assert_multi_select_options(cell_data, &type_option, &field_meta, vec![]);

        // Invalid option id
        let cell_data = type_option
            .apply_changeset(SelectOptionCellContentChangeset::from_insert("123,456").to_str(), None)
            .unwrap();
        assert_multi_select_options(cell_data, &type_option, &field_meta, vec![]);

        // Invalid changeset
        assert!(type_option.apply_changeset("123", None).is_err());
    }

    fn assert_multi_select_options(
        cell_data: String,
        type_option: &MultiSelectTypeOption,
        field_meta: &FieldMeta,
        expected: Vec<SelectOption>,
    ) {
        assert_eq!(
            expected,
            type_option
                .decode_cell_data(cell_data, &field_meta.field_type, field_meta)
                .unwrap()
                .parse::<SelectOptionCellData>()
                .unwrap()
                .select_options,
        );
    }

    fn assert_single_select_options(
        cell_data: String,
        type_option: &SingleSelectTypeOption,
        field_meta: &FieldMeta,
        expected: Vec<SelectOption>,
    ) {
        assert_eq!(
            expected,
            type_option
                .decode_cell_data(cell_data, &field_meta.field_type, field_meta)
                .unwrap()
                .parse::<SelectOptionCellData>()
                .unwrap()
                .select_options,
        );
    }
}
