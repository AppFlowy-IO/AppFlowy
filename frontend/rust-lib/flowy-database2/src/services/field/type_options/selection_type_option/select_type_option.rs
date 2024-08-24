use async_trait::async_trait;
use bytes::Bytes;
use collab_database::database::Database;
use collab_database::entity::{SelectOption, SelectOptionColor};
use collab_database::fields::{Field, TypeOptionData};
use collab_database::rows::Cell;
use flowy_error::{internal_error, ErrorCode, FlowyResult};
use std::str::FromStr;

use crate::entities::{CheckboxCellDataPB, FieldType, SelectOptionCellDataPB};
use crate::services::cell::{CellDataDecoder, CellProtobufBlobParser};
use crate::services::field::selection_type_option::type_option_transform::SelectOptionTypeOptionTransformHelper;
use crate::services::field::{
  make_selected_options, MultiSelectTypeOption, SelectOptionCellData, SelectOptionIds,
  SingleSelectTypeOption, StringCellData, TypeOption, TypeOptionCellDataSerde, TypeOptionTransform,
  SELECTION_IDS_SEPARATOR,
};

/// Defines the shared actions used by SingleSelect or Multi-Select.
pub trait SelectTypeOptionSharedAction: Send + Sync {
  /// Returns `None` means there is no limited
  fn number_of_max_options(&self) -> Option<usize>;

  /// Insert the `SelectOption` into corresponding type option.
  /// If the option already exists, it will be updated.
  /// If the option does not exist, it will be inserted at the beginning.
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

  fn delete_option(&mut self, option_id: &str) {
    let options = self.mut_options();
    if let Some(index) = options.iter().position(|option| option.id == option_id) {
      options.remove(index);
    }
  }

  fn create_option(&self, name: &str) -> SelectOption {
    let color = new_select_option_color(self.options());
    SelectOption::with_color(name, color)
  }

  /// Return a list of options that are selected by user
  fn get_selected_options(&self, ids: SelectOptionIds) -> SelectOptionCellData {
    let mut select_options = make_selected_options(ids, self.options());
    match self.number_of_max_options() {
      None => {},
      Some(number_of_max_options) => {
        select_options.truncate(number_of_max_options);
      },
    }
    SelectOptionCellData { select_options }
  }

  fn to_type_option_data(&self) -> TypeOptionData;

  fn options(&self) -> &Vec<SelectOption>;

  fn mut_options(&mut self) -> &mut Vec<SelectOption>;
}

#[async_trait]
impl<T> TypeOptionTransform for T
where
  T: SelectTypeOptionSharedAction + TypeOption<CellData = SelectOptionIds> + CellDataDecoder,
{
  async fn transform_type_option(
    &mut self,
    view_id: &str,
    field_id: &str,
    old_type_option_field_type: FieldType,
    old_type_option_data: TypeOptionData,
    database: &Database,
  ) {
    SelectOptionTypeOptionTransformHelper::transform_type_option(
      self,
      view_id,
      field_id,
      &old_type_option_field_type,
      old_type_option_data,
      database,
    )
    .await;
  }
}

impl<T> CellDataDecoder for T
where
  T:
    SelectTypeOptionSharedAction + TypeOption<CellData = SelectOptionIds> + TypeOptionCellDataSerde,
{
  fn decode_cell(&self, cell: &Cell) -> FlowyResult<<Self as TypeOption>::CellData> {
    self.parse_cell(cell)
  }

  fn decode_cell_with_transform(
    &self,
    cell: &Cell,
    from_field_type: FieldType,
    _field: &Field,
  ) -> Option<<Self as TypeOption>::CellData> {
    match from_field_type {
      FieldType::RichText => {
        let text_cell = StringCellData::from(cell).into_inner();
        let mut transformed_ids = Vec::new();
        let options = self.options();
        if let Some(option) = options.iter().find(|option| option.name == text_cell) {
          transformed_ids.push(option.id.clone());
        }
        Some(SelectOptionIds::from(transformed_ids))
      },
      FieldType::Checkbox => {
        let cell_content = CheckboxCellDataPB::from(cell).to_string();
        let mut transformed_ids = Vec::new();
        let options = self.options();
        if let Some(option) = options.iter().find(|option| option.name == cell_content) {
          transformed_ids.push(option.id.clone());
        }
        Some(SelectOptionIds::from(transformed_ids))
      },
      FieldType::SingleSelect | FieldType::MultiSelect => Some(SelectOptionIds::from(cell)),
      _ => None,
    }
  }

  fn stringify_cell_data(&self, cell_data: <Self as TypeOption>::CellData) -> String {
    self
      .get_selected_options(cell_data)
      .select_options
      .into_iter()
      .map(|option| option.name)
      .collect::<Vec<String>>()
      .join(SELECTION_IDS_SEPARATOR)
  }

  fn numeric_cell(&self, _cell: &Cell) -> Option<f64> {
    None
  }
}

pub fn select_type_option_from_field(
  field: &Field,
) -> FlowyResult<Box<dyn SelectTypeOptionSharedAction>> {
  let field_type = FieldType::from(field.field_type);
  match &field_type {
    FieldType::SingleSelect => {
      let type_option = field
        .get_type_option::<SingleSelectTypeOption>(field_type)
        .unwrap_or_default();
      Ok(Box::new(type_option))
    },
    FieldType::MultiSelect => {
      let type_option = field
        .get_type_option::<MultiSelectTypeOption>(&field_type)
        .unwrap_or_default();
      Ok(Box::new(type_option))
    },
    ty => {
      tracing::error!("🔴Unsupported field type: {:?} for this handler", ty);
      Err(ErrorCode::FieldInvalidOperation.into())
    },
  }
}

pub fn new_select_option_color(options: &[SelectOption]) -> SelectOptionColor {
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

pub struct SelectOptionIdsParser();
impl CellProtobufBlobParser for SelectOptionIdsParser {
  type Object = SelectOptionIds;
  fn parser(bytes: &Bytes) -> FlowyResult<Self::Object> {
    match String::from_utf8(bytes.to_vec()) {
      Ok(s) => SelectOptionIds::from_str(&s),
      Err(_) => Ok(SelectOptionIds::default()),
    }
  }
}

pub struct SelectOptionCellDataParser();
impl CellProtobufBlobParser for SelectOptionCellDataParser {
  type Object = SelectOptionCellDataPB;

  fn parser(bytes: &Bytes) -> FlowyResult<Self::Object> {
    SelectOptionCellDataPB::try_from(bytes.as_ref()).map_err(internal_error)
  }
}

#[derive(Clone, Default, Debug)]
pub struct SelectOptionCellChangeset {
  pub insert_option_ids: Vec<String>,
  pub delete_option_ids: Vec<String>,
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
}
