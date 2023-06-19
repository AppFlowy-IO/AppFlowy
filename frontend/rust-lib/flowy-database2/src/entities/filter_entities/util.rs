use std::convert::TryInto;
use std::sync::Arc;

use bytes::Bytes;
use collab_database::fields::Field;

use flowy_derive::ProtoBuf;
use flowy_error::ErrorCode;

use crate::entities::parser::NotEmptyStr;
use crate::entities::{
  CheckboxFilterPB, ChecklistFilterPB, DateFilterContentPB, DateFilterPB, FieldType,
  NumberFilterPB, SelectOptionFilterPB, TextFilterPB,
};
use crate::services::field::SelectOptionIds;
use crate::services::filter::{Filter, FilterType};

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct FilterPB {
  #[pb(index = 1)]
  pub id: String,

  #[pb(index = 2)]
  pub field_id: String,

  #[pb(index = 3)]
  pub field_type: FieldType,

  #[pb(index = 4)]
  pub data: Vec<u8>,
}

impl std::convert::From<&Filter> for FilterPB {
  fn from(filter: &Filter) -> Self {
    let bytes: Bytes = match filter.field_type {
      FieldType::RichText => TextFilterPB::from(filter).try_into().unwrap(),
      FieldType::Number => NumberFilterPB::from(filter).try_into().unwrap(),
      FieldType::DateTime | FieldType::LastEditedTime | FieldType::CreatedTime => {
        DateFilterPB::from(filter).try_into().unwrap()
      },
      FieldType::SingleSelect => SelectOptionFilterPB::from(filter).try_into().unwrap(),
      FieldType::MultiSelect => SelectOptionFilterPB::from(filter).try_into().unwrap(),
      FieldType::Checklist => ChecklistFilterPB::from(filter).try_into().unwrap(),
      FieldType::Checkbox => CheckboxFilterPB::from(filter).try_into().unwrap(),
      FieldType::URL => TextFilterPB::from(filter).try_into().unwrap(),
    };
    Self {
      id: filter.id.clone(),
      field_id: filter.field_id.clone(),
      field_type: filter.field_type.clone(),
      data: bytes.to_vec(),
    }
  }
}

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct RepeatedFilterPB {
  #[pb(index = 1)]
  pub items: Vec<FilterPB>,
}

impl std::convert::From<Vec<Arc<Filter>>> for RepeatedFilterPB {
  fn from(filters: Vec<Arc<Filter>>) -> Self {
    RepeatedFilterPB {
      items: filters.into_iter().map(|rev| rev.as_ref().into()).collect(),
    }
  }
}

impl std::convert::From<Vec<FilterPB>> for RepeatedFilterPB {
  fn from(items: Vec<FilterPB>) -> Self {
    Self { items }
  }
}

#[derive(ProtoBuf, Debug, Default, Clone)]
pub struct DeleteFilterPayloadPB {
  #[pb(index = 1)]
  pub field_id: String,

  #[pb(index = 2)]
  pub field_type: FieldType,

  #[pb(index = 3)]
  pub filter_id: String,

  #[pb(index = 4)]
  pub view_id: String,
}

impl TryInto<DeleteFilterParams> for DeleteFilterPayloadPB {
  type Error = ErrorCode;

  fn try_into(self) -> Result<DeleteFilterParams, Self::Error> {
    let view_id = NotEmptyStr::parse(self.view_id)
      .map_err(|_| ErrorCode::DatabaseViewIdIsEmpty)?
      .0;
    let field_id = NotEmptyStr::parse(self.field_id)
      .map_err(|_| ErrorCode::FieldIdIsEmpty)?
      .0;

    let filter_id = NotEmptyStr::parse(self.filter_id)
      .map_err(|_| ErrorCode::UnexpectedEmpty)?
      .0;

    let filter_type = FilterType {
      filter_id: filter_id.clone(),
      field_id,
      field_type: self.field_type,
    };

    Ok(DeleteFilterParams {
      view_id,
      filter_id,
      filter_type,
    })
  }
}

#[derive(Debug)]
pub struct DeleteFilterParams {
  pub view_id: String,
  pub filter_id: String,
  pub filter_type: FilterType,
}

#[derive(ProtoBuf, Debug, Default, Clone)]
pub struct UpdateFilterPayloadPB {
  #[pb(index = 1)]
  pub field_id: String,

  #[pb(index = 2)]
  pub field_type: FieldType,

  /// Create a new filter if the filter_id is None
  #[pb(index = 3, one_of)]
  pub filter_id: Option<String>,

  #[pb(index = 4)]
  pub data: Vec<u8>,

  #[pb(index = 5)]
  pub view_id: String,
}

impl UpdateFilterPayloadPB {
  #[allow(dead_code)]
  pub fn new<T: TryInto<Bytes, Error = ::protobuf::ProtobufError>>(
    view_id: &str,
    field: &Field,
    data: T,
  ) -> Self {
    let data = data.try_into().unwrap_or_else(|_| Bytes::new());
    let field_type = FieldType::from(field.field_type);
    Self {
      view_id: view_id.to_owned(),
      field_id: field.id.clone(),
      field_type,
      filter_id: None,
      data: data.to_vec(),
    }
  }
}

impl TryInto<UpdateFilterParams> for UpdateFilterPayloadPB {
  type Error = ErrorCode;

  fn try_into(self) -> Result<UpdateFilterParams, Self::Error> {
    let view_id = NotEmptyStr::parse(self.view_id)
      .map_err(|_| ErrorCode::DatabaseViewIdIsEmpty)?
      .0;

    let field_id = NotEmptyStr::parse(self.field_id)
      .map_err(|_| ErrorCode::FieldIdIsEmpty)?
      .0;
    let filter_id = match self.filter_id {
      None => None,
      Some(filter_id) => Some(
        NotEmptyStr::parse(filter_id)
          .map_err(|_| ErrorCode::FilterIdIsEmpty)?
          .0,
      ),
    };
    let condition;
    let mut content = "".to_string();
    let bytes: &[u8] = self.data.as_ref();

    match self.field_type {
      FieldType::RichText | FieldType::URL => {
        let filter = TextFilterPB::try_from(bytes).map_err(|_| ErrorCode::ProtobufSerde)?;
        condition = filter.condition as u8;
        content = filter.content;
      },
      FieldType::Checkbox => {
        let filter = CheckboxFilterPB::try_from(bytes).map_err(|_| ErrorCode::ProtobufSerde)?;
        condition = filter.condition as u8;
      },
      FieldType::Number => {
        let filter = NumberFilterPB::try_from(bytes).map_err(|_| ErrorCode::ProtobufSerde)?;
        condition = filter.condition as u8;
        content = filter.content;
      },
      FieldType::DateTime | FieldType::LastEditedTime | FieldType::CreatedTime => {
        let filter = DateFilterPB::try_from(bytes).map_err(|_| ErrorCode::ProtobufSerde)?;
        condition = filter.condition as u8;
        content = DateFilterContentPB {
          start: filter.start,
          end: filter.end,
          timestamp: filter.timestamp,
        }
        .to_string();
      },
      FieldType::SingleSelect | FieldType::MultiSelect | FieldType::Checklist => {
        let filter = SelectOptionFilterPB::try_from(bytes).map_err(|_| ErrorCode::ProtobufSerde)?;
        condition = filter.condition as u8;
        content = SelectOptionIds::from(filter.option_ids).to_string();
      },
    }

    Ok(UpdateFilterParams {
      view_id,
      field_id,
      filter_id,
      field_type: self.field_type,
      condition: condition as i64,
      content,
    })
  }
}

#[derive(Debug)]
pub struct UpdateFilterParams {
  pub view_id: String,
  pub field_id: String,
  /// Create a new filter if the filter_id is None
  pub filter_id: Option<String>,
  pub field_type: FieldType,
  pub condition: i64,
  pub content: String,
}
