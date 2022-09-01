use crate::entities::{CellChangesetPB, FieldType, GridCellIdPB, GridCellIdParams};
use crate::services::cell::{CellBytes, CellBytesParser, CellData, CellDisplayable, FromCellChangeset, FromCellString};
use crate::services::field::{MultiSelectTypeOptionPB, SingleSelectTypeOptionPB};
use bytes::Bytes;
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_error::{internal_error, ErrorCode, FlowyResult};
use flowy_grid_data_model::parser::NotEmptyStr;
use flowy_grid_data_model::revision::{FieldRevision, TypeOptionDataEntry};
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

impl SelectOptionPB {
    pub fn new(name: &str) -> Self {
        SelectOptionPB {
            id: nanoid!(4),
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

pub fn make_selected_select_options(
    cell_data: CellData<SelectOptionIds>,
    options: &[SelectOptionPB],
) -> Vec<SelectOptionPB> {
    if let Ok(ids) = cell_data.try_into_inner() {
        ids.iter()
            .flat_map(|option_id| options.iter().find(|option| &option.id == option_id).cloned())
            .collect()
    } else {
        vec![]
    }
}

pub trait SelectOptionOperation: TypeOptionDataEntry + Send + Sync {
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
        let color = select_option_color_from_index(self.options().len());
        SelectOptionPB::with_color(name, color)
    }

    fn selected_select_option(&self, cell_data: CellData<SelectOptionIds>) -> SelectOptionCellDataPB;

    fn options(&self) -> &Vec<SelectOptionPB>;

    fn mut_options(&mut self) -> &mut Vec<SelectOptionPB>;
}

impl<T> CellDisplayable<SelectOptionIds> for T
where
    T: SelectOptionOperation,
{
    fn display_data(
        &self,
        cell_data: CellData<SelectOptionIds>,
        _decoded_field_type: &FieldType,
        _field_rev: &FieldRevision,
    ) -> FlowyResult<CellBytes> {
        CellBytes::from(self.selected_select_option(cell_data))
    }
}

pub fn select_option_operation(field_rev: &FieldRevision) -> FlowyResult<Box<dyn SelectOptionOperation>> {
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
        ty => {
            tracing::error!("Unsupported field type: {:?} for this handler", ty);
            Err(ErrorCode::FieldInvalidOperation.into())
        }
    }
}

pub fn select_option_color_from_index(index: usize) -> SelectOptionColorPB {
    match index % 8 {
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

#[derive(Default)]
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
        let ids = s
            .split(SELECTION_IDS_SEPARATOR)
            .map(|id| id.to_string())
            .collect::<Vec<String>>();
        Self(ids)
    }
}

impl ToString for SelectOptionIds {
    fn to_string(&self) -> String {
        self.0.join(SELECTION_IDS_SEPARATOR)
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
pub struct SelectOptionIdsParser();
impl CellBytesParser for SelectOptionIdsParser {
    type Object = SelectOptionIds;
    fn parser(bytes: &Bytes) -> FlowyResult<Self::Object> {
        match String::from_utf8(bytes.to_vec()) {
            Ok(s) => Ok(SelectOptionIds::from(s)),
            Err(_) => Ok(SelectOptionIds::from("".to_owned())),
        }
    }
}

pub struct SelectOptionCellDataParser();
impl CellBytesParser for SelectOptionCellDataParser {
    type Object = SelectOptionCellDataPB;

    fn parser(bytes: &Bytes) -> FlowyResult<Self::Object> {
        SelectOptionCellDataPB::try_from(bytes.as_ref()).map_err(internal_error)
    }
}

#[derive(Clone, Debug, Default, ProtoBuf)]
pub struct SelectOptionCellChangesetPayloadPB {
    #[pb(index = 1)]
    pub cell_identifier: GridCellIdPB,

    #[pb(index = 2, one_of)]
    pub insert_option_id: Option<String>,

    #[pb(index = 3, one_of)]
    pub delete_option_id: Option<String>,
}

pub struct SelectOptionCellChangesetParams {
    pub cell_identifier: GridCellIdParams,
    pub insert_option_id: Option<String>,
    pub delete_option_id: Option<String>,
}

impl std::convert::From<SelectOptionCellChangesetParams> for CellChangesetPB {
    fn from(params: SelectOptionCellChangesetParams) -> Self {
        let changeset = SelectOptionCellChangeset {
            insert_option_id: params.insert_option_id,
            delete_option_id: params.delete_option_id,
        };
        let content = serde_json::to_string(&changeset).unwrap();
        CellChangesetPB {
            grid_id: params.cell_identifier.grid_id,
            row_id: params.cell_identifier.row_id,
            field_id: params.cell_identifier.field_id,
            content,
        }
    }
}

impl TryInto<SelectOptionCellChangesetParams> for SelectOptionCellChangesetPayloadPB {
    type Error = ErrorCode;

    fn try_into(self) -> Result<SelectOptionCellChangesetParams, Self::Error> {
        let cell_identifier: GridCellIdParams = self.cell_identifier.try_into()?;
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

/// [SelectOptionChangesetPayloadPB] describes the changes of a FieldTypeOptionData. For the moment,
/// it is used by [MultiSelectTypeOptionPB] and [SingleSelectTypeOptionPB].
#[derive(Clone, Debug, Default, ProtoBuf)]
pub struct SelectOptionChangesetPayloadPB {
    #[pb(index = 1)]
    pub cell_identifier: GridCellIdPB,

    #[pb(index = 2, one_of)]
    pub insert_option: Option<SelectOptionPB>,

    #[pb(index = 3, one_of)]
    pub update_option: Option<SelectOptionPB>,

    #[pb(index = 4, one_of)]
    pub delete_option: Option<SelectOptionPB>,
}

pub struct SelectOptionChangeset {
    pub cell_identifier: GridCellIdParams,
    pub insert_option: Option<SelectOptionPB>,
    pub update_option: Option<SelectOptionPB>,
    pub delete_option: Option<SelectOptionPB>,
}

impl TryInto<SelectOptionChangeset> for SelectOptionChangesetPayloadPB {
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
    pub(crate) options: Vec<SelectOptionPB>,
}

impl std::convert::From<SelectOptionCellDataPB> for SelectedSelectOptions {
    fn from(data: SelectOptionCellDataPB) -> Self {
        Self {
            options: data.select_options,
        }
    }
}
