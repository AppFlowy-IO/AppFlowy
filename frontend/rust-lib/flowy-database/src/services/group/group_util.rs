use crate::entities::FieldType;
use crate::services::group::configuration::GroupConfigurationReader;
use crate::services::group::controller::GroupController;
use crate::services::group::{
  CheckboxGroupContext, CheckboxGroupController, DefaultGroupController, GroupConfigurationWriter,
  MultiSelectGroupController, SelectOptionGroupContext, SingleSelectGroupController,
  URLGroupContext, URLGroupController,
};
use database_model::{
  CheckboxGroupConfigurationRevision, DateGroupConfigurationRevision, FieldRevision,
  GroupConfigurationRevision, GroupRevision, LayoutRevision, NumberGroupConfigurationRevision,
  RowRevision, SelectOptionGroupConfigurationRevision, TextGroupConfigurationRevision,
  URLGroupConfigurationRevision,
};
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
  skip(
    row_revs,
    configuration_reader,
    configuration_writer,
    grouping_field_rev
  ),
  fields(grouping_field_id=%grouping_field_rev.id, grouping_field_type)
  err
)]
pub async fn make_group_controller<R, W>(
  view_id: String,
  grouping_field_rev: Arc<FieldRevision>,
  row_revs: Vec<Arc<RowRevision>>,
  configuration_reader: R,
  configuration_writer: W,
) -> FlowyResult<Box<dyn GroupController>>
where
  R: GroupConfigurationReader,
  W: GroupConfigurationWriter,
{
  let grouping_field_type: FieldType = grouping_field_rev.ty.into();
  tracing::Span::current().record("grouping_field_type", &format!("{}", grouping_field_type));

  let mut group_controller: Box<dyn GroupController>;
  let configuration_reader = Arc::new(configuration_reader);
  let configuration_writer = Arc::new(configuration_writer);

  match grouping_field_type {
    FieldType::SingleSelect => {
      let configuration = SelectOptionGroupContext::new(
        view_id,
        grouping_field_rev.clone(),
        configuration_reader,
        configuration_writer,
      )
      .await?;
      let controller = SingleSelectGroupController::new(&grouping_field_rev, configuration).await?;
      group_controller = Box::new(controller);
    },
    FieldType::MultiSelect => {
      let configuration = SelectOptionGroupContext::new(
        view_id,
        grouping_field_rev.clone(),
        configuration_reader,
        configuration_writer,
      )
      .await?;
      let controller = MultiSelectGroupController::new(&grouping_field_rev, configuration).await?;
      group_controller = Box::new(controller);
    },
    FieldType::Checkbox => {
      let configuration = CheckboxGroupContext::new(
        view_id,
        grouping_field_rev.clone(),
        configuration_reader,
        configuration_writer,
      )
      .await?;
      let controller = CheckboxGroupController::new(&grouping_field_rev, configuration).await?;
      group_controller = Box::new(controller);
    },
    FieldType::URL => {
      let configuration = URLGroupContext::new(
        view_id,
        grouping_field_rev.clone(),
        configuration_reader,
        configuration_writer,
      )
      .await?;
      let controller = URLGroupController::new(&grouping_field_rev, configuration).await?;
      group_controller = Box::new(controller);
    },
    _ => {
      group_controller = Box::new(DefaultGroupController::new(&grouping_field_rev));
    },
  }

  // Separates the rows into different groups
  group_controller.fill_groups(&row_revs, &grouping_field_rev)?;
  Ok(group_controller)
}

#[tracing::instrument(level = "debug", skip_all)]
pub fn find_grouping_field(
  field_revs: &[Arc<FieldRevision>],
  _layout: &LayoutRevision,
) -> Option<Arc<FieldRevision>> {
  let mut groupable_field_revs = field_revs
    .iter()
    .flat_map(|field_rev| {
      let field_type: FieldType = field_rev.ty.into();
      match field_type.can_be_group() {
        true => Some(field_rev.clone()),
        false => None,
      }
    })
    .collect::<Vec<Arc<FieldRevision>>>();

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
pub fn default_group_configuration(field_rev: &FieldRevision) -> GroupConfigurationRevision {
  let field_id = field_rev.id.clone();
  let field_type_rev = field_rev.ty;
  let field_type: FieldType = field_rev.ty.into();
  match field_type {
    FieldType::RichText => GroupConfigurationRevision::new(
      field_id,
      field_type_rev,
      TextGroupConfigurationRevision::default(),
    )
    .unwrap(),
    FieldType::Number => GroupConfigurationRevision::new(
      field_id,
      field_type_rev,
      NumberGroupConfigurationRevision::default(),
    )
    .unwrap(),
    FieldType::DateTime => GroupConfigurationRevision::new(
      field_id,
      field_type_rev,
      DateGroupConfigurationRevision::default(),
    )
    .unwrap(),

    FieldType::SingleSelect => GroupConfigurationRevision::new(
      field_id,
      field_type_rev,
      SelectOptionGroupConfigurationRevision::default(),
    )
    .unwrap(),
    FieldType::MultiSelect => GroupConfigurationRevision::new(
      field_id,
      field_type_rev,
      SelectOptionGroupConfigurationRevision::default(),
    )
    .unwrap(),
    FieldType::Checklist => GroupConfigurationRevision::new(
      field_id,
      field_type_rev,
      SelectOptionGroupConfigurationRevision::default(),
    )
    .unwrap(),
    FieldType::Checkbox => GroupConfigurationRevision::new(
      field_id,
      field_type_rev,
      CheckboxGroupConfigurationRevision::default(),
    )
    .unwrap(),
    FieldType::URL => GroupConfigurationRevision::new(
      field_id,
      field_type_rev,
      URLGroupConfigurationRevision::default(),
    )
    .unwrap(),
  }
}

pub fn make_no_status_group(field_rev: &FieldRevision) -> GroupRevision {
  GroupRevision {
    id: field_rev.id.clone(),
    name: format!("No {}", field_rev.name),
    visible: true,
  }
}
