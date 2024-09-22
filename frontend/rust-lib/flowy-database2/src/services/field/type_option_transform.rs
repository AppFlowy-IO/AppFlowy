use crate::entities::FieldType;
use crate::services::field::summary_type_option::summary::SummarizationTypeOption;
use crate::services::field::translate_type_option::translate::TranslateTypeOption;
use crate::services::field::{
  CheckboxTypeOption, ChecklistTypeOption, DateTypeOption, MediaTypeOption, MultiSelectTypeOption,
  RelationTypeOption, RichTextTypeOption, SingleSelectTypeOption, TimeTypeOption,
  TimestampTypeOption, TypeOptionTransform, URLTypeOption,
};
use async_trait::async_trait;
use collab_database::database::Database;
use collab_database::fields::number_type_option::NumberTypeOption;
use collab_database::fields::TypeOptionData;

pub async fn transform_type_option(
  view_id: &str,
  field_id: &str,
  old_field_type: FieldType,
  new_field_type: FieldType,
  old_type_option_data: Option<TypeOptionData>,
  new_type_option_data: TypeOptionData,
  database: &mut Database,
) -> TypeOptionData {
  if let Some(old_type_option_data) = old_type_option_data {
    let mut transform_handler =
      get_type_option_transform_handler(new_type_option_data, new_field_type);
    transform_handler
      .transform(
        view_id,
        field_id,
        old_field_type,
        old_type_option_data,
        new_field_type,
        database,
      )
      .await;
    transform_handler.to_type_option_data()
  } else {
    new_type_option_data
  }
}

/// A helper trait that used to erase the `Self` of `TypeOption` trait to make it become a Object-safe trait.
#[async_trait]
pub trait TypeOptionTransformHandler: Send + Sync {
  async fn transform(
    &mut self,
    view_id: &str,
    field_id: &str,
    old_type_option_field_type: FieldType,
    old_type_option_data: TypeOptionData,
    new_type_option_field_type: FieldType,
    database: &mut Database,
  );

  fn to_type_option_data(&self) -> TypeOptionData;
}

#[async_trait]
impl<T> TypeOptionTransformHandler for T
where
  T: TypeOptionTransform + Clone,
{
  async fn transform(
    &mut self,
    view_id: &str,
    field_id: &str,
    old_type_option_field_type: FieldType,
    old_type_option_data: TypeOptionData,
    new_type_option_field_type: FieldType,
    database: &mut Database,
  ) {
    self
      .transform_type_option(
        view_id,
        field_id,
        old_type_option_field_type,
        old_type_option_data,
        new_type_option_field_type,
        database,
      )
      .await
  }

  fn to_type_option_data(&self) -> TypeOptionData {
    self.clone().into()
  }
}

fn get_type_option_transform_handler(
  type_option_data: TypeOptionData,
  field_type: FieldType,
) -> Box<dyn TypeOptionTransformHandler> {
  match field_type {
    FieldType::RichText => {
      Box::new(RichTextTypeOption::from(type_option_data)) as Box<dyn TypeOptionTransformHandler>
    },
    FieldType::Number => {
      Box::new(NumberTypeOption::from(type_option_data)) as Box<dyn TypeOptionTransformHandler>
    },
    FieldType::DateTime => {
      Box::new(DateTypeOption::from(type_option_data)) as Box<dyn TypeOptionTransformHandler>
    },
    FieldType::LastEditedTime | FieldType::CreatedTime => {
      Box::new(TimestampTypeOption::from(type_option_data)) as Box<dyn TypeOptionTransformHandler>
    },
    FieldType::SingleSelect => Box::new(SingleSelectTypeOption::from(type_option_data))
      as Box<dyn TypeOptionTransformHandler>,
    FieldType::MultiSelect => {
      Box::new(MultiSelectTypeOption::from(type_option_data)) as Box<dyn TypeOptionTransformHandler>
    },
    FieldType::Checkbox => {
      Box::new(CheckboxTypeOption::from(type_option_data)) as Box<dyn TypeOptionTransformHandler>
    },
    FieldType::URL => {
      Box::new(URLTypeOption::from(type_option_data)) as Box<dyn TypeOptionTransformHandler>
    },
    FieldType::Checklist => {
      Box::new(ChecklistTypeOption::from(type_option_data)) as Box<dyn TypeOptionTransformHandler>
    },
    FieldType::Relation => {
      Box::new(RelationTypeOption::from(type_option_data)) as Box<dyn TypeOptionTransformHandler>
    },
    FieldType::Summary => Box::new(SummarizationTypeOption::from(type_option_data))
      as Box<dyn TypeOptionTransformHandler>,
    FieldType::Time => {
      Box::new(TimeTypeOption::from(type_option_data)) as Box<dyn TypeOptionTransformHandler>
    },
    FieldType::Translate => {
      Box::new(TranslateTypeOption::from(type_option_data)) as Box<dyn TypeOptionTransformHandler>
    },
    FieldType::Media => {
      Box::new(MediaTypeOption::from(type_option_data)) as Box<dyn TypeOptionTransformHandler>
    },
  }
}
