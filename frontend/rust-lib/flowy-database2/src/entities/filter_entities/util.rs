use std::convert::TryInto;

use bytes::Bytes;

use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_error::ErrorCode;
use lib_infra::box_any::BoxAny;
use protobuf::ProtobufError;
use validator::Validate;

use crate::entities::{
  CheckboxFilterPB, ChecklistFilterPB, DateFilterPB, FieldType, NumberFilterPB, RelationFilterPB,
  SelectOptionFilterPB, TextFilterPB, TimeFilterPB,
};
use crate::services::filter::{Filter, FilterChangeset, FilterInner};

#[derive(Debug, Default, Clone, ProtoBuf_Enum, Eq, PartialEq, Copy)]
#[repr(u8)]
pub enum FilterType {
  #[default]
  Data = 0,
  And = 1,
  Or = 2,
}

impl From<&FilterInner> for FilterType {
  fn from(value: &FilterInner) -> Self {
    match value {
      FilterInner::And { .. } => Self::And,
      FilterInner::Or { .. } => Self::Or,
      FilterInner::Data { .. } => Self::Data,
    }
  }
}

#[derive(Debug, Default, Clone, ProtoBuf, Eq, PartialEq)]
pub struct FilterPB {
  #[pb(index = 1)]
  pub id: String,

  #[pb(index = 2)]
  pub filter_type: FilterType,

  #[pb(index = 3)]
  pub children: Vec<FilterPB>,

  #[pb(index = 4, one_of)]
  pub data: Option<FilterDataPB>,
}

#[derive(Debug, Default, Clone, ProtoBuf, Eq, PartialEq)]
pub struct FilterDataPB {
  #[pb(index = 1)]
  pub field_id: String,

  #[pb(index = 2)]
  pub field_type: FieldType,

  #[pb(index = 3)]
  pub data: Vec<u8>,
}

impl From<&Filter> for FilterPB {
  fn from(filter: &Filter) -> Self {
    match &filter.inner {
      FilterInner::And { children } | FilterInner::Or { children } => Self {
        id: filter.id.clone(),
        filter_type: FilterType::from(&filter.inner),
        children: children.iter().map(FilterPB::from).collect(),
        data: None,
      },
      FilterInner::Data {
        field_id,
        field_type,
        condition_and_content,
      } => {
        let bytes: Result<Bytes, ProtobufError> = match field_type {
          FieldType::RichText | FieldType::URL => condition_and_content
            .cloned::<TextFilterPB>()
            .unwrap()
            .try_into(),
          FieldType::Number => condition_and_content
            .cloned::<NumberFilterPB>()
            .unwrap()
            .try_into(),
          FieldType::DateTime | FieldType::CreatedTime | FieldType::LastEditedTime => {
            condition_and_content
              .cloned::<DateFilterPB>()
              .unwrap()
              .try_into()
          },
          FieldType::SingleSelect | FieldType::MultiSelect => condition_and_content
            .cloned::<SelectOptionFilterPB>()
            .unwrap()
            .try_into(),
          FieldType::Checklist => condition_and_content
            .cloned::<ChecklistFilterPB>()
            .unwrap()
            .try_into(),
          FieldType::Checkbox => condition_and_content
            .cloned::<CheckboxFilterPB>()
            .unwrap()
            .try_into(),
          FieldType::Relation => condition_and_content
            .cloned::<RelationFilterPB>()
            .unwrap()
            .try_into(),
          FieldType::Summary => condition_and_content
            .cloned::<TextFilterPB>()
            .unwrap()
            .try_into(),
          FieldType::Time => condition_and_content
            .cloned::<TimeFilterPB>()
            .unwrap()
            .try_into(),
        };

        Self {
          id: filter.id.clone(),
          filter_type: FilterType::Data,
          children: vec![],
          data: Some(FilterDataPB {
            field_id: field_id.clone(),
            field_type: *field_type,
            data: bytes.unwrap().to_vec(),
          }),
        }
      },
    }
  }
}

impl TryFrom<FilterDataPB> for FilterInner {
  type Error = ErrorCode;

  fn try_from(value: FilterDataPB) -> Result<Self, Self::Error> {
    let bytes: &[u8] = value.data.as_ref();
    let condition_and_content = match value.field_type {
      FieldType::RichText | FieldType::URL => {
        BoxAny::new(TextFilterPB::try_from(bytes).map_err(|_| ErrorCode::ProtobufSerde)?)
      },
      FieldType::Checkbox => {
        BoxAny::new(CheckboxFilterPB::try_from(bytes).map_err(|_| ErrorCode::ProtobufSerde)?)
      },
      FieldType::Number => {
        BoxAny::new(NumberFilterPB::try_from(bytes).map_err(|_| ErrorCode::ProtobufSerde)?)
      },
      FieldType::DateTime | FieldType::LastEditedTime | FieldType::CreatedTime => {
        BoxAny::new(DateFilterPB::try_from(bytes).map_err(|_| ErrorCode::ProtobufSerde)?)
      },
      FieldType::SingleSelect | FieldType::MultiSelect => {
        BoxAny::new(SelectOptionFilterPB::try_from(bytes).map_err(|_| ErrorCode::ProtobufSerde)?)
      },
      FieldType::Checklist => {
        BoxAny::new(ChecklistFilterPB::try_from(bytes).map_err(|_| ErrorCode::ProtobufSerde)?)
      },
      FieldType::Relation => {
        BoxAny::new(RelationFilterPB::try_from(bytes).map_err(|_| ErrorCode::ProtobufSerde)?)
      },
      FieldType::Summary => {
        BoxAny::new(TextFilterPB::try_from(bytes).map_err(|_| ErrorCode::ProtobufSerde)?)
      },
      FieldType::Time => {
        BoxAny::new(TimeFilterPB::try_from(bytes).map_err(|_| ErrorCode::ProtobufSerde)?)
      },
    };

    Ok(Self::Data {
      field_id: value.field_id,
      field_type: value.field_type,
      condition_and_content,
    })
  }
}

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct RepeatedFilterPB {
  #[pb(index = 1)]
  pub items: Vec<FilterPB>,
}

impl From<&Vec<Filter>> for RepeatedFilterPB {
  fn from(filters: &Vec<Filter>) -> Self {
    RepeatedFilterPB {
      items: filters.iter().map(|filter| filter.into()).collect(),
    }
  }
}

impl From<Vec<FilterPB>> for RepeatedFilterPB {
  fn from(items: Vec<FilterPB>) -> Self {
    Self { items }
  }
}

#[derive(ProtoBuf, Debug, Default, Clone, Validate)]
pub struct InsertFilterPB {
  /// If None, the filter will be the root of a new filter tree
  #[pb(index = 1, one_of)]
  #[validate(custom = "crate::entities::utils::validate_filter_id")]
  pub parent_filter_id: Option<String>,

  #[pb(index = 2)]
  pub data: FilterDataPB,
}

#[derive(ProtoBuf, Debug, Default, Clone, Validate)]
pub struct UpdateFilterTypePB {
  #[pb(index = 1)]
  #[validate(custom = "crate::entities::utils::validate_filter_id")]
  pub filter_id: String,

  #[pb(index = 2)]
  pub filter_type: FilterType,
}

#[derive(ProtoBuf, Debug, Default, Clone, Validate)]
pub struct UpdateFilterDataPB {
  #[pb(index = 1)]
  #[validate(custom = "crate::entities::utils::validate_filter_id")]
  pub filter_id: String,

  #[pb(index = 2)]
  pub data: FilterDataPB,
}

#[derive(ProtoBuf, Debug, Default, Clone, Validate)]
pub struct DeleteFilterPB {
  #[pb(index = 1)]
  #[validate(custom = "crate::entities::utils::validate_filter_id")]
  pub filter_id: String,

  #[pb(index = 2)]
  #[validate(custom = "lib_infra::validator_fn::required_not_empty_str")]
  pub field_id: String,
}

impl TryFrom<InsertFilterPB> for FilterChangeset {
  type Error = ErrorCode;

  fn try_from(value: InsertFilterPB) -> Result<Self, Self::Error> {
    let changeset = Self::Insert {
      parent_filter_id: value.parent_filter_id,
      data: value.data.try_into()?,
    };

    Ok(changeset)
  }
}

impl TryFrom<UpdateFilterDataPB> for FilterChangeset {
  type Error = ErrorCode;

  fn try_from(value: UpdateFilterDataPB) -> Result<Self, Self::Error> {
    let changeset = Self::UpdateData {
      filter_id: value.filter_id,
      data: value.data.try_into()?,
    };

    Ok(changeset)
  }
}

impl TryFrom<UpdateFilterTypePB> for FilterChangeset {
  type Error = ErrorCode;

  fn try_from(value: UpdateFilterTypePB) -> Result<Self, Self::Error> {
    if matches!(value.filter_type, FilterType::Data) {
      return Err(ErrorCode::InvalidParams);
    }

    let changeset = Self::UpdateType {
      filter_id: value.filter_id,
      filter_type: value.filter_type,
    };
    Ok(changeset)
  }
}

impl From<DeleteFilterPB> for FilterChangeset {
  fn from(value: DeleteFilterPB) -> Self {
    Self::Delete {
      filter_id: value.filter_id,
      field_id: value.field_id,
    }
  }
}
