use crate::entities::{
  CalendarLayoutSettingsPB, DatabaseLayoutPB, DatabasePB, DatabaseViewSettingPB, FieldIdPB,
  FilterPB, GroupSettingPB, LayoutSettingPB, RepeatedFilterPB, RepeatedGroupPB,
  RepeatedGroupSettingPB, RowPB, SortPB,
};
use crate::services::cell::{AnyTypeCache, AtomicCellDataCache};
use crate::services::filter::Filter;
use crate::services::group::GroupSetting;
use crate::services::setting::CalendarLayoutSetting;
use crate::services::sort::Sort;
use anyhow::Error;
use collab::plugin_impl::disk::CollabDiskPlugin;
use collab::plugin_impl::snapshot::CollabSnapshotPlugin;
use collab::preclude::{Collab, CollabBuilder};
use collab_database::database::{Database as InnerDatabase, DatabaseContext};
use collab_database::fields::{Field, TypeOptionData};
use collab_persistence::CollabKV;
use flowy_error::{FlowyError, FlowyResult};
use parking_lot::Mutex;
use std::ops::Deref;
use std::sync::Arc;

#[derive(Clone)]
pub struct DatabaseEditor {
  database: Database,
  pub cell_data_cache: AtomicCellDataCache,
}

impl DatabaseEditor {
  pub fn new(database: Arc<InnerDatabase>) -> Self {
    let cell_data_cache = AnyTypeCache::<u64>::new();
    Self {
      database: Database::new(database),
      cell_data_cache,
    }
  }

  pub fn get_field(&self, _field_id: &str) -> Option<Field> {
    todo!()
  }

  pub fn update_field_type_option(
    &self,
    _view_id: &str,
    _field_id: &str,
    _type_option_data: TypeOptionData,
    _old_field: Option<Field>,
  ) {
  }

  pub async fn get_database_view_setting(
    &self,
    view_id: &str,
  ) -> FlowyResult<DatabaseViewSettingPB> {
    let view = self
      .database
      .lock()
      .get_view(view_id)
      .ok_or(FlowyError::record_not_found().context("Can't find the database view"))?;

    let current_layout: DatabaseLayoutPB = view.layout.into();
    let calendar_setting =
      CalendarLayoutSettingsPB::from(CalendarLayoutSetting::from(view.layout_settings));
    let layout_setting = LayoutSettingPB {
      calendar: calendar_setting,
    };

    let filters = view
      .filters
      .into_iter()
      .flat_map(|value| match Filter::try_from(value) {
        Ok(filter) => Some(FilterPB::from(&filter)),
        Err(_) => None,
      })
      .collect::<Vec<FilterPB>>();
    let group_settings = view
      .group_settings
      .into_iter()
      .flat_map(|value| match GroupSetting::try_from(value) {
        Ok(setting) => Some(GroupSettingPB::from(&setting)),
        Err(_) => None,
      })
      .collect::<Vec<GroupSettingPB>>();

    let sorts = view
      .sorts
      .into_iter()
      .flat_map(|value| match Sort::try_from(value) {
        Ok(sort) => Some(SortPB::from(&sort)),
        Err(_) => None,
      })
      .collect::<Vec<SortPB>>();

    Ok(DatabaseViewSettingPB {
      current_layout,
      filters: filters.into(),
      group_settings: group_settings.into(),
      sorts: sorts.into(),
      layout_setting,
    })
  }

  pub async fn get_database_data(&self) -> DatabasePB {
    let database = self.database.lock();
    let database_id = database.get_database_id();
    let fields = database
      .fields
      .get_all_field_orders()
      .into_iter()
      .map(FieldIdPB::from)
      .collect();
    let rows = database
      .rows
      .get_all_row_orders()
      .into_iter()
      .map(RowPB::from)
      .collect();
    DatabasePB {
      id: database_id,
      fields,
      rows,
    }
  }
}

#[derive(Clone)]
pub struct Database(Arc<Mutex<Arc<InnerDatabase>>>);

impl Database {
  fn new(database: Arc<InnerDatabase>) -> Self {
    Self(Arc::new(Mutex::new(database)))
  }
}

impl Deref for Database {
  type Target = Arc<Mutex<Arc<InnerDatabase>>>;
  fn deref(&self) -> &Self::Target {
    &self.0
  }
}

unsafe impl Sync for Database {}

unsafe impl Send for Database {}
