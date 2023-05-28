use crate::entities::FieldType;
use crate::services::group::configuration::GroupSettingReader;
use crate::services::group::controller::GroupController;
use crate::services::group::{
  CheckboxGroupContext, CheckboxGroupController, DefaultGroupController, Group, GroupSetting,
  GroupSettingWriter, MultiSelectGroupController, MultiSelectOptionGroupContext,
  SingleSelectGroupController, SingleSelectOptionGroupContext, URLGroupContext, URLGroupController,
};
use collab_database::fields::Field;
use collab_database::rows::Row;
use collab_database::views::DatabaseLayout;

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
  level = "trace",
  skip_all,
  fields(grouping_field_id=%grouping_field.id, grouping_field_type)
  err
)]
pub async fn make_group_controller<R, W>(
  view_id: String,
  grouping_field: Arc<Field>,
  rows: Vec<Arc<Row>>,
  setting_reader: R,
  setting_writer: W,
) -> FlowyResult<Box<dyn GroupController>>
where
  R: GroupSettingReader,
  W: GroupSettingWriter,
{
  let grouping_field_type = FieldType::from(grouping_field.field_type);
  tracing::Span::current().record("grouping_field", &grouping_field_type.default_name());

  let mut group_controller: Box<dyn GroupController>;
  let configuration_reader = Arc::new(setting_reader);
  let configuration_writer = Arc::new(setting_writer);

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
pub fn find_new_grouping_field(
  fields: &[Arc<Field>],
  _layout: &DatabaseLayout,
) -> Option<Arc<Field>> {
  let mut groupable_field_revs = fields
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
    fields
      .iter()
      .find(|field_rev| field_rev.is_primary)
      .cloned()
  } else {
    Some(groupable_field_revs.remove(0))
  }
}

/// Returns a `default` group configuration for the [Field]
///
/// # Arguments
///
/// * `field`: making the group configuration for the field
///
pub fn default_group_setting(field: &Field) -> GroupSetting {
  let field_id = field.id.clone();
  GroupSetting::new(field_id, field.field_type, "".to_owned())
}

pub fn make_no_status_group(field: &Field) -> Group {
  Group {
    id: field.id.clone(),
    name: format!("No {}", field.name),
    visible: true,
  }
}
