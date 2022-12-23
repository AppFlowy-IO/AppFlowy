use crate::entities::parser::NotEmptyStr;
use crate::entities::{CellChangesetPB, CellPathPB, CellPathParams, FieldType};
use crate::services::cell::{
    CellDataDecoder, CellProtobufBlobParser, DecodedCellData, FromCellChangeset, FromCellString,
};

use crate::services::field::selection_type_option::type_option_transform::SelectOptionTypeOptionTransformHelper;
use crate::services::field::{
    CheckboxCellData, ChecklistTypeOptionPB, MultiSelectTypeOptionPB, SingleSelectTypeOptionPB, TypeOption,
    TypeOptionCellData, TypeOptionTransform,
};
use bytes::Bytes;
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_error::{internal_error, ErrorCode, FlowyResult};
use grid_rev_model::{FieldRevision, TypeOptionDataSerializer};
use nanoid::nanoid;
use serde::{Deserialize, Serialize};

pub const SELECTION_IDS_SEPARATOR: &str = ",";

/// [SelectOptionPB] represents an option for a single select, and multiple select.
#[derive(Clone, Debug, Default, PartialEq, Eq, Serialize, Deserialize, ProtoBuf)]
pub struct SelectOptionPB {
    #[pb(index = 1)]
    pub id: String,

    #[pb(index = 2)]
    pub name: String,

    #[pb(index = 3)]
    pub color: SelectOptionColorPB,
}

pub fn gen_option_id() -> String {
    nanoid!(4)
}

impl SelectOptionPB {
    pub fn new(name: &str) -> Self {
        SelectOptionPB {
            id: gen_option_id(),
            name: name.to_owned(),
            color: SelectOptionColorPB::default(),
        }
    }

    pub fn with_color(name: &str, color: SelectOptionColorPB) -> Self {
        SelectOptionPB {
            id: nanoid!(4),
            name: name.to_owned(),
            color,
        }
    }
}

#[derive(ProtoBuf_Enum, PartialEq, Eq, Serialize, Deserialize, Debug, Clone)]
#[repr(u8)]
pub enum SelectOptionColorPB {
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

impl std::default::Default for SelectOptionColorPB {
    fn default() -> Self {
        SelectOptionColorPB::Purple
    }
}

pub fn make_selected_options(ids: SelectOptionIds, options: &[SelectOptionPB]) -> Vec<SelectOptionPB> {
    ids.iter()
        .flat_map(|option_id| options.iter().find(|option| &option.id == option_id).cloned())
        .collect()
}
/// Defines the shared actions used by SingleSelect or Multi-Select.
pub trait SelectTypeOptionSharedAction: TypeOptionDataSerializer + Send + Sync {
    /// Returns `None` means there is no limited
    fn number_of_max_options(&self) -> Option<usize>;

    /// Insert the `SelectOptionPB` into corresponding type option.
    fn insert_option(&mut self, new_option: SelectOptionPB) {
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

    fn delete_option(&mut self, delete_option: SelectOptionPB) {
        let options = self.mut_options();
        if let Some(index) = options.iter().position(|option| option.id == delete_option.id) {
            options.remove(index);
        }
    }

    fn create_option(&self, name: &str) -> SelectOptionPB {
        let color = new_select_option_color(self.options());
        SelectOptionPB::with_color(name, color)
    }

    /// Return a list of options that are selected by user
    fn get_selected_options(&self, ids: SelectOptionIds) -> SelectOptionCellDataPB {
        let mut select_options = make_selected_options(ids, self.options());
        match self.number_of_max_options() {
            None => {}
            Some(number_of_max_options) => {
                select_options.truncate(number_of_max_options);
            }
        }
        SelectOptionCellDataPB {
            options: self.options().clone(),
            select_options,
        }
    }

    fn options(&self) -> &Vec<SelectOptionPB>;

    fn mut_options(&mut self) -> &mut Vec<SelectOptionPB>;
}

impl<T> TypeOptionTransform for T
where
    T: SelectTypeOptionSharedAction
        + TypeOption<CellData = SelectOptionIds>
        + TypeOptionDataSerializer
        + CellDataDecoder,
{
    fn transformable(&self) -> bool {
        true
    }

    fn transform_type_option(&mut self, old_type_option_field_type: FieldType, old_type_option_data: String) {
        SelectOptionTypeOptionTransformHelper::transform_type_option(
            self,
            &old_type_option_field_type,
            old_type_option_data,
        );
    }

    fn transform_type_option_cell_data(
        &self,
        cell_data: &str,
        decoded_field_type: &FieldType,
        _field_rev: &FieldRevision,
    ) -> Option<<Self as TypeOption>::CellData> {
        match decoded_field_type {
            FieldType::SingleSelect | FieldType::MultiSelect | FieldType::Checklist => None,
            FieldType::Checkbox => match CheckboxCellData::from_cell_str(cell_data) {
                Ok(checkbox_cell_data) => {
                    let cell_content = checkbox_cell_data.to_string();
                    let mut transformed_ids = Vec::new();
                    let options = self.options();
                    if let Some(option) = options.iter().find(|option| option.name == cell_content) {
                        transformed_ids.push(option.id.clone());
                    }
                    Some(SelectOptionIds::from(transformed_ids))
                }
                Err(_) => None,
            },
            _ => Some(SelectOptionIds::from(vec![])),
        }
    }
}

impl<T> CellDataDecoder for T
where
    T: SelectTypeOptionSharedAction + TypeOption<CellData = SelectOptionIds> + TypeOptionCellData,
{
    fn decode_cell_data(
        &self,
        cell_data: String,
        _decoded_field_type: &FieldType,
        _field_rev: &FieldRevision,
    ) -> FlowyResult<<Self as TypeOption>::CellData> {
        self.decode_type_option_cell_data(cell_data)
    }

    fn decode_cell_data_to_str(&self, cell_data: <Self as TypeOption>::CellData) -> String {
        self.get_selected_options(cell_data)
            .select_options
            .into_iter()
            .map(|option| option.name)
            .collect::<Vec<String>>()
            .join(SELECTION_IDS_SEPARATOR)
    }
}

pub fn select_type_option_from_field_rev(
    field_rev: &FieldRevision,
) -> FlowyResult<Box<dyn SelectTypeOptionSharedAction>> {
    let field_type: FieldType = field_rev.ty.into();
    match &field_type {
        FieldType::SingleSelect => {
            let type_option = SingleSelectTypeOptionPB::from(field_rev);
            Ok(Box::new(type_option))
        }
        FieldType::MultiSelect => {
            let type_option = MultiSelectTypeOptionPB::from(field_rev);
            Ok(Box::new(type_option))
        }
        FieldType::Checklist => {
            let type_option = ChecklistTypeOptionPB::from(field_rev);
            Ok(Box::new(type_option))
        }
        ty => {
            tracing::error!("Unsupported field type: {:?} for this handler", ty);
            Err(ErrorCode::FieldInvalidOperation.into())
        }
    }
}

pub fn new_select_option_color(options: &Vec<SelectOptionPB>) -> SelectOptionColorPB {
    let mut freq: Vec<usize> = vec![0; 9];

    for option in options {
        freq[option.color.to_owned() as usize] += 1;
    }

    match freq
        .into_iter()
        .enumerate()
        .min_by_key(|(_, v)| *v)
        .map(|(idx, _val)| idx)
        .unwrap()
    {
        0 => SelectOptionColorPB::Purple,
        1 => SelectOptionColorPB::Pink,
        2 => SelectOptionColorPB::LightPink,
        3 => SelectOptionColorPB::Orange,
        4 => SelectOptionColorPB::Yellow,
        5 => SelectOptionColorPB::Lime,
        6 => SelectOptionColorPB::Green,
        7 => SelectOptionColorPB::Aqua,
        8 => SelectOptionColorPB::Blue,
        _ => SelectOptionColorPB::Purple,
    }
}

/// List of select option ids
///
/// Calls [to_string] will return a string consists list of ids,
/// placing a commas separator between each
///
#[derive(Default, Clone)]
pub struct SelectOptionIds(Vec<String>);

impl SelectOptionIds {
    pub fn new() -> Self {
        Self::default()
    }
    pub fn into_inner(self) -> Vec<String> {
        self.0
    }
}

impl FromCellString for SelectOptionIds {
    fn from_cell_str(s: &str) -> FlowyResult<Self>
    where
        Self: Sized,
    {
        Ok(Self::from(s.to_owned()))
    }
}

impl std::convert::From<String> for SelectOptionIds {
    fn from(s: String) -> Self {
        if s.is_empty() {
            return Self(vec![]);
        }

        let ids = s
            .split(SELECTION_IDS_SEPARATOR)
            .map(|id| id.to_string())
            .collect::<Vec<String>>();
        Self(ids)
    }
}

impl std::convert::From<Vec<String>> for SelectOptionIds {
    fn from(ids: Vec<String>) -> Self {
        let ids = ids.into_iter().filter(|id| !id.is_empty()).collect::<Vec<String>>();
        Self(ids)
    }
}

impl ToString for SelectOptionIds {
    /// Returns a string that consists list of ids, placing a commas
    /// separator between each
    fn to_string(&self) -> String {
        self.0.join(SELECTION_IDS_SEPARATOR)
    }
}

impl std::convert::From<Option<String>> for SelectOptionIds {
    fn from(s: Option<String>) -> Self {
        match s {
            None => Self(vec![]),
            Some(s) => Self::from(s),
        }
    }
}

impl std::ops::Deref for SelectOptionIds {
    type Target = Vec<String>;

    fn deref(&self) -> &Self::Target {
        &self.0
    }
}

impl std::ops::DerefMut for SelectOptionIds {
    fn deref_mut(&mut self) -> &mut Self::Target {
        &mut self.0
    }
}

impl DecodedCellData for SelectOptionIds {
    type Object = SelectOptionIds;

    fn is_empty(&self) -> bool {
        self.0.is_empty()
    }
}

pub struct SelectOptionIdsParser();
impl CellProtobufBlobParser for SelectOptionIdsParser {
    type Object = SelectOptionIds;
    fn parser(bytes: &Bytes) -> FlowyResult<Self::Object> {
        match String::from_utf8(bytes.to_vec()) {
            Ok(s) => Ok(SelectOptionIds::from(s)),
            Err(_) => Ok(SelectOptionIds::from("".to_owned())),
        }
    }
}

impl DecodedCellData for SelectOptionCellDataPB {
    type Object = SelectOptionCellDataPB;

    fn is_empty(&self) -> bool {
        self.select_options.is_empty()
    }
}

pub struct SelectOptionCellDataParser();
impl CellProtobufBlobParser for SelectOptionCellDataParser {
    type Object = SelectOptionCellDataPB;

    fn parser(bytes: &Bytes) -> FlowyResult<Self::Object> {
        SelectOptionCellDataPB::try_from(bytes.as_ref()).map_err(internal_error)
    }
}

#[derive(Clone, Debug, Default, ProtoBuf)]
pub struct SelectOptionCellChangesetPB {
    #[pb(index = 1)]
    pub cell_identifier: CellPathPB,

    #[pb(index = 2)]
    pub insert_option_ids: Vec<String>,

    #[pb(index = 3)]
    pub delete_option_ids: Vec<String>,
}

pub struct SelectOptionCellChangesetParams {
    pub cell_identifier: CellPathParams,
    pub insert_option_ids: Vec<String>,
    pub delete_option_ids: Vec<String>,
}

impl std::convert::From<SelectOptionCellChangesetParams> for CellChangesetPB {
    fn from(params: SelectOptionCellChangesetParams) -> Self {
        let changeset = SelectOptionCellChangeset {
            insert_option_ids: params.insert_option_ids,
            delete_option_ids: params.delete_option_ids,
        };
        let content = serde_json::to_string(&changeset).unwrap();
        CellChangesetPB {
            grid_id: params.cell_identifier.view_id,
            row_id: params.cell_identifier.row_id,
            field_id: params.cell_identifier.field_id,
            content,
        }
    }
}

impl TryInto<SelectOptionCellChangesetParams> for SelectOptionCellChangesetPB {
    type Error = ErrorCode;

    fn try_into(self) -> Result<SelectOptionCellChangesetParams, Self::Error> {
        let cell_identifier: CellPathParams = self.cell_identifier.try_into()?;
        let insert_option_ids = self
            .insert_option_ids
            .into_iter()
            .flat_map(|option_id| match NotEmptyStr::parse(option_id) {
                Ok(option_id) => Some(option_id.0),
                Err(_) => {
                    tracing::error!("The insert option id should not be empty");
                    None
                }
            })
            .collect::<Vec<String>>();

        let delete_option_ids = self
            .delete_option_ids
            .into_iter()
            .flat_map(|option_id| match NotEmptyStr::parse(option_id) {
                Ok(option_id) => Some(option_id.0),
                Err(_) => {
                    tracing::error!("The deleted option id should not be empty");
                    None
                }
            })
            .collect::<Vec<String>>();

        Ok(SelectOptionCellChangesetParams {
            cell_identifier,
            insert_option_ids,
            delete_option_ids,
        })
    }
}

#[derive(Clone, Serialize, Deserialize)]
pub struct SelectOptionCellChangeset {
    pub insert_option_ids: Vec<String>,
    pub delete_option_ids: Vec<String>,
}

impl FromCellChangeset for SelectOptionCellChangeset {
    fn from_changeset(changeset: String) -> FlowyResult<Self>
    where
        Self: Sized,
    {
        serde_json::from_str::<SelectOptionCellChangeset>(&changeset).map_err(internal_error)
    }
}

impl SelectOptionCellChangeset {
    pub fn from_insert_option_id(option_id: &str) -> Self {
        SelectOptionCellChangeset {
            insert_option_ids: vec![option_id.to_string()],
            delete_option_ids: vec![],
        }
    }

    pub fn from_insert_options(option_ids: Vec<String>) -> Self {
        SelectOptionCellChangeset {
            insert_option_ids: option_ids,
            delete_option_ids: vec![],
        }
    }

    pub fn from_delete_option_id(option_id: &str) -> Self {
        SelectOptionCellChangeset {
            insert_option_ids: vec![],
            delete_option_ids: vec![option_id.to_string()],
        }
    }

    pub fn from_delete_options(option_ids: Vec<String>) -> Self {
        SelectOptionCellChangeset {
            insert_option_ids: vec![],
            delete_option_ids: option_ids,
        }
    }

    pub fn to_str(&self) -> String {
        serde_json::to_string(self).unwrap()
    }
}

/// [SelectOptionCellDataPB] contains a list of user's selected options and a list of all the options
/// that the cell can use.
#[derive(Clone, Debug, Default, Serialize, Deserialize, ProtoBuf)]
pub struct SelectOptionCellDataPB {
    /// The available options that the cell can use.
    #[pb(index = 1)]
    pub options: Vec<SelectOptionPB>,

    /// The selected options for the cell.
    #[pb(index = 2)]
    pub select_options: Vec<SelectOptionPB>,
}

/// [SelectOptionChangesetPB] describes the changes of a FieldTypeOptionData. For the moment,
/// it is used by [MultiSelectTypeOptionPB] and [SingleSelectTypeOptionPB].
#[derive(Clone, Debug, Default, ProtoBuf)]
pub struct SelectOptionChangesetPB {
    #[pb(index = 1)]
    pub cell_identifier: CellPathPB,

    #[pb(index = 2)]
    pub insert_options: Vec<SelectOptionPB>,

    #[pb(index = 3)]
    pub update_options: Vec<SelectOptionPB>,

    #[pb(index = 4)]
    pub delete_options: Vec<SelectOptionPB>,
}

pub struct SelectOptionChangeset {
    pub cell_identifier: CellPathParams,
    pub insert_options: Vec<SelectOptionPB>,
    pub update_options: Vec<SelectOptionPB>,
    pub delete_options: Vec<SelectOptionPB>,
}

impl TryInto<SelectOptionChangeset> for SelectOptionChangesetPB {
    type Error = ErrorCode;

    fn try_into(self) -> Result<SelectOptionChangeset, Self::Error> {
        let cell_identifier = self.cell_identifier.try_into()?;
        Ok(SelectOptionChangeset {
            cell_identifier,
            insert_options: self.insert_options,
            update_options: self.update_options,
            delete_options: self.delete_options,
        })
    }
}

pub struct SelectedSelectOptions {
    pub(crate) options: Vec<SelectOptionPB>,
}

impl std::convert::From<SelectOptionCellDataPB> for SelectedSelectOptions {
    fn from(data: SelectOptionCellDataPB) -> Self {
        Self {
            options: data.select_options,
        }
    }
}
