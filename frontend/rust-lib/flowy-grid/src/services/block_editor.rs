use bytes::Bytes;
use flowy_error::{FlowyError, FlowyResult};
use flowy_http_model::revision::Revision;
use flowy_revision::{
    RevisionCloudService, RevisionManager, RevisionMergeable, RevisionObjectDeserializer, RevisionObjectSerializer,
};
use flowy_sync::client_grid::{GridBlockRevisionChangeset, GridBlockRevisionPad};
use flowy_sync::util::make_operations_from_revisions;
use grid_rev_model::{CellRevision, GridBlockRevision, RowChangeset, RowRevision};
use lib_infra::future::FutureResult;

use flowy_database::ConnectionPool;
use lib_ot::core::EmptyAttributes;
use std::borrow::Cow;
use std::sync::Arc;
use tokio::sync::RwLock;

pub struct GridBlockRevisionEditor {
    #[allow(dead_code)]
    user_id: String,
    pub block_id: String,
    pad: Arc<RwLock<GridBlockRevisionPad>>,
    rev_manager: Arc<RevisionManager<Arc<ConnectionPool>>>,
}

impl GridBlockRevisionEditor {
    pub async fn new(
        user_id: &str,
        token: &str,
        block_id: &str,
        mut rev_manager: RevisionManager<Arc<ConnectionPool>>,
    ) -> FlowyResult<Self> {
        let cloud = Arc::new(GridBlockRevisionCloudService {
            token: token.to_owned(),
        });
        let block_revision_pad = rev_manager.initialize::<GridBlockRevisionSerde>(Some(cloud)).await?;
        let pad = Arc::new(RwLock::new(block_revision_pad));
        let rev_manager = Arc::new(rev_manager);
        let user_id = user_id.to_owned();
        let block_id = block_id.to_owned();
        Ok(Self {
            user_id,
            block_id,
            pad,
            rev_manager,
        })
    }

    pub async fn close(&self) {
        self.rev_manager.generate_snapshot().await;
        self.rev_manager.close().await;
    }

    pub async fn duplicate_block(&self, duplicated_block_id: &str) -> GridBlockRevision {
        self.pad.read().await.duplicate_data(duplicated_block_id).await
    }

    /// Create a row after the the with prev_row_id. If prev_row_id is None, the row will be appended to the list
    pub(crate) async fn create_row(
        &self,
        row: RowRevision,
        prev_row_id: Option<String>,
    ) -> FlowyResult<(i32, Option<i32>)> {
        let mut row_count = 0;
        let mut row_index = None;
        self.modify(|block_pad| {
            if let Some(start_row_id) = prev_row_id.as_ref() {
                match block_pad.index_of_row(start_row_id) {
                    None => {}
                    Some(index) => row_index = Some(index as i32 + 1),
                }
            }

            let change = block_pad.add_row_rev(row, prev_row_id)?;
            row_count = block_pad.number_of_rows();

            if row_index.is_none() {
                row_index = Some(row_count - 1);
            }
            Ok(change)
        })
        .await?;

        Ok((row_count, row_index))
    }

    pub async fn delete_rows(&self, ids: Vec<Cow<'_, String>>) -> FlowyResult<i32> {
        let mut row_count = 0;
        self.modify(|block_pad| {
            let changeset = block_pad.delete_rows(ids)?;
            row_count = block_pad.number_of_rows();
            Ok(changeset)
        })
        .await?;
        Ok(row_count)
    }

    pub async fn update_row(&self, changeset: RowChangeset) -> FlowyResult<()> {
        self.modify(|block_pad| Ok(block_pad.update_row(changeset)?)).await?;
        Ok(())
    }

    pub async fn move_row(&self, row_id: &str, from: usize, to: usize) -> FlowyResult<()> {
        self.modify(|block_pad| Ok(block_pad.move_row(row_id, from, to)?))
            .await?;
        Ok(())
    }

    pub async fn index_of_row(&self, row_id: &str) -> Option<usize> {
        self.pad.read().await.index_of_row(row_id)
    }

    pub async fn number_of_rows(&self) -> i32 {
        self.pad.read().await.rows.len() as i32
    }

    pub async fn get_row_rev(&self, row_id: &str) -> FlowyResult<Option<(usize, Arc<RowRevision>)>> {
        if self.pad.try_read().is_err() {
            tracing::error!("Required grid block read lock failed");
            Ok(None)
        } else {
            let row_rev = self.pad.read().await.get_row_rev(row_id);
            Ok(row_rev)
        }
    }

    pub async fn get_row_revs<T>(&self, row_ids: Option<Vec<Cow<'_, T>>>) -> FlowyResult<Vec<Arc<RowRevision>>>
    where
        T: AsRef<str> + ToOwned + ?Sized,
    {
        let row_revs = self.pad.read().await.get_row_revs(row_ids)?;
        Ok(row_revs)
    }

    pub async fn get_cell_revs(
        &self,
        field_id: &str,
        row_ids: Option<Vec<Cow<'_, String>>>,
    ) -> FlowyResult<Vec<CellRevision>> {
        let cell_revs = self.pad.read().await.get_cell_revs(field_id, row_ids)?;
        Ok(cell_revs)
    }

    async fn modify<F>(&self, f: F) -> FlowyResult<()>
    where
        F: for<'a> FnOnce(&'a mut GridBlockRevisionPad) -> FlowyResult<Option<GridBlockRevisionChangeset>>,
    {
        let mut write_guard = self.pad.write().await;
        match f(&mut write_guard)? {
            None => {}
            Some(change) => {
                self.apply_change(change).await?;
            }
        }
        Ok(())
    }

    async fn apply_change(&self, change: GridBlockRevisionChangeset) -> FlowyResult<()> {
        let GridBlockRevisionChangeset { operations: delta, md5 } = change;
        let data = delta.json_bytes();
        let _ = self.rev_manager.add_local_revision(data, md5).await?;
        Ok(())
    }
}

struct GridBlockRevisionCloudService {
    #[allow(dead_code)]
    token: String,
}

impl RevisionCloudService for GridBlockRevisionCloudService {
    #[tracing::instrument(level = "trace", skip(self))]
    fn fetch_object(&self, _user_id: &str, _object_id: &str) -> FutureResult<Vec<Revision>, FlowyError> {
        FutureResult::new(async move { Ok(vec![]) })
    }
}

struct GridBlockRevisionSerde();
impl RevisionObjectDeserializer for GridBlockRevisionSerde {
    type Output = GridBlockRevisionPad;

    fn deserialize_revisions(object_id: &str, revisions: Vec<Revision>) -> FlowyResult<Self::Output> {
        let pad = GridBlockRevisionPad::from_revisions(object_id, revisions)?;
        Ok(pad)
    }

    fn recover_operations_from_revisions(_revisions: Vec<Revision>) -> Option<Self::Output> {
        None
    }
}

impl RevisionObjectSerializer for GridBlockRevisionSerde {
    fn combine_revisions(revisions: Vec<Revision>) -> FlowyResult<Bytes> {
        let operations = make_operations_from_revisions::<EmptyAttributes>(revisions)?;
        Ok(operations.json_bytes())
    }
}

pub struct GridBlockRevisionMergeable();
impl RevisionMergeable for GridBlockRevisionMergeable {
    fn combine_revisions(&self, revisions: Vec<Revision>) -> FlowyResult<Bytes> {
        GridBlockRevisionSerde::combine_revisions(revisions)
    }
}
