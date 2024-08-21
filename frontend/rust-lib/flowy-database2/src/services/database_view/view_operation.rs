use async_trait::async_trait;
use collab_database::database::Database;
use std::collections::HashMap;
use std::sync::Arc;
use collab_database::entity::DatabaseView;

use collab_database::fields::{Field, TypeOptionData};
use collab_database::rows::{Row, RowCell, RowDetail, RowId};
use collab_database::views::{DatabaseLayout, LayoutSetting};
use tokio::sync::RwLock;

use flowy_error::FlowyError;
use lib_infra::priority_task::TaskDispatcher;

use crate::entities::{FieldSettingsChangesetPB, FieldType};
use crate::services::calculations::Calculation;
use crate::services::field::TypeOptionCellDataHandler;
use crate::services::field_settings::FieldSettings;
use crate::services::filter::Filter;
use crate::services::group::GroupSetting;
use crate::services::sort::Sort;

/// Defines the operation that can be performed on a database view
#[async_trait]
pub trait DatabaseViewOperation: Send + Sync + 'static {
  /// Get the database that the view belongs to
  fn get_database(&self) -> Arc<RwLock<Database>>;

  /// Get the view of the database with the view_id
  async fn get_view(&self, view_id: &str) -> Option<DatabaseView>;
  /// If the field_ids is None, then it will return all the field revisions
  async fn get_fields(&self, view_id: &str, field_ids: Option<Vec<String>>) -> Vec<Field>;

  /// Returns the field with the field_id
  async fn get_field(&self, field_id: &str) -> Option<Field>;

  async fn create_field(
    &self,
    view_id: &str,
    name: &str,
    field_type: FieldType,
    type_option_data: TypeOptionData,
  ) -> Field;

  async fn update_field(
    &self,
    type_option_data: TypeOptionData,
    old_field: Field,
  ) -> Result<(), FlowyError>;

  async fn get_primary_field(&self) -> Option<Arc<Field>>;

  /// Returns the index of the row with row_id
  async fn index_of_row(&self, view_id: &str, row_id: &RowId) -> Option<usize>;

  /// Returns the `index` and `RowRevision` with row_id
  async fn get_row_detail(&self, view_id: &str, row_id: &RowId) -> Option<(usize, Arc<RowDetail>)>;

  /// Returns all the rows in the view
  async fn get_row_details(&self, view_id: &str) -> Vec<Arc<RowDetail>>;

  async fn remove_row(&self, row_id: &RowId) -> Option<Row>;

  async fn get_cells_for_field(&self, view_id: &str, field_id: &str) -> Vec<Arc<RowCell>>;

  async fn get_cell_in_row(&self, field_id: &str, row_id: &RowId) -> Arc<RowCell>;

  /// Return the database layout type for the view with given view_id
  /// The default layout type is [DatabaseLayout::Grid]
  async fn get_layout_for_view(&self, view_id: &str) -> DatabaseLayout;

  async fn get_group_setting(&self, view_id: &str) -> Vec<GroupSetting>;

  async fn insert_group_setting(&self, view_id: &str, setting: GroupSetting);

  async fn get_sort(&self, view_id: &str, sort_id: &str) -> Option<Sort>;

  async fn insert_sort(&self, view_id: &str, sort: Sort);

  async fn move_sort(&self, view_id: &str, from_sort_id: &str, to_sort_id: &str);

  async fn remove_sort(&self, view_id: &str, sort_id: &str);

  async fn get_all_sorts(&self, view_id: &str) -> Vec<Sort>;

  async fn remove_all_sorts(&self, view_id: &str);

  async fn get_all_calculations(&self, view_id: &str) -> Vec<Arc<Calculation>>;

  async fn get_calculation(&self, view_id: &str, field_id: &str) -> Option<Calculation>;

  async fn update_calculation(&self, view_id: &str, calculation: Calculation);

  async fn remove_calculation(&self, view_id: &str, calculation_id: &str);

  async fn get_all_filters(&self, view_id: &str) -> Vec<Filter>;

  async fn get_filter(&self, view_id: &str, filter_id: &str) -> Option<Filter>;

  async fn delete_filter(&self, view_id: &str, filter_id: &str);

  async fn insert_filter(&self, view_id: &str, filter: Filter);

  async fn save_filters(&self, view_id: &str, filters: &[Filter]);

  async fn get_layout_setting(
    &self,
    view_id: &str,
    layout_ty: &DatabaseLayout,
  ) -> Option<LayoutSetting>;

  async fn insert_layout_setting(
    &self,
    view_id: &str,
    layout_ty: &DatabaseLayout,
    layout_setting: LayoutSetting,
  );

  async fn update_layout_type(&self, view_id: &str, layout_type: &DatabaseLayout);

  /// Returns a `TaskDispatcher` used to poll a `Task`
  fn get_task_scheduler(&self) -> Arc<RwLock<TaskDispatcher>>;

  fn get_type_option_cell_handler(
    &self,
    field: &Field,
  ) -> Option<Box<dyn TypeOptionCellDataHandler>>;

  async fn get_field_settings(
    &self,
    view_id: &str,
    field_ids: &[String],
  ) -> HashMap<String, FieldSettings>;

  async fn update_field_settings(&self, params: FieldSettingsChangesetPB);
}
