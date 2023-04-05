use crate::entities::FieldType;
use crate::services::group::configuration::GroupConfigurationReader;
use crate::services::group::controller::GroupController;
use crate::services::group::{
  CheckboxGroupContext, CheckboxGroupController, DefaultGroupController, GroupConfigurationWriter,
  MultiSelectGroupController, MultiSelectOptionGroupContext, SingleSelectGroupController,
  SingleSelectOptionGroupContext, URLGroupContext, URLGroupController,
};
use collab_database::fields::Field;
use collab_database::rows::Row;
use collab_database::views::{DatabaseLayout, Group, GroupSetting};
use database_model::RowRevision;
use flowy_error::FlowyResult;
use std::sync::Arc;

/// Returns a group controller.
///
/// Each view can be grouped by one field, each field has its own group controller.  
/// # Arguments
///
/// * `view_id`: the id of the view
/// * `grouping_field_rev`: the grouping field
/// * `row_revs`: the rows will be separated into different groups
/// * `configuration_reader`: a reader used to read the group configuration from disk
/// * `configuration_writer`: as writer used to write the group configuration to disk
///
#[tracing::instrument(
  level = "debug",
  skip_all,
  fields(grouping_field_id=%grouping_field.id, grouping_field_type)
  err
)]
pub async fn make_group_controller<R, W>(
  view_id: String,
  grouping_field: Arc<Field>,
  rows: Vec<Arc<Row>>,
  configuration_reader: R,
  configuration_writer: W,
) -> FlowyResult<Box<dyn GroupController>>
where
  R: GroupConfigurationReader,
  W: GroupConfigurationWriter,
{
  let grouping_field_type = FieldType::from(grouping_field.field_type);
  tracing::Span::current().record("grouping_field_type", &format!("{}", grouping_field_type));

  let mut group_controller: Box<dyn GroupController>;
  let configuration_reader = Arc::new(configuration_reader);
  let configuration_writer = Arc::new(configuration_writer);

  match grouping_field_type {
    FieldType::SingleSelect => {
      let configuration = SingleSelectOptionGroupContext::new(
        view_id,
        grouping_field.clone(),
        configuration_reader,
        configuration_writer,
      )
      .await?;
      let controller = SingleSelectGroupController::new(&grouping_field, configuration).await?;
      group_controller = Box::new(controller);
    },
    FieldType::MultiSelect => {
      let configuration = MultiSelectOptionGroupContext::new(
        view_id,
        grouping_field.clone(),
        configuration_reader,
        configuration_writer,
      )
      .await?;
      let controller = MultiSelectGroupController::new(&grouping_field, configuration).await?;
      group_controller = Box::new(controller);
    },
    FieldType::Checkbox => {
      let configuration = CheckboxGroupContext::new(
        view_id,
        grouping_field.clone(),
        configuration_reader,
        configuration_writer,
      )
      .await?;
      let controller = CheckboxGroupController::new(&grouping_field, configuration).await?;
      group_controller = Box::new(controller);
    },
    FieldType::URL => {
      let configuration = URLGroupContext::new(
        view_id,
        grouping_field.clone(),
        configuration_reader,
        configuration_writer,
      )
      .await?;
      let controller = URLGroupController::new(&grouping_field, configuration).await?;
      group_controller = Box::new(controller);
    },
    _ => {
      group_controller = Box::new(DefaultGroupController::new(&grouping_field));
    },
  }

  // Separates the rows into different groups
  let rows = rows.iter().map(|row| row.as_ref()).collect::<Vec<&Row>>();
  group_controller.fill_groups(rows.as_slice(), &grouping_field)?;
  Ok(group_controller)
}

#[tracing::instrument(level = "debug", skip_all)]
pub fn find_grouping_field(
  field_revs: &[Arc<Field>],
  _layout: &DatabaseLayout,
) -> Option<Arc<Field>> {
  let mut groupable_field_revs = field_revs
    .iter()
    .flat_map(|field_rev| {
      let field_type = FieldType::from(field_rev.field_type);
      match field_type.can_be_group() {
        true => Some(field_rev.clone()),
        false => None,
      }
    })
    .collect::<Vec<Arc<Field>>>();

  if groupable_field_revs.is_empty() {
    // If there is not groupable fields then we use the primary field.
    field_revs
      .iter()
      .find(|field_rev| field_rev.is_primary)
      .cloned()
  } else {
    Some(groupable_field_revs.remove(0))
  }
}

/// Returns a `default` group configuration for the [FieldRevision]
///
/// # Arguments
///
/// * `field_rev`: making the group configuration for the field
///
pub fn default_group_configuration(field: &Field) -> GroupSetting {
  let field_id = field.id.clone();
  let field_type = FieldType::from(field.field_type);
  match field_type {
    FieldType::RichText => GroupSetting::new(field_id, field.field_type, "".to_owned()),
    FieldType::Number => GroupSetting::new(field_id, field.field_type, "".to_owned()),
    FieldType::DateTime => GroupSetting::new(field_id, field.field_type, "".to_owned()),
    FieldType::SingleSelect => GroupSetting::new(field_id, field.field_type, "".to_owned()),
    FieldType::MultiSelect => GroupSetting::new(field_id, field.field_type, "".to_owned()),
    FieldType::Checklist => GroupSetting::new(field_id, field.field_type, "".to_owned()),
    FieldType::Checkbox => GroupSetting::new(field_id, field.field_type, "".to_owned()),
    FieldType::URL => GroupSetting::new(field_id, field.field_type, "".to_owned()),
  }
}

pub fn make_no_status_group(field: &Field) -> Group {
  Group {
    id: field.id.clone(),
    name: format!("No {}", field.name),
    visible: true,
  }
}
