use collab_database::fields::media_type_option::{MediaCellData, MediaTypeOption};
use collab_database::{fields::Field, rows::Cell};
use flowy_error::FlowyResult;
use std::cmp::Ordering;

use crate::{
  entities::{FieldType, MediaCellChangeset, MediaCellDataPB, MediaFilterPB, MediaTypeOptionPB},
  services::{
    cell::{CellDataChangeset, CellDataDecoder},
    field::{
      default_order, StringCellData, TypeOption, TypeOptionCellData, TypeOptionCellDataCompare,
      TypeOptionCellDataFilter, TypeOptionCellDataSerde, TypeOptionTransform,
    },
    sort::SortCondition,
  },
};

impl TypeOptionCellData for MediaCellData {
  fn is_cell_empty(&self) -> bool {
    self.files.is_empty()
  }
}

impl TypeOption for MediaTypeOption {
  type CellData = MediaCellData;
  type CellChangeset = MediaCellChangeset;
  type CellProtobufType = MediaCellDataPB;
  type CellFilter = MediaFilterPB;
}

impl From<MediaTypeOption> for MediaTypeOptionPB {
  fn from(value: MediaTypeOption) -> Self {
    Self {
      files: value.files.into_iter().map(Into::into).collect(),
      hide_file_names: value.hide_file_names,
    }
  }
}

impl From<MediaTypeOptionPB> for MediaTypeOption {
  fn from(value: MediaTypeOptionPB) -> Self {
    Self {
      files: value.files.into_iter().map(Into::into).collect(),
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
