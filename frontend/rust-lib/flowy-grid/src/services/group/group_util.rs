use crate::entities::FieldType;
use crate::services::group::configuration::GroupConfigurationReader;
use crate::services::group::controller::GroupController;
use crate::services::group::{
    CheckboxGroupContext, CheckboxGroupController, DefaultGroupController, GroupConfigurationWriter,
    MultiSelectGroupController, SelectOptionGroupContext, SingleSelectGroupController,
};
use flowy_error::FlowyResult;
use flowy_grid_data_model::revision::{
    CheckboxGroupConfigurationRevision, DateGroupConfigurationRevision, FieldRevision, GroupConfigurationRevision,
    GroupRevision, LayoutRevision, NumberGroupConfigurationRevision, RowRevision,
    SelectOptionGroupConfigurationRevision, TextGroupConfigurationRevision, UrlGroupConfigurationRevision,
};
use std::sync::Arc;

/// Returns a group controller.
///
/// Each view can be grouped by one field, each field has its own group controller.  
/// # Arguments
///
/// * `view_id`: the id of the view
/// * `field_rev`: the grouping field
/// * `row_revs`: the rows will be separated into different groups
/// * `configuration_reader`: a reader used to read the group configuration from disk
/// * `configuration_writer`: as writer used to write the group configuration to disk
///
#[tracing::instrument(level = "trace", skip_all, err)]
pub async fn make_group_controller<R, W>(
    view_id: String,
    field_rev: Arc<FieldRevision>,
    row_revs: Vec<Arc<RowRevision>>,
    configuration_reader: R,
    configuration_writer: W,
) -> FlowyResult<Box<dyn GroupController>>
where
    R: GroupConfigurationReader,
    W: GroupConfigurationWriter,
{
    let field_type: FieldType = field_rev.ty.into();

    let mut group_controller: Box<dyn GroupController>;
    let configuration_reader = Arc::new(configuration_reader);
    let configuration_writer = Arc::new(configuration_writer);

    match field_type {
        FieldType::SingleSelect => {
            let configuration =
                SelectOptionGroupContext::new(view_id, field_rev.clone(), configuration_reader, configuration_writer)
                    .await?;
            let controller = SingleSelectGroupController::new(&field_rev, configuration).await?;
            group_controller = Box::new(controller);
        }
        FieldType::MultiSelect => {
            let configuration =
                SelectOptionGroupContext::new(view_id, field_rev.clone(), configuration_reader, configuration_writer)
                    .await?;
            let controller = MultiSelectGroupController::new(&field_rev, configuration).await?;
            group_controller = Box::new(controller);
        }
        FieldType::Checkbox => {
            let configuration =
                CheckboxGroupContext::new(view_id, field_rev.clone(), configuration_reader, configuration_writer)
                    .await?;
            let controller = CheckboxGroupController::new(&field_rev, configuration).await?;
            group_controller = Box::new(controller);
        }
        _ => {
            group_controller = Box::new(DefaultGroupController::new(&field_rev));
        }
    }

    // Separates the rows into different groups
    let _ = group_controller.fill_groups(&row_revs, &field_rev)?;
    Ok(group_controller)
}

pub fn find_group_field(field_revs: &[Arc<FieldRevision>], layout: &LayoutRevision) -> Option<Arc<FieldRevision>> {
    match layout {
        LayoutRevision::Table => field_revs.iter().find(|field_rev| field_rev.is_primary).cloned(),
        LayoutRevision::Board => field_revs
            .iter()
            .find(|field_rev| {
                let field_type: FieldType = field_rev.ty.into();
                field_type.can_be_group()
            })
            .cloned(),
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
        FieldType::RichText => {
            GroupConfigurationRevision::new(field_id, field_type_rev, TextGroupConfigurationRevision::default())
                .unwrap()
        }
        FieldType::Number => {
            GroupConfigurationRevision::new(field_id, field_type_rev, NumberGroupConfigurationRevision::default())
                .unwrap()
        }
        FieldType::DateTime => {
            GroupConfigurationRevision::new(field_id, field_type_rev, DateGroupConfigurationRevision::default())
                .unwrap()
        }

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
        FieldType::Checkbox => {
            GroupConfigurationRevision::new(field_id, field_type_rev, CheckboxGroupConfigurationRevision::default())
                .unwrap()
        }
        FieldType::URL => {
            GroupConfigurationRevision::new(field_id, field_type_rev, UrlGroupConfigurationRevision::default()).unwrap()
        }
    }
}

pub fn make_no_status_group(field_rev: &FieldRevision) -> GroupRevision {
    GroupRevision {
        id: field_rev.id.clone(),
        name: format!("No {}", field_rev.name),
        visible: true,
    }
}
