use crate::entities::FieldType;
use crate::services::cell::AtomicCellDataCache;
use crate::services::database::DatabaseBlocks;
use crate::services::database_view::DatabaseViewData;
use crate::services::field::{TypeOptionCellDataHandler, TypeOptionCellExt};
use crate::services::row::DatabaseBlockRowRevision;

use database_model::{FieldRevision, RowRevision};
use flowy_client_sync::client_database::DatabaseRevisionPad;
use flowy_task::TaskDispatcher;
use lib_infra::future::{to_fut, Fut};
use std::any::type_name;
use std::sync::Arc;
use tokio::sync::RwLock;

pub struct DatabaseViewDataImpl {
  pub(crate) pad: Arc<RwLock<DatabaseRevisionPad>>,
  pub(crate) blocks: Arc<DatabaseBlocks>,
  pub(crate) task_scheduler: Arc<RwLock<TaskDispatcher>>,
  pub(crate) cell_data_cache: AtomicCellDataCache,
}

impl DatabaseViewData for DatabaseViewDataImpl {
  fn get_field_revs(&self, field_ids: Option<Vec<String>>) -> Fut<Vec<Arc<FieldRevision>>> {
    let pad = self.pad.clone();
    to_fut(async move {
      match pad.read().await.get_field_revs(field_ids) {
        Ok(field_revs) => field_revs,
        Err(e) => {
          tracing::error!(
            "[{}] get field revisions failed: {}",
            type_name::<DatabaseViewDataImpl>(),
            e
          );
          vec![]
        },
      }
    })
  }
  fn get_field_rev(&self, field_id: &str) -> Fut<Option<Arc<FieldRevision>>> {
    let pad = self.pad.clone();
    let field_id = field_id.to_owned();
    to_fut(async move { Some(pad.read().await.get_field_rev(&field_id)?.1.clone()) })
  }

  fn get_primary_field_rev(&self) -> Fut<Option<Arc<FieldRevision>>> {
    let pad = self.pad.clone();
    to_fut(async move {
      let field_revs = pad.read().await.get_field_revs(None).ok()?;
      field_revs
        .into_iter()
        .find(|field_rev| field_rev.is_primary)
    })
  }

  fn index_of_row(&self, row_id: &str) -> Fut<Option<usize>> {
    let block_manager = self.blocks.clone();
    let row_id = row_id.to_owned();
    to_fut(async move { block_manager.index_of_row(&row_id).await })
  }

  fn get_row_rev(&self, row_id: &str) -> Fut<Option<(usize, Arc<RowRevision>)>> {
    let block_manager = self.blocks.clone();
    let row_id = row_id.to_owned();
    to_fut(async move {
      match block_manager.get_row_rev(&row_id).await {
        Ok(indexed_row) => indexed_row,
        Err(_) => None,
      }
    })
  }

  fn get_row_revs(&self, block_id: Option<Vec<String>>) -> Fut<Vec<Arc<RowRevision>>> {
    let block_manager = self.blocks.clone();

    to_fut(async move {
      let blocks = block_manager.get_blocks(block_id).await.unwrap();
      blocks
        .into_iter()
        .flat_map(|block| block.row_revs)
        .collect::<Vec<Arc<RowRevision>>>()
    })
  }

  // /// Returns the list of cells corresponding to the given field.
  // pub async fn get_cells_for_field(&self, field_id: &str) -> FlowyResult<Vec<RowSingleCellData>> {
  // }

  fn get_blocks(&self) -> Fut<Vec<DatabaseBlockRowRevision>> {
    let block_manager = self.blocks.clone();
    to_fut(async move { block_manager.get_blocks(None).await.unwrap_or_default() })
  }

  fn get_task_scheduler(&self) -> Arc<RwLock<TaskDispatcher>> {
    self.task_scheduler.clone()
  }

  fn get_type_option_cell_handler(
    &self,
    field_rev: &FieldRevision,
    field_type: &FieldType,
  ) -> Option<Box<dyn TypeOptionCellDataHandler>> {
    TypeOptionCellExt::new_with_cell_data_cache(field_rev, Some(self.cell_data_cache.clone()))
      .get_type_option_cell_data_handler(field_type)
  }
}
