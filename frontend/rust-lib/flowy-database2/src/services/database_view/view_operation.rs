use std::collections::HashMap;
use std::sync::Arc;

use collab_database::database::MutexDatabase;
use collab_database::fields::{Field, TypeOptionData};
use collab_database::rows::{Row, RowCell, RowDetail, RowId};
use collab_database::views::{DatabaseLayout, DatabaseView, LayoutSetting};
use tokio::sync::RwLock;

use flowy_error::FlowyError;
use lib_infra::future::{Fut, FutureResult};
use lib_infra::priority_task::TaskDispatcher;

use crate::entities::{FieldType, FieldVisibility};
use crate::services::calculations::Calculation;
use crate::services::field::TypeOptionCellDataHandler;
use crate::services::field_settings::FieldSettings;
use crate::services::filter::Filter;
use crate::services::group::GroupSetting;
use crate::services::sort::Sort;

/// Defines the operation that can be performed on a database view
pub trait DatabaseViewOperation: Send + Sync + 'static {
  /// Get the database that the view belongs to
  fn get_database(&self) -> Arc<MutexDatabase>;

  /// Get the view of the database with the view_id
  fn get_view(&self, view_id: &str) -> Fut<Option<DatabaseView>>;
  /// If the field_ids is None, then it will return all the field revisions
  fn get_fields(&self, view_id: &str, field_ids: Option<Vec<String>>) -> Fut<Vec<Field>>;

  /// Returns the field with the field_id
  fn get_field(&self, field_id: &str) -> Option<Field>;

  fn create_field(
    &self,
    view_id: &str,
    name: &str,
    field_type: FieldType,
    type_option_data: TypeOptionData,
  ) -> Fut<Field>;

  fn update_field(
    &self,
    type_option_data: TypeOptionData,
    old_field: Field,
  ) -> FutureResult<(), FlowyError>;

  fn get_primary_field(&self) -> Fut<Option<Arc<Field>>>;

  /// Returns the index of the row with row_id
  fn index_of_row(&self, view_id: &str, row_id: &RowId) -> Fut<Option<usize>>;

  /// Returns the `index` and `RowRevision` with row_id
  fn get_row(&self, view_id: &str, row_id: &RowId) -> Fut<Option<(usize, Arc<RowDetail>)>>;

  /// Returns all the rows in the view
  fn get_rows(&self, view_id: &str) -> Fut<Vec<Arc<RowDetail>>>;

  fn remove_row(&self, row_id: &RowId) -> Option<Row>;

  fn get_cells_for_field(&self, view_id: &str, field_id: &str) -> Fut<Vec<Arc<RowCell>>>;

  fn get_cell_in_row(&self, field_id: &str, row_id: &RowId) -> Fut<Arc<RowCell>>;

  /// Return the database layout type for the view with given view_id
  /// The default layout type is [DatabaseLayout::Grid]
  fn get_layout_for_view(&self, view_id: &str) -> DatabaseLayout;

  fn get_group_setting(&self, view_id: &str) -> Vec<GroupSetting>;

  fn insert_group_setting(&self, view_id: &str, setting: GroupSetting);

  fn get_sort(&self, view_id: &str, sort_id: &str) -> Option<Sort>;

  fn insert_sort(&self, view_id: &str, sort: Sort);

  fn move_sort(&self, view_id: &str, from_sort_id: &str, to_sort_id: &str);

  fn remove_sort(&self, view_id: &str, sort_id: &str);

  fn get_all_sorts(&self, view_id: &str) -> Vec<Sort>;

  fn remove_all_sorts(&self, view_id: &str);

  fn get_all_calculations(&self, view_id: &str) -> Vec<Arc<Calculation>>;

  fn get_calculation(&self, view_id: &str, field_id: &str) -> Option<Calculation>;

  fn update_calculation(&self, view_id: &str, calculation: Calculation);

  fn remove_calculation(&self, view_id: &str, calculation_id: &str);

  fn get_all_filters(&self, view_id: &str) -> Vec<Filter>;

  fn get_filter(&self, view_id: &str, filter_id: &str) -> Option<Filter>;

  fn delete_filter(&self, view_id: &str, filter_id: &str);

  fn insert_filter(&self, view_id: &str, filter: Filter);

  fn save_filters(&self, view_id: &str, filters: &[Filter]);

  fn get_layout_setting(&self, view_id: &str, layout_ty: &DatabaseLayout) -> Option<LayoutSetting>;

  fn insert_layout_setting(
    &self,
    view_id: &str,
    layout_ty: &DatabaseLayout,
    layout_setting: LayoutSetting,
  );

  fn update_layout_type(&self, view_id: &str, layout_type: &DatabaseLayout);

  /// Returns a `TaskDispatcher` used to poll a `Task`
  fn get_task_scheduler(&self) -> Arc<RwLock<TaskDispatcher>>;

  fn get_type_option_cell_handler(
    &self,
    field: &Field,
  ) -> Option<Box<dyn TypeOptionCellDataHandler>>;

  fn get_field_settings(
    &self,
    view_id: &str,
    field_ids: &[String],
  ) -> HashMap<String, FieldSettings>;

  fn update_field_settings(
    &self,
    view_id: &str,
    field_id: &str,
    visibility: Option<FieldVisibility>,
    width: Option<i32>,
  );
}
