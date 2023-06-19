use crate::entities::{FieldType, TextFilterPB, URLCellDataPB};
use crate::services::cell::{CellDataChangeset, CellDataDecoder};
use crate::services::field::{
  TypeOption, TypeOptionCellData, TypeOptionCellDataCompare, TypeOptionCellDataFilter,
  TypeOptionTransform, URLCellData,
};

use collab::core::any_map::AnyMapExtension;
use collab_database::fields::{Field, TypeOptionData, TypeOptionDataBuilder};
use collab_database::rows::Cell;
use fancy_regex::Regex;
use flowy_error::FlowyResult;
use lazy_static::lazy_static;
use serde::{Deserialize, Serialize};
use std::cmp::Ordering;

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct URLTypeOption {
  pub url: String,
  pub content: String,
}

impl TypeOption for URLTypeOption {
  type CellData = URLCellData;
  type CellChangeset = URLCellChangeset;
  type CellProtobufType = URLCellDataPB;
  type CellFilter = TextFilterPB;
}

impl From<TypeOptionData> for URLTypeOption {
  fn from(data: TypeOptionData) -> Self {
    let url = data.get_str_value("url").unwrap_or_default();
    let content = data.get_str_value("content").unwrap_or_default();
    Self { url, content }
  }
}

impl From<URLTypeOption> for TypeOptionData {
  fn from(data: URLTypeOption) -> Self {
    TypeOptionDataBuilder::new()
      .insert_str_value("url", data.url)
      .insert_str_value("content", data.content)
      .build()
  }
}

impl TypeOptionTransform for URLTypeOption {}

impl TypeOptionCellData for URLTypeOption {
  fn protobuf_encode(
    &self,
    cell_data: <Self as TypeOption>::CellData,
  ) -> <Self as TypeOption>::CellProtobufType {
    cell_data.into()
  }

  fn parse_cell(&self, cell: &Cell) -> FlowyResult<<Self as TypeOption>::CellData> {
    Ok(URLCellData::from(cell))
  }
}

impl CellDataDecoder for URLTypeOption {
  fn decode_cell(
    &self,
    cell: &Cell,
    decoded_field_type: &FieldType,
    _field: &Field,
  ) -> FlowyResult<<Self as TypeOption>::CellData> {
    if !decoded_field_type.is_url() {
      return Ok(Default::default());
    }

    self.parse_cell(cell)
  }

  fn stringify_cell_data(&self, cell_data: <Self as TypeOption>::CellData) -> String {
    cell_data.data
  }

  fn stringify_cell(&self, cell: &Cell) -> String {
    let cell_data = Self::CellData::from(cell);
    self.stringify_cell_data(cell_data)
  }
}

pub type URLCellChangeset = String;

impl CellDataChangeset for URLTypeOption {
  fn apply_changeset(
    &self,
    changeset: <Self as TypeOption>::CellChangeset,
    _cell: Option<Cell>,
  ) -> FlowyResult<(Cell, <Self as TypeOption>::CellData)> {
    let mut url = "".to_string();
    if let Ok(Some(m)) = URL_REGEX.find(&changeset) {
      url = auto_append_scheme(m.as_str());
    }
    let url_cell_data = URLCellData {
      url,
      data: changeset,
    };
    Ok((url_cell_data.clone().into(), url_cell_data))
  }
}

impl TypeOptionCellDataFilter for URLTypeOption {
  fn apply_filter(
    &self,
    filter: &<Self as TypeOption>::CellFilter,
    field_type: &FieldType,
    cell_data: &<Self as TypeOption>::CellData,
  ) -> bool {
    if !field_type.is_url() {
      return true;
    }

    filter.is_visible(cell_data)
  }
}

impl TypeOptionCellDataCompare for URLTypeOption {
  fn apply_cmp(
    &self,
    cell_data: &<Self as TypeOption>::CellData,
    other_cell_data: &<Self as TypeOption>::CellData,
  ) -> Ordering {
    cell_data.data.cmp(&other_cell_data.data)
  }
}
fn auto_append_scheme(s: &str) -> String {
  // Only support https scheme by now
  match url::Url::parse(s) {
    Ok(url) => {
      if url.scheme() == "https" {
        url.into()
      } else {
        format!("https://{}", s)
      }
    },
    Err(_) => {
      format!("https://{}", s)
    },
  }
}

lazy_static! {
    static ref URL_REGEX: Regex = Regex::new(
        "[(http(s)?):\\/\\/(www\\.)?a-zA-Z0-9@:%._\\+~#=]{2,256}\\.[a-z]{2,6}\\b([-a-zA-Z0-9@:%_\\+.~#?&//=]*)"
    )
    .unwrap();
}
