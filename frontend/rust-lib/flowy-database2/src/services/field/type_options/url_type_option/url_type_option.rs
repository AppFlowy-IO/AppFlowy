use crate::entities::{FieldType, TextFilterPB, URLCellDataPB};
use crate::services::cell::{CellDataChangeset, CellDataDecoder, FromCellString, TypeCellData};
use crate::services::field::{
  TypeOption, TypeOptionCellData, TypeOptionCellDataCompare, TypeOptionCellDataFilter,
  TypeOptionTransform, URLCellData,
};

use collab_database::fields::TypeOptionData;
use database_model::FieldRevision;
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
  fn from(_: TypeOptionData) -> Self {
    todo!()
  }
}

impl From<URLTypeOption> for TypeOptionData {
  fn from(_: URLTypeOption) -> Self {
    todo!()
  }
}

impl TypeOptionTransform for URLTypeOption {}

impl TypeOptionCellData for URLTypeOption {
  fn convert_to_protobuf(
    &self,
    cell_data: <Self as TypeOption>::CellData,
  ) -> <Self as TypeOption>::CellProtobufType {
    cell_data.into()
  }

  fn decode_type_option_cell_str(
    &self,
    cell_str: String,
  ) -> FlowyResult<<Self as TypeOption>::CellData> {
    URLCellData::from_cell_str(&cell_str)
  }
}

impl CellDataDecoder for URLTypeOption {
  fn decode_cell_str(
    &self,
    cell_str: String,
    decoded_field_type: &FieldType,
    _field_rev: &FieldRevision,
  ) -> FlowyResult<<Self as TypeOption>::CellData> {
    if !decoded_field_type.is_url() {
      return Ok(Default::default());
    }

    self.decode_type_option_cell_str(cell_str)
  }

  fn decode_cell_data_to_str(&self, cell_data: <Self as TypeOption>::CellData) -> String {
    cell_data.content
  }
}

pub type URLCellChangeset = String;

impl CellDataChangeset for URLTypeOption {
  fn apply_changeset(
    &self,
    changeset: <Self as TypeOption>::CellChangeset,
    _type_cell_data: Option<TypeCellData>,
  ) -> FlowyResult<(String, <Self as TypeOption>::CellData)> {
    let mut url = "".to_string();
    if let Ok(Some(m)) = URL_REGEX.find(&changeset) {
      url = auto_append_scheme(m.as_str());
    }
    let url_cell_data = URLCellData {
      url,
      content: changeset,
    };
    Ok((url_cell_data.to_string(), url_cell_data))
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
    cell_data.content.cmp(&other_cell_data.content)
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
