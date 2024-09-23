use std::{cmp::Ordering, sync::Arc};

use collab::{preclude::Any, util::AnyMapExt};
use collab_database::{
  fields::{Field, TypeOptionData, TypeOptionDataBuilder},
  rows::{new_cell_builder, Cell},
};
use flowy_error::FlowyResult;
use serde::{Deserialize, Serialize};

use crate::{
  entities::{FieldType, MediaCellChangeset, MediaCellDataPB, MediaFilterPB, MediaTypeOptionPB},
  services::{
    cell::{CellDataChangeset, CellDataDecoder},
    field::{
      default_order, StringCellData, TypeOption, TypeOptionCellData, TypeOptionCellDataCompare,
      TypeOptionCellDataFilter, TypeOptionCellDataSerde, TypeOptionTransform, CELL_DATA,
    },
    sort::SortCondition,
  },
};

use super::MediaFile;

#[derive(Clone, Debug, Default, Serialize)]
pub struct MediaCellData {
  pub files: Vec<MediaFile>,
}

impl From<&Cell> for MediaCellData {
  fn from(cell: &Cell) -> Self {
    let files = match cell.get(CELL_DATA) {
      Some(Any::Array(array)) => array
        .iter()
        .flat_map(|item| {
          if let Any::String(string) = item {
            Some(serde_json::from_str::<MediaFile>(string).unwrap_or_default())
          } else {
            None
          }
        })
        .collect(),
      _ => vec![],
    };

    Self { files }
  }
}

impl From<&MediaCellData> for Cell {
  fn from(value: &MediaCellData) -> Self {
    let data = Any::Array(Arc::from(
      value
        .files
        .clone()
        .into_iter()
        .map(|file| Any::String(Arc::from(serde_json::to_string(&file).unwrap_or_default())))
        .collect::<Vec<_>>(),
    ));

    let mut cell = new_cell_builder(FieldType::Media);
    cell.insert(CELL_DATA.into(), data);
    cell
  }
}

impl From<String> for MediaCellData {
  fn from(s: String) -> Self {
    if s.is_empty() {
      return MediaCellData { files: vec![] };
    }

    let files = s
      .split(", ")
      .map(|file: &str| serde_json::from_str::<MediaFile>(file).unwrap_or_default())
      .collect::<Vec<_>>();

    MediaCellData { files }
  }
}

impl TypeOptionCellData for MediaCellData {
  fn is_cell_empty(&self) -> bool {
    self.files.is_empty()
  }
}

impl ToString for MediaCellData {
  fn to_string(&self) -> String {
    self
      .files
      .iter()
      .map(|file| file.to_string())
      .collect::<Vec<_>>()
      .join(", ")
  }
}

#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct MediaTypeOption {
  #[serde(default)]
  pub hide_file_names: bool,
}

impl TypeOption for MediaTypeOption {
  type CellData = MediaCellData;
  type CellChangeset = MediaCellChangeset;
  type CellProtobufType = MediaCellDataPB;
  type CellFilter = MediaFilterPB;
}

impl From<TypeOptionData> for MediaTypeOption {
  fn from(data: TypeOptionData) -> Self {
    data
      .get_as::<String>("content")
      .map(|s| serde_json::from_str::<MediaTypeOption>(&s).unwrap_or_default())
      .unwrap_or_default()
  }
}

impl From<MediaTypeOption> for TypeOptionData {
  fn from(data: MediaTypeOption) -> Self {
    let content = serde_json::to_string(&data).unwrap_or_default();
    TypeOptionDataBuilder::from([("content".into(), content.into())])
  }
}

impl From<MediaTypeOption> for MediaTypeOptionPB {
  fn from(value: MediaTypeOption) -> Self {
    Self {
      hide_file_names: value.hide_file_names,
    }
  }
}

impl From<MediaTypeOptionPB> for MediaTypeOption {
  fn from(value: MediaTypeOptionPB) -> Self {
    Self {
      hide_file_names: value.hide_file_names,
    }
  }
}

impl TypeOptionTransform for MediaTypeOption {}

impl TypeOptionCellDataSerde for MediaTypeOption {
  fn protobuf_encode(
    &self,
    cell_data: <Self as TypeOption>::CellData,
  ) -> <Self as TypeOption>::CellProtobufType {
    cell_data.into()
  }

  fn parse_cell(&self, cell: &Cell) -> FlowyResult<<Self as TypeOption>::CellData> {
    Ok(cell.into())
  }
}

impl CellDataDecoder for MediaTypeOption {
  fn decode_cell(&self, cell: &Cell) -> FlowyResult<<Self as TypeOption>::CellData> {
    self.parse_cell(cell)
  }

  fn decode_cell_with_transform(
    &self,
    _cell: &Cell,
    from_field_type: FieldType,
    _field: &Field,
  ) -> Option<<Self as TypeOption>::CellData> {
    match from_field_type {
      FieldType::RichText
      | FieldType::Number
      | FieldType::DateTime
      | FieldType::SingleSelect
      | FieldType::MultiSelect
      | FieldType::Checkbox
      | FieldType::URL
      | FieldType::Summary
      | FieldType::Translate
      | FieldType::Time
      | FieldType::Checklist
      | FieldType::LastEditedTime
      | FieldType::CreatedTime
      | FieldType::Relation
      | FieldType::Media => None,
    }
  }

  fn stringify_cell_data(&self, cell_data: <Self as TypeOption>::CellData) -> String {
    cell_data.to_string()
  }

  fn numeric_cell(&self, cell: &Cell) -> Option<f64> {
    StringCellData::from(cell).0.parse::<f64>().ok()
  }
}

impl CellDataChangeset for MediaTypeOption {
  fn apply_changeset(
    &self,
    changeset: <Self as TypeOption>::CellChangeset,
    cell: Option<Cell>,
  ) -> FlowyResult<(Cell, <Self as TypeOption>::CellData)> {
    if cell.is_none() {
      let cell_data = MediaCellData {
        files: changeset.inserted_files,
      };
      return Ok(((&cell_data).into(), cell_data));
    }

    let cell_data: MediaCellData = MediaCellData::from(&cell.unwrap());
    let mut files = cell_data.files.clone();
    for removed_id in changeset.removed_ids.iter() {
      if let Some(index) = files.iter().position(|file| file.id == removed_id.clone()) {
        files.remove(index);
      }
    }

    for inserted in changeset.inserted_files.iter() {
      if !files.iter().any(|file| file.id == inserted.id) {
        files.push(inserted.clone())
      }
    }

    let cell_data = MediaCellData { files };

    Ok((Cell::from(&cell_data), cell_data))
  }
}

impl TypeOptionCellDataFilter for MediaTypeOption {
  fn apply_filter(
    &self,
    _filter: &<Self as TypeOption>::CellFilter,
    _cell_data: &<Self as TypeOption>::CellData,
  ) -> bool {
    true
  }
}

impl TypeOptionCellDataCompare for MediaTypeOption {
  fn apply_cmp(
    &self,
    cell_data: &<Self as TypeOption>::CellData,
    other_cell_data: &<Self as TypeOption>::CellData,
    _sort_condition: SortCondition,
  ) -> Ordering {
    match (cell_data.files.is_empty(), other_cell_data.is_cell_empty()) {
      (true, true) => Ordering::Equal,
      (true, false) => Ordering::Greater,
      (false, true) => Ordering::Less,
      (false, false) => default_order(),
    }
  }
}
