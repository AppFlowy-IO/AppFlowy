use crate::entities::{
  CalendarLayoutSettingsPB, DatabaseLayoutPB, DatabasePB, DatabaseViewSettingPB, FieldIdPB,
  FilterPB, GroupSettingPB, LayoutSettingPB, RepeatedFilterPB, RepeatedGroupPB,
  RepeatedGroupSettingPB, RowPB, SortPB,
};
use crate::services::cell::{AnyTypeCache, CellCache};
use crate::services::database::util::{database_view_setting_pb_from_view, get_database_data};
use crate::services::database_view::DatabaseViews;
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
  pub cell_cache: CellCache,
  database_views: Arc<DatabaseViews>,
}

impl DatabaseEditor {
  pub fn new(database: Arc<InnerDatabase>) -> Self {
    let cell_cache = AnyTypeCache::<u64>::new();

    let database_views = DatabaseViews::new(
      database.clone(),
      database_view_data.clone(),
      cell_data_cache.clone(),
      block_event_rx,
    )
    .await?;
    Self {
      database: Database::new(database),
      cell_cache,
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
    Ok(database_view_setting_pb_from_view(view))
  }

  pub async fn get_database_data(&self) -> DatabasePB {
    let database = self.database.lock();
    get_database_data(&database)
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
