use crate::errors::{internal_sync_error, SyncError, SyncResult};
use crate::util::cal_diff;
use database_model::{
  DatabaseViewRevision, FieldRevision, FieldTypeRevision, FilterRevision,
  GroupConfigurationRevision, LayoutRevision, SortRevision,
};
use flowy_sync::util::make_operations_from_revisions;
use lib_infra::util::md5;
use lib_ot::core::{DeltaBuilder, DeltaOperations, EmptyAttributes, OperationTransform};
use revision_model::Revision;
use std::sync::Arc;

pub type DatabaseViewOperations = DeltaOperations<EmptyAttributes>;
pub type DatabaseViewOperationsBuilder = DeltaBuilder;

#[derive(Debug, Clone)]
pub struct DatabaseViewRevisionPad {
  view: Arc<DatabaseViewRevision>,
  operations: DatabaseViewOperations,
}

impl std::ops::Deref for DatabaseViewRevisionPad {
  type Target = DatabaseViewRevision;

  fn deref(&self) -> &Self::Target {
    &self.view
  }
}

impl DatabaseViewRevisionPad {
  // For the moment, the view_id is equal to grid_id. The database_id represents the database id.
  // A database can be referenced by multiple views.
  pub fn new(database_id: String, view_id: String, name: String, layout: LayoutRevision) -> Self {
    let view = Arc::new(DatabaseViewRevision::new(
      database_id,
      view_id,
      true,
      name,
      layout,
    ));
    let json = serde_json::to_string(&view).unwrap();
    let operations = DatabaseViewOperationsBuilder::new().insert(&json).build();
    Self { view, operations }
  }

  pub fn from_operations(operations: DatabaseViewOperations) -> SyncResult<Self> {
    if operations.is_empty() {
      return Err(SyncError::record_not_found().context("Unexpected empty operations"));
    }
    let s = operations.content()?;
    let view: DatabaseViewRevision = serde_json::from_str(&s).map_err(|e| {
      let msg = format!("Deserialize operations to GridViewRevision failed: {}", e);
      tracing::error!("parsing json: {}", s);
      SyncError::internal().context(msg)
    })?;
    Ok(Self {
      view: Arc::new(view),
      operations,
    })
  }

  pub fn from_revisions(revisions: Vec<Revision>) -> SyncResult<Self> {
    let operations: DatabaseViewOperations = make_operations_from_revisions(revisions)?;
    Self::from_operations(operations)
  }

  pub fn get_groups_by_field_revs(
    &self,
    field_revs: &[Arc<FieldRevision>],
  ) -> Vec<Arc<GroupConfigurationRevision>> {
    self.groups.get_objects_by_field_revs(field_revs)
  }

  pub fn get_all_groups(&self) -> Vec<Arc<GroupConfigurationRevision>> {
    self.groups.get_all_objects()
  }

  #[tracing::instrument(level = "trace", skip_all, err)]
  pub fn insert_or_update_group_configuration(
    &mut self,
    field_id: &str,
    field_type: &FieldTypeRevision,
    group_configuration_rev: GroupConfigurationRevision,
  ) -> SyncResult<Option<DatabaseViewRevisionChangeset>> {
    self.modify(|view| {
      // Only save one group
      view.groups.clear();
      view
        .groups
        .add_object(field_id, field_type, group_configuration_rev);
      Ok(Some(()))
    })
  }

  #[tracing::instrument(level = "trace", skip_all)]
  pub fn contains_group(&self, field_id: &str, field_type: &FieldTypeRevision) -> bool {
    self.view.groups.get_objects(field_id, field_type).is_some()
  }

  #[tracing::instrument(level = "trace", skip_all, err)]
  pub fn with_mut_group<F: FnOnce(&mut GroupConfigurationRevision)>(
    &mut self,
    field_id: &str,
    field_type: &FieldTypeRevision,
    configuration_id: &str,
    mut_configuration_fn: F,
  ) -> SyncResult<Option<DatabaseViewRevisionChangeset>> {
    self.modify(
      |view| match view.groups.get_mut_objects(field_id, field_type) {
        None => Ok(None),
        Some(configurations_revs) => {
          for configuration_rev in configurations_revs {
            if configuration_rev.id == configuration_id {
              mut_configuration_fn(Arc::make_mut(configuration_rev));
              return Ok(Some(()));
            }
          }
          Ok(None)
        },
      },
    )
  }

  pub fn delete_group(
    &mut self,
    group_id: &str,
    field_id: &str,
    field_type: &FieldTypeRevision,
  ) -> SyncResult<Option<DatabaseViewRevisionChangeset>> {
    self.modify(|view| {
      if let Some(groups) = view.groups.get_mut_objects(field_id, field_type) {
        groups.retain(|group| group.id != group_id);
        Ok(Some(()))
      } else {
        Ok(None)
      }
    })
  }

  pub fn get_all_sorts(&self, _field_revs: &[Arc<FieldRevision>]) -> Vec<Arc<SortRevision>> {
    self.sorts.get_all_objects()
  }

  /// For the moment, a field type only have one filter.
  pub fn get_sorts(
    &self,
    field_id: &str,
    field_type_rev: &FieldTypeRevision,
  ) -> Vec<Arc<SortRevision>> {
    self
      .sorts
      .get_objects(field_id, field_type_rev)
      .unwrap_or_default()
  }

  pub fn get_sort(
    &self,
    field_id: &str,
    field_type_rev: &FieldTypeRevision,
    sort_id: &str,
  ) -> Option<Arc<SortRevision>> {
    self
      .sorts
      .get_object(field_id, field_type_rev, |sort| sort.id == sort_id)
  }

  pub fn insert_sort(
    &mut self,
    field_id: &str,
    sort_rev: SortRevision,
  ) -> SyncResult<Option<DatabaseViewRevisionChangeset>> {
    self.modify(|view| {
      let field_type = sort_rev.field_type;
      view.sorts.add_object(field_id, &field_type, sort_rev);
      Ok(Some(()))
    })
  }

  pub fn update_sort(
    &mut self,
    field_id: &str,
    sort_rev: SortRevision,
  ) -> SyncResult<Option<DatabaseViewRevisionChangeset>> {
    self.modify(|view| {
      if let Some(sort) = view
        .sorts
        .get_mut_object(field_id, &sort_rev.field_type, |sort| {
          sort.id == sort_rev.id
        })
      {
        let sort = Arc::make_mut(sort);
        sort.condition = sort_rev.condition;
        Ok(Some(()))
      } else {
        Ok(None)
      }
    })
  }

  pub fn delete_sort<T: Into<FieldTypeRevision>>(
    &mut self,
    sort_id: &str,
    field_id: &str,
    field_type: T,
  ) -> SyncResult<Option<DatabaseViewRevisionChangeset>> {
    let field_type = field_type.into();
    self.modify(|view| {
      if let Some(sorts) = view.sorts.get_mut_objects(field_id, &field_type) {
        sorts.retain(|sort| sort.id != sort_id);
        Ok(Some(()))
      } else {
        Ok(None)
      }
    })
  }

  pub fn delete_all_sorts(&mut self) -> SyncResult<Option<DatabaseViewRevisionChangeset>> {
    self.modify(|view| {
      view.sorts.clear();
      Ok(Some(()))
    })
  }

  pub fn get_all_filters(&self, field_revs: &[Arc<FieldRevision>]) -> Vec<Arc<FilterRevision>> {
    self.filters.get_objects_by_field_revs(field_revs)
  }

  /// For the moment, a field type only have one filter.
  pub fn get_filters(
    &self,
    field_id: &str,
    field_type_rev: &FieldTypeRevision,
  ) -> Vec<Arc<FilterRevision>> {
    self
      .filters
      .get_objects(field_id, field_type_rev)
      .unwrap_or_default()
  }

  pub fn get_filter(
    &self,
    field_id: &str,
    field_type_rev: &FieldTypeRevision,
    filter_id: &str,
  ) -> Option<Arc<FilterRevision>> {
    self
      .filters
      .get_object(field_id, field_type_rev, |filter| filter.id == filter_id)
  }

  pub fn insert_filter(
    &mut self,
    field_id: &str,
    filter_rev: FilterRevision,
  ) -> SyncResult<Option<DatabaseViewRevisionChangeset>> {
    self.modify(|view| {
      let field_type = filter_rev.field_type;
      view.filters.add_object(field_id, &field_type, filter_rev);
      Ok(Some(()))
    })
  }

  pub fn update_filter(
    &mut self,
    field_id: &str,
    filter_rev: FilterRevision,
  ) -> SyncResult<Option<DatabaseViewRevisionChangeset>> {
    self.modify(|view| {
      if let Some(filter) =
        view
          .filters
          .get_mut_object(field_id, &filter_rev.field_type, |filter| {
            filter.id == filter_rev.id
          })
      {
        let filter = Arc::make_mut(filter);
        filter.condition = filter_rev.condition;
        filter.content = filter_rev.content;
        Ok(Some(()))
      } else {
        Ok(None)
      }
    })
  }

  pub fn delete_filter<T: Into<FieldTypeRevision>>(
    &mut self,
    filter_id: &str,
    field_id: &str,
    field_type: T,
  ) -> SyncResult<Option<DatabaseViewRevisionChangeset>> {
    let field_type = field_type.into();
    self.modify(|view| {
      if let Some(filters) = view.filters.get_mut_objects(field_id, &field_type) {
        filters.retain(|filter| filter.id != filter_id);
        Ok(Some(()))
      } else {
        Ok(None)
      }
    })
  }

  /// Returns the settings for the given layout. If it's not exists then will return the
  /// default settings for the given layout.
  /// Each [database view](https://appflowy.gitbook.io/docs/essential-documentation/contribute-to-appflowy/architecture/frontend/database-view) has its own settings.
  pub fn get_layout_setting<T>(&self, layout: &LayoutRevision) -> Option<T>
  where
    T: serde::de::DeserializeOwned,
  {
    let settings_str = self.view.layout_settings.get(layout)?;
    serde_json::from_str::<T>(settings_str).ok()
  }

  /// updates the settings for the given layout type
  pub fn set_layout_setting<T>(
    &mut self,
    layout: &LayoutRevision,
    settings: &T,
  ) -> SyncResult<Option<DatabaseViewRevisionChangeset>>
  where
    T: serde::Serialize,
  {
    let settings_str = serde_json::to_string(settings).map_err(internal_sync_error)?;
    self.modify(|view| {
      view.layout_settings.insert(layout.clone(), settings_str);
      Ok(Some(()))
    })
  }

  pub fn json_str(&self) -> SyncResult<String> {
    make_database_view_rev_json_str(&self.view)
  }

  pub fn layout(&self) -> LayoutRevision {
    self.layout.clone()
  }

  fn modify<F>(&mut self, f: F) -> SyncResult<Option<DatabaseViewRevisionChangeset>>
  where
    F: FnOnce(&mut DatabaseViewRevision) -> SyncResult<Option<()>>,
  {
    let cloned_view = self.view.clone();
    match f(Arc::make_mut(&mut self.view))? {
      None => Ok(None),
      Some(_) => {
        let old = make_database_view_rev_json_str(&cloned_view)?;
        let new = self.json_str()?;
        match cal_diff::<EmptyAttributes>(old, new) {
          None => Ok(None),
          Some(operations) => {
            self.operations = self.operations.compose(&operations)?;
            let md5 = md5(&self.operations.json_bytes());
            Ok(Some(DatabaseViewRevisionChangeset { operations, md5 }))
          },
        }
      },
    }
  }
}

#[derive(Debug)]
pub struct DatabaseViewRevisionChangeset {
  pub operations: DatabaseViewOperations,
  pub md5: String,
}

pub fn make_database_view_rev_json_str(
  database_view_rev: &DatabaseViewRevision,
) -> SyncResult<String> {
  let json = serde_json::to_string(database_view_rev).map_err(|err| {
    internal_sync_error(format!("Serialize grid view to json str failed. {:?}", err))
  })?;
  Ok(json)
}

pub fn make_database_view_operations(
  database_view_rev: &DatabaseViewRevision,
) -> DatabaseViewOperations {
  let json = serde_json::to_string(database_view_rev).unwrap();
  DatabaseViewOperationsBuilder::new().insert(&json).build()
}
