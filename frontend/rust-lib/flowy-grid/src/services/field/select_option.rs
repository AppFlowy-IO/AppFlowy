use crate::entities::{CellChangeset, CellIdentifier, CellIdentifierPayload, FieldType};
use crate::services::cell::{AnyCellData, FromCellChangeset, FromCellString};
use crate::services::field::{MultiSelectTypeOption, SingleSelectTypeOption};
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_error::{internal_error, ErrorCode, FlowyError, FlowyResult};
use flowy_grid_data_model::parser::NotEmptyStr;
use flowy_grid_data_model::revision::{FieldRevision, TypeOptionDataEntry};
use nanoid::nanoid;
use serde::{Deserialize, Serialize};

pub const SELECTION_IDS_SEPARATOR: &str = ",";

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

impl std::default::Default for SelectOptionColor {
    fn default() -> Self {
        SelectOptionColor::Purple
    }
}

pub fn make_selected_select_options<T: TryInto<AnyCellData>>(
    any_cell_data: T,
    options: &[SelectOption],
) -> Vec<SelectOption> {
    if let Ok(type_option_cell_data) = any_cell_data.try_into() {
        let ids = SelectOptionIds::from(type_option_cell_data.data);
        ids.iter()
            .flat_map(|option_id| options.iter().find(|option| &option.id == option_id).cloned())
            .collect()
    } else {
        vec![]
    }
}

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

    fn selected_select_option(&self, any_cell_data: AnyCellData) -> SelectOptionCellData;

    fn options(&self) -> &Vec<SelectOption>;

    fn mut_options(&mut self) -> &mut Vec<SelectOption>;
}

pub fn select_option_operation(field_rev: &FieldRevision) -> FlowyResult<Box<dyn SelectOptionOperation>> {
    let field_type: FieldType = field_rev.field_type_rev.into();
    match &field_type {
        FieldType::SingleSelect => {
            let type_option = SingleSelectTypeOption::from(field_rev);
            Ok(Box::new(type_option))
        }
        FieldType::MultiSelect => {
            let type_option = MultiSelectTypeOption::from(field_rev);
            Ok(Box::new(type_option))
        }
        ty => {
            tracing::error!("Unsupported field type: {:?} for this handler", ty);
            Err(ErrorCode::FieldInvalidOperation.into())
        }
    }
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
pub struct SelectOptionIds(Vec<String>);

impl SelectOptionIds {
    pub fn into_inner(self) -> Vec<String> {
        self.0
    }
}

impl std::convert::TryFrom<AnyCellData> for SelectOptionIds {
    type Error = FlowyError;

    fn try_from(value: AnyCellData) -> Result<Self, Self::Error> {
        Ok(Self::from(value.data))
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
        let ids = s
            .split(SELECTION_IDS_SEPARATOR)
            .map(|id| id.to_string())
            .collect::<Vec<String>>();
        Self(ids)
    }
}

impl std::convert::From<Option<String>> for SelectOptionIds {
    fn from(s: Option<String>) -> Self {
        match s {
            None => Self { 0: vec![] },
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
        let changeset = SelectOptionCellChangeset {
            insert_option_id: params.insert_option_id,
            delete_option_id: params.delete_option_id,
        };
        let s = serde_json::to_string(&changeset).unwrap();
        CellChangeset {
            grid_id: params.cell_identifier.grid_id,
            row_id: params.cell_identifier.row_id,
            field_id: params.cell_identifier.field_id,
            content: Some(s),
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
pub struct SelectOptionCellChangeset {
    pub insert_option_id: Option<String>,
    pub delete_option_id: Option<String>,
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

pub struct SelectedSelectOptions {
    pub(crate) options: Vec<SelectOption>,
}

impl std::convert::From<SelectOptionCellData> for SelectedSelectOptions {
    fn from(data: SelectOptionCellData) -> Self {
        Self {
            options: data.select_options,
        }
    }
}
